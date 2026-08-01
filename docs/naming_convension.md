# Naming Conventions

## Overview

This document defines the naming rules used across all three layers of the architecture (Bronze, Silver, Gold), ensuring any schema, table, view, or column name can be decoded immediately without needing to inspect the underlying SQL objects.

---

## Schema Layers

| Schema | Purpose |
|---|---|
| `bronze` | Raw data landing layer, loaded as-is from raw GA4 event export CSVs. Minimal modification to preserve raw data lineage. |
| `silver` | Cleansed and standardized event data. Preserves underlying table names from Bronze while standardizing types and null values. |
| `gold` | Business-ready, aggregated analytical views. Uses explicit functional naming for conversion funnels, channels, and device analysis. |

---

## Bronze / Silver Table Naming

Pattern: `<data_source>_data`

Unlike transactional operational databases with multiple normalized tables, GA4 event data lands as a unified, wide event table. 

| Table | Full Meaning | Description |
|---|---|---|
| `bronze.google_analytics_data` | Bronze GA4 Landing Table | Raw, un-parsed event record storage capturing raw string timestamps and flexible metrics. |
| `silver.google_analytics_data` | Silver Cleansed Event Table | Cleansed GA4 event data with standardized dates (`TRY_CAST`), default `COALESCE` traffic sources, and zeroed metric defaults. |

---

## Gold Layer View Naming

Pattern: `gold.<domain>_<metric_focus>` 

Gold objects are built as live SQL views on top of Silver tables, structured deliberately around key digital marketing and UX performance frameworks.

| Object | Type | Analytical Grain | Business Focus |
|---|---|---|---|
| `gold.cfq_drop_off` | Analytical View | Overall Workspace Grain | Conversion Funnel Quantification (CFQ) & Drop-Off Leakage |
| `gold.channel_perform` | Analytical View | Traffic Source & Medium Grain | Marketing Channel Performance & User Intent Rates |
| `gold.device_friction` | Analytical View | Hardware & Operating System Grain | UX Friction, Cross-Browser & Device Conversion Performance |

---

## Column Naming Rules

- **Strict `snake_case`:** All columns across Bronze, Silver, and Gold strictly use `snake_case` with no capital letters or spaces.
- **Bronze Field Alignment:** Columns match standard BigQuery GA4 export conventions (e.g., `user_pseudo_id`, `event_timestamp`, `traffic_source_medium`).
- **Safeguarded Rates (`_pct`):** All calculated ratios and percentage metrics in Gold views end with the suffix `_pct` (e.g., `landing_to_pdp_conv_pct`, `user_intent_pct`, `promo_ctr_pct`) and are explicitly cast as `DECIMAL(5,2)`.
- **Defensive Division:** All ratio calculations use `NULLIF(denominator, 0)` paired with `COALESCE(..., 0.00)` to ensure zero division error crashes (`Msg 8134`) during report execution.

---

## Abbreviation Glossary

| Abbreviation | Full Term | Context / Meaning |
|---|---|---|
| `cfq` | Conversion Funnel Quantification | Top-of-funnel drop-off and conversion rate analysis |
| `pdp` | Product Detail Page | GA4 `view_item` event triggers |
| `conv` | Conversion | Funnel progression milestone |
| `ctr` | Click-Through Rate | Interactivity percentage (`click_promo` / `view_promo`) |
| `pct` | Percentage | Calculated decimal ratio bounded between 0.00% and 100.00% |
| `perform` | Performance | Attribution and engagement metrics aggregated by acquisition channel |
