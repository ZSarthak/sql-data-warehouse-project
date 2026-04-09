/* Silver Layer Tests 
========================================
Purpose: 
      To test the given data in the bronze layer before adding it in the silver layer.
      We will perform the following tests:
      -> check for duplicate enteries and primary keys
      -> check for spaces before and after strings
      -> perform data standardization
      -> check invaild dates and datatypes
Usage:
      - run these checks (make sure they pass) before loading into silver layer
      - resolve data inconsistency if found
*/


PRINT('==============CRM FILE TESTS====================');

/* First Check:
If primary key is unique or not i.e, no NULLs and duplicates */
SELECT
cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

/* Second Check:
If there is any space before or after String data */
SELECT
	cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT
	cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT * FROM bronze.crm_cust_info;

/* Third Check:
Data Standardization i.e, making shortforms abbrevated */
SELECT
	cst_gndr
FROM bronze.crm_cust_info;

SELECT
	cst_marital_status
FROM bronze.crm_cust_info;

/* *********************QUALIT CHECKS****************************** */
PRINT('----------------- QC -----------------------');
/* CHECKS after cleaning
Expected O/P: No results */
SELECT -- Duplicates
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1

SELECT --Extra space in String
	cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT
	cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT -- Data Standardization
	cst_gndr
FROM silver.crm_cust_info;

SELECT
	cst_marital_status
FROM silver.crm_cust_info;

/* ========================================================== */
/* First Check:
Duplicates and NULLs in Primary Key*/
SELECT
	prd_id,
	COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL
-- No Duplicates or NULLs found

/* Second Check:
Unwanted spaces */
SELECT
	prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)
-- No spaces found

-- Check if there is any NULL or Negative value in cost
SELECT
	prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

SELECT DISTINCT prd_line FROM bronze.crm_prd_info

-- Check for invalid dates
SELECT
	prd_key,
	prd_start_dt,
	prd_end_dt
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt; -- show all the dates where start date is greater than end date

/* ***********************QUALITY CHECKS*************************** */
PRINT('--------------------QC----------------------');
/* First Check:
Duplicates and NULLs in Primary Key
Result: 0 */
SELECT
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

/* Second Check:
Unwanted spaces 
Result: 0 */
SELECT
	prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

/* Check if there is any NULL or Negative value in cost
Result: 0 */
SELECT
	prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

/* Third Check: 
Data Standardization/ Normalization
Result: No shortforms */
SELECT DISTINCT prd_line FROM silver.crm_prd_info

/* Fourth Check:
Check for invalid dates
Result: 0 */
SELECT
	prd_key,
	prd_start_dt,
	prd_end_dt
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt; -- show all the dates where start date is greater than end date

/* ================================================== */
/* First Check:
Incorrect Date */
SELECT
	NULLIF(sls_order_dt,0)
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8
OR sls_order_dt < 19900130; -- lets say this is start year of company

SELECT
	sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 
OR LEN(sls_ship_dt) != 8
OR sls_ship_dt < 19900130;

SELECT
	sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
OR LEN(sls_due_dt) != 8
OR sls_due_dt < 19900130;

/* Second Check: Invaild Date Order
order-> ship-> due date */
SELECT
	sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

/* Third Check: Data Consistency b/w Sales, Quantity and Price */
SELECT
	sls_sales AS old_sales,
	sls_quantity,
	sls_price AS old_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

/* **************QUALITY CHECKS************************** */
PRINT('--------------------QC----------------------');  
/* Second Check: Invaild Date Order
order-> ship-> due date 
Result: 0 */
SELECT
	sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

/* Third Check: Data Consistency b/w Sales, Quantity and Price 
Result: 0 */
SELECT
	sls_sales AS old_sales,
	sls_quantity,
	sls_price AS old_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price

/* ==================================================================== */
PRINT('==================ERP FILE TESTS================================ ');

/*First Check:
Invalid Bdate */

SELECT
	bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE(); -- either check with Source System or fix it yourself by adding NULL

/* Second Check:
Data Standardization and Normalization */
SELECT DISTINCT
	gen
FROM bronze.erp_cust_az12;

/* Next table */
SELECT DISTINCT
	cntry AS old,
	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		WHEN TRIM(cntry) = ' ' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
	END AS cntry
FROM bronze.erp_loc_a101
ORDER BY old, cntry

-- QC
SELECT DISTINCT cntry FROM silver.erp_loc_a101; -- Clean results
SELECT * FROM silver.erp_loc_a101;

/* Last Table */
SELECT * FROM bronze.erp_px_cat_g1v2;

SELECT
	id,
	cat,
	subcat,
	maintenance
FROM bronze.erp_px_cat_g1v2
WHERE id != TRIM(id) OR cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- Everything good with last table

/* **************************** QUALITY CHECKS *************************** */
  PRINT('---------------QC-------------------');
/*First Check:
Invalid Bdate 
Result : 0 */
SELECT
	bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE(); -- either check with Source System or fix it yourself by adding NULL

/* Second Check:
Data Standardization and Normalization 
Result: No shortforms */
SELECT DISTINCT
	gen
FROM silver.erp_cust_az12;

