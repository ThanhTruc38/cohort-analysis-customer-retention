WITH table_first_quarter AS (
	SELECT Customer_ID, Invoice, StockCode, InvoiceDate
		, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, InvoiceDate), 0) AS quarter_time
		, MIN(DATEADD(QUARTER, DATEDIFF(QUARTER, 0, InvoiceDate), 0)) OVER (PARTITION BY Customer_ID) AS first_quarter
	FROM online_retail_II
	WHERE Quantity > 0
		AND Price > 0
		AND Customer_ID IS NOT NULL
)
, table_quarter_n AS (
	SELECT *
		, FORMAT(first_quarter, 'yyyy') + 'Q' + CAST(DATEPART(QUARTER, first_quarter) AS VARCHAR) AS first_quarter_purchase
		, DATEDIFF(QUARTER, first_quarter,quarter_time ) AS quarter_n
	FROM table_first_quarter
)
, table_customer_retained AS (
	SELECT first_quarter_purchase, quarter_n
		, COUNT(DISTINCT Customer_ID) AS customer_retained
	FROM table_quarter_n
	GROUP BY first_quarter_purchase, quarter_n
)
, table_rate AS (
	SELECT *
		, FIRST_VALUE(customer_retained) OVER (PARTITION BY first_quarter_purchase ORDER BY quarter_n) AS total_customer
		, ROUND(CAST(customer_retained AS FLOAT) / FIRST_VALUE(customer_retained) OVER (PARTITION BY first_quarter_purchase ORDER BY quarter_n),4) AS rate
	FROM table_customer_retained
)
SELECT first_quarter_purchase, total_customer
	, "0", "1", "2", "3", "4", "5", "6", "7", "8"
FROM (
	SELECT first_quarter_purchase, quarter_n, total_customer, rate
	FROM table_rate
) AS table_resource
PIVOT (
	SUM(rate)
	FOR quarter_n IN ("0", "1", "2", "3", "4", "5", "6", "7", "8")
) AS table_pivot
ORDER BY first_quarter_purchase