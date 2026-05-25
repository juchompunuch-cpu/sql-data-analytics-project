-- Advannced Data analytics Project 
-- # 7 Change-Over-Time 
-- Analyze Sales Performance Over Time.
select 
	year(order_date) as order_year,
	month(order_date) as order_month,
	sum(sales_amount) as Total_sales,
	count(distinct customer_key) as total_customers,
	sum(quantity) as total_quantity
from dbo.fact_sales
where order_date is not null
group by year(order_date), month(order_date)
order by year(order_date), month(order_date)

-- SAME RESULT BEFORE
select 
	DATETRUNC(month,order_date) as order_date,
	sum(sales_amount) as Total_sales,
	count(distinct customer_key) as total_customers,
	sum(quantity) as total_quantity
from dbo.fact_sales
where order_date is not null
group by DATETRUNC(month,order_date)
order by DATETRUNC(month,order_date)

--=================================================================================
-- # 8 Cumulative Analysis 
-- Calculate the total sales per month
-- and the running total of sales over time
select  
	order_date,
	total_sales,
	sum(total_sales) over (order by order_date) as Running_Total_sales
from (
select 
	DATETRUNC(month,order_date) as order_date,
	sum(sales_amount) as Total_sales
from dbo.fact_sales
where order_date is not null
group by DATETRUNC(month,order_date)
) t
order by DATETRUNC(month,order_date)

-- Calculate the total sales per year
-- and the running total of sales over time
select  
	order_date,
	total_sales,
	sum(total_sales) over (order by order_date) as Running_Total_sales,
	avg(total_sales) over (order by order_date) as moving_average_price
from (
select 
	DATETRUNC(YEAR,order_date) as order_date,
	sum(sales_amount) as Total_sales,
	avg(price) as avg_price
from dbo.fact_sales
where order_date is not null
group by DATETRUNC(YEAR,order_date)
) t
order by DATETRUNC(YEAR,order_date)

--=================================================================================
-- # 9 Performance Analysis
/* Analyze the yearly performance of products
by comparing each product's sales to both
its average sales performance and the previous year's sales. */ 
with yearly_product_sales as
(
select
	year(f.order_date) as order_year,
	p.product_name,
	sum(f.sales_amount) as current_sales
from dbo.fact_sales as f
left join dbo.dim_products as p
	on f.product_key = p.product_key
where f.order_date is not null
group by year(f.order_date), p.product_name
)

select
	order_year,
	product_name,
	current_sales,
	avg(current_sales) over (Partition by product_name) as avg_sales,
	current_sales - avg(current_sales) over (Partition by product_name) as diff_avg,
	case 
		when current_sales - avg(current_sales) over (Partition by product_name) > 0 then 'Above Avg'
		when current_sales - avg(current_sales) over (Partition by product_name) < 0 then 'Below Avg'
		Else 'Avg'
	end as avg_change,
	lag(current_sales) over (Partition by product_name order by order_year) py_sales,
	case 
		when current_sales - lag(current_sales) over (Partition by product_name order by order_year) > 0 then 'Increase'
		when current_sales - lag(current_sales) over (Partition by product_name order by order_year) < 0 then 'decrease'
		Else 'No Change'
	end as py_change
from yearly_product_sales
order by product_name, order_year

-- ===============================================================================
-- 10 Perfomance Analysis 
-- Which categories contribute the most to overall sales?
with category_sales as (
select
	p.category ,
	sum(f.sales_amount) as total_sales
from dbo.fact_sales as f
left join dbo.dim_products as p
	on f.product_key = p.product_key
Group by p.category 
)

select
	category ,
	total_sales,
	sum(total_sales) over() as overall_sales,
	concat(Round((cast(total_sales as float) / sum(total_sales) over()) * 100,2),'%') as percentage_of_tatal
from category_sales
order by total_sales desc ;

--=================================================================================
-- # 11 Data Segmentation
/*Segment products into cost ranges and
 count how many products fall into each segment*/
with product_stagement as
(
select
	product_key,
	product_name,
	cost,
	case 
		when cost < 100 then 'Below 100'
		when cost between 100 and 500 then '100-500'
		when cost between 500 and 1000 then '500-1000'
		else 'Above 1000'
	end as cost_range
from dbo.dim_products
)
select
	cost_range,
	count(product_key) as total_product
from product_stagement
group by cost_range
order by total_product desc ;

/* Group customers into three segments based on their spending behavior:
- VIP: at least 12 months of history and spending more than 5,000.
- Regular: at least 12 months of history but spending 5,000 or less.
- New: lifespan less than 12 months. */
with customer_spending as
(
select
	c.customer_key,
	sum(f.sales_amount) as total_spending,
	min(order_date) as first_order,
	max(order_date) as last_order,
	datediff(month,min(order_date),max(order_date)) as lifespan
from dbo.fact_sales as f
left join dbo.dim_customers as c
	on f.customer_key = c.customer_key
group by c.customer_key
)

select
	customer_segment,
	count(customer_key) as total_customers
from (
select 
	customer_key,
	case 
		when lifespan >= 12 and total_spending > 5000 then 'VIP'
		when lifespan >= 12 and total_spending <= 5000 then 'Regular'
		else 'New'
	end customer_segment
from customer_spending) t
group by customer_segment
order by total_customers desc



-- # 12 Reporting 
/* Customer Report
Purpose :
- This report consolidates key customer metrics and behaviors
Highlights:
1. Gathers essential fields such as names, ages, and transaction details.
2. Segments customers into categories (VIP, Regular, New) and age groups.
3. Aggregates customer-level metrics:
- total orders
- total sales
- total quantity purchased
- total products
- lifespan (in months)
4. Calculates valuable KPIs:
- recency (months since last order)
- average order value
- average monthly spend
*/ 
IF OBJECT_ID('dbo.report_customers', 'V') IS NOT NULL
    DROP VIEW dbo.report_customers;
GO

CREATE VIEW dbo.report_customers AS
with base_query as (
-- =============================================================================
-- 1. Gathers essential fields such as names, ages, and transaction details.
-- =============================================================================
SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	c.first_name,
	c.last_name,
	concat(c.first_name, ' ', c.last_name) as customer_name,
	datediff(year,c.birthdate,getdate()) as age
from dbo.fact_sales as f
LEFT JOIN dbo.dim_customers as c
	ON c.customer_key = f.customer_key
)


, customer_aggeration as (
-- =============================================================================
/* 2 Customer Aggregates : Summarizes key metrics at the customer levrl*/
-- =============================================================================
select
	customer_key,
	customer_number,
	customer_name,
	age,
	count(distinct order_number) as total_orders,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	count(distinct product_key) as total_product,
	max(order_date) as last_order_date,
	datediff(month,min(order_date),max(order_date)) as lifespan
from base_query
group by 
	customer_key,
	customer_number,
	customer_name,
	age
)
-- # 3
select
	customer_key,
	customer_number,
	customer_name,
	age,
	case 
		when age < 20 then 'Under 20 '
		when age between 20 and 29 then '20-29'
		when age between 30 and 39 then '30-39'
		when age between 40 and 49 then '40-49'
		else '50 and above'
	end as age_group,
	case 
		when lifespan >= 12 and total_sales > 5000 then 'VIP'
		when lifespan >= 12 and total_sales <= 5000 then 'Regular'
		else 'New'
	end as customer_segment,
	total_orders,
-- # 4 recency (months since last order)
	datediff(MONTH,last_order_date,getdate()) as recency ,
	total_sales,
	total_quantity,
	total_product,
	last_order_date,
	lifespan,
-- # 4 Compuate aberage order values (AVO)
	case 
		when total_sales = 0 then 0
		Else total_sales / total_orders 
	end as avg_order_values,
-- # 4 compuate average monthly spend
	case 
		when lifespan = 0 then total_sales
		else total_sales / lifespan
	end as avg_monthly_spend
	from customer_aggeration










/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: dbo.report_products
-- =============================================================================
IF OBJECT_ID('dbo.report_products', 'V') IS NOT NULL
    DROP VIEW dbo.report_products;
GO

CREATE VIEW dbo.report_products AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
    SELECT
	    f.order_number,
        f.order_date,
		f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM dbo.fact_sales f
    LEFT JOIN dbo.dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL  -- only consider valid sales dates
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan
	END AS avg_monthly_revenue

FROM product_aggregations 





/* 
====================================================================================
Product Report
====================================================================================
Purpose :
	- This report consolidates key product metrics and behaviors.

Highlights:
	1. Gathers essential fields such as product name, category, subcategory, and
	2. Segments products by revenue to identify High-Performers, Mid-Range, or Lo
	3. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
====================================================================================
*/

 -- Advannced Data analytics Project 
 -- # 7 Change-Over-Time 
 -- Analyze Sales Performance Over Time.
 select 
     year(order_date) as order_year,
     month(order_date) as order_month,
     sum(sales_amount) as Total_sales,
     count(distinct customer_key) as total_customers,
     sum(quantity) as total_quantity
 from dbo.fact_sales
 where order_date is not null
 group by year(order_date), month(order_date)
 order by year(order_date), month(order_date)
 
 -- SAME RESULT BEFORE
 select 
     DATETRUNC(month,order_date) as order_date,
     sum(sales_amount) as Total_sales,
     count(distinct customer_key) as total_customers,
     sum(quantity) as total_quantity
 from dbo.fact_sales
 where order_date is not null
 group by DATETRUNC(month,order_date)
 order by DATETRUNC(month,order_date)
 
 --=================================================================================
 -- # 8 Cumulative Analysis 
 -- Calculate the total sales per month
 -- and the running total of sales over time
 select  
     order_date,
     total_sales,
     sum(total_sales) over (order by order_date) as Running_Total_sales
 from (
 select 
     DATETRUNC(month,order_date) as order_date,
     sum(sales_amount) as Total_sales
 from dbo.fact_sales
 where order_date is not null
 group by DATETRUNC(month,order_date)
 ) t
 order by DATETRUNC(month,order_date)
 
 -- Calculate the total sales per year
 -- and the running total of sales over time
 select  
     order_date,
     total_sales,
     sum(total_sales) over (order by order_date) as Running_Total_sales,
     avg(total_sales) over (order by order_date) as moving_average_price
 from (
 select 
     DATETRUNC(YEAR,order_date) as order_date,
     sum(sales_amount) as Total_sales,
     avg(price) as avg_price
 from dbo.fact_sales
 where order_date is not null
 group by DATETRUNC(YEAR,order_date)
 ) t
 order by DATETRUNC(YEAR,order_date)
 
 --=================================================================================
 -- # 9 Performance Analysis
 /* Analyze the yearly performance of products
 by comparing each product's sales to both
 its average sales performance and the previous year's sales. */ 
 with yearly_product_sales as
 (
 select
     year(f.order_date) as order_year,
     p.product_name,
     sum(f.sales_amount) as current_sales
 from dbo.fact_sales as f
 left join dbo.dim_products as p
     on f.product_key = p.product_key
 where f.order_date is not null
 group by year(f.order_date), p.product_name
 )
 
 select
     order_year,
     product_name,
     current_sales,
     avg(current_sales) over (Partition by product_name) as avg_sales,
     current_sales - avg(current_sales) over (Partition by product_name) as diff_avg,
     case 
         when current_sales - avg(current_sales) over (Partition by product_name) > 0 then 'Above Avg'
         when current_sales - avg(current_sales) over (Partition by product_name) < 0 then 'Below Avg'
         Else 'Avg'
     end as avg_change,
     lag(current_sales) over (Partition by product_name order by order_year) py_sales,
     case 
         when current_sales - lag(current_sales) over (Partition by product_name order by order_year) > 0 then 'Increase'
         when current_sales - lag(current_sales) over (Partition by product_name order by order_year) < 0 then 'decrease'
         Else 'No Change'
     end as py_change
 from yearly_product_sales
 order by product_name, order_year
 
 -- ===============================================================================
 -- 10 Perfomance Analysis 
 -- Which categories contribute the most to overall sales?
 with category_sales as (
 select
     p.category ,
     sum(f.sales_amount) as total_sales
 from dbo.fact_sales as f
 left join dbo.dim_products as p
     on f.product_key = p.product_key
 Group by p.category 
 )
 
 select
     category ,
     total_sales,
     sum(total_sales) over() as overall_sales,
     concat(Round((cast(total_sales as float) / sum(total_sales) over()) * 100,2),'%') as percentage_of_tatal
 from category_sales
 order by total_sales desc ;
 
 --=================================================================================
 -- # 11 Data Segmentation
 /*Segment products into cost ranges and
  count how many products fall into each segment*/
 with product_stagement as
 (
 select
     product_key,
     product_name,
     cost,
     case 
         when cost < 100 then 'Below 100'
         when cost between 100 and 500 then '100-500'
         when cost between 500 and 1000 then '500-1000'
         else 'Above 1000'
     end as cost_range
 from dbo.dim_products
 )
 select
     cost_range,
     count(product_key) as total_product
 from product_stagement
 group by cost_range
 order by total_product desc ;
 
 /* Group customers into three segments based on their spending behavior:
 - VIP: at least 12 months of history and spending more than 5,000.
 - Regular: at least 12 months of history but spending 5,000 or less.
 - New: lifespan less than 12 months. */
 with customer_spending as
 (
 select
     c.customer_key,
     sum(f.sales_amount) as total_spending,
     min(order_date) as first_order,
     max(order_date) as last_order,
     datediff(month,min(order_date),max(order_date)) as lifespan
 from dbo.fact_sales as f
 left join dbo.dim_customers as c
     on f.customer_key = c.customer_key
 group by c.customer_key
 )
 
 select
     customer_segment,
     count(customer_key) as total_customers
 from (
 select 
     customer_key,
     case 
         when lifespan >= 12 and total_spending > 5000 then 'VIP'
         when lifespan >= 12 and total_spending <= 5000 then 'Regular'
         else 'New'
     end customer_segment
 from customer_spending) t
 group by customer_segment
 order by total_customers desc
 
 
 
 -- # 12 Reporting 
 /* Customer Report
 Purpose :
 - This report consolidates key customer metrics and behaviors
 Highlights:
 1. Gathers essential fields such as names, ages, and transaction details.
 2. Segments customers into categories (VIP, Regular, New) and age groups.
 3. Aggregates customer-level metrics:
 - total orders
 - total sales
 - total quantity purchased
 - total products
 - lifespan (in months)
 4. Calculates valuable KPIs:
 - recency (months since last order)
 - average order value
 - average monthly spend
 */ 
 IF OBJECT_ID('dbo.report_customers', 'V') IS NOT NULL
    DROP VIEW dbo.report_customers;
 GO

CREATE VIEW dbo.report_customers AS
 with base_query as (
 -- =============================================================================
 -- 1. Gathers essential fields such as names, ages, and transaction details.
 -- =============================================================================
 SELECT
     f.order_number,
     f.product_key,
     f.order_date,
     f.sales_amount,
     f.quantity,
     c.customer_key,
     c.customer_number,
     c.first_name,
     c.last_name,
     concat(c.first_name, ' ', c.last_name) as customer_name,
     datediff(year,c.birthdate,getdate()) as age
 from dbo.fact_sales as f
 LEFT JOIN dbo.dim_customers as c
     ON c.customer_key = f.customer_key
 )
 
 
 , customer_aggeration as (
 -- =============================================================================
 /* 2 Customer Aggregates : Summarizes key metrics at the customer levrl*/
 -- =============================================================================
 select
     customer_key,
     customer_number,
     customer_name,
     age,
     count(distinct order_number) as total_orders,
     sum(sales_amount) as total_sales,
     sum(quantity) as total_quantity,
     count(distinct product_key) as total_product,
     max(order_date) as last_order_date,
     datediff(month,min(order_date),max(order_date)) as lifespan
 from base_query
 group by 
     customer_key,
     customer_number,
     customer_name,
     age
 )
 -- # 3
 select
     customer_key,
     customer_number,
     customer_name,
     age,
     case 
         when age < 20 then 'Under 20 '
         when age between 20 and 29 then '20-29'
         when age between 30 and 39 then '30-39'
         when age between 40 and 49 then '40-49'
         else '50 and above'
     end as age_group,
     case 
         when lifespan >= 12 and total_sales > 5000 then 'VIP'
         when lifespan >= 12 and total_sales <= 5000 then 'Regular'
         else 'New'
     end as customer_segment,
     total_orders,
 -- # 4 recency (months since last order)
     datediff(MONTH,last_order_date,getdate()) as recency ,
     total_sales,
     total_quantity,
     total_product,
     last_order_date,
     lifespan,
 -- # 4 Compuate aberage order values (AVO)
     case 
         when total_sales = 0 then 0
         Else total_sales / total_orders 
     end as avg_order_values,
 -- # 4 compuate average monthly spend
     case 
         when lifespan = 0 then total_sales
         else total_sales / lifespan
     end as avg_monthly_spend
     from customer_aggeration
 
 
 
 
 
 
 
 
 
 
 /*
 ===============================================================================
 Product Report
 ===============================================================================
 Purpose:
     - This report consolidates key product metrics and behaviors.
 
 Highlights:
     1. Gathers essential fields such as product name, category, subcategory, and cost.
     2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
     3. Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
     4. Calculates valuable KPIs:
        - recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue
 ===============================================================================
 */
 -- =============================================================================
 -- Create Report: dbo.report_products
 -- =============================================================================
 IF OBJECT_ID('dbo.report_products', 'V') IS NOT NULL
     DROP VIEW dbo.report_products;
 GO
 
 CREATE VIEW dbo.report_products AS
 
 WITH base_query AS (
 /*---------------------------------------------------------------------------
 1) Base Query: Retrieves core columns from fact_sales and dim_products
 ---------------------------------------------------------------------------*/
     SELECT
         f.order_number,
         f.order_date,
         f.customer_key,
         f.sales_amount,
         f.quantity,
         p.product_key,
         p.product_name,
         p.category,
         p.subcategory,
         p.cost
     FROM dbo.fact_sales f
     LEFT JOIN dbo.dim_products p
         ON f.product_key = p.product_key
     WHERE order_date IS NOT NULL  -- only consider valid sales dates
 ),
 
 product_aggregations AS (
 /*---------------------------------------------------------------------------
 2) Product Aggregations: Summarizes key metrics at the product level
 ---------------------------------------------------------------------------*/
 SELECT
     product_key,
     product_name,
     category,
     subcategory,
     cost,
     DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
     MAX(order_date) AS last_sale_date,
     COUNT(DISTINCT order_number) AS total_orders,
     COUNT(DISTINCT customer_key) AS total_customers,
     SUM(sales_amount) AS total_sales,
     SUM(quantity) AS total_quantity,
     ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
 FROM base_query
 
 GROUP BY
     product_key,
     product_name,
     category,
     subcategory,
     cost
 )
 
 /*---------------------------------------------------------------------------
   3) Final Query: Combines all product results into one output
 ---------------------------------------------------------------------------*/
 SELECT 
     product_key,
     product_name,
     category,
     subcategory,
     cost,
     last_sale_date,
     DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
     CASE
         WHEN total_sales > 50000 THEN 'High-Performer'
         WHEN total_sales >= 10000 THEN 'Mid-Range'
         ELSE 'Low-Performer'
     END AS product_segment,
     lifespan,
     total_orders,
     total_sales,
     total_quantity,
     total_customers,
     avg_selling_price,
     -- Average Order Revenue (AOR)
     CASE 
         WHEN total_orders = 0 THEN 0
         ELSE total_sales / total_orders
     END AS avg_order_revenue,
 
     -- Average Monthly Revenue
     CASE
         WHEN lifespan = 0 THEN total_sales
         ELSE total_sales / lifespan
     END AS avg_monthly_revenue
 
 FROM product_aggregations 
 
 
 
 
 
 /* 
 ====================================================================================
 Product Report
 ====================================================================================
 Purpose :
     - This report consolidates key product metrics and behaviors.
 
 Highlights:
     1. Gathers essential fields such as product name, category, subcategory, and
     2. Segments products by revenue to identify High-Performers, Mid-Range, or Lo
     3. Aggregates product-level metrics:
         - total orders
         - total sales
         - total quantity sold
         - total customers (unique)
         - lifespan (in months)
     4. Calculates valuable KPIs:
         - recency (months since last sale)
         - average order revenue (AOR)
         - average monthly revenue
 ====================================================================================
 */
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
































