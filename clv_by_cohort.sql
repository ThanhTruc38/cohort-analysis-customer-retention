WITH table_first_quarter AS (
	SELECT Customer_ID, InvoiceDate
		, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, InvoiceDate), 0) AS quarter_time
		, MIN(DATEADD(QUARTER, DATEDIFF(QUARTER, 0, InvoiceDate), 0)) OVER (PARTITION BY Customer_ID) AS first_quarter
	FROM online_retail_II
	WHERE Quantity > 0 
		AND Price > 0 
		AND Customer_ID IS NOT NULL
)
, table_cohort AS (
	SELECT DISTINCT Customer_ID
		, FORMAT(first_quarter, 'yyyy') + 'Q' + CAST(DATEPART(QUARTER, first_quarter) AS VARCHAR) AS first_quarter_purchase
	FROM table_first_quarter
)
, table_rfm AS (
	SELECT Customer_ID
		, SUM(CAST(Quantity * Price AS BIGINT)) AS clv
	FROM online_retail_II
	WHERE Quantity > 0 
		AND Price > 0 
			AND Customer_ID IS NOT NULL
	GROUP BY Customer_ID
)
, table_clv_cohort AS (
	SELECT cohort.first_quarter_purchase
		, rfm.Customer_ID
		, rfm.clv
	FROM table_cohort AS cohort
	JOIN table_rfm AS rfm
		ON cohort.Customer_ID = rfm.Customer_ID
)
SELECT first_quarter_purchase
	, COUNT(*) AS total_customers
	, AVG(clv) AS avg_clv
FROM table_clv_cohort
GROUP BY first_quarter_purchase
ORDER BY first_quarter_purchase;