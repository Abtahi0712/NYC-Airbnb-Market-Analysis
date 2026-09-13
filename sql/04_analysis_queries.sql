-- 04_analysis_queries.sql
-- Purpose: Queries that directly answer the business questions defined in
-- Step 2, using the cleaned data.
-- Filled in during Step 6 (Analyze and Answer).

-- ============================================================
-- Question 1: Which neighborhood x room-type segment has the
-- highest price?
-- ============================================================
-- We use median (not mean) per segment -- decided back in Step 4 -- because
-- price has legitimate high-end outliers (luxury listings) that would pull
-- a mean upward and misrepresent the "typical" listing in a segment.
--
-- Step 1 (the CTE, segment_price): compute the median price and listing
-- count for every neighbourhood_group x room_type combination. This is
-- just GROUP BY -- nothing new here.
--
-- Step 2 (the outer SELECT): rank those segments using a window function.
-- RANK() OVER (PARTITION BY neighbourhood_group ORDER BY median_price DESC)
-- resets the ranking separately for each borough, so "rank 1" means
-- "highest median price room type, within this specific borough" -- not
-- highest across all 25 segments combined. That's the more useful business
-- answer: a property manager operating in Queens cares which room type is
-- the top performer IN Queens, not that it happens to be cheaper than the
-- cheapest Manhattan segment.
--
-- Result: Entire home/apt is rank 1 in every borough except Manhattan,
-- where Hotel room ($470 median, but only 303 listings -- a thinner sample
-- worth flagging) narrowly beats Entire home/apt ($388.5, 912 listings).

WITH segment_price AS (
    SELECT
        neighbourhood_group,
        room_type,
        COUNT(*) AS listing_count,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price
    FROM listings_clean
    GROUP BY neighbourhood_group, room_type
)
SELECT
    neighbourhood_group,
    room_type,
    listing_count,
    median_price,
    RANK() OVER (PARTITION BY neighbourhood_group ORDER BY median_price DESC) AS price_rank_in_borough
FROM segment_price
ORDER BY neighbourhood_group, price_rank_in_borough;


-- ============================================================
-- Question 2: Which segments show the strongest demand?
-- ============================================================
-- Airbnb's public data has no real booking count, so reviews_per_month is
-- used as a documented proxy for demand: a guest can only leave a review
-- after a completed stay, so more reviews per month roughly tracks more
-- guest turnover. This is a limitation, not a hidden assumption -- it goes
-- into the final write-up as-is.
--
-- Data decision: 727 listings have reviews_per_month = NULL (never
-- received a single review). We do NOT exclude them -- a listing with zero
-- reviews IS a demand signal, the lowest possible one, and excluding it
-- would erase exactly the weak-performing segments Question 4 needs to
-- find later. COALESCE(reviews_per_month, 0) treats every NULL as 0.
--
-- Step 1 (the CTE, segment_demand): average monthly-review-demand per
-- segment, same GROUP BY pattern as Question 1.
--
-- Step 2 (the outer SELECT) uses TWO window functions on the same data:
--   - RANK() OVER (PARTITION BY neighbourhood_group ORDER BY ... DESC)
--     -- same ranking pattern as Question 1.
--   - SUM(avg_monthly_reviews) OVER (PARTITION BY neighbourhood_group)
--     -- an AGGREGATE function used as a window function. It computes the
--     total demand for the whole borough, but (unlike GROUP BY) attaches
--     that borough-wide total to every row in the borough instead of
--     collapsing to one row. That lets us divide each segment's own
--     demand by its borough's total to get "% of borough demand" --
--     a more useful number than rank alone, since rank 1 could still be
--     a tiny sliver of a borough's total demand.
--
-- Result: Hotel room is dead last for demand in every borough it appears
-- in (0.00-0.34 avg monthly reviews). "Shared room" shows up as rank 1 in
-- Manhattan and Queens, but on only 7 and 8 listings respectively -- too
-- thin a sample to trust. Most importantly: Manhattan's Hotel room was
-- rank 1 for PRICE in Question 1, but is rank 4 (last) for demand here --
-- highest price, lowest turnover. That contradiction is explored properly
-- below.

WITH segment_demand AS (
    SELECT
        neighbourhood_group,
        room_type,
        COUNT(*) AS listing_count,
        AVG(COALESCE(reviews_per_month, 0)) AS avg_monthly_reviews
    FROM listings_clean
    GROUP BY neighbourhood_group, room_type
)
SELECT
    neighbourhood_group,
    room_type,
    listing_count,
    ROUND(avg_monthly_reviews, 2) AS avg_monthly_reviews,
    RANK() OVER (PARTITION BY neighbourhood_group ORDER BY avg_monthly_reviews DESC) AS demand_rank_in_borough,
    ROUND(
        100.0 * avg_monthly_reviews
        / SUM(avg_monthly_reviews) OVER (PARTITION BY neighbourhood_group),
        1
    ) AS pct_of_borough_demand
FROM segment_demand
ORDER BY neighbourhood_group, demand_rank_in_borough;


-- ============================================================
-- Combining Question 1 + Question 2: which segment is best on
-- BOTH price and demand, per borough? (feeds into Question 5,
-- price vs. demand relationship)
-- ============================================================
-- segment_price and segment_demand are the same two CTEs as above, each
-- with one row per neighbourhood_group x room_type segment. Neither one
-- alone has both price AND demand together -- a JOIN combines them.
--
-- The JOIN condition matches on BOTH neighbourhood_group AND room_type,
-- because a single segment is identified by that pair together, not
-- either column alone -- matching on only one would incorrectly pair,
-- e.g., Manhattan's price with Brooklyn's demand.
--
-- segment_ranks (the third CTE) computes price_rank and demand_rank for
-- each segment using the same RANK()-per-borough pattern as before, now
-- computed on the joined data.
--
-- The final SELECT adds a combined_score (price_rank + demand_rank --
-- lower is better on both) and a window function that ranks segments by
-- that combined score within each borough. Caution: as with Questions 1
-- and 2, always check listing_count before trusting a combined result --
-- a segment can look good on paper with very few listings behind it.

WITH segment_price AS (
    SELECT
        neighbourhood_group,
        room_type,
        COUNT(*) AS listing_count,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price
    FROM listings_clean
    GROUP BY neighbourhood_group, room_type
),
segment_demand AS (
    SELECT
        neighbourhood_group,
        room_type,
        AVG(COALESCE(reviews_per_month, 0)) AS avg_monthly_reviews
    FROM listings_clean
    GROUP BY neighbourhood_group, room_type
),
segment_ranks AS (
    SELECT
        p.neighbourhood_group,
        p.room_type,
        p.listing_count,
        p.median_price,
        d.avg_monthly_reviews,
        RANK() OVER (PARTITION BY p.neighbourhood_group ORDER BY p.median_price DESC) AS price_rank,
        RANK() OVER (PARTITION BY p.neighbourhood_group ORDER BY d.avg_monthly_reviews DESC) AS demand_rank
    FROM segment_price p
    JOIN segment_demand d
      ON p.neighbourhood_group = d.neighbourhood_group
     AND p.room_type = d.room_type
)
SELECT
    neighbourhood_group,
    room_type,
    listing_count,
    median_price,
    ROUND(avg_monthly_reviews, 2) AS avg_monthly_reviews,
    price_rank,
    demand_rank,
    (price_rank + demand_rank) AS combined_score,
    RANK() OVER (PARTITION BY neighbourhood_group ORDER BY (price_rank + demand_rank) ASC) AS overall_rank_in_borough
FROM segment_ranks
ORDER BY neighbourhood_group, overall_rank_in_borough;


-- ============================================================
-- Question 3: Market saturation by segment
-- ============================================================
-- calculated_host_listings_count tells us, per listing, how many total
-- listings that listing's host manages. A segment dominated by hosts with
-- high portfolio counts is "saturated" by professional, multi-property
-- operators -- more competitive, likely more sophisticated pricing already
-- in place. A segment where most hosts only have this one listing is
-- fragmented -- individual hosts, less professionalized, more room for a
-- new entrant to compete.
--
-- Two saturation metrics per segment:
--   - avg_host_portfolio_size: mean calculated_host_listings_count.
--   - pct_multi_listing_hosts: % of listings whose host has more than one
--     listing, using COUNT(*) FILTER (WHERE ...) -- the same conditional
--     aggregate pattern from earlier in this project. This catches cases
--     where the average alone could be skewed by one very large operator.
--
-- New window function: DENSE_RANK() instead of RANK(). The difference:
-- if two segments tie for rank 1, RANK() assigns both "1" then skips to
-- "3" for the next segment (no "2"). DENSE_RANK() assigns both "1" and
-- gives the next segment "2" -- no gap. We want DENSE_RANK() here because
-- we care about how many DISTINCT saturation levels exist above a
-- segment, not how many individual rows are tied at the top.

WITH segment_saturation AS (
    SELECT
        neighbourhood_group,
        room_type,
        COUNT(*) AS listing_count,
        ROUND(AVG(calculated_host_listings_count), 2) AS avg_host_portfolio_size,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE calculated_host_listings_count > 1)
            / COUNT(*),
            1
        ) AS pct_multi_listing_hosts
    FROM listings_clean
    GROUP BY neighbourhood_group, room_type
)
SELECT
    neighbourhood_group,
    room_type,
    listing_count,
    avg_host_portfolio_size,
    pct_multi_listing_hosts,
    DENSE_RANK() OVER (
        PARTITION BY neighbourhood_group
        ORDER BY avg_host_portfolio_size DESC
    ) AS saturation_rank_in_borough
FROM segment_saturation
ORDER BY neighbourhood_group, saturation_rank_in_borough;


-- ============================================================
-- Question 4: Weak-performing segments
-- ============================================================
-- availability_365 = days out of the next 365 a listing is still bookable.
-- Counter-intuitively, HIGH availability is a bad sign here -- it means the
-- listing is rarely booked, so most days remain open. Combined with LOW
-- reviews_per_month (our demand proxy from Question 2), that identifies
-- segments that are listed but barely used by guests.
--
-- Deliberate design choice: unlike Questions 1-3, there is NO
-- PARTITION BY here. We want to know which segments are weak across the
-- WHOLE city, not just weak relative to their own borough's other room
-- types -- a segment could look mediocre-but-fine next to its borough
-- peers while still being one of the worst-performing segments overall.
--
-- New window function: NTILE(4) sorts all 20 segments by a chosen order
-- and splits them into 4 roughly equal-sized buckets (quartiles),
-- labeling each row 1-4. Bucket 1 = the worst quartile for whatever we
-- ordered by. This gives a business-friendly category ("worst 25%")
-- instead of a precise, less useful single rank position.
--
-- Same alias lesson as before: availability_quartile and demand_quartile
-- are computed in segment_quartiles, then referenced by name in the final
-- CASE WHEN -- exactly like combined_score needed its own CTE stage
-- earlier, because a SELECT list can't reference its own aliases.
--
-- Result: 4 segments flagged 'Weak-performing' -- Bronx/Brooklyn/Manhattan
-- Hotel room, and Staten Island Shared room. Brooklyn (39 listings) and
-- Manhattan (303 listings) are credible findings; Bronx (4) and Staten
-- Island Shared room (2) are too small to trust as a real pattern. This
-- closes the loop across all four questions: Hotel room is highest-priced
-- (Q1), lowest-demand (Q2), fully saturated by professional operators
-- (Q3), and now confirmed weak-performing (Q4) -- four independent
-- analyses agreeing on the same conclusion.

WITH segment_performance AS (
    SELECT
        neighbourhood_group,
        room_type,
        COUNT(*) AS listing_count,
        ROUND(AVG(availability_365), 1) AS avg_availability,
        ROUND(AVG(COALESCE(reviews_per_month, 0)), 2) AS avg_monthly_reviews
    FROM listings_clean
    GROUP BY neighbourhood_group, room_type
),
segment_quartiles AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY avg_availability DESC) AS availability_quartile,
        NTILE(4) OVER (ORDER BY avg_monthly_reviews ASC) AS demand_quartile
    FROM segment_performance
)
SELECT
    neighbourhood_group,
    room_type,
    listing_count,
    avg_availability,
    avg_monthly_reviews,
    availability_quartile,
    demand_quartile,
    CASE
        WHEN availability_quartile = 1 AND demand_quartile = 1
            THEN 'Weak-performing'
        ELSE 'OK'
    END AS performance_flag
FROM segment_quartiles
ORDER BY availability_quartile, demand_quartile, neighbourhood_group;


-- ============================================================
-- Question 5: Price vs. demand relationship within segments
-- ============================================================
-- CORR(y, x) is a standard aggregate function (same family as COUNT/AVG/
-- SUM) that measures how strongly two numeric columns move together,
-- returning one number from -1 to +1:
--   close to +1  -- higher price segments also tend to have higher demand
--   close to -1  -- higher price segments tend to have LOWER demand
--   close to 0   -- no real relationship either way
--
-- This is a plain aggregate, not a window function -- we want exactly ONE
-- number summarizing the whole dataset, so no PARTITION BY, no OVER(...),
-- and no GROUP BY (we want it across all 20 segments at once, not per
-- borough). segment_price and segment_demand are joined exactly as in the
-- combined Q1+Q2 analysis above.
--
-- CORR() returns a double precision value that Postgres's ROUND() cannot
-- round directly -- the ::NUMERIC cast converts it to a type ROUND() can
-- work with.

WITH segment_price AS (
    SELECT
        neighbourhood_group,
        room_type,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price
    FROM listings_clean
    GROUP BY neighbourhood_group, room_type
),
segment_demand AS (
    SELECT
        neighbourhood_group,
        room_type,
        AVG(COALESCE(reviews_per_month, 0)) AS avg_monthly_reviews
    FROM listings_clean
    GROUP BY neighbourhood_group, room_type
)
SELECT
    ROUND(
        CORR(d.avg_monthly_reviews, p.median_price)::NUMERIC,
        3
    ) AS price_demand_correlation
FROM segment_price p
JOIN segment_demand d
  ON p.neighbourhood_group = d.neighbourhood_group
 AND p.room_type = d.room_type;
