# E-commerce Funnel & Drop-off Analysis

Where do e-commerce sessions actually break down? A funnel analysis of
~74,000 real Google Merchandise Store sessions, segmented by device and
tested for statistical significance.

## The question

Where do users drop off between landing, viewing a product, adding to
cart, checking out, and purchasing -- and does that differ meaningfully
by device? A secondary question going in: is there a segment that looks
fine in the aggregate numbers but is quietly broken underneath?

## Headline finding

**83.8% of sessions never view a specific product** -- by far the
single biggest leak in the funnel, well ahead of any cart or checkout
drop-off.

**Once a session does engage with a product, mobile users convert to
purchase at roughly 1/5th the rate of desktop users** (0.39% vs. 2.05%).
This isn't one broken step -- it's a compounding ~10-20 point gap at
*every* remaining stage (product detail to cart, cart to checkout,
checkout to purchase), all confirmed statistically significant
(two-proportion z-test, p < .05, z-scores of 7-12). The consistency
across stages points to a broader mobile experience issue rather than a
single fixable bug.

## Dashboard

[View the interactive Looker Studio dashboard](https://datastudio.google.com/reporting/1f408587-3ceb-4543-a6d5-4d67bbde8956)
-- funnel breakdown by device, plus the purchase-rate comparison chart.

## Repo structure

```
sql/        Four SQL files, in analysis order:
            01_session_events.sql      session-level grain + dedup
            02_funnel_stages.sql       funnel stage tagging + conversion
            03_segment_breakdowns.sql  device-level segmentation
            04_significance_tests.sql  two-proportion z-tests

docs/       Full methodology write-up, including funnel-stage
            definitions, assumptions, and limitations

dashboard/  Link to the live Looker Studio dashboard
```

## Tools

SQL (BigQuery), two-proportion z-test for statistical validation,
Looker Studio for visualization.

## Key methodology decisions

- **Funnel defined as viewed -> product detail -> add to cart ->
-   checkout -> purchase.** Product-list clicks and cart removals were
-     excluded as non-funnel signals (see `docs/methodology.md` for the
-   reasoning).
-   - **Each session tagged by the furthest stage it reached**, so no
    -   session is double-counted across stages.
    -   - **Tablet was excluded from significance testing** -- its sample size
        -   (3,192 sessions, 13 purchases) was judged too thin to test reliably.
     
        -   ## Limitations
     
        -   This is one month of data from one specific site, and device category
        -   is a proxy for *where* the mobile gap shows up, not a direct measurement
        -   of *why* it exists. Full limitations are documented in
        -   [`docs/methodology.md`](docs/methodology.md).
        -   
