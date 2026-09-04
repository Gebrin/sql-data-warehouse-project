create view gold.dim_product as
select
	row_number() over(order by pn.prd_start_dt,pn.prd_key) as prodcut_key,
	pn.prd_id as product_id,
	pn.cat_id as category_id,
	pn.prd_key as product_number,
	pn.prd_nm as product_name,
	pn.prd_cost as cost,
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance as maintenance
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
on pn.cat_id = pc.id
where prd_end_dt is null  --- Filter out all historical data ---

