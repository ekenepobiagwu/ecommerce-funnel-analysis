-- 02_funnel_stages.sql
-- Tags each session with the furthest funnel stage it reached, then
-- calculates cumulative reach and stage-over-stage conversion rates.
-- Funnel stages: 0 viewed, 2 product_detail, 3 add_to_cart, 5 checkout, 6 purchase.
-- action_type 1 (list click) and 4 (remove from cart) are excluded as non-funnel signals.

WITH session_hits AS (
  SELECT
    CONCAT(fullVisitorId, CAST(visitId AS STRING)) AS session_id,
    h.eCommerceAction.action_type AS action_type
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'
    AND h.eCommerceAction.action_type IN ('0', '2', '3', '5', '6')
),

session_max_stage AS (
  SELECT
    session_id,
    MAX(CAST(action_type AS INT64)) AS max_stage
  FROM session_hits
  GROUP BY session_id
),

cumulative_funnel AS (
  SELECT
    'viewed' AS funnel_stage, 0 AS stage_order,
    COUNT(*) AS sessions_reached
  FROM session_max_stage WHERE max_stage >= 0

  UNION ALL

  SELECT 'product_detail', 1, COUNT(*)
  FROM session_max_stage WHERE max_stage >= 2

  UNION ALL

  SELECT 'add_to_cart', 2, COUNT(*)
  FROM session_max_stage WHERE max_stage >= 3

  UNION ALL

  SELECT 'checkout', 3, COUNT(*)
  FROM session_max_stage WHERE max_stage >= 5

  UNION ALL

  SELECT 'purchase', 4, COUNT(*)
  FROM session_max_stage WHERE max_stage >= 6
)

SELECT
  funnel_stage,
  sessions_reached,
  ROUND(sessions_reached / FIRST_VALUE(sessions_reached) OVER (ORDER BY stage_order), 4) AS pct_of_total,
  ROUND(sessions_reached / LAG(sessions_reached) OVER (ORDER BY stage_order), 4) AS pct_of_previous_stage
FROM cumulative_funnel
ORDER BY stage_order
