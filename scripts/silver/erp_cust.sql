truncate table silver.erp_cust_az12;

insert into silver.erp_cust_az12(
cid,bdate,gen
)

select 
case when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
	else cid
end cid,
CASE
        WHEN TRY_CAST(bdate AS DATE) > CAST(GETDATE() AS DATE)
            THEN NULL
        ELSE TRY_CAST(bdate AS DATE)
    END AS bdate,
case when UPPER(TRIM(gen)) IN ('F','FEMALE') then 'Female'
    when UPPER(TRIM(gen)) IN ('M','MALE') then 'Male'
    else 'n/a'
end as gen
from bronze.erp_cust_az12;
