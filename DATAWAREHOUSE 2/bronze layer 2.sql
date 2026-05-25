/*
===============================================================================
Stored Procedure: Load bronze_TEST Layer (Source -> bronze_TEST)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze_TEST' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze_TEST tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze_TEST tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze_TEST.load_bronze_TEST;
===============================================================================
*/

GO
CREATE OR ALTER PROCEDURE bronze_TEST.load_bronze_TEST AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '================================================';
		PRINT 'Loading bronze_TEST Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze_TEST.crm_cust_info';
		TRUNCATE TABLE bronze_TEST.crm_cust_info;
		PRINT '>> Inserting Data Into: bronze_TEST.crm_cust_info';
		BULK INSERT bronze_TEST.crm_cust_info
		FROM 'C:\Users\jucho\OneDrive\Desktop\DATA WITH BRASS\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze_TEST.crm_prd_info';
		TRUNCATE TABLE bronze_TEST.crm_prd_info;

		PRINT '>> Inserting Data Into: bronze_TEST.crm_prd_info';
		BULK INSERT bronze_TEST.crm_prd_info
		FROM 'C:\Users\jucho\OneDrive\Desktop\DATA WITH BRASS\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze_TEST.crm_sales_details';
		TRUNCATE TABLE bronze_TEST.crm_sales_details;
		PRINT '>> Inserting Data Into: bronze_TEST.crm_sales_details';
		BULK INSERT bronze_TEST.crm_sales_details
		FROM 'C:\Users\jucho\OneDrive\Desktop\DATA WITH BRASS\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze_TEST.erp_loc_a101';
		TRUNCATE TABLE bronze_TEST.erp_loc_a101;
		PRINT '>> Inserting Data Into: bronze_TEST.erp_loc_a101';
		BULK INSERT bronze_TEST.erp_loc_a101
		FROM 'C:\Users\jucho\OneDrive\Desktop\DATA WITH BRASS\sql-data-warehouse-project-main\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze_TEST.erp_cust_az12';
		TRUNCATE TABLE bronze_TEST.erp_cust_az12;
		PRINT '>> Inserting Data Into: bronze_TEST.erp_cust_az12';
		BULK INSERT bronze_TEST.erp_cust_az12
		FROM 'C:\Users\jucho\OneDrive\Desktop\DATA WITH BRASS\sql-data-warehouse-project-main\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze_TEST.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze_TEST.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: bronze_TEST.erp_px_cat_g1v2';
		BULK INSERT bronze_TEST.erp_px_cat_g1v2
		FROM 'C:\Users\jucho\OneDrive\Desktop\DATA WITH BRASS\sql-data-warehouse-project-main\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading bronze_TEST Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING bronze_TEST LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
