# Findings: Customer Segmentation and Delivery Experience

**Scratch document, updated through Day 3.** Source for the Q1 and Q2 sections of the final README. Numbers verified against `sql/04_rfm_scores.sql` and `sql/07_delivery_reviews.sql` output on the 2016-09 to 2018-10 snapshot.

---

## Top-line context

- 93,358 customers with at least one delivered order, spanning a 2-year window.
- 96,999 delivered orders with valid delivery timing fields (used for Q2 analysis).
- 97.0% of customers are single-purchase (90,557); only 3.0% returned for a second order (2,801).
- Overall average CLV: 165 BRL (approximately $30 USD).
- Estimated total recognized revenue across delivered orders: approximately 15.4M BRL.

This 3% repeat rate is the single most important framing fact for the entire analysis: Olist's growth problem is not acquisition, it is that almost no one comes back.

---

## Methodology note

Traditional RFM scoring breaks down on Olist's data because frequency is degenerate for 97% of customers (everyone has frequency = 1). To produce actionable segments, I split the customer base into two populations and scored each independently:

- **Repeat customers (n=2,801):** scored on full Recency × Frequency × Monetary, mapped to six segments (Champions, Loyal, At Risk, Can't Lose Them, Hibernating, Needs Attention).
- **Single-purchase customers (n=90,557):** scored on Recency × Monetary only, mapped to five segments (New High-Value, Lost High-Value, Recent One-Timer, Dormant One-Timer, Lost).

Quintile cuts are computed *within* each population so that the F-score among repeats discriminates meaningfully (freq=3+ vs freq=2) rather than collapsing into a binary repeat-customer flag.

---

## Q1 Finding 1: The biggest growth lever is hiding in single-purchase customers

Approximately 29,000 single-purchase customers spent around 300 BRL on average, nearly 2x the dataset's overall avg CLV, and almost half of them (14,200) have not returned in over a year.

| Segment | Customers | Avg CLV | Avg Recency | Est. Revenue |
|---|---|---|---|---|
| New High-Value | 14,885 | 297 BRL | 91 days | 4.42M BRL |
| Lost High-Value | 14,200 | 302 BRL | 394 days | 4.29M BRL |

These two segments alone account for approximately 56% of all revenue while representing only 31% of the customer base. They are also nearly identical in average CLV, which suggests the high-value cohort has been consistently present throughout the data window. In other words, customers currently in "New High-Value" are statistically very likely to drift into "Lost High-Value" within 12 months unless retention is actively driven.

**Recommendation:** Second-purchase activation on "New High-Value" is the highest-priority intervention. The customers are still in the consideration window (avg 91 days since first order), the value is proven (avg 297 BRL spent on order one), and the marginal cost of a personalized re-engagement email is small relative to the lifetime value at risk.

---

## Q1 Finding 2: Lost High-Value is a recoverable revenue pool

Win-back targeting on the Lost High-Value cohort is justified by unit economics:

- 14,200 customers, avg historical spend 302 BRL, so approximately 4.3M BRL of proven willingness-to-pay.
- Acquisition cost on these customers is already sunk; any positive response is incremental margin.
- A 20 to 30% incentive is defensible because the LTV signal is strong.

Compare against the **Recent + Lost One-Timer** segments (43,361 customers, avg CLV around 71 BRL): retention spend on those segments has worse expected return per dollar because the demonstrated willingness-to-pay is much lower. Deprioritize them in retention budgets.

This split also raises a strategic question worth flagging to the acquisition team: **why does the marketplace acquire 43K low-CLV one-timers vs 29K high-CLV ones?** A channel-level CLV breakdown (not in scope for Q1) would identify which acquisition sources bring in the wrong customer profile.

---

## Q1 Finding 3: Among the 3% who repeat, "Can't Lose Them" is the most urgent cohort

Within the 2,801 repeat customers, segment economics break down as follows:

| Segment | Customers | Avg CLV | Avg Recency | Avg Freq | Est. Revenue |
|---|---|---|---|---|---|
| Champions | 435 | 542 BRL | 78 days | 2.33 | 236K BRL |
| Loyal | 570 | 340 BRL | 155 days | 2.11 | 194K BRL |
| Can't Lose Them | 370 | 528 BRL | 360 days | 2.00 | 195K BRL |
| At Risk | 58 | 517 BRL | 365 days | 3.09 | 30K BRL |
| Hibernating | 693 | 157 BRL | 371 days | 2.03 | 109K BRL |
| Needs Attention | 675 | 149 BRL | 122 days | 2.04 | 101K BRL |

The most actionable insight is **"Can't Lose Them"**: 370 customers with avg CLV 528 BRL who have not ordered in nearly a year. They have proven they will spend at premium price points, and they have proven they will return, but the data suggests they have stopped. This is the highest-value win-back opportunity in the repeat population.

**At Risk** is smaller (58 customers) but represents the highest-frequency churned cohort (avg 3.09 orders before lapsing). These should receive the most personalized treatment. A generic email won't recover a customer who has placed three orders.

**Champions** (435 customers, 542 BRL avg CLV) is the segment to *protect*, not discount. They buy at full price; the right intervention is recognition (VIP status, early access, referral incentives), not promotional pricing.

---

## Q2.1 Finding: Delivery experience is a binary pass/fail signal, not a gradient

The moment an order crosses from "on time" to "late" (delayed vs. the promised date), average review score drops from 4.11 to 2.71 stars. Once late, further lateness continues to erode reviews (Very Late orders average 1.70 stars), but the primary damage happens at the boundary itself.

| Delivery bucket | Orders | Avg Review | 1-star % | 5-star % | Bad review % |
|---|---|---|---|---|---|
| Very Early (10+ days) | 61,884 | 4.32 | 6.4 | 64.0 | 8.9 |
| Early (3-10 days) | 23,764 | 4.24 | 6.9 | 59.4 | 9.8 |
| On Time (-3 to 0) | 4,296 | 4.11 | 8.1 | 53.9 | 11.7 |
| Late (1-7 days) | 3,612 | 2.71 | 41.4 | 23.9 | 49.4 |
| Very Late (7+ days) | 2,797 | 1.70 | 69.7 | 7.0 | 79.2 |

This has a specific implication: customers grade delivery on whether it beat the promise, not on absolute speed. A 15-day delivery that arrived 3 days early scores 4.32; a 15-day delivery that arrived 1 day late scores 2.71. Same actual experience, dramatically different sentiment.

Only 6.6% of orders (6,409 of 96,999) are delivered late. But those orders produce approximately 40% of all bad reviews. The concentration is severe enough that fixing lateness on the marketplace's worst-performing 5% of shipments would meaningfully move the platform-wide review average.

**Sub-finding:** orders delivered exactly on the promised date score worse (11.7% bad reviews) than orders delivered 3+ days early (8.9%). Olist systematically promises 24-day delivery windows and delivers in an average of 12.5 days, a 12-day padding that is doing genuine psychological work. Customers reward "faster than expected," not "as expected." Any effort to tighten delivery promises should account for this psychological premium.

---

## Q2.2 Finding: Delivery experience does not drive return behavior

A hypothesis worth testing was that late deliveries drive Olist's non-return problem. The data does not support this.

| First delivery bucket | Customers | Return rate | Avg first review |
|---|---|---|---|
| Very Early (10+ days) | 59,782 | 3.31% | 4.32 |
| Early (3-10 days) | 23,061 | 2.81% | 4.24 |
| On Time (-3 to 0) | 4,150 | 2.39% | 4.11 |
| Late (1-7 days) | 3,569 | 2.41% | 2.71 |
| Very Late (7+ days) | 2,788 | 2.83% | 1.69 |

Return rates across first-order delivery buckets range from 2.39% (On Time) to 3.31% (Very Early), a spread of less than 1 percentage point. Customers who received a Very Late first order return at 2.83%, statistically indistinguishable from customers who received an On Time first order. This is despite the enormous gap in review sentiment across the same buckets (4.32 stars for Very Early vs 1.69 stars for Very Late).

**The gap between review sentiment and return behavior is itself the finding.** Customers express frustration through reviews when delivery fails, but they do not modulate their return behavior based on delivery quality, because the return rate is near-zero across all conditions. Even the customers who had the best possible first experience only return at 3.31%. The 97% non-return problem identified in Q1 is not a delivery problem; it is a marketplace design problem.

**Implication for the project's overall recommendation:** improving delivery reliability will improve reviews (and therefore likely conversion at checkout, since new customers read reviews before buying). But it will not, by itself, solve the retention problem. Retention requires an active re-engagement mechanism: post-purchase email sequences, personalized recommendations from prior order categories, or loyalty programs, none of which are visible in the marketplace's current data.

**Anomaly worth flagging:** the Very Late bucket shows a slightly higher return rate (2.83%) than On Time (2.39%) or Late (2.41%). Two candidate explanations: (1) complaint-driven re-engagement, where very late orders trigger customer service resolutions that lead to a follow-up purchase with a credit; or (2) small-sample noise, since the Very Late bucket has only 79 returners. Both are plausible; verifying either would require support ticket data not present in the dataset.

---

## Recommended marketing motions, ranked by expected impact

1. **Second-purchase activation, New High-Value (14,885 customers, 4.4M BRL at stake).** Time-sensitive personalized re-engagement with category recommendations from the first order. Modest incentive on second purchase. This is the highest-leverage single intervention identified across Q1 and Q2.
2. **Win-back, Lost High-Value (14,200 customers, 4.3M BRL recoverable).** Aggressive incentive (20 to 30%) justified by sunk acquisition cost and demonstrated willingness-to-pay.
3. **Win-back, Can't Lose Them (370 customers, 195K BRL).** Smaller absolute size but highest per-customer value among repeats. Personalized outreach referencing past purchases.
4. **VIP program, Champions (435 customers).** Non-promotional recognition. Goal is retention, not conversion.
5. **Targeted logistics improvement on late-delivery lanes/sellers.** The 6.6% late orders drive ~40% of bad reviews. This is a review-score and conversion play, not a retention play. Focus effort on the ~5% worst-performing shipments rather than platform-wide delivery speed.
6. **Channel audit, Recent + Lost One-Timer (43,361 customers).** Don't retention-spend; investigate whether acquisition channels are targeting the wrong customer profile.

---

## Limitations to acknowledge in the README

- **Data window is fixed (Sept 2016 to Oct 2018).** "Lost" segments are defined relative to the snapshot date, not a current date. In production this would be a rolling calculation.
- **No cost data is available**, so segment-level *profit* contribution can't be computed, only revenue. Recommendations on discounting depth ("a 20% incentive is defensible") would need margin data to be fully justified.
- **Frequency distribution is highly concentrated at freq=2** even within the repeat population (92%). Quintile scoring on frequency primarily discriminates at the high end (freq=3+) rather than across the full quintile spread.
- **Segment boundary rules are editorial.** The CASE-WHEN thresholds (e.g., "r_score ≥ 4 AND f_score ≥ 4 AND m_score ≥ 4 = Champions") follow industry convention but are not the only defensible cuts. Sensitivity analysis on the boundaries was not performed.
- **The single-purchase segmentation drops the F dimension entirely**, which makes the segments coarser than the repeat segments. This is a feature, not a bug: F provides no information when the value is constant. But it does mean the two halves of the analysis are not directly comparable on a segment-by-segment basis.
- **Q2's null result on delivery-driven retention is a correlational finding, not a causal one.** A more rigorous test would control for order value, category, geography, and cohort. The current analysis is sufficient to reject the strong hypothesis ("delivery is the primary driver") but not to fully characterize the (weaker) relationship that likely exists.
- **Review coverage is incomplete.** Approximately 1% of delivered orders have no review, which are excluded from Q2.1. The bias is likely small but not corrected for.

---

## Open threads for later questions

- Q2 answered part of the Q1 open question about non-return drivers: delivery is not the primary cause. This shifts weight onto Q3 (category and seller quality) as the next testable driver.
- Q3 (category and seller quality) should test whether specific categories produce experiences bad enough to suppress return behavior on their own, controlling for delivery. If a category shows low return rates *even when* delivery was fine, that's a product-quality signal.
- Q4 (geographic CLV) should be cross-referenced with this segmentation. Where do New High-Value customers live? Does retention investment have a geographic prior?
- A follow-up not in scope: cohort retention curves by acquisition month. Would tell us whether the repeat rate is improving or degrading over time.
- Another follow-up not in scope: the 12-day promise padding is a fascinating platform-level design choice. A tighter promise could drive higher conversion at checkout even at the cost of some lateness. This is an A/B test question, not an observational one.

---

## Scratch notes / things to verify before final write-up

- [ ] Re-run total revenue figure with a cleaner SQL query (current 15.4M BRL is computed from segment-level rollups; should be verified against `SUM(price + freight_value)` on delivered orders directly).
- [ ] Decide whether to include the "Estimated Revenue" column in the public README, depends on how confident the rollups feel after verification.
- [ ] Draft the chart spec for the Tableau dashboard: segment treemap (size = customers, color = avg CLV) is the headline visual for Q1. A second chart showing "% of revenue by segment" stacked bar would reinforce the New High-Value finding visually.
- [ ] Q2 dashboard tiles: (a) bar chart of avg review by delivery bucket (Q2.1 cliff), (b) bar chart of return rate by first-delivery bucket (Q2.2 flat line). Placed side-by-side, they tell the whole Q2 story.
- [ ] Consider whether to run Q2.3 (seller-leg vs carrier-leg breakdown) as a supporting analysis for the "targeted logistics improvement" recommendation. Adds practical color but not essential to the argument.