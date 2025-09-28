
drop view if exists purchases_info;
create view purchases_info as
# create tow columns to mark whether the plan fall in Q2 of 2021 and 2022 separately
select * ,
       case when sub1.date_end < '2021-04-01'then 0 
            when sub1.date_start > '2021-06-30' then 0 
            else 1 end as paid_q2_2021,
       case when sub1.date_end < '2022-04-01' then 0 
            when sub1.date_start > '2022-06-30' then 0 
            else 1 end as paid_q2_2022    
from (
# Rectify plan_end_date in case of refunds
select sub.purchase_id , sub.student_id , sub.plan_id , sub.date_purchased as date_start , 
       case when sub.date_refunded is null then sub.date_end else sub.date_refunded end as date_end 
from (
# Calculating the end_date from date_purchased and plan_id
select *,
       case when plan_id = 0 then date_add(date_purchased, interval 1  month ) 
            when plan_id = 1 then date_add(date_purchased, interval 3 month)
            when plan_id = 2 then date_add(date_purchased, interval 12 month)
       end as date_end
from student_purchases )sub
)sub1

# Calculating total watched time in min for each student in Q2 2021
select  student_id , sum(round(seconds_watched/60 , 2)) as minutes_watched
from student_video_watched
where  (YEAR(date_watched) = 2021 AND QUARTER(date_watched) = 2)
group by student_id ) sub

# Calculating total watched time in min for each student in Q2 2022
select  student_id , sum(round(seconds_watched/60 , 2)) as minutes_watched
from student_video_watched
where  (YEAR(date_watched) = 2022 AND QUARTER(date_watched) = 2)
group by student_id ) sub

# Retriving four datasets with students total watch time in Q2 for further analysis; 
# dataset for students engaged in Q2 2022 who have had a paid subscription
select count(*) from (
select sub.student_id, (sub.minutes_watched)   , pi.paid_q2_2022 as paid_in_q2 
from (
select  student_id , sum(round(seconds_watched/60 , 2)) as minutes_watched
from student_video_watched
where  (YEAR(date_watched) = 2022 AND QUARTER(date_watched) = 2)
group by student_id ) sub
join purchases_info pi
on sub.student_id = pi.student_id                           
group by sub.student_id , paid_in_q2 
having  paid_in_q2 = 1)sub1

# Students total_watched time and number of certificate issued
select sub.student_id, sub.num_certificate as certificates_issued , 
	   case when sub2.minutes_watched is null then 0 
       else sub2.minutes_watched end as minutes_watched
from (
select  student_id , count(certificate_id) as num_certificate
from student_certificates
group by student_id)sub
left join (
select  student_id , sum(round(seconds_watched/60 , 2)) as minutes_watched
from student_video_watched
group by student_id)sub2
on sub2.student_id = sub.student_id 
 