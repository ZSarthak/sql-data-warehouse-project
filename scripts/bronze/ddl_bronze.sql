/* 
======================================================
DDL Script for creating tables
------------------------------------------------------
Purpose:
      These DDL scripts will create the tables in the DWH
      The TSQL will check if the table is already created and delete it, if it is
      then create the table from the CREATE TABLE line
-------------------------------------------------------
========================================================
*/




IF OBJECT_ID ('bronze.crm_cust_info', 'U') IS NOT NULL
DROP TABLE bronze.crm_cust_info; --T SQL used to check if table exists or not, if does then drop and create this
CREATE TABLE bronze.crm_cust_info ( -- follow naming convention-> name of source_table name
	cst_id INT,
	cst_key NVARCHAR(50),
	cst_firstname NVARCHAR(50),
	cst_lastname NVARCHAR(50),
	cst_marital_status NVARCHAR(50),
	cst_gndr NVARCHAR(50),
	cst_create_date DATE
);

IF OBJECT_ID ('bronze.crm_prd_info', 'U') IS NOT NULL
DROP TABLE bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
	prd_id INT,
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(10),
	prd_start_dt DATE,
	prd_end_dt DATE
);

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
DROP TABLE bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT,
	sls_due_dt INT,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT
);

IF OBJECT_ID('bronze.erp_CUST_AZ12', 'U') IS NOT NULL
DROP TABLE bronze.erp_CUST_AZ12;
CREATE TABLE bronze.erp_CUST_AZ12(
	cid NVARCHAR(50),
	bdate DATE,
	gen NVARCHAR(50)
);
IF OBJECT_ID('bronze.erp_LOC_A101', 'U') IS NOT NULL
DROP TABLE bronze.erp_LOC_A101;
CREATE TABLE bronze.erp_LOC_A101(
	cid NVARCHAR(50),
	cntry NVARCHAR(50)
);

IF OBJECT_ID('bronze.erp_PX_CAT_G1V2', 'U') IS NOT NULL
DROP TABLE bronze.erp_PX_CAT_G1V2;
CREATE TABLE bronze.erp_PX_CAT_G1V2(
	id NVARCHAR(50),
	cat NVARCHAR(50),
	subcat NVARCHAR(50),
	maintenance NVARCHAR(50)
);
