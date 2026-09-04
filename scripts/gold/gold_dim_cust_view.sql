use Datawarehouse;


--- Joining two tables ---
SELECT
    t.cst_id,
    COUNT(*) AS record_count
FROM
(
    SELECT
        ci.cst_id,
        ci.cst_key,
        ci.cst_firstname,
        ci.cst_lastname,
        ci.cst_material_status,
        ci.cst_gndr,
        ci.cst_create_date,
        ca.bdate,
        ca.gen,
        la.cntry
    FROM silver.crm_cust_info AS ci

    LEFT JOIN silver.erp_cust_az12 AS ca
        ON ci.cst_key = ca.cid

    LEFT JOIN silver.erp_loc_a101 AS la
        ON ci.cst_key = la.cid
) AS t

GROUP BY t.cst_id
HAVING COUNT(*) > 1;

--- since 2 gender table combining the both ---

select distinct 
ci.cst_gndr,
ca.gen,
case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- CRM is the master for gender info --
    else coalesce(ca.gen,'n/a')
end as new_gen
FROM silver.crm_cust_info AS ci

    LEFT JOIN silver.erp_cust_az12 AS ca
        ON ci.cst_key = ca.cid

    LEFT JOIN silver.erp_loc_a101 AS la
        ON ci.cst_key = la.cid

---- Final Query ---

create view gold.dim_customers as
SELECT
        row_number() over (order by cst_id) as customer_key,
        ci.cst_id as customer_id,
        ci.cst_key as customer_number,
        ci.cst_firstname as first_name,
        ci.cst_lastname as last_name,
        ci.cst_material_status as marital_status,
        case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- CRM is the master for gender info --
            else coalesce(ca.gen,'n/a')
        end as gender,
        ci.cst_create_date as create_date,
        ca.bdate as birthdate,
        la.cntry as country
    FROM silver.crm_cust_info AS ci

    LEFT JOIN silver.erp_cust_az12 AS ca
        ON ci.cst_key = ca.cid

    LEFT JOIN silver.erp_loc_a101 AS la
        ON ci.cst_key = la.cid
