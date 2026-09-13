-- 01_create_tables.sql
-- Purpose: Define the schema for the raw NYC Airbnb listings data (Step 3: Data Discovery).
-- Data types chosen to match what the raw CSV actually contains, including nullable
-- fields where the source data has legitimate blanks (not errors).
--
-- Dataset: Inside Airbnb, New York City, listings.csv snapshot dated 10 August 2026.
-- Source: https://data.insideairbnb.com/united-states/ny/new-york-city/2026-08-10/visualisations/listings.csv

CREATE TABLE listings_raw (
    id                              BIGINT PRIMARY KEY,      -- unique listing ID
    name                            TEXT,                    -- listing title
    host_id                         BIGINT,
    host_profile_id                 BIGINT,                  -- large numeric ID, purely a label (no math performed on it)
    host_name                       TEXT,
    neighbourhood_group             TEXT,                    -- NYC borough (Manhattan, Brooklyn, Queens, etc.)
    neighbourhood                   TEXT,
    latitude                        NUMERIC(9,6),
    longitude                       NUMERIC(9,6),
    room_type                       TEXT,                    -- Entire home/apt, Private room, Shared room, Hotel room
    price                           NUMERIC,                 -- nullable: blank means not currently priced/listed
    minimum_nights                  INTEGER,
    number_of_reviews               INTEGER,
    last_review                     DATE,                    -- nullable: no reviews yet = no date
    reviews_per_month               NUMERIC,                 -- decimal, e.g. 0.04
    calculated_host_listings_count  INTEGER,                 -- how many listings this host manages total
    availability_365                INTEGER,                 -- days available for booking in next 365 days
    number_of_reviews_ltm           INTEGER,                 -- reviews in the last twelve months
    license                         TEXT                     -- nullable: NYC license number, mostly blank in this data
);
