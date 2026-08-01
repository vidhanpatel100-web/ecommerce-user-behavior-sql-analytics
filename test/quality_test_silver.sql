/*
===============================================================================
SILVER LAYER — DATA QUALITY VALIDATION SUITE

Google Analytics 4 (GA4) Warehouse | SQL Server Management Studio
Convention: Each check states its expected result in a section header query.
Note: These checks verify the OUTPUT of transformations applied during 
      the Silver load (Noise reduction, TRIM formatting, Date parsing, 
      COALESCE fallbacks, and ISNULL numeric defaults).
===============================================================================
*/

-- ============================================================================
-- 1. NOISE REDUCTION & EVENT GRAIN
-- ============================================================================

SELECT '1. NOISE REDUCTION & EVENT GRAIN' AS test_suite_section;

-- Check 1.1: Noise reduction validation (Row count verification)
-- Expectation: Matches cleansed Silver event row count
SELECT 
    'silver.google_analytics_data' AS table_name,
    COUNT(*) AS total_silver_event_rows
FROM silver.google_analytics_data;

-- Check 1.2: Event Grain Integrity — Duplicate event records
-- Expectation: No rows returned (Each event should be unique per user + timestamp + event_name)
SELECT
    user_pseudo_id,
    event_timestamp,
    event_name,
    COUNT(*) AS duplicate_event_count
FROM silver.google_analytics_data
GROUP BY 
    user_pseudo_id, 
    event_timestamp, 
    event_name
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- 2. IDENTIFIER & STRING SANITATION
-- ============================================================================

SELECT '2. IDENTIFIER & STRING SANITATION' AS test_suite_section;

-- Check 2.1: Null or blank core identifiers
-- Expectation: user_id_nulls = 0, event_name_nulls = 0
SELECT
    SUM(CASE WHEN user_pseudo_id IS NULL OR TRIM(user_pseudo_id) = '' THEN 1 ELSE 0 END) AS user_pseudo_id_nulls,
    SUM(CASE WHEN event_name IS NULL OR TRIM(event_name) = '' THEN 1 ELSE 0 END) AS event_name_nulls
FROM silver.google_analytics_data;

-- Check 2.2: Leading/trailing whitespace in core string attributes (Validates TRIM)
-- Expectation: All counts = 0
SELECT
    COUNT(CASE WHEN LEN(user_pseudo_id) != LEN(TRIM(user_pseudo_id)) THEN 1 END) AS user_id_has_spaces,
    COUNT(CASE WHEN LEN(event_name) != LEN(TRIM(event_name)) THEN 1 END) AS event_name_has_spaces
FROM silver.google_analytics_data;
GO

-- ============================================================================
-- 3. DATE & TEMPORAL INTEGRITY
-- ============================================================================

SELECT '3. DATE & TEMPORAL INTEGRITY' AS test_suite_section;

-- Check 3.1: Date parsing and boundary range (Validates TRY_CAST conversion)
-- Expectation: missing_dates = 0, date range matches target event batch
SELECT
    COUNT(CASE WHEN event_date IS NULL THEN 1 END) AS missing_dates,
    MIN(event_date) AS earliest_event_date,
    MAX(event_date) AS latest_event_date
FROM silver.google_analytics_data;
GO

-- ============================================================================
-- 4. MARKETING & UTM ATTRIBUTION
-- ============================================================================

SELECT '4. MARKETING & UTM ATTRIBUTION' AS test_suite_section;

-- Check 4.1: UTM Traffic attribution null handling (Validates COALESCE fallbacks)
-- Expectation: All counts = 0 (Nulls replaced with '(direct)' or '(none)')
SELECT
    SUM(CASE WHEN traffic_source_source IS NULL THEN 1 ELSE 0 END) AS source_nulls,
    SUM(CASE WHEN traffic_source_medium IS NULL THEN 1 ELSE 0 END) AS medium_nulls,
    SUM(CASE WHEN traffic_source_name   IS NULL THEN 1 ELSE 0 END) AS campaign_nulls
FROM silver.google_analytics_data;

-- Check 4.2: Distinct traffic medium alignment
-- Expectation: Manual review — confirms standard GA4 channel groupings ('organic', 'referral', 'cpc', '(none)')
SELECT DISTINCT
    traffic_source_source,
    traffic_source_medium
FROM silver.google_analytics_data
ORDER BY traffic_source_medium;
GO

-- ============================================================================
-- 5. FINANCIAL & METRIC INTEGRITY
-- ============================================================================

SELECT '5. FINANCIAL & METRIC INTEGRITY' AS test_suite_section;

-- Check 5.1: Financial metrics default handling (Validates ISNULL(..., 0) conversions)
-- Expectation: All null counts = 0
SELECT
    SUM(CASE WHEN items_price_in_usd                  IS NULL THEN 1 ELSE 0 END) AS price_usd_nulls,
    SUM(CASE WHEN items_quantity                      IS NULL THEN 1 ELSE 0 END) AS quantity_nulls,
    SUM(CASE WHEN items_item_revenue_in_usd           IS NULL THEN 1 ELSE 0 END) AS item_revenue_nulls,
    SUM(CASE WHEN ecommerce_purchase_revenue_in_usd   IS NULL THEN 1 ELSE 0 END) AS purchase_revenue_nulls
FROM silver.google_analytics_data;

-- Check 5.2: Financial boundary checks — Negative revenue or quantity values
-- Expectation: negative_prices = 0, negative_quantities = 0, negative_revenue = 0
SELECT
    COUNT(CASE WHEN items_price_in_usd < 0 THEN 1 END)                  AS negative_prices,
    COUNT(CASE WHEN items_quantity < 0 THEN 1 END)                      AS negative_quantities,
    COUNT(CASE WHEN ecommerce_purchase_revenue_in_usd < 0 THEN 1 END)  AS negative_revenue
FROM silver.google_analytics_data;
GO

-- ============================================================================
-- 6. DEVICE & GEOGRAPHIC BOUNDS
-- ============================================================================

SELECT '6. DEVICE & GEOGRAPHIC BOUNDS' AS test_suite_section;

-- Check 6.1: Distinct device categories
-- Expectation: Manual review — values restricted to 'desktop', 'mobile', 'tablet'
SELECT DISTINCT device_category
FROM silver.google_analytics_data
ORDER BY device_category;

-- Check 6.2: Geographic country distribution
-- Expectation: Manual review — validates global reach, flags '(not set)' or missing origins
SELECT
    geo_country,
    COUNT(*) AS event_count
FROM silver.google_analytics_data
GROUP BY geo_country
ORDER BY event_count DESC;
GO
