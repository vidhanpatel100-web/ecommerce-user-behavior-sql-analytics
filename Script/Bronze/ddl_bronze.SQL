/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates all the tracking and data staging tables within the 
    'bronze' schema layer for Google Analytics 4 event export data. It safely 
    drops existing tables if they already exist to prevent structural deployment 
    conflicts.
    
    Run this master file to re-define or initialize the core database blueprint.
===============================================================================
*/

-- Ensure the 'bronze' schema exists
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze');
END
GO

-- Drop existing table if it already exists
IF OBJECT_ID('bronze.google_analytics_data', 'U') IS NOT NULL
    DROP TABLE bronze.google_analytics_data;
GO

-- Create Bronze Raw Ingestion Table
CREATE TABLE bronze.google_analytics_data (

    -- Event Identification & Timestamps
    event_date                          NVARCHAR(255),
    event_timestamp                     NVARCHAR(50),   -- Kept as NVARCHAR to avoid scientific notation parsing errors
    event_name                          NVARCHAR(255),
    event_params_key                    NVARCHAR(255),
    event_params_value_string_value     NVARCHAR(255),
    event_params_value_int_value        FLOAT,
    event_params_value_float_value      FLOAT,
    event_params_value_double_value     FLOAT,
    event_previous_timestamp            NVARCHAR(50),
    event_value_in_usd                  FLOAT,
    event_bundle_sequence_id            NVARCHAR(50),
    event_server_timestamp_offset       NVARCHAR(50),

    -- User Identifiers & Properties
    user_id                             NVARCHAR(255),
    user_pseudo_id                      NVARCHAR(255),
    privacy_info_analytics_storage      NVARCHAR(255),
    privacy_info_ads_storage            NVARCHAR(255),
    privacy_info_uses_transient_token   NVARCHAR(255),
    user_properties_key                 NVARCHAR(255),
    user_properties_value_string_value  NVARCHAR(255),
    user_properties_value_int_value     FLOAT,
    user_properties_value_float_value   FLOAT,
    user_properties_value_double_value  FLOAT,
    user_properties_value_set_timestamp_micros NVARCHAR(50),
    user_first_touch_timestamp          NVARCHAR(50),
    user_ltv_revenue                    FLOAT,
    user_ltv_currency                   NVARCHAR(255),

    -- Device Dimensions
    device_category                     NVARCHAR(255),
    device_mobile_brand_name            NVARCHAR(255),
    device_mobile_model_name            NVARCHAR(255),
    device_mobile_marketing_name        NVARCHAR(255),
    device_mobile_os_hardware_model     NVARCHAR(255),
    device_operating_system             NVARCHAR(255),
    device_operating_system_version     NVARCHAR(255),
    device_vendor_id                    NVARCHAR(255),
    device_advertising_id               NVARCHAR(255),
    device_language                     NVARCHAR(255),
    device_is_limited_ad_tracking       NVARCHAR(255),
    device_time_zone_offset_seconds     FLOAT,
    device_web_info_browser             NVARCHAR(255),
    device_web_info_browser_version     NVARCHAR(255),

    -- Geographic Dimensions
    geo_continent                       NVARCHAR(255),
    geo_sub_continent                   NVARCHAR(255),
    geo_country                         NVARCHAR(255),
    geo_region                          NVARCHAR(255),
    geo_city                            NVARCHAR(255),
    geo_metro                           NVARCHAR(255),

    -- Application & Stream Info
    app_info_id                         NVARCHAR(255),
    app_info_version                    NVARCHAR(255),
    app_info_install_store              NVARCHAR(255),
    app_info_firebase_app_id            NVARCHAR(255),
    app_info_install_source             NVARCHAR(255),
    traffic_source_medium               NVARCHAR(255),
    traffic_source_name                 NVARCHAR(255),
    traffic_source_source               NVARCHAR(255),
    stream_id                           NVARCHAR(50),
    platform                            NVARCHAR(255),
    event_dimensions_hostname           NVARCHAR(255),

    -- E-Commerce Metrics
    ecommerce_total_item_quantity       FLOAT,
    ecommerce_purchase_revenue_in_usd   FLOAT,
    ecommerce_purchase_revenue          FLOAT,
    ecommerce_refund_value_in_usd       FLOAT,
    ecommerce_refund_value              FLOAT,
    ecommerce_shipping_value_in_usd     FLOAT,
    ecommerce_shipping_value            FLOAT,
    ecommerce_tax_value_in_usd          FLOAT,
    ecommerce_tax_value                 FLOAT,
    ecommerce_unique_items              FLOAT,
    ecommerce_transaction_id            NVARCHAR(255),

    -- Item Level Dimensions & Metrics
    items_item_id                       NVARCHAR(255),
    items_item_name                     NVARCHAR(255),
    items_item_brand                    NVARCHAR(255),
    items_item_variant                  NVARCHAR(255),
    items_item_category                 NVARCHAR(255),
    items_item_category2                NVARCHAR(255),
    items_item_category3                NVARCHAR(255),
    items_item_category4                NVARCHAR(255),
    items_item_category5                NVARCHAR(255),
    items_price_in_usd                  FLOAT,
    items_price                         FLOAT,
    items_quantity                      FLOAT,
    items_item_revenue_in_usd           FLOAT,
    items_item_revenue                  FLOAT,
    items_item_refund_in_usd            FLOAT,
    items_item_refund                   FLOAT,
    items_coupon                        NVARCHAR(255),
    items_affiliation                   NVARCHAR(255),
    items_location_id                   NVARCHAR(255),
    items_item_list_id                  NVARCHAR(255),
    items_item_list_name                NVARCHAR(255),
    items_item_list_index               NVARCHAR(255),
    items_promotion_id                  NVARCHAR(255),
    items_promotion_name                NVARCHAR(255),
    items_creative_name                 NVARCHAR(255),
    items_creative_slot                 NVARCHAR(255)
);
GO
