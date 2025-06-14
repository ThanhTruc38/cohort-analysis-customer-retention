-- RFM Score --
WITH table_cleaned AS (
	SELECT *
	FROM online_retail_II
	WHERE Quantity > 0
		AND Price > 0
		AND Customer_ID IS NOT NULL
)
, table_rfm AS (
	SELECT Customer_ID
		, recency = DATEDIFF(day, MAX(InvoiceDate), '2011-12-09')
		, frequency = COUNT(DISTINCT Invoice)
		, monetary = SUM(CAST(Price*Quantity AS BIGINT))
	FROM table_cleaned
	GROUP BY Customer_ID
)
, table_rank AS (
	SELECT *
		, PERCENT_RANK() OVER (ORDER BY recency ASC) AS r_rank
		, PERCENT_RANK() OVER (ORDER BY frequency DESC) AS p_rank
		, PERCENT_RANK() OVER (ORDER BY monetary DESC) AS m_rank
	FROM table_rfm
)
, table_tier AS (
	SELECT *
		, CASE WHEN r_rank <= 0.2 THEN 1
			WHEN r_rank <= 0.4 THEN 2
			WHEN r_rank <= 0.6 THEN 3
			WHEN r_rank <= 0.8 THEN 4
			ELSE 5 END AS r_tier
		, CASE WHEN p_rank <= 0.2 THEN 1
			WHEN p_rank <= 0.4 THEN 2
			WHEN p_rank <= 0.6 THEN 3
			WHEN p_rank <= 0.8 THEN 4
			ELSE 5 END AS p_tier
		, CASE WHEN m_rank <= 0.2 THEN 1
			WHEN m_rank <= 0.4 THEN 2
			WHEN m_rank <= 0.6 THEN 3
			WHEN m_rank <= 0.8 THEN 4
			ELSE 5 END AS m_tier
	FROM table_rank
)
, table_score AS (
	SELECT *
		, CONCAT(r_tier, p_tier, m_tier) AS rfm_score
	FROM table_tier
)
, table_seg AS (
	SELECT *
		, CASE WHEN rfm_score IN ('555','554','544','545','454','455','445') THEN 'Champions'
			WHEN rfm_score IN ('543','444','435','355','354','345','344','335') THEN 'Loyal Customers'
			WHEN rfm_score IN ('553','551','552','541','542','533','532','531','452','451','442','441','431'
								,'453','433','432','423','353','352','351','342','341','333','323') THEN 'Potential Loyalist'
			WHEN rfm_score IN ('512','511','422','421','412','411','311') THEN 'Recent Customers'
			WHEN rfm_score IN ('525','524','523','522','521','515','514','513','425','424','413','414','415'
								,'315','314','313') THEN 'Promising'
			WHEN rfm_score IN ('535','534','443','434','343','334','325','324') THEN 'Customers Needing Attention'
			WHEN rfm_score IN ('331','321','312','221','213') THEN 'About To Sleep'
			WHEN rfm_score IN ('255','254','245','244','253','252','243','242','235','234','225','224','153'
								  ,'152','145','143','142','135','134','133','125','124') THEN 'At Risk'
			WHEN rfm_score IN ('155','154','144','214','215','115','114','113') THEN 'Can’t Lose Them'
			WHEN rfm_score IN ('332','322','231','241','251','233','232','223','222','132','123','122','212','211') THEN 'Hibernating'
			ELSE 'Lost' END AS customer_segmentation
	FROM table_score
)
-- Calculate CLV average -- 
, table_with_clv AS (
	SELECT seg.*
		, rfm.monetary AS clv
	FROM table_seg AS seg
	JOIN table_rfm AS rfm
		ON seg.Customer_ID = rfm.Customer_ID
)
SELECT customer_segmentation
	, COUNT(*) AS total_customers
	, AVG(clv) AS avg_clv
FROM table_with_clv
GROUP BY customer_segmentation
ORDER BY avg_clv DESC;