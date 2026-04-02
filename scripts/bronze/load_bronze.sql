/*
========================================================================
-----------------------------------------------------
Stored Procedure for loading data into the table
------------------------------------------------------
Purpose:
      This will add the data from the csv files of crm and erp folders into the tables (TRUNCATE & BULK INSERT)
      There are PRINT statements to segregate each section
      There is a TRY & CATCH block for error handling
      There is also execution time taken by each INSERT block and overall Bronze layer 
-------------------------------------------------------
How to run:
          Execute the line EXEC bronze.load_bronze
-------------------------------------------------------
=========================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @total_start_time DATETIME, @total_end_time DATETIME;
	BEGIN TRY
		SET @total_start_time = GETDATE();
		PRINT('======================================');
		PRINT('Loading Bronze Layer');
		PRINT('======================================');
	
		PRINT('--------------------------------------');
		PRINT('LOADING CRM TABLE');
		PRINT('--------------------------------------');
		
		SET @start_time = GETDATE();
		PRINT('>>Truncating Table: bronze.crm_cust_info');
		TRUNCATE TABLE bronze.crm_cust_info; --delete rows

		PRINT('>>Inserting Into: bronze.crm_cust_info');
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\Sarthak\SQL\SQL Project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv' --exact location of the file
		WITH (
			FIRSTROW = 2, --start from 2nd row as first row is header
			FIELDTERMINATOR = ',', --set the delimiter
			TABLOCK --improve performance
		);
		SET @end_time = GETDATE();

		PRINT('--> Load time is ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT('------------------------------------')

		/*==============================================================================================*/
		SET @start_time = GETDATE();
		PRINT('>>Truncating Table: bronze.crm_prd_info');
		TRUNCATE TABLE bronze.crm_prd_info;
	
		PRINT('>>Inserting Into: bronze.crm_prd_info');
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\Sarthak\SQL\SQL Project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv' --add extension also
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT('--> Load time is ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT('------------------------------------')


		/*==============================================================================================*/
		SET @start_time = GETDATE();
		PRINT('>>Truncating Table: bronze.crm_sales_details');
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT('>>Inserting Into: bronze.crm_sales_details');
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\Sarthak\SQL\SQL Project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time= GETDATE();
		PRINT('--> Load time is ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT('------------------------------------')

		/*==============================================================================================*/
		PRINT('--------------------------------------');
		PRINT('LOADING ERP TABLE');
		PRINT('--------------------------------------');
		
		SET @start_time = GETDATE();
		PRINT('>>Truncating Table: bronze.erp_CUST_AZ12');
		TRUNCATE TABLE bronze.erp_CUST_AZ12;

		PRINT('>>Inserting Into: bronze.erp_CUST_AZ12');
		BULK INSERT bronze.erp_CUST_AZ12
		FROM 'D:\Sarthak\SQL\SQL Project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time= GETDATE();
		PRINT('--> Load time is ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT('------------------------------------')

		/*==============================================================================================*/
		SET @start_time= GETDATE();
		PRINT('>>Truncating Table: bronze.erp_LOC_A101');
		TRUNCATE TABLE bronze.erp_LOC_A101;

		PRINT('>>Inserting Into: bronze.erp_LOC_A101');
		BULK INSERT bronze.erp_LOC_A101
		FROM 'D:\Sarthak\SQL\SQL Project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time= GETDATE();
		PRINT('--> Load time is ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT('------------------------------------')
		/*===============================================================================================*/
		SET @start_time= GETDATE();
		PRINT('>>Truncating Table: bronze.erp_PX_CAT_G1V2');
		TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;

		PRINT('>>Inserting Into: bronze.erp_PX_CAT_G1V2');
		BULK INSERT bronze.erp_PX_CAT_G1V2
		FROM 'D:\Sarthak\SQL\SQL Project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time= GETDATE();
		PRINT('--> Load time is ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT('------------------------------------');
	END TRY

	BEGIN CATCH
		PRINT('**************************************');
		PRINT('AN ERROR OCCURED!');
		PRINT('Error Message' + ERROR_MESSAGE());
		PRINT('Error Number' + CAST(ERROR_NUMBER() AS NVARCHAR));
		PRINT('Error Line' + CAST(ERROR_LINE() AS NVARCHAR));
		PRINT('**************************************');
	END CATCH
	SET @total_end_time = GETDATE();
	PRINT('-------------------------------------------------------');
	PRINT('---------------BRONZE LAYER IS EXECUTED----------------');
	PRINT('Total time take to run the Bronze Layer is ') + CAST(DATEDIFF(second, @total_start_time, @total_end_time) AS NVARCHAR) + 'seconds';
	PRINT('-------------------------------------------------------');
END
