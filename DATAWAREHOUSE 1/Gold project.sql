-- Gold project.sql
USE DATA_WAREHOUSE_TEST


-- customer
GO
create or alter view gold_TEST.dim_customer as
select
-- 5 Surrogate key
	ROW_NUMBER() over(order by cst_id) as customer_key,
-- 3 frindly column name
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
-- 4 Sort the column into the logical groups to improve readability
	la.CNTRY as country,
	ci.cst_marital_status as marital_status,
-- 2 DATA intergation -- CRM is the master for gender 
	case 
		when ci.cst_gndr != 'n/a' then ci.cst_gndr
		else coalesce (ca.GEN, 'n/a')
	end as gender,
	ca.BDATE as birthdate,
	ci.cst_create_date as create_date
from silver_TEST.crm_cust_info as ci
-- 1 JOIN with erp_cust_az12 to get BDATE and GEN
left join silver_TEST.erp_cust_az12 as ca
	on ci.cst_key = ca.CID
left join silver_TEST.erp_loc_a101 as la
	on ci.cst_key = la.CID

-- Product

GO
create or alter view gold_TEST.dim_product as
-- 6 Dimention & Fact
select 
-- 4 Sort the column into the logical groups to improve readability
-- 5 friendly column name
	row_number() over (order by pn.prd_start_dt,pn.prd_key) as product_key,
	pn.prd_id as product_id,
	pn.prd_key as product_number,
	pn.prd_nm as product_name,
	pn.cat_id as category_id,
	pc.cat as category,
	pc.subcat as subcatergory,
	pc.maintenance ,
	pn.prd_cost as cost,
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date
from silver_TEST.crm_prd_info as pn
-- 2 JOIN with erp_px_cat_g1v2 to get cat, subcat and maintenance
left join silver_test.erp_px_cat_g1v2 as pc
	on pn.cat_id = pc.id
-- 1 Filter to get only active products (current products) based on prd_end_dt
where prd_end_dt is NULL -- Filter out all historical data


-- Sales 
GO
create or alter view gold_TEST.fac_sales as
select 
	sd.sls_ord_num as order_number,
-- 1 Dimension & FACt
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt as order_date,
	sd.sls_ship_dt as shipping_date,
	sd.sls_due_dt as due_date,
	sd.sls_sales as sales_amount,
	sd.sls_quantity as quanity,
	sd.sls_price as price
from silver_TEST.crm_sales_details as sd
left join gold_TEST.dim_product as pr
	on sd.sls_prd_key = pr.product_number
left join gold_TEST.dim_customer as cu
	on sd.sls_cust_id = cu.customer_id

-- Foreign Key Integrity (Dimensions)
GO
select *
from gold_TEST.fac_sales as f
left join gold_TEST.dim_customer as c
on c.customer_key = f.customer_key
where c.customer_key is null

GO
select *
from gold_TEST.fac_sales as f
left join gold_TEST.dim_product as c
on c.product_key = f.product_key
where c.product_key is null


