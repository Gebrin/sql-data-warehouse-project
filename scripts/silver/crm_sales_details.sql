TRUNCATE TABLE silver.crm_sales_details;
GO

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
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    TRY_CONVERT(
        DATE,
        NULLIF(CAST(sls_order_dt AS VARCHAR(8)), '0'),
        112
    ) AS sls_order_dt,

    TRY_CONVERT(
        DATE,
        NULLIF(CAST(sls_ship_dt AS VARCHAR(8)), '0'),
        112
    ) AS sls_ship_dt,

    TRY_CONVERT(
        DATE,
        NULLIF(CAST(sls_due_dt AS VARCHAR(8)), '0'),
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
            CAST(sls_sales AS DECIMAL(18,2))
            / NULLIF(sls_quatity, 0)
        ELSE ABS(sls_price)
    END AS sls_price

FROM bronze.crm_sales_details;
GO
