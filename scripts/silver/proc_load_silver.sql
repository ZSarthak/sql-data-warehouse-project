/*  Load Scripts for Silver Layer 
==============================================
Stored Procedure for Bronze-> Silver
==============================================
Purpose:
    This Stored Procedure uses the ETL (Extract, Transform, Load) process
    to create the Silver Layer schema from Bronze Layer schema
Actions Performed:
     a. Truncate Silver table
      b. Transform data (cleaning and normalization) and insert into the Silver layer
Parameters:
          None. No parameters or values returned
Execution:
      -> run this script EXEC silver.load_silver;
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @total_start_time DATETIME, @total_end_time DATETIME
	BEGIN TRY
		
		SET @total_start_time = GETDATE();
		PRINT('===========================================');
		PRINT('==========LOADING SILVER LAYER=============');
		PRINT('===========================================');

		PRINT('-------------------------------------------');
		PRINT('------------LOADING CRM TABLES-------------');
		PRINT('-------------------------------------------');

		/*==============================================================================================*/
		SET @start_time = GETDATE();
		PRINT('>>> REMOVING DATA FROM silver.crm_cust_info');
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT('>>> INSERTING CLEAN DATA INTO silver.crm_cust_info');
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)

		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname, -- cleaning spaces
			TRIM(cst_lastname) AS cst_lastname, -- cleaning spaces
			CASE WHEN UPPER(TRIM(cst_marital_status))= 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status))= 'M' THEN 'Married'
				ELSE 'n/a'
				END cst_marital_status,
			CASE WHEN UPPER(TRIM(cst_gndr))= 'F' THEN 'Female' -- standardize the gender to abbrevation
				WHEN UPPER(TRIM(cst_gndr))= 'M' THEN 'Male'
				ELSE 'n/a'
				END AS cst_gndr,
			cst_create_date
		FROM (
		SELECT
			*,
			ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flag_Rank
		FROM bronze.crm_cust_info
		)t WHERE Flag_Rank = 1 -- keep the row which is latest and has complete data
		SET @end_time = GETDATE();
		PRINT('Time taken to insert data is: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('----------------------------------');

		/*==============================================================================================*/

		SET @start_time= GETDATE();
		PRINT('>>> REMOVING DATA FROM silver.crm_prd_info');
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT('>>> INSERTING CLEAN DATA INTO silver.crm_prd_info');
		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)

		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key,1,5), '-', '_') AS cat_id, -- this is to link with erp prd category table in Gold Layer
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- this is to link to crm sales details table
			prd_nm,
			ISNULL(prd_cost, 0) AS prd_cost,
			CASE UPPER(TRIM(prd_line)) -- short form of using CASE, use when only mapping
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
				END AS prd_line,
			prd_start_dt,
			DATEADD(day, -1, LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt /* to fix the invalid date issue. 
			We take the start date of the next row and add it to the end date of the current row -1 */
		FROM bronze.crm_prd_info;
		-- WHERE REPLACE(SUBSTRING(prd_key,1,5), '-', '_') NOT IN (SELECT id FROM bronze.erp_PX_CAT_G1V2); to check which cat id is not in erp prd category
		SET @end_time = GETDATE();
		PRINT('Time taken to insert data is: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('----------------------------------');

		/*==============================================================================================*/

		SET @start_time= GETDATE();
		PRINT('>>> REMOVING DATA FROM silver.crm_sales_details');
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT('>>> INSERTING CLEAN DATA INTO silver.crm_sales_details');
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)

		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) -- in SQL first convert to VARCHAR and then DATE
				END AS sls_order_dt,
			CASE WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt,
			CASE WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt,

				/* there is bad data found in sales now what happens is
			1-> Source system will fix it OR
			2-> they will ask you to fix it */

			/* There are rules to follow when fixing
			1st-> if Sales has negative, zero or NULLs then calculate sales from Quantity and Price
			2nd-> if Price is zero or NULL, calculae it from Sales and Quantity
			3rd-> if Price is negative, convert to positive */

			CASE WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * sls_price THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales,
			sls_quantity,
			CASE WHEN sls_price <= 0 OR sls_price IS NULL THEN sls_sales / NULLIF(sls_quantity, 0)
				ELSE sls_price
			END AS sls_price
		FROM bronze.crm_sales_details
		SET @end_time = GETDATE();
		PRINT('Time taken to insert data is: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('----------------------------------');

		/*==============================================================================================*/
		
		PRINT('-------------------------------------------');
		PRINT('------------LOADING ERP TABLES-------------');
		PRINT('-------------------------------------------');

		SET @start_time= GETDATE();
		PRINT('>>> REMOVING DATA FROM silver.erp_cust_az12');
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT('>>> INSERTING CLEAN DATA INTO silver.erp_cust_az12');
		INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
		SELECT
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- use LIKE when check string start or end
				ELSE cid
			END AS cid,
			CASE WHEN bdate > GETDATE() THEN NULL
				ELSE bdate
			END AS bdate,
			CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
				ELSE 'n/a'
			END AS gen -- Normalized
		FROM bronze.erp_cust_az12;
		SET @end_time = GETDATE();
		PRINT('Time taken to insert data is: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('----------------------------------');

		/*==============================================================================================*/

		SET @start_time = GETDATE();
		PRINT('>>> REMOVING DATA FROM silver.erp_loc_a101');
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT('>>> INSERTING CLEAN DATA INTO silver.erp_loc_a101');
		INSERT INTO silver.erp_loc_a101 (cid, cntry)
		SELECT
			REPLACE(cid, '-', '') AS cid,
			CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
				WHEN TRIM(cntry) = ' ' OR cntry IS NULL THEN 'n/a'
			ELSE TRIM(cntry)
			END AS cntry
		FROM bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT('Time taken to insert data is: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('----------------------------------');

		/*==============================================================================================*/

		SET @start_time= GETDATE();
		PRINT('>>> REMOVING DATA FROM silver.erp_px_cat_g1v2');
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT('>>> INSERTING CLEAN DATA INTO silver.erp_px_cat_g1v2');
		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT('Time taken to insert data is: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' seconds');
		PRINT('----------------------------------');

		/*==============================================================================================*/

	END TRY

	BEGIN CATCH
			PRINT('*******AN ERROR OCCURED*******');
			PRINT('Error Line:' + CAST(ERROR_LINE() AS VARCHAR));
			PRINT('Error Message:' + ERROR_MESSAGE());
			PRINT('Error Number:' + CAST(ERROR_NUMBER() AS VARCHAR));
			PRINT('*******************************');
	END CATCH
	SET @total_end_time = GETDATE();
	PRINT('Overall time taken to execute Silver Layer is: ' + CAST(DATEDIFF(second, @total_start_time, @total_end_time) AS VARCHAR) + ' seconds');

END
