/* Total amount each customer spent at the restaurant
*/

select a.customer_id,sum(b.price) as 'customer_spending'
from sales as a left join menu as b 
on a.product_id = b.product_id
group by 1;

/*How many days has each customer visited the restaurant*/


select customer_id,count(distinct order_date) as num_days_visited
from sales
group by 1;

/*What was the first item from the menu purchased by each customer*/


with cte as (select customer_id, order_date,product_id,
dense_rank() over(partition by customer_id order by order_date asc) as rank_of_date
from sales)

select  cte.customer_id  ,  menu.product_name
from cte left join menu 
on cte.product_id = menu.product_id
where cte.rank_of_date = 1
group by cte.customer_id,menu.product_name;

/*What is the most purchased item on the menu and how many 
times was it purchased by all customers?
*/

with cte as (select  b.product_name, count(a.product_id) as most_purchased_product

from sales as a left join menu as b
on a.product_id = b.product_id
group by 1
order by most_purchased_product desc
limit 1) 
-- the most purchased item on the menu is Ramen, total  purchase 8 times
-- ramen product_id is 3
select customer_id, count(*) as " num of times ramen purchased"
from sales
where product_id = 3
group by customer_id;

/*Which item was the most popular one for each customer*/

-- The most  popular item will depend upon how many time does the customer buy
-- that item

with cte as (
select a.customer_id  as customer_id, a.product_id,b.product_name as product_name,
count(a.product_id) as num_count
, dense_rank() over(partition by a.customer_id order by count(a.product_id) desc) as d_rank
from sales as a left join menu as b 
on a.product_id = b.product_id
group by 1,2,3
order by a.customer_id)

select cte.customer_id ,cte.product_name,cte.num_count
from cte 
where cte.d_rank = 1;

/* Which item was purchased first by the customer after they became a member?*/

with member_sales_cte as 
(
 select s.customer_id, m.join_date, s.order_date, s.product_id,
 dense_rank() over(partition by s.customer_id
 order by s.order_date) as  rnk
 from sales as s
 join members as m
 on s.customer_id = m.customer_id
 where s.order_date >= m.join_date
)
select s.customer_id, s.order_date, m2.product_name 
from member_sales_cte as s
join menu as m2
 on s.product_id = m2.product_id
where rnk = 1;

/* Which item was purchased right before they customer became a member?
*/

with prior_member_purchased_cte as 
(
 select s.customer_id, m.join_date, s.order_date, s.product_id,
 dense_rank() over(partition by s.customer_id
 order by s.order_date desc) as rnk
 from sales as s
 join members as m
 on s.customer_id = m.customer_id
 where s.order_date < m.join_date
)
select s.customer_id, s.order_date, m2.product_name 
from prior_member_purchased_cte as s
join menu as m2
 on s.product_id = m2.product_id
where rnk = 1;

/*What is the total number of items and amount spent for each member 
before they became a member?
*/
-- since we have to find out the count of items sold, amount spent before they became member
-- so we will use all three tables
select 
s.customer_id, COUNT(distinct s.product_id) as unique_menu_item, 
SUM(mm.price) as total_sales
from sales as s
join 
members as m
on s.customer_id = m.customer_id
join menu as mm
on s.product_id = mm.product_id
where s.order_date < m.join_date
group by s.customer_id;


/*If each customers’ $1 spent equates to 10 points and sushi has a 2x points multiplier —
 how many points would each customer 
have?
*/
-- 1$ spent = 20 points but in sushi 1$ spent = 20 points
with price_points as
 (
 select *, 
 case when product_id = 1 then price * 20 else price * 10 end as  points
 from menu
 )
 select s.customer_id, SUM(p.points) as total_points
from 
price_points as p
join sales as s
on p.product_id = s.product_id
group by  
s.customer_id
order by
customer_id



