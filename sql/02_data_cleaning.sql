-- 02_data_cleaning.sql
-- Purpose: Build a clean, analysis-ready table from listings_raw (Step 4: Data Cleaning).
-- listings_raw is NEVER modified -- this creates a new derived table so every cleaning
-- decision stays auditable and reversible (we can always regenerate this from the
-- untouched original if a decision needs revisiting).

-- Decision: exclude listings with a NULL price.
-- Rationale: a listing with no price is treated as not currently active/bookable. Our
-- business questions are about pricing and demand in the CURRENT market, so including
-- non-priced listings would let inactive properties skew average price and demand
-- metrics for segments that are actually live. This excludes 9,903 of 30,234 rows (32.8%).
-- Documented limitation: some genuinely paused-but-real listings may be excluded by this
-- rule, but the alternative (including them) does more damage to the analysis.

-- Decision: exclude listings with minimum_nights >= 30.
-- Rationale: our business scope (Step 1) is the short-term rental market -- a property
-- management company providing Airbnb management services (dynamic pricing, guest
-- turnover, calendar management) has no reason to manage a listing that requires a
-- 30+ night minimum stay, since there is no real guest turnover to manage on one.
-- Discovery in the Python layer (python/eda_analysis.ipynb) found that 74% of listings
-- (15,048 of 20,331 remaining after the price filter) have minimum_nights >= 30, with a
-- markedly lower median price ($145) than genuine short-term listings ($275). This
-- reflects a real market condition, not a data error: NYC's Local Law 18 (2023) heavily
-- restricts short-term rentals (under 30 nights), and a well-documented host response has
-- been shifting listings to 30+ night minimums to operate outside that law while staying
-- on the platform. Excluding them focuses the analysis on the actual short-term market
-- our stakeholder operates in.

-- Decision: license column dropped entirely -- 83% NULL, not used in any business question.

-- Decision: TRIM() applied to all text columns to remove stray leading/trailing whitespace
-- that CSV exports commonly introduce -- this whitespace is invisible but breaks GROUP BY
-- (e.g. "Manhattan" vs "Manhattan " would otherwise count as two different groups).

DROP TABLE IF EXISTS listings_clean;

CREATE TABLE listings_clean AS
SELECT
    id,
    TRIM(name)                 AS name,
    host_id,
    host_profile_id,
    TRIM(host_name)            AS host_name,
    TRIM(neighbourhood_group)  AS neighbourhood_group,
    TRIM(neighbourhood)        AS neighbourhood,
    latitude,
    longitude,
    TRIM(room_type)            AS room_type,
    price,
    minimum_nights,
    number_of_reviews,
    last_review,
    reviews_per_month,
    calculated_host_listings_count,
    availability_365,
    number_of_reviews_ltm
FROM listings_raw
WHERE price IS NOT NULL
  AND minimum_nights < 30;
