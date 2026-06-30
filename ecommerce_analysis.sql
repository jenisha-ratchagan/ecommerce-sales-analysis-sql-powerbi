USE ecommerce_analysis;

SHOW tables;

DESC online_retail_sales;

select * from online_retail_sales
limit 5; 

select COUNT(*) as total_rows from online_retail_sales;

select COUNT(*) as missing_customerids from online_retail_sales
where `Customer ID` is null;

select COUNT(*) as missing_decriptions from online_retail_sales
where `Description` is null;

select COUNT(*) as zero_quantities from online_retail_sales
where `Quantity` <= 0;

select round(sum(Quantity * Price),2) as total_revenue
from  online_retail_sales;

select Description, round(sum(Quantity * Price), 2) as revenue
from online_retail_sales
group by Description
order by revenue desc
limit 10;

select `Customer ID`,round(sum(Quantity * Price), 2) as revenue_bycustomers
from online_retail_sales
group by `Customer ID`
order by revenue_bycustomers desc
limit 10;

select Country,count(distinct Invoice) as total_orders
from online_retail_sales
group by Country
order by total_orders desc
limit 10;

with customer_revenue as(
select Country,`Customer ID`,round(sum(Quantity * Price),2) as revenue
from online_retail_sales
group by Country,`Customer ID`
)
select *
from
(
select *,
dense_rank() over(partition by Country order by revenue desc) as ranking
from customer_revenue
)t
where ranking <=3;

select YEAR(InvoiceDate) as sales_year,
MONTH(InvoiceDate) as sales_month,
round(sum(Quantity * Price),2) as revenue
from online_retail_sales
group by YEAR(InvoiceDate),MONTH(InvoiceDate)
order by sales_year,sales_month desc;

WITH cust_revenue AS
(
    SELECT 
        `Customer ID` AS customer_id,
        ROUND(SUM(Quantity * Price), 2) AS revenue
    FROM online_retail_sales
    WHERE `Customer ID` IS NOT NULL
    GROUP BY `Customer ID`
)

SELECT 
    customer_id,
    revenue,
    CASE
        WHEN revenue >= 500 THEN 'High_value'
        WHEN revenue >= 200 THEN 'Medium_value'
        ELSE 'Low_value'
    END AS customer_segment
FROM cust_revenue
ORDER BY revenue DESC;

with customer_country_revenue as(
 select `Customer ID`as customer_id,Country,round(sum(Quantity * Price),2) as revenue
 from online_retail_sales
 where `Customer ID` is not null
 group by `Customer ID`,Country
 ),
customer_rank as(
SELECT
    Country,
    customer_id,
    revenue,
    ROW_NUMBER() OVER(
        PARTITION BY Country
        ORDER BY revenue DESC
    ) AS rank_no
FROM customer_country_revenue
)
select * from customer_rank
where rank_no <=3;

with customer_behaviour as(
  select `Customer ID` as customer_id,
  count(distinct Invoice) as total_orders from online_retail_sales
  where `Customer ID` is not null
  group by customer_id
  ),
customer_types as(
select 
  customer_id,
  total_orders,
  case
    when total_orders > 1 then "Repeated_customer"
    else "Onetime_customer"
  end as customer_type
from customer_behaviour
)
select customer_type,count(customer_id)
from customer_types
group by customer_type;

with customer_rfm as(
select `Customer ID` as customer_id,
datediff(max(InvoiceDate), min(InvoiceDate)) as customer_lifetime,
count(distinct Invoice) as total_orders,
round(sum(Quantity * Price), 2) as total_spent
from online_retail_sales
where `Customer ID` is not null
group by `Customer ID`
order by total_spent desc
)
select 
    customer_id,
    customer_lifetime,
    total_orders,
    total_spent,
    case
    when total_spent >= 1000
      and total_orders >= 10
	then "VIP customer"
    
    when total_orders >=5
    then "Loyal customer"
    
    when total_orders =1
    then "Onetime customer"
    
    else "Regular customer"
    
    end as customer_segment_analysis
from customer_rfm
order by total_spent desc


