# Q1 Findings: Customer Segmentation

**Scratch document — drafted Day 2.** Source for the Q1 section of the final README. Numbers verified against `sql/04_rfm_scores.sql` output on the 2016-09 → 2018-10 snapshot.

---

## Top-line context

- **93,358 customers** with at least one delivered order, spanning a 2-year window.
- **97.0% are single-purchase customers** (90,557); only 3.0% returned for a second order (2,801).
- Overall average CLV: **165 BRL** (~$30 USD).
- Estimated total recognized revenue across delivered orders: **~15.4M BRL**.

This 3% repeat rate is the single most important framing fact for the entire analysis: Olist's growth problem is not acquisition — it's that almost no one comes back.

---

## Methodology note

Traditional RFM scoring breaks down on Olist's data because frequency is degenerate for 97% of customers (everyone has frequency = 1). To produce actionable segments, I split the customer base into two populations and scored each independently:

- **Repeat customers (n=2,801):** scored on full Recency × Frequency × Monetary, mapped to six segments (Champions, Loyal, At Risk, Can't Lose Them, Hibernating, Needs Attention).
- **Single-purchase customers (n=90,557):** scored on Recency × Monetary only, mapped to five segments (New High-Value, Lost High-Value, Recent One-Timer, Dormant One-Timer, Lost).

Quintile cuts are computed *within* each population so that the F-score among repeats discriminates meaningfully (freq=3+ vs freq=2) rather than collapsing into a binary repeat-customer flag.

---

## Finding 1 — The biggest growth lever is hiding in single-purchase customers

Approximately **29,000 single-purchase customers spent ~300 BRL on average — nearly 2x the dataset's overall avg CLV** — and almost half of them (14,200) have not returned in over a year.

| Segment | Customers | Avg CLV | Avg Recency | Est. Revenue |
|---|---|---|---|---|
| New High-Value | 14,885 | 297 BRL | 91 days | 4.42M BRL |
| Lost High-Value | 14,200 | 302 BRL | 394 days | 4.29M BRL |

These two segments alone account for **~56% of all revenue** while representing only **31% of the customer base**. They are also nearly identical in average CLV, which suggests the high-value cohort has been consistently present throughout the data window — meaning customers currently in "New High-Value" are statistically very likely to drift into "Lost High-Value" within 12 months unless retention is actively driven.

**Recommendation:** Second-purchase activation on "New High-Value" is the highest-priority intervention. The customers are still in the consideration window (avg 91 days since first order), the value is proven (avg 297 BRL spent on order one), and the marginal cost of a personalized re-engagement email is small relative to the lifetime value at risk.

---

## Finding 2 — Lost High-Value is a recoverable revenue pool

Win-back targeting on the Lost High-Value cohort is justified by unit economics:

- 14,200 customers, avg historical spend 302 BRL → ~4.3M BRL of proven willingness-to-pay.
- Acquisition cost on these customers is already sunk; any positive response is incremental margin.
- A 20–30% incentive is defensible because the LTV signal is strong.

Compare against the **Recent + Lost One-Timer** segments (43,361 customers, avg CLV ~71 BRL): retention spend on those segments has worse expected return per dollar because the demonstrated willingness-to-pay is much lower. Deprioritize them in retention budgets.

This split also raises a strategic question worth flagging to the acquisition team: **why does the marketplace acquire 43K low-CLV one-timers vs 29K high-CLV ones?** A channel-level CLV breakdown (not in scope for Q1) would identify which acquisition sources bring in the wrong customer profile.

---

## Finding 3 — Among the 3% who repeat, "Can't Lose Them" is the most urgent cohort

Within the 2,801 repeat customers, segment economics break down as follows:

| Segment | Customers | Avg CLV | Avg Recency | Avg Freq | Est. Revenue |
|---|---|---|---|---|---|
| Champions | 435 | 542 BRL | 78 days | 2.33 | 236K BRL |
| Loyal | 570 | 340 BRL | 155 days | 2.11 | 194K BRL |
| Can't Lose Them | 370 | 528 BRL | 360 days | 2.00 | 195K BRL |
| At Risk | 58 | 517 BRL | 365 days | 3.09 | 30K BRL |
| Hibernating | 693 | 157 BRL | 371 days | 2.03 | 109K BRL |
| Needs Attention | 675 | 149 BRL | 122 days | 2.04 | 101K BRL |

The most actionable insight is **"Can't Lose Them"**: 370 customers with avg CLV 528 BRL who have not ordered in nearly a year. They have proven they will spend at premium price points, and they have proven they will return — but the data suggests they have stopped. This is the highest-value win-back opportunity in the repeat population.

**At Risk** is smaller (58 customers) but represents the highest-frequency churned cohort (avg 3.09 orders before lapsing). These should receive the most personalized treatment — a generic email won't recover a customer who has placed three orders.

**Champions** (435 customers, 542 BRL avg CLV) is the segment to *protect*, not discount. They buy at full price; the right intervention is recognition (VIP status, early access, referral incentives), not promotional pricing.

---

## Recommended marketing motions, ranked by expected impact

1. **Second-purchase activation — New High-Value (14,885 customers, 4.4M BRL at stake).** Time-sensitive personalized re-engagement with category recommendations from the first order. Modest incentive on second purchase.
2. **Win-back — Lost High-Value (14,200 customers, 4.3M BRL recoverable).** Aggressive incentive (20–30%) justified by sunk acquisition cost and demonstrated willingness-to-pay.
3. **Win-back — Can't Lose Them (370 customers, 195K BRL).** Smaller absolute size but highest per-customer value among repeats. Personalized outreach referencing past purchases.
4. **VIP program — Champions (435 customers).** Non-promotional recognition. Goal is retention, not conversion.
5. **Channel audit — Recent + Lost One-Timer (43,361 customers).** Don't retention-spend; investigate whether acquisition channels are targeting the wrong customer profile.

---

## Limitations to acknowledge in the README

- **Data window is fixed (Sept 2016 – Oct 2018);** "Lost" segments are defined relative to the snapshot date, not a current date. In production this would be a rolling calculation.
- **No cost data is available**, so segment-level *profit* contribution can't be computed — only revenue. Recommendations on discounting depth ("a 20% incentive is defensible") would need margin data to be fully justified.
- **Frequency distribution is highly concentrated at freq=2** even within the repeat population (92%). Quintile scoring on frequency primarily discriminates at the high end (freq=3+) rather than across the full quintile spread.
- **Segment boundary rules are editorial.** The CASE-WHEN thresholds (e.g., "r_score ≥ 4 AND f_score ≥ 4 AND m_score ≥ 4 = Champions") follow industry convention but are not the only defensible cuts. Sensitivity analysis on the boundaries was not performed.
- **The single-purchase segmentation drops the F dimension entirely**, which makes the segments coarser than the repeat segments. This is a feature, not a bug — F provides no information when the value is constant — but it does mean the two halves of the analysis are not directly comparable on a segment-by-segment basis.

---

## Open threads for later questions

- Q2 (delivery delay vs reviews) may help explain *why* high-value first-purchasers don't return. If late deliveries disproportionately hit higher-priced orders, that's part of the answer.
- Q4 (geographic CLV) should be cross-referenced with this segmentation. Where do New High-Value customers live? Does retention investment have a geographic prior?
- A follow-up not in scope: cohort retention curves by acquisition month. Would tell us whether the repeat rate is improving or degrading over time.

---

## Scratch notes / things to verify before final write-up

- [ ] Re-run total revenue figure with a cleaner SQL query (current 15.4M BRL is computed from segment-level rollups; should be verified against `SUM(price + freight_value)` on delivered orders directly).
- [ ] Decide whether to include the "Estimated Revenue" column in the public README — depends on how confident the rollups feel after verification.
- [ ] Draft the chart spec for the Tableau dashboard: segment treemap (size = customers, color = avg CLV) is the headline visual. A second chart showing "% of revenue by segment" stacked bar would reinforce the New High-Value finding visually.