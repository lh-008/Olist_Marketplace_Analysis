-- sql/07_delivery_reviews.sql
-- Does delivery experience predict review score?

-- Query A: bucketed view for the dashboard
COPY (
    WITH bucketed AS (
        SELECT
            *,
            CASE
                WHEN delay_vs_promise <= -10 THEN '1. Very Early (10+ days)'
                WHEN delay_vs_promise <=  -3 THEN '2. Early (3-10 days)'
                WHEN delay_vs_promise <=   0 THEN '3. On Time (-3 to 0)'
                WHEN delay_vs_promise <=   7 THEN '4. Late (1-7 days)'
                ELSE                             '5. Very Late (7+ days)'
            END AS delivery_bucket
        FROM delivery_base
        WHERE review_score IS NOT NULL
    )
    SELECT
        delivery_bucket,
        COUNT(*) AS orders,
        ROUND(AVG(review_score), 2) AS avg_review,
        ROUND(100.0 * SUM(CASE WHEN review_score = 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_1_star,
        ROUND(100.0 * SUM(CASE WHEN review_score = 5 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_5_star,
        ROUND(100.0 * SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_bad_reviews
    FROM bucketed
    GROUP BY delivery_bucket
    ORDER BY delivery_bucket
) TO 'output/delivery_review_buckets.csv' (HEADER, DELIMITER ',');