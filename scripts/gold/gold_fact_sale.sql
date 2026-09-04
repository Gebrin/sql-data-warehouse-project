create view  gold.fact_sales as

select 
sd.sls_ord_num as order_number,
pr.prodcut_key,
cu.customer_key,
sd.sls_prd_key,
sd.sls_cust_id,
sd.sls_order_dt as order_date,
sd.sls_ship_dt as shipping_date,
sd.sls_due_dt as due_date,
sd.sls_quatity as sales_amount,
sd.sls_price as price

from silver.crm_sales_details sd 
left join gold.dim_product pr
on sd.sls_prd_key = pr.product_number
left join gold.dim_customers cu
on sd.sls_cust_id = cu.customer_id
