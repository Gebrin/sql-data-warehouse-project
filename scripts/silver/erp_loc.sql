truncate table silver.erp_loc_a101;

select * from bronze.erp_loc_a101

insert into silver.erp_loc_a101(
cid,cntry)

SELECT
    REPLACE(cid, '-', '') AS cid,

    CASE
        WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'N/A'
        WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
        WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
        ELSE TRIM(cntry)
    END AS cntry

FROM bronze.erp_loc_a101;
