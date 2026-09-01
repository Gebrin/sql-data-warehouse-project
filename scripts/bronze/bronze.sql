/*
===============================================================================
Procedure    : bronze.load_bronze
Description  : Truncates and reloads all Bronze-layer tables from CRM and ERP
               CSV source files.

Execution:
    EXEC bronze.load_bronze;

Load method:
    Full load using TRUNCATE TABLE followed by BULK INSERT.
===============================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @batch_start_time DATETIME2,
        @batch_end_time   DATETIME2;

    BEGIN TRY
        SET @batch_start_time = SYSDATETIME();

        PRINT '================================================';
        PRINT 'Starting Bronze-layer load';
        PRINT '================================================';


        /*======================================================================
          1. LOAD CRM TABLES
        ======================================================================*/

        PRINT 'Loading bronze.crm_cust_info...';

        TRUNCATE TABLE bronze.crm_cust_info;

        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\gibso\Desktop\Gebrin\01 Data Engineering\Data_warehouse_project\datasets\source_crm\cust_info.csv'
        WITH
        (
            FIRSTROW       = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            TABLOCK
        );


        PRINT 'Loading bronze.crm_prd_info...';

        TRUNCATE TABLE bronze.crm_prd_info;

        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\gibso\Desktop\Gebrin\01 Data Engineering\Data_warehouse_project\datasets\source_crm\prd_info.csv'
        WITH
        (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            TABLOCK
        );


        PRINT 'Loading bronze.crm_sales_details...';

        TRUNCATE TABLE bronze.crm_sales_details;

        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\gibso\Desktop\Gebrin\01 Data Engineering\Data_warehouse_project\datasets\source_crm\sales_details.csv'
        WITH
        (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            TABLOCK
        );


        /*======================================================================
          2. LOAD ERP TABLES
        ======================================================================*/

        PRINT 'Loading bronze.erp_cust_az12...';

        TRUNCATE TABLE bronze.erp_cust_az12;

        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\gibso\Desktop\Gebrin\01 Data Engineering\Data_warehouse_project\datasets\source_erp\CUST_AZ12.csv'
        WITH
        (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            TABLOCK
        );


        PRINT 'Loading bronze.erp_loc_a101...';

        TRUNCATE TABLE bronze.erp_loc_a101;

        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\gibso\Desktop\Gebrin\01 Data Engineering\Data_warehouse_project\datasets\source_erp\LOC_A101.csv'
        WITH
        (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            TABLOCK
        );


        PRINT 'Loading bronze.erp_px_cat_g1v2...';

        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\gibso\Desktop\Gebrin\01 Data Engineering\Data_warehouse_project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH
        (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '0x0a',
            CODEPAGE        = '65001',
            TABLOCK
        );


        /*======================================================================
          3. LOAD SUMMARY
        ======================================================================*/

        SET @batch_end_time = SYSDATETIME();

        PRINT '================================================';
        PRINT 'Bronze-layer load completed successfully.';
        PRINT 'Total load duration: '
            + CAST(
                DATEDIFF(SECOND, @batch_start_time, @batch_end_time)
                AS NVARCHAR(20)
              )
            + ' seconds.';
        PRINT '================================================';

    END TRY

    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR: Bronze-layer load failed';
        PRINT 'Error number: '
            + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error state: '
            + CAST(ERROR_STATE() AS NVARCHAR(20));
        PRINT 'Error line: '
            + CAST(ERROR_LINE() AS NVARCHAR(20));
        PRINT 'Error procedure: '
            + COALESCE(ERROR_PROCEDURE(), N'Not available');
        PRINT 'Error message: '
            + ERROR_MESSAGE();
        PRINT '================================================';

        THROW;
    END CATCH;
END;
GO
