-- sql/04_rfm_scores.sql
-- Assign 1-5 quintile scores for R, F, M and map to named segments.
-- Repeat customers get full RFM. Single-purchase customers get R+M only.

CREATE OR REPLACE TABLE rfm_scored AS
WITH repeat_scored AS (
    SELECT
        customer_unique_id,
        purchase_type,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency)         AS f_score,
        NTILE(5) OVER (ORDER BY monetary)          AS m_score
    FROM rfm_base
    WHERE purchase_type = 'repeat'
),
single_scored AS (
    SELECT
        customer_unique_id,
        purchase_type,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NULL::INTEGER                              AS f_score,
        NTILE(5) OVER (ORDER BY monetary)          AS m_score
    FROM rfm_base
    WHERE purchase_type = 'single'
),
all_scored AS (
    SELECT * FROM repeat_scored
    UNION ALL
    SELECT * FROM single_scored
)
SELECT
    *,
    CASE
        -- Repeat customer segments (use full RFM)
        WHEN purchase_type = 'repeat' AND r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN purchase_type = 'repeat' AND r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
        WHEN purchase_type = 'repeat' AND r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
        WHEN purchase_type = 'repeat' AND r_score <= 2 AND m_score >= 4                  THEN 'Cant Lose Them'
        WHEN purchase_type = 'repeat' AND r_score <= 2                                   THEN 'Hibernating'
        WHEN purchase_type = 'repeat'                                                    THEN 'Needs Attention'

        -- Single-purchase segments (R + M only)
        WHEN purchase_type = 'single' AND r_score >= 4 AND m_score >= 4 THEN 'New High-Value'
        WHEN purchase_type = 'single' AND r_score >= 4                  THEN 'Recent One-Timer'
        WHEN purchase_type = 'single' AND r_score <= 2 AND m_score >= 4 THEN 'Lost High-Value'
        WHEN purchase_type = 'single' AND r_score <= 2                  THEN 'Lost'
        ELSE 'Dormant One-Timer'
    END AS segment
FROM all_scored;