/*
===============================================================================
DDL Script: Deploy Gold Layer Views
===============================================================================

Script Purpose:
    Defines the reporting and analytical layer of the workspace for Google 
    Analytics 4 web event data:
      1. gold.cfq_drop_off        - Conversion Funnel Leakage & Drop-Off Metrics
      2. gold.channel_perform     - Traffic Attribution & Channel User Intent
      3. gold.device_friction     - Cross-Platform, OS & Browser UX Analysis

    Uses CREATE OR ALTER so this script can be re-run safely at any time 
    without needing a separate DROP step.

===============================================================================
*/

-- Ensure the 'gold' schema exists
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END
GO

-- ===============================================================================
-- 1. CONVERSION FUNNEL & DROP-OFF ANALYSIS VIEW
-- ===============================================================================
CREATE OR ALTER VIEW gold.cfq_drop_off AS
WITH Action_table AS (
    SELECT 
        COUNT(DISTINCT user_pseudo_id) AS total_users,
        COUNT(DISTINCT CASE WHEN event_name = 'view_promotion'   THEN user_pseudo_id END) AS view_promo,
        COUNT(DISTINCT CASE WHEN event_name = 'select_promotion' THEN user_pseudo_id END) AS click_promo,
        COUNT(DISTINCT CASE WHEN event_name = 'first_visit'       THEN user_pseudo_id END) AS new_viewer,
        COUNT(DISTINCT CASE WHEN event_name = 'page_view'         THEN user_pseudo_id END) AS open_page,
        COUNT(DISTINCT CASE WHEN event_name = 'scroll'            THEN user_pseudo_id END) AS scroll_page,
        COUNT(DISTINCT CASE WHEN event_name = 'view_item'         THEN user_pseudo_id END) AS product_interest,
        COUNT(DISTINCT CASE WHEN event_name = 'user_engagement'   THEN user_pseudo_id END) AS product_click
    FROM silver.google_analytics_data
)
SELECT
    total_users,
    view_promo,
    click_promo,
    new_viewer,
    open_page,
    scroll_page,
    product_interest,
    product_click,

    -- Landing Page (page_view) to Product Detail Page (view_item) Conversion %
    CAST((product_interest * 100.0 / NULLIF(open_page, 0)) AS DECIMAL(5,2)) AS landing_to_pdp_conv_pct,

    -- Landing Page Drop-off Leakage %
    CAST(((open_page - product_interest) * 100.0 / NULLIF(open_page, 0)) AS DECIMAL(5,2)) AS landing_dropoff_pct,

    -- Promotion Click-Through Rate % (Clicked / Viewed)
    CAST((click_promo * 100.0 / NULLIF(view_promo, 0)) AS DECIMAL(5,2)) AS promo_ctr_pct
FROM Action_table;
GO

-- ===============================================================================
-- 2. MARKETING CHANNEL ATTRIBUTION & INTENT VIEW
-- ===============================================================================
CREATE OR ALTER VIEW gold.channel_perform AS
WITH user_table AS (
    SELECT
        traffic_source_medium AS traffic_medium,
        traffic_source_source AS traffic_source,
        traffic_source_name   AS traffic_name,
        COUNT(DISTINCT user_pseudo_id) AS id_user,
        COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END) AS open_page,
        COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id END) AS product_interest
    FROM silver.google_analytics_data
    GROUP BY
        traffic_source_medium,
        traffic_source_source,
        traffic_source_name
)
SELECT
    traffic_medium,
    traffic_source,
    traffic_name,
    id_user,
    open_page,
    product_interest,
    COALESCE(CAST((product_interest * 100.0 / NULLIF(open_page, 0)) AS DECIMAL(5,2)), 0.00) AS user_intent_pct
FROM user_table;
GO

-- ===============================================================================
-- 3. HARDWARE & DEVICE FRICTION ANALYSIS VIEW
-- ===============================================================================
CREATE OR ALTER VIEW gold.device_friction AS
WITH device_table AS (
    SELECT
        COUNT(DISTINCT user_pseudo_id) AS total_user,
        COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END) AS open_page,
        COUNT(DISTINCT CASE WHEN event_name = 'view_item' THEN user_pseudo_id END) AS product_interest,
        COALESCE(device_category, 'Uncategorized')         AS device_category,
        COALESCE(device_operating_system, 'Uncategorized') AS device_operating_system,
        COALESCE(device_language, 'Uncategorized')         AS device_language,
        COALESCE(device_web_info_browser, 'Uncategorized') AS device_web_info_browser
    FROM silver.google_analytics_data
    GROUP BY
        device_category,
        device_operating_system,
        device_language,
        device_web_info_browser
)
SELECT
    device_category,
    device_operating_system,
    device_language,
    device_web_info_browser,
    total_user,
    open_page,
    product_interest,
    COALESCE(CAST((product_interest * 100.0 / NULLIF(open_page, 0)) AS DECIMAL(5,2)), 0.00) AS device_intrest
FROM device_table;
GO
