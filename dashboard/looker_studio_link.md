# Dashboard

Live Looker Studio dashboard: https://datastudio.google.com/reporting/1f408587-3ceb-4543-a6d5-4d67bbde8956

## What's in it

1. **Funnel by device (session counts)** -- a bar chart showing all five
2.    funnel stages (viewed, product_detail, add_to_cart, checkout, purchase),
3.   broken out by device category (desktop, mobile, tablet), sorted in
4.      correct funnel order via `stage_order`.

5.  2. **Purchase conversion rate by device** -- a bar chart isolating just the
    3.    purchase stage, showing `pct_of_total` per device. This is the headline
    4.   chart: desktop converts at roughly 5x the rate of mobile and tablet.
  
    5.   ## Data source
  
    6.   Both charts are built on a single BigQuery custom SQL connection, using
    7.   the same funnel and segmentation logic as `sql/03_segment_breakdowns.sql`.
    8.   
