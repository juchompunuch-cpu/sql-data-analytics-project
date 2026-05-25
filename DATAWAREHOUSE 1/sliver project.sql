-- silver project.sql
if OBJECT_ID ('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO
create table silver.crm_cust_info (
    cst_id int,
    cst_key Nvarchar(50),
    cst_firstname Nvarchar(100),
    cst_lastname Nvarchar(100),
    cst_marital_status Nvarchar(20),
    cst_gndr Nvarchar(50),
    cst_create_date date,
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);

if object_id ('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
create table silver.crm_prd_info (
    prd_id int,
    cat_id NVARCHAR(50),
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(100),
    prd_cost int,
    prd_line NVARCHAR(100),
    prd_start_dt DATE,
    prd_end_dt DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
if object_id ('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
create table silver.crm_sales_details (
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id int,
    sls_order_dt DATE,
    sls_ship_dt DATE,
    sls_due_dt DATE,
    sls_sales INT,
    sls_quantity INT ,
    sls_price INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);

if object_id ('silver.rep_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.rep_cust_az12;
create table silver.rep_cust_az12 (
    CID NVARCHAR(50),
    BDATE DATE,
    GEN NVARCHAR(50),
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
)

if object_id ('silver.rep_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.rep_loc_a101;
create table silver.rep_loc_a101 (
  CID NVARCHAR(50),
  CNTRY NVARCHAR(50),
  dwh_create_date    DATETIME2 DEFAULT GETDATE()
)

if object_id ('silver.rep_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.rep_px_cat_g1v2;
create table silver.rep_px_cat_g1v2 (
    ID NVARCHAR(50),
    CAT NVARCHAR(50),
    SUBCAT NVARCHAR(50),
    MAINTENANCE NVARCHAR(50),
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
) ;
