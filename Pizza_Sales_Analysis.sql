create database pizza_project;
use pizza_project;

select * from order_details limit 10;
select * from orders limit 10;
select * from pizza_types;
select * from pizzas;

-- Retrieve the total number of orders placed.
select count(distinct order_id) as total_orders from orders;

-- Calculate the total revenue generated from pizza sales.
select round(sum(price*quantity),2) as revenue from order_details od
join pizzas p on od.pizza_id = p.pizza_id;

-- Identify the highest-priced pizza.
Select name, price from pizzas p
join pizza_types pt
on p.pizza_type_id = pt.pizza_type_id
order by price desc limit 1;

-- Alternate solution ( using WINDOW function)
with cte as (
select name, price, rank() over(order by price desc) as rnk from pizzas p 
join pizza_types pt 
on p.pizza_type_id = pt.pizza_type_id)
select name, price from cte where rnk=1;

-- Identify the most common pizza size ordered. 
Select size, count(distinct order_id) as no_of_orders, sum(quantity) as total_quantity_ordered from order_details od
join pizzas p
on od.pizza_id=p.pizza_id
group by size
order by count(distinct order_id) desc;

-- List the top 5 most ordered pizza types along with their quantities.
SELECT name, sum(quantity) from pizza_types pt
join pizzas p 
on p.pizza_type_id = pt.pizza_type_id
join order_details od
on od.pizza_id = p.pizza_id
group by name
order by sum(quantity) desc limit 5;

-- Intermediate:
-- Find the total quantity of each pizza category ordered (this will help us to understand the category which customers prefer the most).
SELECT category, sum(quantity) from pizza_types pt
join pizzas p 
on p.pizza_type_id = pt.pizza_type_id
join order_details od
on od.pizza_id = p.pizza_id
group by category
order by sum(quantity) desc;

-- Determine the distribution of orders by hour of the day (at which time the orders are maximum (for inventory management and resource allocation).
SELECT extract(hour from time) as hour_of_day, count(distinct order_id) as no_of_orders 
from orders
group by extract(hour from time)
order by count(distinct order_id) desc;

-- Find the category-wise distribution of pizzas (to understand customer behaviour).
select category, count(distinct pizza_type_id) as pizza_types
from pizza_types
group by category
order by pizza_types desc;

-- Group the orders by date and calculate the average number of pizzas ordered per day.
with cte as(
select orders.date as Date, sum(order_details.quantity) as Total_Pizza_Ordered_that_day
from order_details
join orders on order_details.order_id = orders.order_id
group by orders.date
)
select avg(Total_Pizza_Ordered_that_day) as Avg_Number_of_pizzas_ordered_per_day from cte;

-- alternate using subquery
select avg(Total_Pizza_Ordered_that_day) as Avg_Number_of_pizzas_ordered_per_day from 
(
	select orders.date as date, sum(order_details.quantity) as Total_Pizza_Ordered_that_day
	from order_details
	join orders on order_details.order_id = orders.order_id
	group by orders.date
) as pizzas_ordered;

-- Determine the top 3 most ordered pizza types based on revenue (let's see the revenue wise pizza orders to understand from sales perspective which pizza is the best selling)
select pt.name, sum(price*quantity) as revenue from order_details od
join pizzas p on od.pizza_id=p.pizza_id
join pizza_types pt on pt.pizza_type_id=p.pizza_type_id
group by name
order by revenue desc limit 3;

/*
Advanced:
Calculate the percentage contribution of each pizza type to total revenue.
Analyze the cumulative revenue generated over time.
Determine the top 3 most ordered pizza types based on revenue for each pizza category.
*/


-- Calculate the percentage contribution of each pizza type to total revenues


select pizza_types.category, 
concat(cast((sum(order_details.quantity*pizzas.price) /
(select sum(order_details.quantity*pizzas.price) 
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id 
))*100 as decimal(10,2)), '%')
as Revenue_contribution_from_pizza
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.category;
-- order by [Revenue from pizza] desc

-- revenue contribution from each pizza by pizza name
select pizza_types.name, 
concat(cast((sum(order_details.quantity*pizzas.price) /
(select sum(order_details.quantity*pizzas.price) 
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id 
))*100 as decimal(10,2)), '%')
as Revenue_contribution_from_pizza
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by pizza_types.name
order by Revenue_contribution_from_pizza desc;


-- Analyze the cumulative revenue generated over time.
-- use of aggregate window function (to get the cumulative sum)
with cte as (
select date as Date, cast(sum(quantity*price) as decimal(10,2)) as Revenue
from order_details 
join orders on order_details.order_id = orders.order_id
join pizzas on pizzas.pizza_id = order_details.pizza_id
group by date
-- order by [Revenue] desc
)
select Date, Revenue, sum(Revenue) over (order by date) as Cumulative_Sum
from cte 
group by date, Revenue;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

with cte as (
select category, name, cast(sum(quantity*price) as decimal(10,2)) as Revenue
from order_details 
join pizzas on pizzas.pizza_id = order_details.pizza_id
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
group by category, name
-- order by category, name, Revenue desc
)
, cte1 as (
select category, name, Revenue,
rank() over (partition by category order by Revenue desc) as rnk
from cte 
)
select category, name, Revenue
from cte1 
where rnk in (1,2,3)
order by category, name, Revenue;