/* Creating DDL for Gold Layer
======================================================
Purpose:
    To create views for the Gold Layer in the DWH (using Start Schema) 
    where we have business ready data that is extracted from the Silver Layer 
    to help create meaningful readable data

Usage:
    Run these Views to get the result for analysis and reporting
======================================================= */



/*========================================================== */
/*--------- CREATING DIMENSION VIEW FOR CUSTOMERS ---------- */
/*========================================================== */
CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key, -- creating a surrogate key to connect the data models since there is no primary key 
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	loc.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- here we consider the data from crm table to be correct, so when gndr NOT EQUAL to 'n/a' (that means there is good data in gndr) then use ci.cst_gndr
		ELSE ISNULL(caz.gen, 'n/a') -- else use data from erp and correct the NULL
	END AS gender,
	caz.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS caz
ON ci.cst_key = caz.cid
LEFT JOIN silver.erp_loc_a101 AS loc
ON ci.cst_key = loc.cid;

/* Data Integration
Now we have gender in both crm_cust and erp_cust, so we need to integrate (join) from both the tables to create complete data */

SELECT DISTINCT
	ci.cst_gndr,
	caz.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- here we consider the data from crm table to be correct, so when gndr NOT EQUAL to 'n/a' (that means there is good data in gndr) then use ci.cst_gndr
		ELSE ISNULL(caz.gen, 'n/a') -- else use data from erp and correct the NULL
	END AS new_gndr
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS caz
ON ci.cst_key = caz.cid
ORDER BY 1,2   

/*========================================================== */
/*--------- CREATING DIMENSION VIEW FOR PRODUCTS ---------- */
/*========================================================== */

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER(ORDER BY cpi.prd_start_dt, cpi.prd_key) AS product_key,
	cpi.prd_id AS product_id,
	cpi.prd_key AS product_number,
	cpi.prd_nm AS product_name,
	cpi.prd_line AS product_line,
	cpi.prd_cost AS product_cost,
	cpi.prd_start_dt AS product_start_date,
	cpi.cat_id AS category_id,
	pcat.cat AS category,
	pcat.subcat AS sub_category,
	pcat.maintenance
FROM silver.crm_prd_info AS cpi
LEFT JOIN silver.erp_px_cat_g1v2 AS pcat
ON cpi.cat_id = pcat.id
WHERE prd_end_dt IS NULL; -- filter out the historical data and keep only current data

/*========================================================== */
/*--------- CREATING FACTS VIEW FOR SALES ---------- */
/*========================================================== */
CREATE VIEW gold.fact_sales AS
SELECT
	sal.sls_ord_num AS order_number,
	gp.product_key,
	gc.customer_key,
	sal.sls_order_dt AS order_date,
	sal.sls_ship_dt AS shipping_date,
	sal.sls_due_dt AS due_date,
	sal.sls_sales AS sales,
	sal.sls_quantity AS quantity,
	sal.sls_price AS price
FROM silver.crm_sales_details AS sal
LEFT JOIN gold.dim_customers AS gc
ON sal.sls_cust_id = gc.customer_id
LEFT JOIN gold.dim_products AS gp
ON sal.sls_prd_key = gp.product_number
