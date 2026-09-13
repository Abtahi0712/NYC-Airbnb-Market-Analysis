-- 03_eda_queries.sql
-- Purpose: Explore the cleaned data in numbers (Step 5: EDA -- SQL layer).
-- We are NOT answering the business questions yet (that's Step 6) -- just getting
-- familiar with how listings_clean actually looks: counts, distributions, typical values.

-- How many listings per borough (neighbourhood_group)?
SELECT
    neighbourhood_group,
    COUNT(*) AS listing_count
FROM listings_clean
GROUP BY neighbourhood_group
ORDER BY listing_count DESC;

-- How many listings per room type?
SELECT
    room_type,
    COUNT(*) AS listing_count
FROM listings_clean
GROUP BY room_type
ORDER BY listing_count DESC;

-- Overall median price, using PERCENTILE_CONT.
-- PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) sorts all price values and
-- interpolates the middle one -- the actual definition of a median. AVG() cannot do
-- this; it just sums and divides, which is a different calculation entirely and gets
-- pulled around by outliers the way we saw with price in Step 4.
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price,
    AVG(price)::NUMERIC(10,2) AS mean_price
FROM listings_clean;

-- Median price broken down by borough -- first look at whether price typically
-- differs by location, ahead of the full segment analysis in Step 6.
SELECT
    neighbourhood_group,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price,
    COUNT(*) AS listing_count
FROM listings_clean
GROUP BY neighbourhood_group
ORDER BY median_price DESC;
