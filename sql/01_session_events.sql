-- 01_session_events.sql
-- Defines the session-level grain: one row per unique session,
-- deduplicated, with device/channel/geo attributes attached.

SELECT
  CONCAT(fullVisitorId, CAST(visitId AS STRING)) AS session_id,
  fullVisitorId,
  visitId,
  PARSE_DATE('%Y%m%d', date) AS session_date,
  device.deviceCategory AS device_category,
  trafficSource.medium AS channel_medium,
  trafficSource.source AS channel_source,
  geoNetwork.country AS country,
  totals.hits AS total_hits,
  totals.pageviews AS total_pageviews,
  totals.transactions AS total_transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY fullVisitorId, visitId ORDER BY visitStartTime
  ) = 1
