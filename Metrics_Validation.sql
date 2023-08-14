#1.How does the revenue generated from document registration vary
#across districts in Telangana? List down the top 5 districts that showed
#the highest document registration revenue growth between FY 2019
#and 2022.

#Solution ----correct

#Total revenue
select d.district,
		sum(f.documents_registered_rev)as tot
from dim_districts d
join fact_stamps f
on d.dist_code=f.dist_code
group by 1
order by 2 desc;

#Top % districts by revenue growth

select d.district,
        sum(b.rev_growth) as net_rev
from(
		select dist_code, 
				yr_date,     
				total_rev,
				lag(total_rev,1,0)over(partition by dist_code order by yr_date) as prev_total_rev,
				total_rev-lag(total_rev,1,0)over(partition by dist_code order by yr_date) as rev_growth
		from (
				select dist_code,
						year(month) as yr_date,
						sum(documents_registered_rev) as total_rev 
				from fact_stamps
				group by 1,2
				having yr_date between 2019 and 2022
		) a
		group by 1,2
		order by 1,2 asc
) b
join dim_districts d
on b.dist_code = d.dist_code
group by 1 
order by net_rev desc 
limit 5
;

#Test Condition
select sb.dist_code,yr_date,sum(sb.documents_registered_rev) as cnt
from(
select dist_code,year(month)as yr_date ,documents_registered_rev
from fact_stamps
where dist_code = "14_1"
) sb
group by 1,2
order by 1,2;



#2.How does the revenue generated from document registration compare
#to the revenue generated from e-stamp challans across districts? List
#down the top 5 districts where e-stamps revenue contributes
#significantly more to the revenue than the documents in FY 2022?

#Solution --correvt
select dist_code,
		year(month) as yr,
		sum(documents_registered_rev) as tot_doc_rev,
        sum(estamps_challans_rev) as tot_estamp_rev
from fact_stamps
where year(month) =2022
group by 1,2
order by (tot_estamp_rev-tot_doc_rev) desc limit 5;

#Test
select dist_code,
		(tot_estamp_rev-tot_doc_rev) as diff_rev
from(
select dist_code,
		year(month) as yr,
		sum(documents_registered_rev) as tot_doc_rev,
        sum(estamps_challans_rev) as tot_estamp_rev
from fact_stamps
where year(month) =2022
group by 1,2
)a
order by diff_rev desc 
;

select * from fact_stamps;

#3. Is there any alteration of e-Stamp challan count and document
#registration count pattern since the implementation of e-Stamp
#challan? If so, what suggestions would you propose to the
#government?

# Solution--- the resgistration count has increased after the introduction of estamp challans
with before_est as(
select dist_code,sum(documents_registered_cnt) as tot_drc_before, sum(estamps_challans_cnt) as tot_estamp_before
from fact_stamps
where estamps_challans_cnt  in (0)
group by 1
order by 1 asc),

after_est as(
select dist_code,sum(documents_registered_cnt) as tot_drc_after, sum(estamps_challans_cnt) as tot_estamp_after
from fact_stamps
where estamps_challans_cnt  not in (0)
group by 1
order by 1 asc)

select b.dist_code,
		b.tot_drc_before,
        a.tot_drc_after,
        b.tot_estamp_before,
        a.tot_estamp_after
from before_est b
join after_est a
on b.dist_code = a.dist_code;


#4. Categorize districts into three segments based on their stamp
#registration revenue generation during the fiscal year 2021 to 2022.

#Solution
select dist_code,
		tot_rev,
		case 
			when segments =1 then "High Revenue"
			when segments =2 then "Average Revenue"
			when segments =3 then "Low Revenue"
		end as "Remarks"
from(
		select dist_code, 
        sum(estamps_challans_rev) as tot_rev,
        ntile(3) over( order by sum(estamps_challans_rev) desc) as segments
		from fact_stamps
		where year(month) between 2021 and 2022
		group by 1
		order by 1
		)a
order by 2 desc;


#5. Investigate whether there is any correlation between vehicle sales and
#specific months or seasons in different districts. Are there any months
#or seasons that consistently show higher or lower sales rate, and if yes,
#what could be the driving factors? (Consider Fuel-Type category only)


select * from fact_transport;

select dist_code,
		month(month) as mn,
		sum(fuel_type_petrol) as sftp,
		sum(fuel_type_diesel) as sftd,
		sum(fuel_type_electric) as sfte,
		sum(fuel_type_others) as sfto
from fact_transport
group by 1,2
order by 1,2
;


select dist_code,mn,
        max(sftp),max(sftd),max(sfte),max(sfto)
from(
		select dist_code,
				month(month) as mn,
				sum(fuel_type_petrol) as sftp,
				sum(fuel_type_diesel) as sftd,
				sum(fuel_type_electric) as sfte,
				sum(fuel_type_others) as sfto
		from fact_transport
		group by 1,2
		order by 1,2
        )a
group by 1,2
order by 3 desc;


select dist_code,
		mn,
        min(sftp),min(sftd),min(sfte),min(sfto)
from(
		select dist_code,
				month(month) as mn,
				sum(fuel_type_petrol) as sftp,
				sum(fuel_type_diesel) as sftd,
				sum(fuel_type_electric) as sfte,
				sum(fuel_type_others) as sfto
		from fact_transport
		group by 1,2
		order by 1,2
        )a
group by 1,2
order by 3 asc;


#6. How does the distribution of vehicles vary by vehicle class
#MotorCycle, MotorCar, AutoRickshaw, Agriculture) across different
#districts? Are there any districts with a predominant preference for a
#specific vehicle class? Consider FY 2022 for analysis.

#Solution ---correct
select dist_code,sum(vehicleClass_MotorCycle),sum(vehicleClass_MotorCar),sum(vehicleClass_AutoRickshaw),sum(vehicleClass_Agriculture),sum(vehicleClass_others)
from fact_transport
where year(month) = 2022
group by 1
order by 1 asc;

#vehicleClass 				Max dist_code		Min dist_code
#vehicleClass_MotorCycle		16_1				19_4
#vehicleClass_MotorCar			15_1				19_4
#vehicleClass_AutoRickshaw		16_1				15_2
#vehicleClass_Agriculture		23_1				16_1
#vehicleClass_others			15_1				20_3


#7. List down the top 3 and bottom 3 districts that have shown the highest
#and lowest vehicle sales growth during FY 2022 compared to FY
#2021? (Consider and compare categories: Petrol, Diesel and Electric)


with base_cte as(
	select dist_code,
			sum(case when year(month) = 2022 then fuel_type_petrol end) as sftp_22,
            sum(case when year(month) = 2022 then fuel_type_diesel end) as sftd_22,
			sum(case when year(month) = 2022 then fuel_type_electric end) as sfte_22,
			sum(case when year(month) = 2021 then fuel_type_petrol end) as sftp_21,
            sum(case when year(month) = 2021 then fuel_type_diesel end) as sftd_21,
			sum(case when year(month) = 2021 then fuel_type_electric end) as sfte_21
	from fact_transport
    where year(month) in (2022,2021)
    group by dist_code
    order by dist_code asc
)
select dist_code,
		sftp_22-sftp_21 as net_sftp,
		sftd_22-sftd_21 as net_sftd,
		sfte_22-sfte_21 as net_sfte
from base_cte;

select * from fact_transport;

with agg_table as(

select '2022' as yr,dist_code, sum(fuel_type_petrol) as sftp, sum(fuel_type_diesel) as sdtd, sum(fuel_type_electric) as sfte
from fact_transport
where year(month) = 2022
group by 1,2
Union
select '2021'as yr, dist_code, sum(fuel_type_petrol) as sftp, sum(fuel_type_diesel) as sdtd, sum(fuel_type_electric) as sfte
from fact_transport
where year(month) = 2021
group by 1,2
order by 2,1
),
lag_amt as(
select yr,
		dist_code,
        sftp,
        lag(sftp,1,0) over(partition by dist_code order by yr) as prev_sftp,
		sdtd,
        lag(sdtd,1,0) over(partition by dist_code order by yr) as prev_sdtd,
		sfte,
        lag(sfte,1,0) over(partition by dist_code order by yr) as prev_sfte
from agg_table
),
net_sales as(
select yr,
		dist_code,
        sftp -prev_sftp as net_sftp,
        sdtd -prev_sdtd as net_sdtd,
        sfte- prev_sfte as net_sfte
from lag_amt
where prev_sftp <> 0
)
(select 'Top Petrol' as pointer,
		dist_code,
        net_sftp
from net_sales
order by net_sftp desc limit 3)
union all
(select 'Bottom Petrol' as pointer,
		dist_code,
        net_sftp
from net_sales
order by net_sftp desc limit 3)
union all
(select 'Top Diesel' as pointer,
		dist_code,
        net_sdtd
from net_sales
order by net_sdtd desc limit 3)
union all
(select 'Bottom Diesel' as pointer,
		dist_code,
        net_sdtd
from net_sales
order by net_sdtd desc limit 3)
Union all
(select 'Top Electric' as pointer,
		dist_code,
        net_sfte
from net_sales
order by net_sfte desc limit 3)
union all
(select 'Bottom Electric' as pointer,
		dist_code,
        net_sfte
from net_sales
order by net_sfte desc limit 3)
;


#8.List down the top 5 sectors that have witnessed the most significant
#investments in FY 2022.

select * from fact_ts_ipass;

#Solution
select sector,
round(sum(`investment in cr`),2) as sm
from fact_ts_ipass
where year(month) = 2022
group by sector
order by sm desc
limit 5;

#9. List down the top 3 districts that have attracted the most significant
#sector investments during FY 2019 to 2022? What factors could have
#led to the substantial investments in these particular districts?

#Solution

select dist_code,
		round(sum(`investment in cr`),2) as tot_inv
from fact_ts_ipass
where year(month) between 2019 and 2022
group by dist_code
order by tot_inv desc
limit 5;

#10. Is there any relationship between district investments, vehicles
#sales and stamps revenue within the same district between FY 2021
# and 2022?;

select * from fact_transport;
select * from fact_stamps;
select * from fact_ts_ipass;

with cte as (
	select dist_code,
	coalesce(sum(t.vehicleClass_MotorCycle),0) as tm,
    coalesce(sum(t.vehicleClass_MotorCar),0) tmc,
    coalesce(sum(t.vehicleClass_AutoRickshaw),0) tar,
    coalesce(sum(t.vehicleClass_Agriculture),0) ta,
    coalesce(sum(t.vehicleClass_others),0) tos
from fact_transport t
group by 1
)
select p.dist_code,
		round(sum(p.`investment in cr`),2) as total_investment_cr,
        round(sum(s.estamps_challans_rev),2) as total_estamps_rev,
		t.tm + t.tmc + t.tar + t.ta + t.tos	as total_vehicle_sales
from fact_ts_ipass p 
join cte t
on p.dist_code = t.dist_code
join fact_stamps s
on p.dist_code = s.dist_code
where year(p.month) between 2021 and 2022
group by p.dist_code;


#11.Are there any particular sectors that have shown substantial
#investment in multiple districts between FY 2021 and 2022?

select * from fact_ts_ipass;

select sector,
		dist_code,
		round(sum(`investment in cr`),2) as tot_inv
from fact_ts_ipass
where year(month) between 2021 and 2022
group by 1,2
order by 3 desc;

#12. Can we identify any seasonal patterns or cyclicality in the
#investment trends for specific sectors? Do certain sectors
# experience higher investments during particular months?

select sector,
		month(month) as mn,
		round(sum(`investment in cr`),2) as tot_inv
from fact_ts_ipass
where year(month) between 2021 and 2022
group by 2,1
;

#What are the top 5 districts to buy commercial properties in
#Telangana? Justify your answer. 

select * from fact_ts_ipass;
select * from fact_transport;
