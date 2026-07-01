-- sql/08_first_order_retention.sql
-- Among customers whose FIRST order had a given delivery experience,
-- what fraction ever placed a second order?
-- This is the direct link between delivery quality and retention.

COPY (
    WITH first_orders AS (
        -- Identify each customer's first delivered order using window function
        SELECT
            customer_unique_id,
            order_id,
            delay_vs_promise,
            review_score,
            ROW_NUMBER() OVER (
                PARTITION BY customer_unique_id 
                ORDER BY order_purchase_timestamp
            ) AS order_rank
        FROM delivery_base
    ),
    customer_first AS (
        SELECT * FROM first_orders WHERE order_rank = 1
    ),
    customer_totals AS (
        -- Total delivered orders per customer (across all time)
        SELECT
            customer_unique_id,
            COUNT(*) AS total_orders
        FROM delivery_base
        GROUP BY customer_unique_id
    ),
    joined AS (
        SELECT
            cf.customer_unique_id,
            cf.delay_vs_promise,
            cf.review_score AS first_review,
            ct.total_orders,
            CASE WHEN ct.total_orders > 1 THEN 1 ELSE 0 END AS returned,
            CASE
                WHEN cf.delay_vs_promise <= -10 THEN '1. Very Early (10+ days)'
                WHEN cf.delay_vs_promise <=  -3 THEN '2. Early (3-10 days)'
                WHEN cf.delay_vs_promise <=   0 THEN '3. On Time (-3 to 0)'
                WHEN cf.delay_vs_promise <=   7 THEN '4. Late (1-7 days)'
                ELSE                                 '5. Very Late (7+ days)'
            END AS first_delivery_bucket
        FROM customer_first cf
        JOIN customer_totals ct ON cf.customer_unique_id = ct.customer_unique_id
    )
    SELECT
        first_delivery_bucket,
        COUNT(*) AS customers,
        SUM(returned) AS returned_customers,
        ROUND(100.0 * SUM(returned) / COUNT(*), 2) AS return_rate_pct,
        ROUND(AVG(first_review), 2) AS avg_first_review
    FROM joined
    GROUP BY first_delivery_bucket
    ORDER BY first_delivery_bucket
) TO 'output/first_order_retention.csv' (HEADER, DELIMITER ',');