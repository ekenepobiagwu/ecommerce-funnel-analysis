-- 03_segment_breakdowns.sql
-- Breaks the same funnel logic down by device category, showing
-- stage-over-stage conversion within each device rather than in aggregate.

WITH session_device AS (
    SELECT
      CONCAT(fullVisitorId, CAST(visitId AS STRING)) AS session_id,
      device.deviceCategory AS device_category
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY fullVisitorId, visitId ORDER BY visitStartTime) = 1
  ),

session_hits AS (
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

joined AS (
    SELECT
      d.device_category,
      s.max_stage
    FROM session_device d
    JOIN session_max_stage s USING (session_id)
  ),

device_funnel AS (
    SELECT device_category, 'viewed' AS funnel_stage, 0 AS stage_order,
      COUNTIF(max_stage >= 0) AS sessions_reached
    FROM joined GROUP BY device_category

    UNION ALL

  SELECT device_category, 'product_detail', 1,
      COUNTIF(max_stage >= 2)
    FROM joined GROUP BY device_category

    UNION ALL

  SELECT device_category, 'add_to_cart', 2,
      COUNTIF(max_stage >= 3)
    FROM joined GROUP BY device_category

    UNION ALL

  SELECT device_category, 'checkout', 3,
      COUNTIF(max_stage >= 5)
    FROM joined GROUP BY device_category

    UNION ALL

  SELECT device_category, 'purchase', 4,
      COUNTIF(max_stage >= 6)
    FROM joined GROUP BY device_category
  )

SELECT
  device_category,
  funnel_stage,
  sessions_reached,
  ROUND(sessions_reached / FIRST_VALUE(sessions_reached) OVER (
      PARTITION BY device_category ORDER BY stage_order
    ), 4) AS pct_of_total,
  ROUND(sessions_reached / LAG(sessions_reached) OVER (
      PARTITION BY device_category ORDER BY stage_order
    ), 4) AS pct_of_previous_stage
FROM device_funnel
ORDER BY device_category, stage_order
