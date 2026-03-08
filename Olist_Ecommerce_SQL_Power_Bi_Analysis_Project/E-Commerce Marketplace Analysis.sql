-- ======================================================
-- E-Commerce Marketplace Analysis (SQL)
-- Dataset: Olist Brazilian E-Commerce Dataset (100k orders)
-- Tools: SQL Server
--
-- Analysis Topics:
-- 1. Revenue (GMV) Analysis
-- 2. Customer Behavior
-- 3. Seller Performance
-- 4. Logistics & Delivery Performance
-- 5. Payment Analysis
-- ======================================================

--1. Total GMV
USE Olist_ECommerce;
GO

SELECT 
    ROUND(SUM(oi.price + oi.freight_value), 2) AS Total_GMV
FROM order_items oi
JOIN orders as o 
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';

----------------------------------------------------------------------
--2. Monthly GMV Trend
SELECT 
    YEAR(o.order_purchase_timestamp) AS Order_Year,
    MONTH(o.order_purchase_timestamp) AS Order_Month,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS Monthly_GMV,
    COUNT(DISTINCT oi.order_id) AS Total_Orders
FROM order_items as oi
JOIN orders as o 
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 
    YEAR(o.order_purchase_timestamp), 
    MONTH(o.order_purchase_timestamp)
ORDER BY 
    Order_Year, 
    Order_Month;

----------------------------------------------------------------------
--3. Top Product Categories
SELECT TOP 5
    pt.column2 AS Category,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS Total_Revenue

FROM order_items as oi
JOIN orders as o 
    ON oi.order_id = o.order_id
JOIN products as p 
    ON oi.product_id = p.product_id
JOIN product_category_name_translation as pt 
    ON p.product_category_name = pt.column1
WHERE o.order_status = 'delivered'
  AND pt.column1 != 'product_category_name'
GROUP BY 
    pt.column2
ORDER BY 
    Total_Revenue DESC;

----------------------------------------------------------------------
--4. Top Customers by Total Orders
select top 10 
c.customer_unique_id as Customer, count(o.customer_id) as Total_Orders
from customers as c
join orders as o

on c.customer_id = o.customer_id
where o.order_status = 'delivered'
group by c.customer_unique_id
order by Total_Orders desc;

----------------------------------------------------------------------
--5. Top Customers by Total Spent
select TOP 10

c.customer_unique_id as Customer, 
count(distinct oi.order_id) as Total_Order, --can remove
round(sum(oi.price + oi.freight_value),2 ) as Total_Spent

from customers as c
join orders as o
on c.customer_id = o.customer_id

join order_items as oi
on o.order_id = oi.order_id

where o.order_status = 'delivered'
group by c.customer_unique_id
order by Total_Spent desc;

----------------------------------------------------------------------
--6. Top Customers by Total Spent and Their City
select TOP 10

c.customer_unique_id as Customer, 
round(sum(oi.price + oi.freight_value),2 ) as Total_Spent ,
c.customer_city as City

from customers as c
join orders as o
on c.customer_id = o.customer_id

join order_items as oi
on o.order_id = oi.order_id

where o.order_status = 'delivered'
group by c.customer_unique_id, c.customer_city
order by Total_Spent desc;

----------------------------------------------------------------------
--7. Top Sellers by Total Orders Yearly
select Top 10
s.seller_id as Seller, count(oi.seller_id) as Total_Order,
YEAR(o.order_purchase_timestamp) as Years

from sellers as s
join order_items as oi

on s.seller_id = oi.seller_id

join orders as o
on o.order_id = oi.order_id

where Year(o.order_purchase_timestamp) = 2018 -- change to 2017 / 2016 

group by s.seller_id , Year(o.order_purchase_timestamp)
order by Total_Order desc;

----------------------------------------------------------------------
--8. Top Sellers by Total Sales
select Top 10
s.seller_id as Seller, count(oi.seller_id) as Total_Order , round(sum(oi.price + oi.freight_value), 2) as Total_Sales

from sellers as s
join order_items as oi

on s.seller_id = oi.seller_id

group by s.seller_id
order by Total_Sales desc;
----------------------------------------------------------------------

--9. Top Sellers by Total Sales & Rating
select Top 10
s.seller_id as Seller, avg(orr.review_score) as Avg_Review, round(sum(oi.price + oi.freight_value),2) as Total_Sales

from sellers as s
join order_items as oi

on s.seller_id = oi.seller_id

join order_reviews as orr

on oi.order_id = orr.order_id

group by s.seller_id 

having count(oi.order_id) > 10

order by Total_Sales desc ;

----------------------------------------------------------------------
--10. Top Orders & Sellers by Late Delivery 
select Top 10

o.order_id as Order_Reciept, order_estimated_delivery_date as Promised_Delivery , o.order_delivered_customer_date as Actual_Delivery,
DATEDIFF(day, o.order_estimated_delivery_date, o.order_delivered_customer_date) as Days_Late, s.seller_id as Seller_ID

from orders as o
join order_items as oi
on o.order_id = oi.order_id

join sellers as s 
on s.seller_id = oi.seller_id 

where order_status = 'delivered' and order_delivered_customer_date > order_estimated_delivery_date

order by Days_Late desc;

----------------------------------------------------------------------
--11. Late Delivery Percentage by Year
select 
count(order_id) as Total_Order ,
Year(order_purchase_timestamp) as Years,

sum(case when order_delivered_customer_date > order_estimated_delivery_date then 1 else 0 end) as Late_Delivery,

round(sum(case when order_delivered_customer_date > order_estimated_delivery_date then 100.0 else 0.0 end)/ count(order_id), 2) as Late_Percentage

from orders

where order_status = 'delivered'

group by Year(order_purchase_timestamp);

----------------------------------------------------------------------
--12. Delivery Type by Average Rating
select 
case when o.order_delivered_customer_date <= o.order_estimated_delivery_date then 'On-Time' else 'Late' end as Delivery,
count(o.order_id) as Total_Sales,
round(avg(orr.review_score*1.0),2) as Avg_Rating

from orders as o
join order_reviews as orr

on o.order_id = orr.order_id
 
where o.order_status = 'delivered'

group by case when o.order_delivered_customer_date <= o.order_estimated_delivery_date then 'On-Time' else 'Late' end ;

----------------------------------------------------------------------
--13. Payment Type by Total Order
select payment_type as Payment_Type, count(order_id) as Total_Order

from order_payments

where payment_type != 'not_defined'

group by payment_type

order by Total_Order desc;

----------------------------------------------------------------------
--1. Top Sellers by Average Review
select Top 10
s.seller_id as Seller, avg(orr.review_score) as Avg_Review, round(sum(oi.price + oi.freight_value),2) as Total_Sales

from sellers as s
join order_items as oi

on s.seller_id = oi.seller_id

join order_reviews as orr

on oi.order_id = orr.order_id

group by s.seller_id 

having count(oi.order_id) > 10

order by Avg_Review desc ;

