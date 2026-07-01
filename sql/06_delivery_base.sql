-- sql/06_delivery_base.sql
-- Base table: one row per delivered order with all delivery timing fields.
-- Excludes orders where delivery timing can't be computed.

CREATE OR REPLACE TABLE delivery_base AS
SELECT
    o.order_id,
    c.customer_unique_id,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    r.review_score,

    -- Total time from purchase to customer receipt
    DATE_DIFF('day', o.order_purchase_timestamp, o.order_delivered_customer_date) AS actual_delivery_days,

    -- Time promised at checkout
    DATE_DIFF('day', o.order_purchase_timestamp, o.order_estimated_delivery_date) AS promised_delivery_days,

    -- The key metric: was it late vs the promise? Negative = early, 0 = on time, positive = late
    DATE_DIFF('day', o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delay_vs_promise,

    -- Sub-legs (for Q2.3 later)
    DATE_DIFF('day', o.order_purchase_timestamp, o.order_delivered_carrier_date) AS seller_to_carrier_days,
    DATE_DIFF('day', o.order_delivered_carrier_date, o.order_delivered_customer_date) AS carrier_to_customer_days

FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL;