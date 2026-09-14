# NYC Airbnb Market Analysis — Insights & Recommendations

**Prepared for:** A property management company providing Airbnb management services (dynamic pricing, guest turnover, calendar management) across New York City
**Business question:** Which NYC neighborhood × room-type segments should the company prioritize for new host acquisition, and what pricing guidance should it give hosts in those segments?
**Dataset:** Inside Airbnb, New York City `listings.csv`, snapshot dated 10 August 2026
**Analysis scope:** 5,280 short-term listings (active pricing, under a 30-night minimum stay) across 5 boroughs and 4 room types

---

## 1. Executive Summary

Entire home/apt is the strongest segment in this market, combining a high price with genuine guest demand in four of the five boroughs. Hotel room listings command the single highest median price anywhere in the dataset — $470/night in Manhattan — but that headline number is misleading on its own: Hotel room is simultaneously the lowest-demand room type in every borough it appears in, is 100% controlled by professional multi-listing operators with no individual-host presence at all, and is independently flagged as structurally weak in two boroughs with enough data to trust the result. Four separate analyses, run independently, all point to the same conclusion about this one segment. Meanwhile, the city-wide correlation between price and demand is essentially zero (r = −0.009) — a number that on its own would suggest "price doesn't predict demand," but which is actually the average of two opposite, segment-specific patterns cancelling out. The recommendation is to prioritize Entire home/apt listings, treat Hotel room as a segment to actively avoid despite its price tag, and read every borough-level headline number alongside its underlying sample size before acting on it.

---

## 2. Market Overview

Before segment-level findings, it's worth establishing the shape of the market itself — where the listings are and how they split by type. This context is what makes later findings ("Bronx numbers are directional, not conclusive") interpretable rather than arbitrary.

**Listings by borough** (5,280 total):

| Borough | Listings | Share of market | Median price |
|---|---|---|---|
| Manhattan | 2,776 | 52.6% | $328 |
| Brooklyn | 1,488 | 28.2% | $252 |
| Queens | 819 | 15.5% | $192 |
| Bronx | 145 | 2.7% | $166 |
| Staten Island | 52 | 1.0% | $164 |

Manhattan and Brooklyn together account for over 80% of the entire short-term market. Bronx and Staten Island combined are under 4% of listings — any finding specific to those two boroughs needs to be read as directional, not statistically solid, purely because of how little data exists there.

**Listings by room type** (5,280 total):

| Room type | Listings | Share of market |
|---|---|---|
| Private room | 3,281 | 62.1% |
| Entire home/apt | 1,539 | 29.1% |
| Hotel room | 422 | 8.0% |
| Shared room | 38 | 0.7% |

Private room is the most *common* listing type by a wide margin — nearly two-thirds of the market — but volume is not the same question as opportunity. Across every borough in this dataset, the top-ranked segment by price is always either Entire home/apt or Hotel room; Private room, despite its volume, does not hold the #1 price position in a single borough. Being the most abundant segment and being the best segment to prioritize turned out to be two different questions with two different answers.

**Overall pricing distribution:** median price is $275/night; the mean is $395.19 — 44% higher than the median. That gap is the signature of outliers pulling an average upward, which is exactly why every price comparison in this analysis uses the median, not the mean (see Methodology, below). Using the IQR (interquartile range) method — Q1 = $101, Q3 = $287, IQR = $186, giving an upper outlier bound of $566 — roughly 7.4% of listings (about 391) are statistical price outliers. These were deliberately kept in the dataset rather than removed, since they represent real, bookable, high-value listings (the kind a "highest price" business question is specifically trying to find), not data errors.

---

## 3. Methodology Summary

Three methodology decisions shape every finding below, and they're worth stating explicitly because they'd come up in any serious review of this work:

- **Median over mean, everywhere.** Given the 44% gap between median and mean price city-wide, any "average price" figure computed with a mean would overstate what a typical listing in a segment actually charges. Every price comparison in this document uses the median.
- **`reviews_per_month` as a demand proxy, not a booking count.** Airbnb's public data does not expose actual bookings or occupancy. A guest can only leave a review after a completed stay, so review frequency is the closest available signal for guest turnover — an industry-standard workaround, not a hidden assumption. 727 listings (about 14% of the cleaned dataset) have never received a review; these are treated as zero demand rather than excluded, because a listing nobody books *is* the lowest possible demand signal, and dropping it would erase exactly the weak-performing segments this analysis needs to find.
- **Rankings computed within each borough, not city-wide.** "Highest-priced segment" is calculated separately for Manhattan, separately for Brooklyn, and so on, rather than ranking all 20 borough × room-type segments against each other in one list. A property manager operating in Queens needs to know what performs best *in Queens* — the fact that the cheapest Manhattan segment still outprices the most expensive Queens segment isn't actionable information for someone deciding where to focus within a specific borough.

Full detail on every cleaning rule and SQL/Python implementation is in `sql/02_data_cleaning.sql`, `sql/03_eda_queries.sql`, `sql/04_analysis_queries.sql`, and `python/eda_analysis.ipynb`.

---

## 4. Detailed Findings

### 4.1 — Which segments command the highest price?

Entire home/apt holds the #1 price position in every borough except one. The exception is Manhattan, where Hotel room narrowly beats it: $470 median (303 listings) versus Entire home/apt's $388.50 (912 listings). On the surface this makes Manhattan Hotel room look like the single best-priced opportunity in the entire dataset — but that reading doesn't survive contact with the demand and saturation findings below (see 4.5, "The Hotel Room Case Study").

Median price also varies sharply by borough on its own: Manhattan's overall median ($328) is roughly double Staten Island's and the Bronx's (~$165 each), with Brooklyn ($252) and Queens ($192) in between. A pricing strategy that works in Manhattan will not transplant directly to an outer borough.

### 4.2 — Which segments show the strongest demand?

Hotel room is the lowest-demand room type in every single borough it appears in, ranging from 0.00 to 0.34 average monthly reviews — genuinely near-zero guest turnover. "Shared room" technically ranks #1 for demand in Manhattan and Queens, but on samples of only 7 and 8 listings respectively — far too thin to treat as a real market signal rather than noise from a handful of listings.

The single most important individual data point in this entire analysis: **Manhattan Hotel room is rank #1 for price and rank #4 (dead last) for demand, in the same borough, at the same time.** Highest price, lowest turnover — the opposite of what a healthy segment looks like.

### 4.3 — Which segment is best on price *and* demand combined?

Combining the two rankings per borough (lower combined score = better on both), Entire home/apt is the best or tied-for-best segment in four of the five boroughs. Brooklyn is a particularly clean example: Entire home/apt is simultaneously high-priced *and* high-demand there, with no trade-off between the two — the kind of segment a business wants to find. Manhattan is the sole exception, where Hotel room's price-rank advantage is more than cancelled out by its demand-rank collapse once both metrics are weighed together.

### 4.4 — How saturated is each segment by professional operators?

`calculated_host_listings_count` (how many total listings a listing's host manages) measures whether a segment is dominated by professional, multi-property operators or is still fragmented among individual hosts — the latter being where a company selling host-management *services* actually has a market to sell into.

Hotel room is saturated by professional operators without exception, in every borough it appears in — 100% of Hotel room listings belong to hosts with more than one property. In Manhattan specifically, the average host in this segment manages **77.84 listings** — a scale consistent with a hotel chain or professional operator running a portfolio, not an individual host who might want management services. There is structurally no addressable market for new host acquisition in this segment: the sellers this business would want to sign don't exist there.

### 4.5 — Which segments are flagged as weak-performing?

Using the worst quartile (bottom 25% city-wide) for *both* booked availability and guest demand together, four segments are flagged as weak-performing overall: **Manhattan Hotel room (303 listings)**, **Brooklyn Hotel room (39 listings)**, **Bronx Hotel room (4 listings)**, and **Staten Island Shared room (2 listings)**.

Only the first two are large enough samples to treat as credible findings. The Bronx and Staten Island flags are worth noting for completeness, but at 4 and 2 listings respectively they're too small to distinguish a real pattern from a handful of unusual individual listings — this is a case where the *same statistical method* produces one trustworthy result and one that shouldn't be acted on, purely because of sample size, and that distinction matters more than the flag itself.

This closes the loop across four independent analyses: Hotel room holds the top median price in Manhattan (4.1), yet is the lowest-demand room type in every borough (4.2), is fully saturated by professional operators with zero individual-host presence (4.4), and is now independently confirmed weak-performing wherever the sample size is large enough to trust (4.5). Four different methods, four different angles into the data, one consistent answer.

### 4.6 — Does higher price mean lower demand, city-wide?

The overall correlation between price and demand across all 20 borough × room-type segments is essentially zero (r = −0.009). Taken at face value, that number says "price and demand are unrelated across this market" — and that conclusion would be wrong. What's actually happening is that Hotel room shows a strong *negative* price/demand relationship (high price, low demand — see 4.2 and 4.5), while segments like Brooklyn Entire home/apt show high price *and* high demand simultaneously (see 4.3). These two opposite patterns average out to a number close to zero at the city level, hiding both real patterns underneath it.

This is as much a methodological finding as a business one: a single city-wide statistic can actively mislead a stakeholder if it's reported without the segment-level context that explains *why* it lands where it does.

---

## 5. Cross-Cutting Pattern: The Hotel Room Case Study

It's worth stating this as its own section because it's the clearest illustration in the whole dataset of why a multi-angle analysis matters more than any single metric. If this analysis had stopped at "which segment has the highest price?" (finding 4.1 alone), the recommendation would have been to prioritize Manhattan Hotel room — the exact opposite of the correct answer. It took demand data (4.2), ownership-structure data (4.4), and a combined-quartile weak-performance flag (4.5) to reveal that the highest sticker price in the dataset sits on top of the single worst-performing segment by every other measure available. In a real job, this is the difference between a one-metric dashboard and an actual analysis: the former would have pointed the business in the wrong direction with full confidence.

---

## 6. Recommendations

**Primary — prioritize Entire home/apt.** It is the most consistently strong segment across the market: best or tied-best on combined price and demand in 4 of 5 boroughs, and the clear #1 segment on price alone outside Manhattan. This is where new host acquisition effort should concentrate first.

**In Manhattan specifically, lead with Entire home/apt despite Hotel room's higher headline price.** Manhattan is the one borough where the "obvious" answer (highest price) and the correct answer (best combined performance) diverge. Entire home/apt's combined price-and-demand position beats Hotel room's price-only advantage once turnover is accounted for.

**Actively avoid Hotel room as a segment, city-wide.** The price advantage doesn't offset four independent findings — lowest demand of any room type, complete saturation by professional operators, zero individual-host presence, and a confirmed weak-performance flag everywhere the sample size supports one. There is no realistic entry point here for the individual or small-portfolio hosts this business model depends on.

**Treat Bronx and Staten Island as data-gap boroughs, not confirmed opportunities or confirmed non-opportunities.** At 145 and 52 total listings (2.7% and 1.0% of the market), neither borough has enough data to support a confident segment-level recommendation either way. The correct next step is more data, not a decision made on the numbers currently available.

**Don't let median price alone drive pricing guidance for hosts.** Manhattan Hotel room is the clearest proof in this dataset that the highest-priced segment can simultaneously be the worst one to be in. Any pricing recommendation given to a host should be paired with that segment's demand and saturation figures, not price in isolation.

**Flag Private room as a candidate for a follow-up analysis, not a current recommendation.** It is by far the most common listing type (62% of the market) but was not the primary focus of the five business questions driving this project, and its detailed demand and saturation numbers weren't broken out segment-by-segment the way Entire home/apt and Hotel room were. Given how much of the market it represents, it's a natural next question rather than an oversight to leave unaddressed.

---

## 7. Limitations and Caveats

- **Reviews are a proxy for demand, not a direct booking or occupancy count.** Airbnb's public data doesn't expose actual bookings. This affects the absolute scale of "demand" (the true booking rate is certainly higher than review counts alone suggest, since not every guest leaves a review) but not the *relative* comparison between segments, which is what every recommendation above depends on.
- **This is a single point-in-time snapshot (10 August 2026), not a trend.** Seasonal effects — summer tourism peaks, holiday demand spikes — are invisible in a one-snapshot dataset. A listing that looks weak in an August snapshot could look different in December. Detecting this would require a time-series extension using multiple Inside Airbnb snapshots or the companion `reviews.csv` dataset (considered for this project and deliberately scoped out — see the project notes).
- **The analysis excludes 74% of the post-price-filter dataset via the 30-night minimum-stay rule**, a deliberate decision tied directly to the business model (this company offers *short-term* rental management services, and a 30+ night listing has no real guest turnover to manage). This means the findings above describe the short-term rental market specifically, not the NYC Airbnb-platform market as a whole — a meaningful distinction if this analysis were ever handed to a stakeholder without that context.
- **Small-sample segments appear throughout this document and are called out individually**, but it's worth restating as a general caveat: any single-digit or low-double-digit listing count (Bronx and Staten Island borough totals; "Shared room" demand rank in Manhattan/Queens; the Bronx and Staten Island weak-performance flags) should be treated as a lead worth investigating further, not a standalone justification for a business decision.

---

## 8. Suggested Next Iteration

Consistent with Step 10 of this project's own analytical framework — real projects are revisited, not delivered once and left alone — a few concrete extensions were identified but deliberately left out of this round's scope:

- **A time-series extension using Inside Airbnb's `reviews.csv`**, joined against `listings_clean` to see whether demand for a given segment is trending up or down, not just where it sits in a single snapshot. This was scoped out of the current project specifically because the core skill it would demonstrate (a real JOIN across tables) was already covered by the price/demand JOIN in section 4.3 above, and the added time cost wasn't worth it against the remaining project budget — but it's the natural next step if this project continues.
- **A segment-level breakdown for Private room**, mirroring the depth given to Entire home/apt and Hotel room in this document, given that it represents 62% of the market by listing count.
- **A geographic drill-down below the borough level**, using the `neighbourhood` column (more granular than `neighbourhood_group`), to check whether the borough-level patterns found here hold up — or break down — at the individual-neighborhood level.

---

## 9. Methodology Note

Every cleaning decision, EDA query, and analysis query behind this document — including exact filters, SQL, row counts, and the full window-function logic used to compute each ranking — is documented inline in `sql/02_data_cleaning.sql` through `sql/04_analysis_queries.sql`, and independently validated in `python/eda_analysis.ipynb`. This document summarizes and interprets those results for a business audience; it does not introduce any analysis that isn't already backed by those files.
