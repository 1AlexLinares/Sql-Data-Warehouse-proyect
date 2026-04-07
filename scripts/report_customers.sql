--============================================================================
--Create Report: gold.report_customers
--===========================================================================
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

WITH base_query AS(
/*------------------------------------------------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
------------------------------------------------------------------------------------------------------------------*/
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key, 
c.customer_number,
CONCAT(C.first_name,'  ',c.last_name)AS customer_name,
DATEDIFF( year,c.birthdate, GETDATE()) age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)


,  customer_aggregation AS(
/*------------------------------------------------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer leve
------------------------------------------------------------------------------------------------------------------*/
SELECT
		customer_key,
		customer_number,
		customer_name,		
		age,
		COUNT(DISTINCT product_key) AS total_orders,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT product_key) AS total_products,
		MAX(order_date) AS last_order_date,
		DATEDIFF(month,MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY  
		customer_key,
		customer_name,
		customer_number,
		age
)
SELECT 
customer_key,
customer_name,
customer_number,
age,
CASE
		WHEN age < 20 THEN 'Under 20'
		WHEN age between 20 and 29 THEN '20 - 29'
		WHEN age between 30 and 39 THEN '30 - 39'
		WHEN age between 40 and 49 THEN '40 - 49'
		ELSE '50 and above'
END AS age_group,
CASE 
		WHEN lifespan > 12 and total_sales > 5000 THEN 'Vip'
		WHEN lifespan > 12 and total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
END customer_segment,
last_order_date,
DATEDIFF(month, last_order_date,GETDATE()) AS recency,
total_orders,
total_sales,
total_quantity,
total_products,
lifespan,
--compuate average order value (AVO)
CASE WHEN total_sales = 0 THEN 0
		   ELSE total_sales / total_orders 
END AS avg_order_value,
--compiate average montly spend
CASE WHEN lifespan = 0 THEN total_sales	
		  ELSE total_sales / lifespan
END AS avg_montly_spend
FROM  customer_aggregation;
