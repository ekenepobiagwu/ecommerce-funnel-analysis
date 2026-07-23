-- 04_significance_tests.sql
-- Two-proportion z-test comparing desktop vs. mobile at each
-- back-half funnel transition. Tablet excluded -- sample too thin to test.
-- Result: all three transitions are statistically significant at 95% confidence,
-- and the gaps are also large in practical terms (10-20 percentage points).

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
    SELECT session_id, MAX(CAST(action_type AS INT64)) AS max_stage
    FROM session_hits
    GROUP BY session_id
  ),

joined AS (
    SELECT d.device_category, s.max_stage
    FROM session_device d
    JOIN session_max_stage s USING (session_id)
    WHERE d.device_category IN ('desktop', 'mobile')
  ),

stage_counts AS (
    SELECT
      device_category,
      COUNTIF(max_stage >= 2) AS reached_product_detail,
      COUNTIF(max_stage >= 3) AS reached_add_to_cart,
      COUNTIF(max_stage >= 5) AS reached_checkout,
      COUNTIF(max_stage >= 6) AS reached_purchase
    FROM joined
    GROUP BY device_category
  ),

pivoted AS (
    SELECT
      MAX(IF(device_category = 'desktop', reached_product_detail, NULL)) AS d_product_detail,
      MAX(IF(device_category = 'desktop', reached_add_to_cart, NULL)) AS d_add_to_cart,
      MAX(IF(device_category = 'desktop', reached_checkout, NULL)) AS d_checkout,
      MAX(IF(device_category = 'desktop', reached_purchase, NULL)) AS d_purchase,
      MAX(IF(device_category = 'mobile', reached_product_detail, NULL)) AS m_product_detail,
      MAX(IF(device_category = 'mobile', reached_add_to_cart, NULL)) AS m_add_to_cart,
      MAX(IF(device_category = 'mobile', reached_checkout, NULL)) AS m_checkout,
      MAX(IF(device_category = 'mobile', reached_purchase, NULL)) AS m_purchase
    FROM stage_counts
  ),

transitions AS (
    SELECT 'product_detail_to_add_to_cart' AS transition,
      d_add_to_cart AS x1, d_product_detail AS n1,
      m_add_to_cart AS x2, m_product_detail AS n2
    FROM pivoted

    UNION ALL

  SELECT 'add_to_cart_to_checkout',
      d_checkout, d_add_to_cart,
      m_checkout, m_add_to_cart
    FROM pivoted

    UNION ALL

  SELECT 'checkout_to_purchase',
      d_purchase, d_checkout,
      m_purchase, m_checkout
    FROM pivoted
  )

SELECT
  transition,
  ROUND(x1 / n1, 4) AS desktop_rate,
  ROUND(x2 / n2, 4) AS mobile_rate,
  ROUND(
      ((x1 / n1) - (x2 / n2)) /
      SQRT(
        ((x1 + x2) / (n1 + n2)) * (1 - ((x1 + x2) / (n1 + n2))) * ((1.0 / n1) + (1.0 / n2))
      ), 2
    ) AS z_score,
  CASE
    WHEN ABS(
        ((x1 / n1) - (x2 / n2)) /
        SQRT(
          ((x1 + x2) / (n1 + n2)) * (1 - ((x1 + x2) / (n1 + n2))) * ((1.0 / n1) + (1.0 / n2))
        )
      ) > 1.96 THEN 'significant (95%)'
    ELSE 'not significant'
  END AS result
FROM transitions
