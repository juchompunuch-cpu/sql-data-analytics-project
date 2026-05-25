-- ทด Gold project.sql
-- Inner join table
select 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.BDATE,
	ca.GEN,
	la.CNTRY
from silver_TEST.crm_cust_info as ci
left join silver_TEST.erp_cust_az12 as ca
	on ci.cst_key = ca.CID
left join silver_TEST.erp_loc_a101 as la
	on ci.cst_key = la.CID

-- Check Dupilcate
select cst_id,count(*) from
(
select 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.BDATE,
	ca.GEN,
	la.CNTRY
from silver_TEST.crm_cust_info as ci
left join silver_TEST.erp_cust_az12 as ca
	on ci.cst_key = ca.CID
left join silver_TEST.erp_loc_a101 as la
	on ci.cst_key = la.CID
)t 
group by cst_id
having count(*) > 1

--DATA intergation
select distinct
	ci.cst_gndr,
	ca.GEN,
	case 
		when ci.cst_gndr != 'n/a' then ci.cst_gndr
		else coalesce (ca.GEN, 'n/a')
	end as new_gndr
from silver_TEST.crm_cust_info as ci
left join silver_TEST.erp_cust_az12 as ca
	on ci.cst_key = ca.CID
left join silver_TEST.erp_loc_a101 as la
	on ci.cst_key = la.CID
order by 1 ,2 


-- Surrogate key

-- RECHECK after create view
GO
select * from gold_TEST.dim_customer ;
GO
select distinct gender from gold_TEST.dim_customer ;

-- ==============================
-- 1 ,2 ดูจาก หลัก 

-- 3 find duplicate record
GO
select prd_key, count(*) from (
select 
	pn.prd_id,
	pn.cat_id,
	pn.prd_key,
	pn.prd_nm,
	pn.prd_cost,
	pn.prd_line,
	pn.prd_start_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
from silver_TEST.crm_prd_info as pn
-- 2 JOIN with erp_px_cat_g1v2 to get cat, subcat and maintenance
left join silver_test.erp_px_cat_g1v2 as pc
	on pn.cat_id = pc.id
-- 1 Filter to get only active products (current products) based on prd_end_dt
where prd_end_dt is NULL -- Filter out all historical data
)t group by prd_key
having count(*) > 1



