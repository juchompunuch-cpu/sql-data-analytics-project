-- ทด Silver project2.sql

-- table1
-- 1 -- Check for nulls or Dupliicates in primary key
-- Expextation : No result
-- ดู ตัวที่ซ้ำ กัน หรือ ตัวที่เป็น null ใน cst_id


select
	cst_id,
	count(*)
from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null ;

-- ดู ตัวที่ซ้ำ กัน และเรียงลำดับจากวันที่ล่าสุด
select 
*,
ROW_NUMBER () over (partition by cst_id order by cst_create_date desc) as flag_last
from bronze.crm_cust_info
where cst_id = 29466 ;

-- เลือกตัวที่ flag_last = 1 เพื่อเอาแค่ตัวล่าสุด
select
* 
from 
(
select 
*,
ROW_NUMBER () over (partition by cst_id order by cst_create_date desc) as flag_last
from bronze.crm_cust_info
)t where flag_last = 1 and cst_id is not null ;


-- ======================================================
-- 2 Ckeck for unwated spaces
-- Expextation : No result

select cst_firstname
from bronze.crm_cust_info
where cst_firstname! = trim(cst_firstname)

select cst_lastname
from bronze.crm_cust_info
where cst_lastname! = trim(cst_lastname)

select cst_firstname
from bronze.crm_cust_info
where cst_gndr! = trim(cst_gndr)


--========================================================
-- check
-- 3 Data Standardization & Consistency
select distinct cst_gndr
from bronze.crm_cust_info


select distinct cst_marital_status
from bronze.crm_cust_info


--========================================================
-- 4 check after insert into silver (Quality)
select
	cst_id,
	count(*)
from silver.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null ;


select cst_firstname
from silver.crm_cust_info
where cst_gndr! = trim(cst_gndr)

select distinct cst_gndr
from silver.crm_cust_info

select distinct cst_marital_status
from silver.crm_cust_info




-- table 2
select 
	prd_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line
	prd_start_dt,
	prd_end_dt
from bronze.crm_prd_info

-- 1-- Check for nulls or Dupliicates in primary key
-- Expextation : No result
select
	prd_id,
	count(*)
from bronze.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null ;

-- 2 Ckeck for unwated spaces
select 
	prd_id,
	prd_key,
-- แบ่ง prd_key เพื่อเอาแค่ 5 ตัวแรก และ แทนที่ - ด้วย _ เพื่อให้ตรงกับ id ในตาราง rep_px_cat_g1v2
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id,
-- แบ่ง prd_key เอารหัส 5 ตัวหลัง เพื่อเอาไปเช็คกับตาราง rep_px_cat_g1v2 ว่ามีรหัสไหนบ้างที่ไม่มีในตารางนั้น
	SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key,
	prd_nm,
	prd_cost,
	prd_line
	prd_start_dt,
	prd_end_dt
from bronze.crm_prd_info
--
where REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') not in
-- Recheck ว่าตัวที่แปลงแล้วมีค่าอะไรบ้างที่แตกต่าง สำหรับ 5 ตัวแรก
(select distinct id from bronze.rep_px_cat_g1v2)

and

-- Recheck ว่าตัวที่แปลงแล้วมีค่าอะไรบ้างที่แตกต่าง สำหรับ 5 ตัวหลัง
SUBSTRING(prd_key, 7, LEN(prd_key)) in (
select sls_prd_key from bronze.crm_sales_details)



-- Ckeck for unwated spaces
select prd_nm
from bronze.crm_prd_info
where prd_nm! = trim(prd_nm)


-- 3 Check for Nulls or Negative Numbers แล้ว แปลงค่า null เป็น 0 เพื่อให้สามารถนำไปคำนวณได้
-- Expectation : No result
select prd_cost
from bronze.crm_prd_info
where prd_cost is null or prd_cost < 0

-- 4 Data Standardization & Consistency
select distinct prd_line 
from bronze.crm_prd_info

-- check for invalid date orders
select *
from bronze.crm_prd_info
where prd_start_dt > prd_end_dt
-- 
select 
	prd_id,
	prd_key,
	prd_nm,
	prd_start_dt,
	prd_end_dt,
	lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as prd_end_dt_test
from bronze.crm_prd_info 
where prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509')

---- 5 check after insert into silver (Quality)
select
	prd_id,
	count(*)
from silver.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null ;

select prd_nm
from silver.crm_prd_info
where prd_nm! = trim(prd_nm)

select prd_cost
from silver.crm_prd_info
where prd_cost is null or prd_cost < 0

select distinct prd_line 
from silver.crm_prd_info

select *
from silver.crm_prd_info
where prd_start_dt > prd_end_dt

-- teble 3
select 
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
from bronze.crm_sales_details

-- Check for invalid dates
select
	nullif(sls_order_dt,0) as sls_order_dt
from bronze.crm_sales_details
where sls_order_dt <= 0 
or len(sls_order_dt) ! = 8 
or sls_order_dt > 20500101
or sls_order_dt < 19000101

-- 1 Data Normalization & Standardization
select
	case
		when sls_order_dt <= 0 or len(sls_order_dt) ! = 8 then null
		else cast(cast(sls_order_dt as varchar) as date)
	end as sls_order_dt,
	case
		when sls_ship_dt <= 0 or len(sls_ship_dt) ! = 8 then null
		else cast(cast(sls_ship_dt as varchar) as date)
	end as sls_ship_dt,
	case
		when sls_due_dt <= 0 or len(sls_due_dt) ! = 8 then null
		else cast(cast(sls_due_dt as varchar) as date)
	end as sls_due_dt
from bronze.crm_sales_details


-- 2 Check for Invalid dates orders
select *
from bronze.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt

-- 2.1 check data consistency : between sales,Quatity, and price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative
select distinct
	sls_sales as old_sls_sales ,
	sls_quantity,
	sls_price as old_sls_price,
	case
		when sls_sales is null or sls_sales <= 0 or sls_sales ! = sls_quantity * ABS(sls_price)
			then sls_quantity * ABS(sls_price)
			else sls_sales
	end as sls_sales,
	case
		when sls_price is null or sls_price < = 0 
			then sls_sales / Nullif(sls_quantity,0)
			else sls_price
	end as sls_price
from bronze.crm_sales_details
where sls_sales ! = sls_quantity * sls_price
or sls_sales is NULL or sls_quantity is NULL or sls_price is NULL
or sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0
order by sls_sales, sls_quantity, sls_price

-- check after insert into silver (Quality)
select *
from silver.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt

--
select distinct
	sls_sales ,
	sls_quantity,
	sls_price 
from silver.crm_sales_details
where sls_sales ! = sls_quantity * sls_price
or sls_sales is NULL or sls_quantity is NULL or sls_price is NULL
or sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0
order by sls_sales, sls_quantity, sls_price



select distinct
	sls_sales,
	sls_quantity,
	sls_price
from silver.crm_sales_details
where sls_sales ! = sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0
order by sls_sales, sls_quantity, sls_price


-- table 4
-- check relationship between tables
select 
	CID,
	BDATE,
	GEN
from bronze.rep_cust_az12
where cid like '%AW00011000'

select *
from silver.crm_cust_info

-- Remove 'NAS' 
select 
	CID,
	case
		when cid like 'NAS%' then substring(cid,4, len(cid))
		else cid
	end as CID,
	BDATE,
	GEN
from bronze.rep_cust_az12
-- Recheck ว่าตัวที่แปลงแล้วมีค่าอะไรบ้างที่แตกต่าง สำหรับ CID
-- So it's work
select 
	CID,
	case
		when cid like 'NAS%' then substring(cid,4, len(cid))
		else cid
	end as CID,
	BDATE,
	GEN
from bronze.rep_cust_az12
where case when cid like 'NAS%' then substring(cid,4, len(cid))
	else cid
end not in (select distinct cst_key from silver.crm_cust_info)

-- check for very old customers
-- Check for birthdate in the future
select 
	BDATE
from bronze.rep_cust_az12
where BDATE < '1924-01-01' and bdate > GETDATE()

-- data standardization & consistency
select distinct 
	gen,
	case
		when UPPER(TRIM(GEN)) in ('F', 'FEMALE') then 'Female'
		when UPPER(TRIM(GEN)) in ('M', 'MALE') then 'Male'
		else 'n/a'
	end as gen
from bronze.rep_cust_az12

-- data Quality check after insert into silver
-- idrntify out*of-range date
-- data standardization & consistency
select 
	BDATE
from silver.rep_cust_az12
where BDATE < '1924-01-01' and bdate > GETDATE()
-- data standardization & consistency
select distinct 
	gen
from silver.rep_cust_az12

-- table 5
select 
	CID,
	CNTRY
from bronze.rep_loc_a101

-- ralationship between tables
select 
	replace(CID,'-','') as CID,
	CNTRY
from bronze.rep_loc_a101 where replace(CID,'-','') not in (select distinct cst_key from silver.crm_cust_info) ;

-- COMPARE WITH
select cst_key
from silver.crm_cust_info;

-- data standardization & consistency
-- Fullname , NULL
select distinct cntry,
case
	when trim(CNTRY) = 'DE' then 'Germany'
	when trim(CNTRY) IN ('US','USA') then 'United States'
	when trim(CNTRY) = '' or cntry is null then 'n/a'
	else trim(cntry)
end as cntry
from bronze.rep_loc_a101

-- check after insert into silver (Quality)
select 
	distinct CNTRY
from silver.rep_loc_a101
order by CNTRY

select * 
from silver.rep_loc_a101



-- Table 6
select
	ID,
	CAT,
	SUBCAT,
	MAINTENANCE
from bronze.rep_px_cat_g1v2

--  Check relationship between tables
select *
from silver.crm_prd_info
-- can be used

-- Check for unwated spaces
select *
from bronze.rep_px_cat_g1v2
where CAT != trim(CAT) or SUBCAT != trim(SUBCAT) or MAINTENANCE != trim(MAINTENANCE)

-- data standardization & consistency
select distinct CAT
from bronze.rep_px_cat_g1v2

select distinct SUBCAT
from bronze.rep_px_cat_g1v2

select distinct MAINTENANCE
from bronze.rep_px_cat_g1v2
-- So This Table very nice can use



exec silver.load_silver ;




