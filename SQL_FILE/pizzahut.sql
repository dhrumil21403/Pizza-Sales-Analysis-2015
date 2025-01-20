create database pizzahut;
use pizzahut;
create table orders(
order_id int not null,
date date not null,
time time not null,
primary key(order_id)
);
load data local infile "/Users/DHRUMIL/OneDrive/Desktop/websiteflythe nest/sqlproject/pizzasales/orders.csv"
into table orders 
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;
select * from orders;
show variables like 'local_infile';
set global local_infile = 1;
create table order_details (
order_details_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
primary key(order_details_id)
);
load data local infile "/Users/DHRUMIL/OneDrive/Desktop/websiteflythe nest/sqlproject/pizzasales/order_details.csv"
into table order_details 
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;

-- Basic:
-- Retrieve the total number of orders placed.
select count(*) from orders;
-- Calculate the total revenue generated from pizza sales.
select round(sum(price*quantity),2) as revenue_generated from order_details as o
inner join pizzas as p
on o.pizza_id=p.pizza_id;
-- Identify the highest-priced pizza.
select t.name,t.category,p.size,p.price from pizzas as p 
join pizza_types as t 
on p.pizza_type_id=t.pizza_type_id
order by p.price desc 
limit 1;
-- Identify the most common pizza size ordered.
select pt.name,count(o.quantity) as total from order_details as o 
join pizzas as p
on o.pizza_id=p.pizza_id
join pizza_types as pt
on p.pizza_type_id=pt.pizza_type_id
group by pt.name
order by total desc
limit 1;
-- List the top 5 most ordered pizza types along with their quantities.
select pt.name,count(o.quantity) as total from order_details as o 
join pizzas as p
on o.pizza_id=p.pizza_id
join pizza_types as pt
on p.pizza_type_id=pt.pizza_type_id
group by pt.name
order by total desc
limit 5;

-- Intermediate:
-- Join the necessary tables to find the total quantity of each pizza category ordered.
select pt.name,count(o.quantity) as total from order_details as o 
join pizzas as p
on o.pizza_id=p.pizza_id
join pizza_types as pt
on p.pizza_type_id=pt.pizza_type_id
group by pt.name
order by total desc;
-- Determine the distribution of orders by hour of the day.
select hour(time) as hours,count(*) as order_per_hour from orders
group by hours;
-- Join relevant tables to find the category-wise distribution of pizzas.
select pt.category, count(od.quantity) as pizza_count from pizza_types as pt
join pizzas as p
on pt.pizza_type_id=p.pizza_type_id
join order_details as od 
on p.pizza_id=od.pizza_id
group by pt.category;
-- Group the orders by date and calculate the average number of pizzas ordered per day.
select date,avg(quantity) as average from orders as o
join order_details as od
on o.order_id=od.order_id
group by date;
-- Determine the top 3 most ordered pizza types based on revenue.
select pt.name as pizza_type,pt.category,sum(od.quantity * p.price) as total_revenue
from order_details od
join pizzas p on od.pizza_id = p.pizza_id
join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
group by pt.name, pt.category
order by total_revenue desc
limit 3;

-- Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue.
select name,round((sum(price*quantity)/(select sum(p.price*od.quantity) as total_revenue from pizzas as p join order_details as od on p.pizza_id=od.pizza_id ))*100,2) as contribution
from pizzas as p 
join order_details as od on p.pizza_id=od.pizza_id
join pizza_types as pt on p.pizza_type_id=pt.pizza_type_id
group by pt.name
order by contribution desc;
-- Analyze the cumulative revenue generated over time.
select o.date,round(sum(sum(p.price*od.quantity)) over(partition by o.date),2) as cummulative_revenue
from orders as o 
join order_details as od on o.order_id=od.order_id 
join pizzas as p on od.pizza_id=p.pizza_id
group by o.date
order by cummulative_revenue desc;
-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
-- using subquerry
select name,category,revenue from
(select name,category,revenue,rank() over(partition by category order by revenue desc) as rn 
from
(select pt.name,pt.category,sum(od.quantity*p.price) as revenue from pizza_types as pt
join pizzas as p on pt.pizza_type_id=p.pizza_type_id 
join order_details as od on p.pizza_id=od.pizza_id
group by pt.category,pt.name) as a)as b
where rn<=3;
-- using cte
with revenueperpizza as (
select pt.name, pt.category, sum(od.quantity * p.price) as revenue
from pizza_types as pt
    join pizzas as p on pt.pizza_type_id = p.pizza_type_id
    join order_details as od on p.pizza_id = od.pizza_id
    group by pt.category, pt.name
),
rankedpizzas as (
select name, category, revenue, rank() over (partition by category order by revenue desc) as rn
from revenueperpizza
)
select name, category, revenue
from rankedpizzas
where rn <= 3;
