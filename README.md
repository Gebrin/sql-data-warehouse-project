SQL Server Data Warehouse Project

Overview

This project demonstrates the development of a modern data warehouse in Microsoft SQL Server using a Medallion Architecture. Data from CRM and ERP source systems is ingested from CSV files, cleaned and standardized, and then transformed into business-ready dimensional models for reporting and analytics.

The project covers:

Database and schema design

CSV ingestion with BULK INSERT

Stored procedures for automated loading

Data cleansing and standardization

Duplicate removal and null handling

Date and business-rule validation

Bronze, Silver, and Gold data layers

Dimension views for analytical reporting

Architecture

flowchart LR
    A["CRM CSV files"] --> C["Bronze layer"]
    B["ERP CSV files"] --> C
    C --> D["Silver layer"]
    D --> E["Gold layer"]
    E --> F["Reporting and analytics"]

Layer

Purpose

Bronze

Stores raw data loaded from the CRM and ERP CSV files.

Silver

Contains cleaned, standardized, deduplicated, and validated data.

Gold

Provides business-ready dimensions and facts for analytics.

Data Sources

The project uses two source systems.

CRM

Customer information

Product information

Sales transactions

ERP

Customer demographics

Customer locations

Product categories

Database Objects

Bronze tables

bronze.crm_cust_info

bronze.crm_prd_info

bronze.crm_sales_details

bronze.erp_cust_az12

bronze.erp_loc_a101

bronze.erp_px_cat_g1v2

Silver tables

silver.crm_cust_info

silver.crm_prd_info

silver.crm_sales_details

silver.erp_cust_az12

silver.erp_loc_a101

silver.erp_px_cat_g1v2

Gold objects

gold.dim_product — current product dimension containing active product records and ERP category attributes

Additional customer dimensions and sales fact models can be added as the Gold layer develops.

Bronze Layer

The Bronze layer preserves source data with minimal modification. The stored procedure bronze.load_bronze performs a full refresh by truncating each Bronze table and loading its CSV file with BULK INSERT.

EXEC bronze.load_bronze;

The procedure includes:

Full-load processing

Execution-time logging

Error handling

CRM and ERP source ingestion

The file paths in the Bronze procedure are local SQL Server paths. Update them to match the dataset location on your machine before running the load.

Silver Layer

The Silver layer applies data-quality rules and business transformations. It is loaded by the silver.load_silver stored procedure.

EXEC silver.load_silver;

The procedure uses a transaction so that a failed load can be rolled back instead of leaving the Silver layer partially refreshed.

Customer transformations

Removes records with null customer IDs

Deduplicates customers with ROW_NUMBER()

Keeps the most recent customer record

Removes leading and trailing spaces

Standardizes marital status

Standardizes gender values

Product transformations

Extracts category and product keys from the source product key

Replaces missing product costs with zero

Standardizes product-line codes

Derives product end dates with the LEAD() window function

Identifies the current active product record

Sales transformations

Converts integer dates in YYYYMMDD format to the SQL Server DATE type

Converts invalid or zero date values to null

Recalculates invalid sales amounts

Corrects invalid or negative prices

Protects calculations against division by zero

ERP transformations

Removes the NAS prefix from customer IDs

Removes hyphens from location customer IDs

Rejects future birth dates

Standardizes gender values

Standardizes country codes such as DE, US, and USA

Cleans product-category attributes

Gold Layer

The Gold layer provides analytics-ready dimensional objects. The current product dimension joins cleaned CRM product information with ERP product categories and keeps only active product records.

CREATE OR ALTER VIEW gold.dim_product
AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key, pn.prd_id
    ) AS product_key,
    pn.prd_id AS product_id,
    pn.cat_id AS category_id,
    pn.prd_key AS product_number,
    pn.prd_nm AS product_name,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;

Suggested Repository Structure

sql-server-data-warehouse/
├── datasets/
│   ├── source_crm/
│   └── source_erp/
├── scripts/
│   ├── 01_init_database.sql
│   ├── 02_load_bronze.sql
│   ├── 03_create_silver_tables.sql
│   ├── 04_load_silver.sql
│   └── 05_create_gold_views.sql
├── tests/
│   └── data_quality_checks.sql
└── README.md

Prerequisites

Microsoft SQL Server

SQL Server Management Studio (SSMS)

Permission to create databases, schemas, tables, views, and stored procedures

SQL Server service-account access to the CSV directories

CRM and ERP source CSV files

Execution Order

Open SSMS and connect to SQL Server.

Run 01_init_database.sql to create DataWarehouse, its schemas, and Bronze tables.

Update the CSV paths in 02_load_bronze.sql.

Create and execute bronze.load_bronze.

Run 03_create_silver_tables.sql.

Create and execute silver.load_silver from 04_load_silver.sql.

Run 05_create_gold_views.sql.

Run the data-quality checks.

Use the correct database before creating or executing project objects:

USE DataWarehouse;
GO

Data-Quality Validation

Check row counts

SELECT 'crm_cust_info' AS table_name, COUNT(*) AS row_count
FROM silver.crm_cust_info
UNION ALL
SELECT 'crm_prd_info', COUNT(*) FROM silver.crm_prd_info
UNION ALL
SELECT 'crm_sales_details', COUNT(*) FROM silver.crm_sales_details
UNION ALL
SELECT 'erp_cust_az12', COUNT(*) FROM silver.erp_cust_az12
UNION ALL
SELECT 'erp_loc_a101', COUNT(*) FROM silver.erp_loc_a101
UNION ALL
SELECT 'erp_px_cat_g1v2', COUNT(*) FROM silver.erp_px_cat_g1v2;

Check duplicate customer IDs

SELECT
    cst_id,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

Check invalid sales values

SELECT *
FROM silver.crm_sales_details
WHERE sls_sales <= 0
   OR sls_quatity <= 0
   OR sls_price <= 0;

Check invalid sales dates

SELECT *
FROM silver.crm_sales_details
WHERE sls_ship_dt < sls_order_dt
   OR sls_due_dt < sls_order_dt;

Technologies and SQL Features

Microsoft SQL Server

SQL Server Management Studio

T-SQL

Stored procedures

BULK INSERT

Window functions: ROW_NUMBER() and LEAD()

TRY_CONVERT, CASE, TRIM, NULLIF, and ISNULL

Transactions and TRY...CATCH error handling

Medallion Architecture

Dimensional modelling

Key Learning Outcomes

This project demonstrates how to:

Build a multi-layer data warehouse from raw files

Integrate CRM and ERP datasets

automate repeatable full-load pipelines with stored procedures

Apply practical data-quality and standardization rules

Design analytics-ready dimensional views

Validate data after each processing layer

Future Improvements

Complete the customer dimension and sales fact model

Add primary-key and foreign-key validation for Gold objects

Replace local paths with configurable ingestion parameters

Add incremental-loading support

Add audit tables for load history and rejected records

Connect the Gold layer to Power BI

Schedule pipeline execution with SQL Server Agent

Author

Gebrin

Data Engineering Portfolio Project
