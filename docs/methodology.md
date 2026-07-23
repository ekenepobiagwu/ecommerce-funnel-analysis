# Methodology

## Question

Where do users actually drop off between landing, viewing a product,
adding to cart, checking out, and purchasing -- and does that differ
meaningfully by device? A secondary question going in was whether some
segment might look fine in the aggregate numbers while being quietly
broken underneath.

## Data source

`bigquery-public-data.google_analytics_sample` -- real (anonymized)
session-level GA360 event data from the Google Merchandise Store. This
is the older Universal Analytics export schema (nested `hits` and
`totals` fields), not the GA4 event schema.

Data window: July 1 - August 1, 2017, pulled via a wildcard query across
the daily `ga_sessions_YYYYMMDD` tables. A single day's table (~2,500
sessions) was judged too small a sample to segment reliably, so the
window was widened to a full month (~74,000 sessions) before any
segmentation or significance testing was attempted.

## Defining a session

A session is the combination of `fullVisitorId` and `visitId` -- neither
field alone is a unique identifier, since one visitor can have many
visits, and visitIds are not guaranteed unique across visitors. Sessions
were deduplicated (`QUALIFY ROW_NUMBER() ... = 1`) before analysis.
Verified zero duplicate `session_id` values remained after dedup.

## Defining the funnel

Google's `eCommerceAction.action_type` field encodes what happened on
each hit within a session:

| Code | Meaning |
|---|---|
| 0 | No ecommerce action (browsing) |
| 1 | Product list click-through |
| 2 | Product detail view |
| 3 | Add to cart |
| 4 | Remove from cart |
| 5 | Checkout |
| 6 | Completed purchase |

The funnel used for this analysis is **0 -> 2 -> 3 -> 5 -> 6**
(viewed -> product detail -> add to cart -> checkout -> purchase).

Two codes were deliberately excluded from the funnel:

- **Code 1 (product list click)** -- a minor browsing action, not a
-   meaningful forward-progress milestone.
-   - **Code 4 (remove from cart)** -- represents a user backing out of an
    -   earlier action, not progressing toward a purchase. It remains in the
    -     underlying data and could be analyzed separately as a cart-hesitation
    -   signal, but is not treated as a funnel stage.
 
    -   Each session was tagged with the **furthest** stage it reached (via
    -   `MAX(action_type)` per session), so every session falls into exactly one
    -   mutually exclusive bucket rather than being counted across multiple
    -   stages.
 
    -   This funnel assumes stage codes are strictly ordered (0 < 2 < 3 < 5 < 6)
    -   and that reaching a higher code implies having passed through the lower
    -   ones. That's a reasonable assumption given how Google designed these
    -   codes, but it is an assumption, not a verified fact about every
    -   individual session's click path.
 
    -   ## Overall funnel results
 
    -   | Stage | Sessions reached | % of total | % of previous stage |
    -   |---|---|---|---|
    -   | Viewed | 74,261 | 100% | -- |
    -   | Product detail | 12,062 | 16.2% | 16.2% |
    -   | Add to cart | 5,147 | 6.9% | 42.7% |
    -   | Checkout | 2,163 | 2.9% | 42.0% |
    -   | Purchase | 1,074 | 1.4% | 49.7% |
 
    -   **Finding:** the single largest drop-off, by a wide margin, is
    -   viewed -> product detail (83.8% of sessions never engage with a specific
    -   product). By contrast, the back half of the funnel -- once someone views
    -   a product -- converts at a fairly healthy 42-50% at each remaining step.
 
    -   ## Segmentation by device
 
    -   Sessions were split by `device.deviceCategory` (desktop, mobile,
    -   tablet) and run through the same funnel logic.
 
    -   | Device | Sessions | Purchase rate |
    -   |---|---|---|
    -   | Desktop | 47,264 | 2.05% |
    -   | Mobile | 23,805 | 0.39% |
    -   | Tablet | 3,192 | 0.41% |
 
    -   Desktop converts to purchase at roughly **5x** the rate of mobile.
    -   Breaking down each individual transition showed this isn't one broken
    -   step -- it's a compounding pattern across the entire back half of the
    -   funnel:
 
    -   | Transition | Desktop | Mobile |
    -   |---|---|---|
    -   | Product detail -> add to cart | 46.1% | 34.0% |
    -   | Add to cart -> checkout | 45.8% | 29.6% |
    -   | Checkout -> purchase | 53.1% | 30.8% |
 
    -   **Finding:** mobile sessions underperform desktop by roughly 10-20
    -   percentage points at *every* stage past product discovery, rather than
    -   failing at one identifiable point. Because these gaps compound
    -   multiplicatively across three steps, they produce the ~5x overall gap
    -   in final purchase rate. This points toward a broader mobile experience
    -   issue (page speed, form usability, payment friction) rather than a
    -   single fixable bug.
 
    -   **Tablet caveat:** tablet's sample size is small relative to desktop and
    -   mobile (3,192 sessions, only 36 reaching checkout and 13 reaching
    -   purchase). Its rates are shown for completeness but were not put through
    -   significance testing, and shouldn't be read with the same confidence as
    -   the desktop/mobile comparison.
 
    -   ## Statistical testing
 
    -   Two-proportion z-tests were run comparing desktop vs. mobile at each of
    -   the three back-half transitions, to confirm the observed gaps weren't
    -   sampling noise.
 
    -   | Transition | Desktop rate | Mobile rate | z-score | Result |
    -   |---|---|---|---|---|
    -   | Product detail -> add to cart | 46.1% | 34.0% | 11.63 | Significant (95%) |
    -   | Add to cart -> checkout | 45.8% | 29.6% | 9.35 | Significant (95%) |
    -   | Checkout -> purchase | 53.1% | 30.8% | 7.19 | Significant (95%) |
 
    -   All three transitions are statistically significant well beyond the
    -   conventional 95% threshold (z > 1.96).
 
    -   **A note on statistical vs. practical significance:** with sample sizes
    -   in the thousands, even a modest true difference would likely register
    -   as statistically significant -- significance alone doesn't imply a gap
    -   is *large* or *important*. In this case, the gaps are also large in
    -   absolute terms (10-20 percentage points, compounding to a 5x difference
    -   in final purchase rate), so the statistical and practical stories agree.
    -   That agreement is worth stating explicitly rather than assumed.
 
    -   ## Limitations
 
    -   - This is a single month of data (July 2017) from one specific
        -   ecommerce site (Google Merchandise Store); patterns may not generalize
        -     to other retailers, seasons, or years.
        - - Tablet's small sample size limits how confidently its numbers can be
          -   interpreted.
          -   - The funnel treats each session's *furthest* reached stage as the
              -   metric of interest; it does not account for users who purchase across
              -     multiple sessions, or re-engage after abandoning a cart in an earlier
              -   visit.
              -   - Device category is a proxy for user experience differences, not a
                  -   direct measurement of *why* mobile underperforms (e.g., page load
                  -     time, screen size, form design). This analysis identifies *where* the
                  -   gap is, not definitively *why* it exists.
                  -   
