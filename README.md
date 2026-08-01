Markdown
# Google Analytics 4 (GA4) E-Commerce Funnel & Attribution Analytics

An end-to-end SQL analytics project built on real-world Google Analytics 4 (GA4) web event export data using SQL Server (T-SQL) and a Medallion Architecture (Bronze → Silver → Gold). 

Rather than focusing on back-end ERP inventory, this project models **front-end user behavior**: mapping top-of-funnel drop-offs, evaluating marketing channel intent rates, and detecting cross-device/browser UX conversion friction.

---

## Architecture & Data Lineage

[ Raw GA4 Event CSV ]
│
▼
┌──────────────────┐
│   Bronze Schema  │  --> Raw Ingestion & Flexible Staging (bronze.google_analytics_data)
└─────────┬────────┘
│
▼
┌──────────────────┐
│   Silver Schema  │  --> Data Cleansing, Date Normalization & Default Attribution (silver.google_analytics_data)
└─────────┬────────┘
│
▼
┌──────────────────┐
│   Gold Schema    │  --> Live Analytical Views for BI & Funnel Optimization
└─────────┬────────┘
├──────► gold.cfq_drop_off       (Overall Conversion Funnel Leakage)
├──────► gold.channel_perform    (Acquisition Channel Intent & Attribution)
└──────► gold.device_friction    (Hardware, OS & Browser UX Friction)


### Medallion Layer Breakdown

1. **Bronze Layer (`bronze.google_analytics_data`)**
   * Raw staging table created via T-SQL DDL script.
   * Flexible data types (`NVARCHAR`, `FLOAT`) prevent ingestion failures from non-standard timestamps or missing parameter values.
   * Automated loading orchestrated via `bronze.proc_load_bronze` using `BULK INSERT` with quote-stripping (`FIELDQUOTE = '"'`) and Unix LF row termination (`0x0a`).

2. **Silver Layer (`silver.google_analytics_data`)**
   * Structured data cleansing, standardization, and typing orchestrated via `silver.proc_load_silver`.
   * Normalizes raw event dates to true T-SQL `DATE` objects using `TRY_CAST`.
   * Standardizes missing marketing dimensions using `COALESCE` defaults (`(direct)`, `(none)`).
   * Replaces `NULL` revenue, price, and item quantity metrics with defensive `0` values (`ISNULL`).

3. **Gold Layer (Live Reporting Views)**
   * Built directly on top of Silver as live views (`CREATE OR ALTER VIEW`) — zero data duplication or sync delays.
   * Enforces zero-division safety across all percentage calculations using `NULLIF(denominator, 0)`.

---

## Analytical Views & Key Insights

### 1. Overall Conversion Funnel Quantification (`gold.cfq_drop_off`)
* **Focus:** Quantifies user progression across key lifecycle events (`page_view` → `view_item` → `select_promotion`).
* **Key Findings:**
  * **Landing Page Leakage:** Evaluates the exact percentage of users who bounce immediately after `page_view` versus those who navigate to a Product Detail Page (PDP).
  * **Promotion CTR:** Tracks on-site promotional engagement by comparing impression count (`view_promotion`) against interaction count (`select_promotion`).

### 2. Marketing Channel Attribution & Intent (`gold.channel_perform`)
* **Focus:** Groups traffic by `traffic_source_medium`, `traffic_source_source`, and campaign name to calculate a **User Intent Rate %** (`view_item` / `page_view`).
* **Key Findings:**
  * Distinguishes high-volume "bounce" channels from lower-volume, high-intent traffic sources.
  * Measures acquisition quality across Organic, Paid Search (CPC), Referral, and Direct traffic.

### 3. Hardware & Device UX Friction (`gold.device_friction`)
* **Focus:** Aggregates intent rates across `device_category`, `device_operating_system`, `device_language`, and `device_web_info_browser`.
* **Key Findings:**
  * Identifies platform-specific responsiveness gaps (e.g., comparing Mobile vs. Desktop PDP intent rates).
  * Flags potential browser rendering or checkout friction across specific OS/browser combinations.

---

## Repository Structure

```text
├── Script/
│   ├── Bronze/
│   │   ├── ddl_bronze.sql           -- Staging table DDL
│   │   └── proc_load_bronze.sql     -- Automated BULK INSERT load procedure
│   ├── Silver/
│   │   ├── ddl_silver.sql           -- Cleansed schema table DDL
│   │   └── proc_load_silver.sql     -- ETL cleaning & transformation procedure
│   └── Gold/
│       └── ddl_gold.sql             -- Master views (cfq_drop_off, channel_perform, device_friction)
├── datasets/
│   └── readme.md                    -- Dataset source details, schema dictionary, and license info
├── docs/
│   ├── data_dictionary.md           -- Field definitions and metrics logic for Gold views
│   └── naming_convension.md         -- Schema, view, and column naming rules
└── test/
    ├── quality_test_silver.sql      -- Silver layer cleaning & boundary validation suite
    └── quality_test_gold.sql        -- Gold view integrity, null, and percentage boundary checks
