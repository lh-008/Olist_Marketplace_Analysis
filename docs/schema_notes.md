# Olist Schema Notes

Reference document for the Olist Brazilian E-Commerce marketplace analysis.

---

## 1. Dataset overview

**Source:** Olist Brazilian E-Commerce Public Dataset (Kaggle).
**Domain:** Olist is a Brazilian marketplace platform that connects small/medium sellers to major e-commerce sites (think Shopify + aggregator). When a customer buys an item, the order may contain products from multiple sellers, each shipped separately.
**Scope:** ~100K orders placed between **September 2016 and October 2018** (~2 years).
**Granularity:** transactional — one row per order, with line items, payments, and reviews split into related tables.
**Currency:** Brazilian Real (BRL). All `price`, `freight_value`, `payment_value` columns are BRL.

The dataset is anonymized — customer and seller IDs are hashed, names and street addresses are removed, but zip code prefixes and geolocation lat/lng are preserved for geographic analysis.

---

## 2. Table inventory

Nine tables. Sizes are approximate.

| Table | Rows | One row = | PK |
|---|---|---|---|
| `orders` | ~99K | One order placed by a customer | `order_id` |
| `customers` | ~99K | One customer record per order | `customer_id` |
| `order_items` | ~113K | One product line in an order from one seller | (`order_id`, `order_item_id`) |
| `order_payments` | ~104K | One payment record (an order may split across methods) | (`order_id`, `payment_sequential`) |
| `order_reviews` | ~99K | One review submitted by a customer for an order | `review_id` |
| `products` | ~33K | One product in the catalog | `product_id` |
| `sellers` | ~3K | One seller on the marketplace | `seller_id` |
| `geolocation` | ~1M | One geocoded address (multiple per zip prefix) | none (composite, not unique) |
| `category_translation` | 71 | Portuguese → English category name | `product_category_name` |

---

## 3. Table-by-table reference

### `orders`
**One row =** one order placed by one customer.

| Column | Type | Notes |
|---|---|---|
| `order_id` | string (hash) | **PK.** Verified unique. |
| `customer_id` | string (hash) | **FK → `customers.customer_id`.** Note: this is *per-order* customer ID, not the person. |
| `order_status` | string | One of: delivered, shipped, canceled, unavailable, invoiced, processing, created, approved. ~97% are 'delivered'. |
| `order_purchase_timestamp` | timestamp | When the order was placed. The anchor date for recency calculations. |
| `order_approved_at` | timestamp | When payment was approved. ~0.2% null. |
| `order_delivered_carrier_date` | timestamp | When seller handed off to carrier. Null if not shipped. |
| `order_delivered_customer_date` | timestamp | When customer received it. ~3% null even among 'delivered' orders. |
| `order_estimated_delivery_date` | timestamp | The promise made to the customer. Always populated. Critical for Q2 (delivery delay vs review). |

**Key join paths:**
- `orders ⟷ customers` on `customer_id` (1:1)
- `orders ⟷ order_items` on `order_id` (1:N)
- `orders ⟷ order_payments` on `order_id` (1:N)
- `orders ⟷ order_reviews` on `order_id` (1:0..1, ~99% have a review)

---

### `customers`
**One row =** one customer record, created per order. **Not deduplicated to individuals.**

| Column | Type | Notes |
|---|---|---|
| `customer_id` | string (hash) | **PK.** Unique per row, but represents one *order's* customer record. |
| `customer_unique_id` | string (hash) | **Identity column.** This is the actual person. ~96K distinct values vs ~99K rows — ~3K customers made repeat purchases. |
| `customer_zip_code_prefix` | string | First 5 digits of Brazilian CEP. Joins to `geolocation.geolocation_zip_code_prefix` and `sellers.seller_zip_code_prefix`. |
| `customer_city` | string | Lowercased, no diacritics in most rows. |
| `customer_state` | string | 2-letter Brazilian state code (SP, RJ, MG, etc.). |

**⚠ Critical gotcha:** `customer_id` ≠ `customer_unique_id`. Always use `customer_unique_id` for:
- "Did this person come back?" (repeat purchase, RFM)
- Counting unique customers
- Computing CLV per person

Use `customer_id` only to join `orders` to `customers`.

---

### `order_items`
**One row =** one product line in an order from one seller.

An order with two products from the same seller has two rows. An order with the same product from two different sellers has two rows. An order with three of the same product is **still one row** with `order_item_id` 1, 2, 3 — quantity is encoded as multiple rows, not a column.

| Column | Type | Notes |
|---|---|---|
| `order_id` | string | **FK → `orders`.** Part of composite PK. |
| `order_item_id` | int | Line number within the order, starts at 1. Part of composite PK. |
| `product_id` | string | **FK → `products`.** |
| `seller_id` | string | **FK → `sellers`.** |
| `shipping_limit_date` | timestamp | Deadline for seller to ship to carrier. |
| `price` | numeric | Item price in BRL (single unit). |
| `freight_value` | numeric | Shipping cost in BRL allocated to this line. |

**Key derived metrics:**
- Order GMV: `SUM(price + freight_value) GROUP BY order_id`
- Order item count: `COUNT(*) GROUP BY order_id`
- Multi-seller order indicator: `COUNT(DISTINCT seller_id) > 1 GROUP BY order_id`

---

### `order_payments`
**One row =** one payment installment/method for an order. Orders can split across methods (e.g., voucher + credit card).

| Column | Type | Notes |
|---|---|---|
| `order_id` | string | **FK → `orders`.** Part of composite PK. |
| `payment_sequential` | int | Sequence within the order (1, 2, ...). Part of composite PK. |
| `payment_type` | string | credit_card, boleto, voucher, debit_card, not_defined. |
| `payment_installments` | int | Number of installments (Brazilian credit cards often split into parts). |
| `payment_value` | numeric | Amount paid in BRL for this row. |

**Reconciliation note:** `SUM(payment_value)` per order does not always exactly equal `SUM(price + freight_value)` from `order_items` — there are small discrepancies due to vouchers and rounding. Don't tie out the totals; report from `order_items` for GMV and `order_payments` for payment-method analysis.

---

### `order_reviews`
**One row =** one customer-submitted review for an order.

| Column | Type | Notes |
|---|---|---|
| `review_id` | string | **PK.** A handful of reviews appear with the same `review_id` across orders due to bulk submissions — verify uniqueness if you use it as a join key. |
| `order_id` | string | **FK → `orders`.** ~99% of orders have one review; a tiny number have two. |
| `review_score` | int | 1–5 stars. Distribution is **bimodal**: peak at 5, secondary peak at 1, valley at 2–3. |
| `review_comment_title` | string | Often null. Portuguese text. |
| `review_comment_message` | string | Often null. Portuguese text. Out of scope for this project unless you add NLP. |
| `review_creation_date` | date | When the review form was sent to the customer. |
| `review_answer_timestamp` | timestamp | When the customer submitted the review. |

**Score distribution (approximate):** 5★ ~57%, 4★ ~19%, 3★ ~8%, 2★ ~3%, 1★ ~12%.

---

### `products`
**One row =** one product in the catalog.

| Column | Type | Notes |
|---|---|---|
| `product_id` | string | **PK.** |
| `product_category_name` | string | Portuguese. ~600 products have null category. Join to `category_translation` for English. |
| `product_name_lenght` | int | [sic — typo in source data] Character count of product name. |
| `product_description_lenght` | int | [sic] Character count of description. |
| `product_photos_qty` | int | Number of photos. |
| `product_weight_g` | numeric | Weight in grams. |
| `product_length_cm`, `product_height_cm`, `product_width_cm` | numeric | Dimensions in cm. Useful if extending into freight modeling. |

**Note the misspellings** `lenght` are real column names in the data. Use them verbatim or alias on read.

---

### `sellers`
**One row =** one seller on the marketplace.

| Column | Type | Notes |
|---|---|---|
| `seller_id` | string | **PK.** |
| `seller_zip_code_prefix` | string | Joins to `geolocation`. |
| `seller_city` | string | |
| `seller_state` | string | Heavily concentrated in SP. |

Only ~3K sellers, small enough to surface "top problem sellers" in Q3 without sampling.

---

### `geolocation`
**One row =** one geocoded address. **Not unique by zip prefix** — multiple rows per prefix with slightly different lat/lng.

| Column | Type | Notes |
|---|---|---|
| `geolocation_zip_code_prefix` | string | Join key. |
| `geolocation_lat` | numeric | Latitude. |
| `geolocation_lng` | numeric | Longitude. |
| `geolocation_city` | string | |
| `geolocation_state` | string | |

**⚠ Critical gotcha:** if you naïvely join `customers` to `geolocation` on zip prefix, you'll multiply rows. Always pre-aggregate:

```sql
WITH geo AS (
    SELECT 
        geolocation_zip_code_prefix AS zip,
        AVG(geolocation_lat) AS lat,
        AVG(geolocation_lng) AS lng
    FROM geolocation
    GROUP BY 1
)
SELECT ... FROM customers c LEFT JOIN geo ON c.customer_zip_code_prefix = geo.zip
```

Some zip prefixes in `customers`/`sellers` are not in `geolocation` (~0.3% miss). Use `LEFT JOIN` and handle nulls in the dashboard.

---

### `category_translation`
**One row =** one Portuguese → English category name mapping.

| Column | Type | Notes |
|---|---|---|
| `product_category_name` | string | **PK.** Portuguese name (matches `products.product_category_name`). |
| `product_category_name_english` | string | English name for display. |

Coverage is incomplete — a few Portuguese categories in `products` have no English mapping. `LEFT JOIN` and fall back to the Portuguese name with `COALESCE`.

---

## 4. Join map (cheat sheet)

```
geolocation ─┐                         ┌─ category_translation
             │ zip_prefix              │ product_category_name
             │                         │
       customers ──── orders ──── order_items ──── products
                       │   │           │
                       │   │           └── sellers ──── geolocation
                       │   │                            (via seller zip)
                       │   └── order_reviews
                       │
                       └── order_payments
```

**The most common join pattern** (orders + customers + items, filtered to delivered):

```sql
FROM orders o
JOIN customers c   ON o.customer_id = c.customer_id
JOIN order_items i ON o.order_id    = i.order_id
WHERE o.order_status = 'delivered'
```

Memorize this — three of the four business questions start from this base.

---

## 5. Data quality summary

Confirmed via EDA queries:

| Issue | Impact | Handling |
|---|---|---|
| ~3% orders not in 'delivered' status | Excludes from revenue/delivery analysis | `WHERE order_status = 'delivered'` |
| ~3% delivered orders have null `order_delivered_customer_date` | Can't compute delivery delay | Filter out for Q2; report count as limitation |
| ~1% orders have no review | Excludes from Q2/Q3 | `INNER JOIN order_reviews` for review-dependent analyses |
| ~97% customers ordered exactly once | RFM frequency dimension is severely skewed | Note as limitation in README; consider single-purchase customer analysis instead |
| ~600 products have null category | Excludes from Q3 | `WHERE product_category_name IS NOT NULL` for category analysis |
| Geolocation has duplicates per zip | Row multiplication on naive join | Pre-aggregate `AVG(lat), AVG(lng) GROUP BY zip` |
| Some categories lack English translation | Display issue | `COALESCE(english, portuguese)` |
| Order payments don't tie to order_items totals | Reconciliation discrepancies | Use order_items for GMV, payments for payment-method splits — don't reconcile |
| 'lenght' misspelled in products columns | Easy typo when writing queries | Use as-is or alias on first read |

---

## 6. Key business facts (from EDA)

These shape the analysis decisions in Q1–Q4:

- **~99K orders, ~96K unique customers, ~33K products, ~3K sellers.**
- **2-year window** (Sept 2016 – Oct 2018), but volume is uneven: first 3 months are sparse, peak is late 2017 / early 2018.
- **Geographic concentration:** SP (São Paulo state) holds ~42% of customers; top 3 states (SP, RJ, MG) hold ~67%. Other 24 states are long tail.
- **Review score:** average ~4.1/5, but heavily bimodal (lots of 5s, second peak at 1).
- **Repeat purchase rate ~3%** — the single most important business fact for framing. Almost all revenue is single-purchase.
- **Multi-seller orders are rare** (~3%) — most orders fulfill from one seller.

---

## 7. Open questions

- **Q1 RFM:** with ~97% single-purchase customers, traditional RFM segments may collapse. Consider hybrid: do RFM on the ~3K repeat customers; do a separate "first-order" analysis for everyone else.
- **Q2 delivery:** define "late" as `delivered_date > estimated_date`? Or by absolute days from purchase? Pick before writing the query.
- **Q3 category quality:** what minimum order count to include a category? Suggest ≥100 to filter noise.
- **Q4 geographic CLV:** aggregate at state (clean, ~27 entities) or city (~4K, messy)? Start with state for Tableau, drill to city if time permits.

---

## 8. Glossary

| Term | Definition |
|---|---|
| GMV | Gross Merchandise Value. `SUM(price + freight_value)` over delivered orders. |
| CLV | Customer Lifetime Value. Total spend per `customer_unique_id` over the data window. |
| Recency | Days from a customer's last order to the dataset's max order date. |
| Frequency | Number of distinct delivered orders per `customer_unique_id`. |
| Monetary | Total spend (GMV-equivalent) per `customer_unique_id`. |
| Multi-seller order | An order with `COUNT(DISTINCT seller_id) > 1` in `order_items`. |
| Delivery delay | `order_delivered_customer_date - order_estimated_delivery_date` in days. Negative = early, positive = late. |