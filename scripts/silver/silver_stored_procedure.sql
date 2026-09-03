USE DataWarehouse;
GO

EXEC silver.load_silver;
GO




/*
===============================================================================
Procedure   : silver.load_silver
Description : Cleans and transforms Bronze-layer data and loads it into the
              corresponding Silver-layer tables.

Load type   : Full load
Method      : TRUNCATE TABLE followed by INSERT INTO

Execution:
    EXEC silver.load_silver;
===============================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @start_time DATETIME2,
        @end_time   DATETIME2,
        @row_count  INT;

    BEGIN TRY
        SET @start_time = SYSDATETIME();

        BEGIN TRANSACTION;

        PRINT '================================================';
        PRINT 'Starting Silver-layer load';
        PRINT '================================================';


        /*======================================================================
          1. LOAD CRM CUSTOMER INFORMATION
        ======================================================================*/

        PRINT 'Truncating silver.crm_cust_info';

        TRUNCATE TABLE silver.crm_cust_info;

        PRINT 'Inserting data into silver.crm_cust_info';

        INSERT INTO silver.crm_cust_info
        (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_material_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            TRIM(cst_key) AS cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,

            CASE
                WHEN UPPER(TRIM(cst_material_status)) = 'S'
                    THEN 'Single'
                WHEN UPPER(TRIM(cst_material_status)) = 'M'
                    THEN 'Married'
                ELSE 'N/A'
            END AS cst_material_status,

            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F'
                    THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M'
                    THEN 'Male'
                ELSE 'N/A'
            END AS cst_gndr,

            cst_create_date

        FROM
        (
            SELECT
                *,
                ROW_NUMBER() OVER
                (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS row_num
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) AS ranked_customers
        WHERE row_num = 1;

        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded silver.crm_cust_info: '
            + CAST(@row_count AS VARCHAR(20))
            + ' rows';


        /*======================================================================
          2. LOAD CRM PRODUCT INFORMATION
        ======================================================================*/

        PRINT '------------------------------------------------';
        PRINT 'Truncating silver.crm_prd_info';

        TRUNCATE TABLE silver.crm_prd_info;

        PRINT 'Inserting data into silver.crm_prd_info';

        INSERT INTO silver.crm_prd_info
        (
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

            REPLACE(
                SUBSTRING(TRIM(prd_key), 1, 5),
                '-',
                '_'
            ) AS cat_id,

            SUBSTRING(
                TRIM(prd_key),
                7,
                LEN(TRIM(prd_key))
            ) AS prd_key,

            TRIM(prd_nm) AS prd_nm,

            ISNULL(prd_cost, 0) AS prd_cost,

            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'N/A'
            END AS prd_line,

            prd_start_dt,

            DATEADD
            (
                DAY,
                -1,
                LEAD(prd_start_dt) OVER
                (
                    PARTITION BY SUBSTRING(
                        TRIM(prd_key),
                        7,
                        LEN(TRIM(prd_key))
                    )
                    ORDER BY prd_start_dt
                )
            ) AS prd_end_dt

        FROM bronze.crm_prd_info;

        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded silver.crm_prd_info: '
            + CAST(@row_count AS VARCHAR(20))
            + ' rows';


        /*======================================================================
          3. LOAD CRM SALES DETAILS
        ======================================================================*/

        PRINT '------------------------------------------------';
        PRINT 'Truncating silver.crm_sales_details';

        TRUNCATE TABLE silver.crm_sales_details;

        PRINT 'Inserting data into silver.crm_sales_details';

        INSERT INTO silver.crm_sales_details
        (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quatity,
            sls_price
        )
        SELECT
            TRIM(sls_ord_num) AS sls_ord_num,
            TRIM(sls_prd_key) AS sls_prd_key,
            sls_cust_id,

            TRY_CONVERT
            (
                DATE,
                NULLIF(
                    CAST(sls_order_dt AS VARCHAR(8)),
                    '0'
                ),
                112
            ) AS sls_order_dt,

            TRY_CONVERT
            (
                DATE,
                NULLIF(
                    CAST(sls_ship_dt AS VARCHAR(8)),
                    '0'
                ),
                112
            ) AS sls_ship_dt,

            TRY_CONVERT
            (
                DATE,
                NULLIF(
                    CAST(sls_due_dt AS VARCHAR(8)),
                    '0'
                ),
                112
            ) AS sls_due_dt,

            CASE
                WHEN sls_sales IS NULL
                  OR sls_sales <= 0
                  OR sls_sales <> sls_quatity * ABS(sls_price)
                THEN sls_quatity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quatity,

            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                THEN
                    CAST(sls_sales AS DECIMAL(18, 2))
                    / NULLIF(sls_quatity, 0)
                ELSE ABS(sls_price)
            END AS sls_price

        FROM bronze.crm_sales_details;

        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded silver.crm_sales_details: '
            + CAST(@row_count AS VARCHAR(20))
            + ' rows';


        /*======================================================================
          4. LOAD ERP CUSTOMER INFORMATION
        ======================================================================*/

        PRINT '------------------------------------------------';
        PRINT 'Truncating silver.erp_cust_az12';

        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT 'Inserting data into silver.erp_cust_az12';

        INSERT INTO silver.erp_cust_az12
        (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE
                WHEN TRIM(cid) LIKE 'NAS%'
                THEN SUBSTRING(
                    TRIM(cid),
                    4,
                    LEN(TRIM(cid))
                )
                ELSE TRIM(cid)
            END AS cid,

            CASE
                WHEN TRY_CONVERT(
                        DATE,
                        TRIM(bdate),
                        23
                     ) > CAST(GETDATE() AS DATE)
                THEN NULL
                ELSE TRY_CONVERT(
                    DATE,
                    TRIM(bdate),
                    23
                )
            END AS bdate,

            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                    THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                    THEN 'Male'
                ELSE 'N/A'
            END AS gen

        FROM bronze.erp_cust_az12;

        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded silver.erp_cust_az12: '
            + CAST(@row_count AS VARCHAR(20))
            + ' rows';


        /*======================================================================
          5. LOAD ERP CUSTOMER LOCATION
        ======================================================================*/

        PRINT '------------------------------------------------';
        PRINT 'Truncating silver.erp_loc_a101';

        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT 'Inserting data into silver.erp_loc_a101';

        INSERT INTO silver.erp_loc_a101
        (
            cid,
            cntry
        )
        SELECT
            REPLACE(
                TRIM(cid),
                '-',
                ''
            ) AS cid,

            CASE
                WHEN cntry IS NULL OR TRIM(cntry) = ''
                    THEN 'N/A'
                WHEN UPPER(TRIM(cntry)) = 'DE'
                    THEN 'Germany'
                WHEN UPPER(TRIM(cntry)) IN ('US', 'USA')
                    THEN 'United States'
                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze.erp_loc_a101;

        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded silver.erp_loc_a101: '
            + CAST(@row_count AS VARCHAR(20))
            + ' rows';


        /*======================================================================
          6. LOAD ERP PRODUCT CATEGORIES
        ======================================================================*/

        PRINT '------------------------------------------------';
        PRINT 'Truncating silver.erp_px_cat_g1v2';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT 'Inserting data into silver.erp_px_cat_g1v2';

        INSERT INTO silver.erp_px_cat_g1v2
        (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            TRIM(id) AS id,
            TRIM(cat) AS cat,
            TRIM(subcat) AS subcat,
            TRIM(maintenance) AS maintenance

        FROM bronze.erp_px_cat_g1v2;

        SET @row_count = @@ROWCOUNT;

        PRINT 'Loaded silver.erp_px_cat_g1v2: '
            + CAST(@row_count AS VARCHAR(20))
            + ' rows';


        /*======================================================================
          7. COMPLETE TRANSACTION
        ======================================================================*/

        COMMIT TRANSACTION;

        SET @end_time = SYSDATETIME();

        PRINT '================================================';
        PRINT 'Silver-layer load completed successfully';
        PRINT 'Total duration: '
            + CAST(
                DATEDIFF(SECOND, @start_time, @end_time)
                AS VARCHAR(20)
              )
            + ' seconds';
        PRINT '================================================';

    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT '================================================';
        PRINT 'ERROR: Silver-layer load failed';
        PRINT 'Error number: '
            + CAST(ERROR_NUMBER() AS VARCHAR(20));
        PRINT 'Error state: '
            + CAST(ERROR_STATE() AS VARCHAR(20));
        PRINT 'Error line: '
            + CAST(ERROR_LINE() AS VARCHAR(20));
        PRINT 'Error procedure: '
            + COALESCE(ERROR_PROCEDURE(), 'Not available');
        PRINT 'Error message: '
            + ERROR_MESSAGE();
        PRINT '================================================';

        THROW;
    END CATCH;
END;
GO
