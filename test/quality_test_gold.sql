/*
===============================================================================
QUALITY ASSURANCE SUITE: GOLD LAYER (GA4 WEB ANALYTICS)
===============================================================================
Diagnostic suite for Gold Layer views:
    1. Execution & Row Count Verification
    2. Null Audit & Default Fallback Checks
    3. Metric Boundaries & Percentage Validation (0.00% - 100.00%)
    4. Grain & Duplicate Integrity Verification
    5. Business Logic & Funnel Reconciliation
===============================================================================
*/

-- ============================================================================
-- SECTION 1: EXECUTION & ROW COUNT OVERVIEW
-- ============================================================================

SELECT '1. VIEW EXECUTION & ROW COUNT OVERVIEW' AS test_suite_section;

SELECT 'gold.cfq_drop_off'        AS view_name, COUNT(*) AS record_count FROM gold.cfq_drop_off
UNION ALL
SELECT 'gold.channel_perform',     COUNT(*) FROM gold.channel_perform
UNION ALL
SELECT 'gold.device_friction',     COUNT(*) FROM gold.device_friction;
GO

-- ============================================================================
-- SECTION 2: NULL AUDITS — ALL 3 GOLD VIEWS
-- ============================================================================

SELECT '2. NULL AUDITS & DEFAULT FALLBACK VERIFICATION' AS test_suite_section;

-- Check 2.1: gold.cfq_drop_off null audit (All counts expected to be 0)
SELECT
    'gold.cfq_drop_off' AS target_view,
    SUM(CASE WHEN total_users            IS NULL THEN 1 ELSE 0 END) AS total_users_nulls,
    SUM(CASE WHEN open_page              IS NULL THEN 1 ELSE 0 END) AS open_page_nulls,
    SUM(CASE WHEN product_interest       IS NULL THEN 1 ELSE 0 END) AS product_interest_nulls,
    SUM(CASE WHEN landing_to_pdp_conv_pct IS NULL THEN 1 ELSE 0 END) AS conv_pct_nulls,
    SUM(CASE WHEN landing_dropoff_pct    IS NULL THEN 1 ELSE 0 END) AS dropoff_pct_nulls,
    SUM(CASE WHEN promo_ctr_pct          IS NULL THEN 1 ELSE 0 END) AS promo_ctr_nulls
FROM gold.cfq_drop_off;

-- Check 2.2: gold.channel_perform null audit (All counts expected to be 0)
SELECT
    'gold.channel_perform' AS target_view,
    SUM(CASE WHEN traffic_medium   IS NULL THEN 1 ELSE 0 END) AS traffic_medium_nulls,
    SUM(CASE WHEN traffic_source   IS NULL THEN 1 ELSE 0 END) AS traffic_source_nulls,
    SUM(CASE WHEN id_user          IS NULL THEN 1 ELSE 0 END) AS id_user_nulls,
    SUM(CASE WHEN user_intent_pct  IS NULL THEN 1 ELSE 0 END) AS user_intent_nulls
FROM gold.channel_perform;

-- Check 2.3: gold.device_friction null audit (All counts expected to be 0)
SELECT
    'gold.device_friction' AS target_view,
    SUM(CASE WHEN device_category         IS NULL THEN 1 ELSE 0 END) AS device_category_nulls,
    SUM(CASE WHEN device_operating_system IS NULL THEN 1 ELSE 0 END) AS device_os_nulls,
    SUM(CASE WHEN device_web_info_browser IS NULL THEN 1 ELSE 0 END) AS browser_nulls,
    SUM(CASE WHEN device_intrest          IS NULL THEN 1 ELSE 0 END) AS device_interest_nulls
FROM gold.device_friction;
GO

-- ============================================================================
-- SECTION 3: METRIC BOUNDARY & RANGE VALIDATION (0.00% to 100.00%)
-- ============================================================================

SELECT '3. PERCENTAGE BOUNDARY AUDITS (0.00% to 100.00%)' AS test_suite_section;

-- Check 3.1: Invalid conversion/drop-off percentages outside 0-100% boundary (Expectation: 0 rows)
SELECT 
    'gold.cfq_drop_off' AS view_name,
    landing_to_pdp_conv_pct,
    landing_dropoff_pct,
    promo_ctr_pct
FROM gold.cfq_drop_off 
WHERE landing_to_pdp_conv_pct < 0.00 OR landing_to_pdp_conv_pct > 100.00
   OR landing_dropoff_pct < 0.00    OR landing_dropoff_pct > 100.00
   OR promo_ctr_pct < 0.00          OR promo_ctr_pct > 100.00;

-- Check 3.2: Invalid channel intent percentages outside 0-100% boundary (Expectation: 0 rows)
SELECT 
    'gold.channel_perform' AS view_name,
    traffic_medium,
    traffic_source,
    user_intent_pct
FROM gold.channel_perform 
WHERE user_intent_pct < 0.00 OR user_intent_pct > 100.00;

-- Check 3.3: Invalid device intent percentages outside 0-100% boundary (Expectation: 0 rows)
SELECT 
    'gold.device_friction' AS view_name,
    device_category,
    device_operating_system,
    device_intrest
FROM gold.device_friction 
WHERE device_intrest < 0.00 OR device_intrest > 100.00;
GO

-- ============================================================================
-- SECTION 4: GRAIN & DUPLICATE INTEGRITY CHECKS
-- ============================================================================

SELECT '4. GRAIN & DUPLICATE INTEGRITY CHECKS' AS test_suite_section;

-- Check 4.1: Duplicate channel attribution combinations (Expectation: 0 rows)
SELECT 
    traffic_medium, 
    traffic_source, 
    traffic_name, 
    COUNT(*) AS dup_count
FROM gold.channel_perform
GROUP BY traffic_medium, traffic_source, traffic_name
HAVING COUNT(*) > 1;

-- Check 4.2: Duplicate device/hardware combinations (Expectation: 0 rows)
SELECT 
    device_category, 
    device_operating_system, 
    device_language, 
    device_web_info_browser, 
    COUNT(*) AS dup_count
FROM gold.device_friction
GROUP BY device_category, device_operating_system, device_language, device_web_info_browser
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- SECTION 5: BUSINESS LOGIC SANITY CHECKS
-- ============================================================================

SELECT '5. BUSINESS LOGIC & FUNNEL RECONCILIATION' AS test_suite_section;

-- Check 5.1: Product Detail Page viewers higher than total landing page visitors (Expectation: 0 rows)
SELECT 
    'channel_perform_leakage_check' AS audit_rule,
    traffic_medium,
    traffic_source,
    open_page,
    product_interest
FROM gold.channel_perform 
WHERE product_interest > open_page;

-- Check 5.2: Overall Funnel Drop-off Rate + Conversion Rate = 100% (Expectation: 0 rows)
SELECT 
    'cfq_funnel_balance_check' AS audit_rule,
    landing_to_pdp_conv_pct, 
    landing_dropoff_pct, 
    (landing_to_pdp_conv_pct + landing_dropoff_pct) AS calculated_sum
FROM gold.cfq_drop_off
WHERE open_page > 0 
  AND (landing_to_pdp_conv_pct + landing_dropoff_pct) <> 100.00;
GO
