-- sql/03_rfm_base.sql
-- Compute raw Recency, Frequency, Monetary per unique customer.
-- Filters to delivered orders only.

CREATE OR REPLACE TABLE rfm_base AS
WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
order_value AS (
    SELECT
        order_id,
        SUM(price + freight_value) AS order_total
    FROM order_items
    GROUP BY order_id
),
snapshot AS (
    SELECT MAX(order_purchase_timestamp) AS snapshot_date
    FROM delivered_orders
)
SELECT
    d.customer_unique_id,
    COUNT(DISTINCT d.order_id) AS frequency,
    ROUND(SUM(v.order_total), 2) AS monetary,
    DATE_DIFF('day', MAX(d.order_purchase_timestamp), (SELECT snapshot_date FROM snapshot)) AS recency_days,
    MAX(d.order_purchase_timestamp) AS last_order_date,
    CASE WHEN COUNT(DISTINCT d.order_id) = 1 THEN 'single' ELSE 'repeat' END AS purchase_type
FROM delivered_orders d
JOIN order_value v ON d.order_id = v.order_id
GROUP BY d.customer_unique_id;