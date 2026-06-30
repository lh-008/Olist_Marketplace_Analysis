COPY (
    SELECT
        segment,
        purchase_type,
        COUNT(*) AS customers,
        ROUND(AVG(recency_days), 1) AS avg_recency_days,
        ROUND(AVG(frequency), 2) AS avg_frequency,
        ROUND(AVG(monetary), 2) AS avg_monetary,
        ROUND(SUM(monetary), 2) AS total_monetary,
        ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers,
        ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 2) AS pct_of_revenue
    FROM rfm_scored
    GROUP BY segment, purchase_type
    ORDER BY total_monetary DESC
) TO 'output/rfm_segment_summary.csv' (HEADER, DELIMITER ',');

COPY (
    SELECT customer_unique_id, purchase_type, segment, r_score, f_score, m_score, 
           recency_days, frequency, monetary
    FROM rfm_scored
) TO 'output/rfm_customers.csv' (HEADER, DELIMITER ',');