use Datawarehouse

/* Silver layer cleaning of crm_cst_info table */

/* checking   for Primary Key    */

select cst_id, count(*) 
from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null;

/* reading all the value where the cst_id is more than one      */
select * 
from bronze.crm_cust_info
where cst_id in (29449,29473,29433,29483,29466) or cst_id is null;

/* Flagging the the repeated primary key  */

select * 
from ( select *, ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last
from bronze.crm_cust_info
where cst_id is not null )t where flag_last!=1;

-- Check Unwanted Space --

select cst_key,cst_firstname,cst_lastname,cst_material_status,cst_gndr
from bronze.crm_cust_info
where cst_firstname != TRIM(cst_firstname) or cst_lastname != TRIM(cst_lastname) or
cst_key != TRIM(cst_key) or cst_material_status != TRIM(cst_material_status) or cst_gndr != TRIM(cst_gndr);

-- Checking data data standarization and Consistency --

select * from bronze.crm_cust_info;

select distinct cst_gndr,cst_material_status
from bronze.crm_cust_info;

SELECT
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE
        WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
        ELSE 'N/A'
    END AS cst_material_status,
    CASE
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
        ELSE 'N/A'
    END AS cst_gndr
FROM bronze.crm_cust_info;

---  Complete query after combining the above the cleaning that we did to insert the value to the silver.crm_cust_info table


TRUNCATE TABLE silver.crm_cust_info;

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
        WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
        ELSE 'N/A'
    END AS cst_marital_status,

    CASE
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'N/A'
    END AS cst_gndr,

    cst_create_date
FROM
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS row_num
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) AS ranked_customers
WHERE row_num = 1;
GO

select * from silver.crm_cust_info;
