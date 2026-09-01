/*
===============================================================================
Project      : SQL Server Data Warehouse
Script       : 01_init_database.sql
Description  : Creates the DataWarehouse database, Medallion schemas,
               and Bronze-layer tables.

Layers:
    bronze   - Raw source data
    silver   - Cleaned and transformed data
    gold     - Business-ready analytical data

Warning:
    This script creates objects only when they do not already exist.
===============================================================================
*/


/*==============================================================================
  1. CREATE DATABASE
==============================================================================*/

USE master;
GO

IF DB_ID(N'DataWarehouse') IS NULL
BEGIN
    CREATE DATABASE DataWarehouse;
    PRINT 'Database DataWarehouse created successfully.';
END
ELSE
BEGIN
    PRINT 'Database DataWarehouse already exists.';
END;
GO


/*==============================================================================
  2. SELECT DATABASE
==============================================================================*/

USE DataWarehouse;
GO


/*==============================================================================
  3. CREATE MEDALLION SCHEMAS
==============================================================================*/

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'bronze'
)
BEGIN
    EXEC(N'CREATE SCHEMA bronze AUTHORIZATION dbo;');
    PRINT 'Schema bronze created successfully.';
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'silver'
)
BEGIN
    EXEC(N'CREATE SCHEMA silver AUTHORIZATION dbo;');
    PRINT 'Schema silver created successfully.';
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'gold'
)
BEGIN
    EXEC(N'CREATE SCHEMA gold AUTHORIZATION dbo;');
    PRINT 'Schema gold created successfully.';
END;
GO


/*==============================================================================
  4. CREATE BRONZE CRM TABLES
==============================================================================*/


/*------------------------------------------------------------------------------
  Table: bronze.crm_cust_info
  Source: CRM customer information
------------------------------------------------------------------------------*/

IF OBJECT_ID(N'bronze.crm_cust_info', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_cust_info
    (
        cst_id             INT,
        cst_key            NVARCHAR(50),
        cst_firstname      NVARCHAR(50),
        cst_lastname       NVARCHAR(50),
        cst_marital_status NVARCHAR(50),
        cst_gndr           NVARCHAR(50),
        cst_create_date    DATE
    );

    PRINT 'Table bronze.crm_cust_info created successfully.';
END;
GO


/*------------------------------------------------------------------------------
  Table: bronze.crm_prd_info
  Source: CRM product information
------------------------------------------------------------------------------*/

IF OBJECT_ID(N'bronze.crm_prd_info', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_prd_info
    (
        prd_id       INT,
        prd_key      NVARCHAR(50),
        prd_nm       NVARCHAR(50),
        prd_cost     INT,
        prd_line     NVARCHAR(50),
        prd_start_dt DATE,
        prd_end_dt   DATE
    );

    PRINT 'Table bronze.crm_prd_info created successfully.';
END;
GO


/*------------------------------------------------------------------------------
  Table: bronze.crm_sales_details
  Source: CRM sales transactions
------------------------------------------------------------------------------*/

IF OBJECT_ID(N'bronze.crm_sales_details', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.crm_sales_details
    (
        sls_ord_num  NVARCHAR(50),
        sls_prd_key  NVARCHAR(50),
        sls_cust_id  INT,
        sls_order_dt INT,
        sls_ship_dt  INT,
        sls_due_dt   INT,
        sls_sales    INT,
        sls_quantity INT,
        sls_price    INT
    );

    PRINT 'Table bronze.crm_sales_details created successfully.';
END;
GO


/*==============================================================================
  5. CREATE BRONZE ERP TABLES
==============================================================================*/


/*------------------------------------------------------------------------------
  Table: bronze.erp_loc_a101
  Source: ERP customer location information
------------------------------------------------------------------------------*/

IF OBJECT_ID(N'bronze.erp_loc_a101', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_loc_a101
    (
        cid   NVARCHAR(50),
        cntry NVARCHAR(50)
    );

    PRINT 'Table bronze.erp_loc_a101 created successfully.';
END;
GO


/*------------------------------------------------------------------------------
  Table: bronze.erp_cust_az12
  Source: ERP customer demographic information

  Note:
      bdate is stored as NVARCHAR in Bronze to preserve raw source values.
      It should be validated and converted to DATE in the Silver layer.
------------------------------------------------------------------------------*/

IF OBJECT_ID(N'bronze.erp_cust_az12', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_cust_az12
    (
        cid   NVARCHAR(50),
        bdate NVARCHAR(50),
        gen   NVARCHAR(50)
    );

    PRINT 'Table bronze.erp_cust_az12 created successfully.';
END;
GO


/*------------------------------------------------------------------------------
  Table: bronze.erp_px_cat_g1v2
  Source: ERP product category information
------------------------------------------------------------------------------*/

IF OBJECT_ID(N'bronze.erp_px_cat_g1v2', N'U') IS NULL
BEGIN
    CREATE TABLE bronze.erp_px_cat_g1v2
    (
        id          NVARCHAR(50),
        cat         NVARCHAR(50),
        subcat      NVARCHAR(50),
        maintenance NVARCHAR(50)
    );

    PRINT 'Table bronze.erp_px_cat_g1v2 created successfully.';
END;
GO


/*==============================================================================
  6. VALIDATE CREATED OBJECTS
==============================================================================*/

SELECT
    TABLE_SCHEMA AS schema_name,
    TABLE_NAME AS table_name,
    TABLE_TYPE AS object_type
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN (N'bronze', N'silver', N'gold')
ORDER BY
    TABLE_SCHEMA,
    TABLE_NAME;
GO
