-- 1. Time range of the data
SELECT 
    MIN(order_purchase_timestamp) AS earliest,
    MAX(order_purchase_timestamp) AS latest,
    COUNT(*) AS total_orders
FROM orders;

-- 2. Order status distribution — what fraction are actually delivered?
SELECT 
    order_status, 
    COUNT(*) AS n,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM orders
GROUP BY order_status
ORDER BY n DESC;

-- 3. Null check on key delivery columns
SELECT
    COUNT(*) AS total,
    COUNT(order_delivered_customer_date) AS has_delivery_date,
    COUNT(order_estimated_delivery_date) AS has_estimate,
    COUNT(*) - COUNT(order_delivered_customer_date) AS missing_delivery
FROM orders;

-- 4. Reviews coverage — what % of orders have reviews?
SELECT
    (SELECT COUNT(DISTINCT order_id) FROM order_reviews) * 100.0 
    / (SELECT COUNT(*) FROM orders) AS pct_orders_with_review;

-- 5. Review score distribution
SELECT review_score, COUNT(*) AS n
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- 6. Repeat customer share (preview of Q1 territory)
WITH order_counts AS (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS n_orders
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT 
    n_orders,
    COUNT(*) AS n_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM order_counts
GROUP BY n_orders
ORDER BY n_orders;

-- 7. Geographic spread
SELECT customer_state, COUNT(DISTINCT customer_unique_id) AS customers
FROM customers
GROUP BY customer_state
ORDER BY customers DESC
LIMIT 10;

-- 8. Category coverage
SELECT COUNT(DISTINCT product_category_name) AS categories FROM products;