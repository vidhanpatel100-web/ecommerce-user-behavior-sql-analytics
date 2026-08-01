# Data Dictionary for Gold Layer

## Overview

The Gold Layer is the business-level analytical layer of the pipeline, structured as high-level aggregated reporting views optimized for BI reporting (Power BI / Tableau) and conversion funnel analysis. All Gold objects are implemented as SQL views (not physical tables) — they compute live over the Silver layer (`silver.google_analytics_data`), so there is no separate ETL step required to keep them in sync.

---

## 1. gold.cfq_drop_off

**Purpose:** Comprehensive Conversion Funnel & Drop-Off Leakage view. Aggregates distinct user events across key milestones (`page_view` → `view_item` → promotion interactions) to identify top-of-funnel drop-off points.

| Column Name | Data Type | Description |
|---|---|---|
| `total_users` | INT | Count of total distinct users (`user_pseudo_id`) tracked across all events. |
| `view_promo` | INT | Count of distinct users who viewed an on-site promotion (`view_promotion`). |
| `click_promo` | INT | Count of distinct users who clicked on a promotion (`select_promotion`). |
| `new_viewer` | INT | Count of distinct new visitors recording their first session (`first_visit`). |
| `open_page` | INT | Count of distinct users who generated a page view (`page_view`). Landing page baseline. |
| `scroll_page` | INT | Count of distinct users who engaged in page scrolling (`scroll`). |
| `product_interest` | INT | Count of distinct users who navigated to a Product Detail Page (`view_item`). |
| `product_click` | INT | Count of distinct users exhibiting active product engagement (`user_engagement`). |
| `landing_to_pdp_conv_pct` | DECIMAL(5,2) | Conversion rate % from Landing Page (`page_view`) to Product Detail Page (`view_item`). Safe calculation via `NULLIF`. |
| `landing_dropoff_pct` | DECIMAL(5,2) | User leakage rate % dropping off after page load without viewing a product detail page. |
| `promo_ctr_pct` | DECIMAL(5,2) | Promotion Click-Through Rate % (`click_promo` / `view_promo`). |

---

## 2. gold.channel_perform

**Purpose:** Marketing Channel Attribution and User Intent view. Evaluates user intent rates across traffic mediums, acquisition channels, and campaign sources.

| Column Name | Data Type | Description |
|---|---|---|
| `traffic_medium` | NVARCHAR | Medium that acquired the user session (e.g., `organic`, `cpc`, `referral`, `(none)`). |
| `traffic_source` | NVARCHAR | Specific traffic source origin (e.g., `google`, `direct`, `youtube`). Sourced with fallback `(direct)`. |
| `traffic_name` | NVARCHAR | Marketing campaign name associated with the user session. |
| `id_user` | INT | Count of distinct active users acquired through this channel combination. |
| `open_page` | INT | Count of distinct users from this channel who completed a page view. |
| `product_interest` | INT | Count of distinct users from this channel who evaluated a product detail page (`view_item`). |
| `user_intent_pct` | DECIMAL(5,2) | Channel User Intent Rate % (`product_interest` / `open_page`). Measures acquisition quality. |

---

## 3. gold.device_friction

**Purpose:** Hardware, Operating System, and Browser UX Friction Analysis view. Identifies technical drop-offs across hardware categories, mobile OS platforms, and web browsers.

| Column Name | Data Type | Description |
|---|---|---|
| `device_category` | NVARCHAR | Hardware type (`desktop`, `mobile`, `tablet`). Sourced with `'Uncategorized'` default. |
| `device_operating_system` | NVARCHAR | Operating system (`iOS`, `Android`, `Windows`, `Macintosh`). Sourced with `'Uncategorized'` default. |
| `device_language` | NVARCHAR | Browser ISO language code (e.g., `en-us`, `es-es`). Sourced with `'Uncategorized'` default. |
| `device_web_info_browser` | NVARCHAR | Web browser client (`Chrome`, `Safari`, `Edge`, `<Other>`). Sourced with `'Uncategorized'` default. |
| `total_user` | INT | Count of distinct users active on this specific hardware/browser combination. |
| `open_page` | INT | Count of distinct landing page sessions on this device profile. |
| `product_interest` | INT | Count of distinct product evaluations (`view_item`) on this device profile. |
| `device_intrest` | DECIMAL(5,2) | Device UX Intent Rate % (`product_interest` / `open_page`). Measures cross-device responsiveness and conversion friction. |
