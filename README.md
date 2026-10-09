# CareSync — End-to-End Healthcare Clinical Analytics on Databricks

[![Platform](https://img.shields.io/badge/Platform-Databricks-red)](https://databricks.com)
[![Architecture](https://img.shields.io/badge/Architecture-Medallion-blue)]()
[![Cloud](https://img.shields.io/badge/Cloud-Azure-0078D4)]()
[![License](https://img.shields.io/badge/License-MIT-green)]()

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Business Objective](#business-objective)
3. [Architecture](#architecture)
4. [Tech Stack](#tech-stack)
5. [Unity Catalog Structure](#unity-catalog-structure)
6. [Data Flow — End to End](#data-flow--end-to-end)
   - [Step 1: Source Data Generation & Upload](#step-1-source-data-generation--upload)
   - [Step 2: Landing to Bronze](#step-2-landing-to-bronze)
   - [Step 3: Bronze to Silver](#step-3-bronze-to-silver)
   - [Step 4: Calendar Dimension](#step-4-calendar-dimension)
   - [Step 5: Silver to Gold](#step-5-silver-to-gold)
   - [Step 6: Dashboard & Visualization](#step-6-dashboard--visualization)
   - [Step 7: Gmail Integration (Planned)](#step-7-gmail-integration-planned)
7. [Notebook Reference](#notebook-reference)
8. [Table Inventory](#table-inventory)
9. [Dashboard Overview](#dashboard-overview)
10. [Repository Structure](#repository-structure)
11. [Execution Order](#execution-order)
12. [Parameters & Widgets](#parameters--widgets)
13. [Data Quality & Validation](#data-quality--validation)
14. [Deployment & Run Guide](#deployment--run-guide)
15. [Future Enhancements](#future-enhancements)

---

## Project Overview

**CareSync** is a production-grade, end-to-end healthcare clinical analytics platform built entirely on **Databricks (Azure)**. It processes clinical lab test data across a network of **50 hospitals**, **5,003 patients**, **25 insurance providers**, and **19 U.S. states**, following the **Medallion Architecture** (Landing → Bronze → Silver → Gold) with **Unity Catalog** governance throughout.

The platform ingests raw clinical data from CSV/Parquet files, cleanses and enriches it through a multi-layer lakehouse pipeline, and delivers business-ready analytics through an interactive **AI/BI Dashboard** with 6 analytical pages and 29 datasets.

---

## Business Objective

CareSync enables healthcare operations teams and clinical leadership to:

- **Monitor lab testing volumes** across the hospital network in real time
- **Track abnormal and critical test rates** (overall ~22.4% abnormal, ~8.2% critical) to prioritize clinical interventions
- **Analyze hospital performance** — comparing daily volumes, weekend vs. weekday patterns, and day-over-day changes
- **Build patient 360 profiles** — combining demographics, insurance, and lab history into a unified view
- **Identify lab test trends** — month-over-month abnormal rate changes across 5 test types (CBC, BMP, Thyroid Panel, Lipid Panel, HbA1c)
- **Support data-driven decisions** for resource allocation, staffing, and quality improvement

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        CareSync Architecture                                 │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   SOURCE DATA (CSV/Parquet)                                                  │
│       │                                                                      │
│       ▼                                                                      │
│   ┌─────────────────────────────────────────┐                                │
│   │  LANDING ZONE                           │                                │
│   │  UC External Volume                     │                                │
│   │  /Volumes/adb_caresync/landing/         │                                │
│   │    landing_volume/{source}/{table}/{ts}/ │                                │
│   └──────────────┬──────────────────────────┘                                │
│                  │  Landing_to_Bronze notebook                               │
│                  ▼                                                            │
│   ┌─────────────────────────────────────────┐                                │
│   │  BRONZE LAYER (Raw + Metadata)          │                                │
│   │  adb_caresync.bronze.*                  │                                │
│   │  5 tables: doctors, hospitals,          │                                │
│   │  insurance_providers, lab_results,      │                                │
│   │  patients                               │                                │
│   └──────────────┬──────────────────────────┘                                │
│                  │  Bronze_to_Silver notebook                                │
│                  ▼                                                            │
│   ┌─────────────────────────────────────────┐                                │
│   │  SILVER LAYER (Cleansed + Enriched)     │                                │
│   │  adb_caresync.silver.*                  │                                │
│   │  6 tables: calendar, doctors, hospitals,│                                │
│   │  insurance_providers, lab_results,      │                                │
│   │  patients                               │                                │
│   └──────────────┬──────────────────────────┘                                │
│                  │  Gold notebooks (3)                                        │
│                  ▼                                                            │
│   ┌─────────────────────────────────────────┐                                │
│   │  GOLD LAYER (Business Aggregations)     │                                │
│   │  adb_caresync.gold.*                    │                                │
│   │  3 tables: patient_360,                 │                                │
│   │  hospital_daily_summary,                │                                │
│   │  lab_test_trends                        │                                │
│   └──────────────┬──────────────────────────┘                                │
│                  │                                                            │
│                  ▼                                                            │
│   ┌─────────────────────────────────────────┐                                │
│   │  AI/BI DASHBOARD                        │                                │
│   │  CareSync Clinical Analytics Dashboard  │                                │
│   │  6 pages · 29 datasets · 25+ widgets    │                                │
│   └──────────────┬──────────────────────────┘                                │
│                  │                                                            │
│                  ▼                                                            │
│   ┌─────────────────────────────────────────┐                                │
│   │  GMAIL INTEGRATION (Planned)            │                                │
│   │  Email alerts for critical thresholds   │                                │
│   │  Scheduled report delivery              │                                │
│   └─────────────────────────────────────────┘                                │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Component              | Technology                                       |
| ---------------------- | ------------------------------------------------ |
| Cloud Platform         | Microsoft Azure                                  |
| Data Platform          | Databricks (Azure Databricks)                    |
| Compute                | Serverless SQL Warehouse / All-Purpose Cluster    |
| Data Governance        | Unity Catalog (`adb_caresync`)                   |
| Storage                | UC External Volume (Landing), Managed Tables     |
| Processing Engine      | Apache Spark (PySpark + Spark SQL)               |
| Architecture Pattern   | Medallion (Landing → Bronze → Silver → Gold)     |
| Visualization          | Databricks AI/BI Dashboard (Lakeview)            |
| Version Control        | Git (GitHub)                                     |
| File Formats           | CSV, Parquet, Delta Lake                         |
| Language               | Python, SQL                                      |

---

## Unity Catalog Structure

```
adb_caresync (Catalog)
│
├── landing (Schema)
│   └── landing_volume (External Volume)
│       └── /Volumes/adb_caresync/landing/landing_volume/
│           └── {source_system}/{table_name}/{landing_timestamp}/
│               └── *.csv / *.parquet
│
├── bronze (Schema)
│   ├── doctors
│   ├── hospitals
│   ├── insurance_providers
│   ├── lab_results
│   └── patients
│
├── silver (Schema)
│   ├── calendar          ← dimension table (1940–2030)
│   ├── doctors
│   ├── hospitals
│   ├── insurance_providers
│   ├── lab_results
│   └── patients
│
└── gold (Schema)
    ├── patient_360              (5,003 rows)
    ├── hospital_daily_summary   (6,711 rows)
    └── lab_test_trends          (78 rows)
```

---

## Data Flow — End to End

### Step 1: Source Data Generation & Upload

Raw clinical data files (CSV or Parquet) are generated from hospital source systems and uploaded to the **Unity Catalog External Volume**:

```
/Volumes/adb_caresync/landing/landing_volume/
    └── {source_system}/
        └── {table_name}/
            └── {landing_timestamp}/
                └── data files (*.csv or *.parquet)
```

**Source tables** (5 entities):

| Table                | Description                                               | Format      |
| -------------------- | --------------------------------------------------------- | ----------- |
| `hospitals`          | 50 hospitals across the network                           | CSV/Parquet |
| `patients`           | 5,003 patients with demographics and registration info    | CSV/Parquet |
| `doctors`            | Physicians linked to hospitals                            | CSV/Parquet |
| `insurance_providers`| 25 insurance providers (PPO, HMO, Government)             | CSV/Parquet |
| `lab_results`        | Clinical lab test results with status (Normal/Abnormal/Critical) | CSV/Parquet |

The `landing_timestamp` folder (e.g., `2026-10-08_06:50:38`) acts as a partition key, enabling incremental loads and full traceability back to the exact data drop.

---

### Step 2: Landing to Bronze

**Notebook:** `Landing_to_Bronze`  
**Parameters:** `source_system`, `table_name`, `landing_timestamp`, `source_file_format`

This notebook performs the initial ingestion:

1. **Path validation** — Checks that the landing path exists for the given source/table/timestamp combination. If missing, exits gracefully with a descriptive message.
2. **File reading** — Reads CSV (with header + schema inference) or Parquet based on the `source_file_format` parameter.
3. **Metadata enrichment** — Adds two audit columns:
   - `landing_timestamp` — the timestamp folder from which data was loaded
   - `insert_timestamp` — `current_timestamp()` at load time
4. **Write to Bronze** — Appends data to `adb_caresync.bronze.{table_name}` as a Delta table.

**Key design decisions:**
- Append-only write mode preserves full history in Bronze
- No schema enforcement at Bronze — raw data is loaded as-is
- Landing path structure enables reprocessing of any historical load

---

### Step 3: Bronze to Silver

**Notebook:** `Bronze_to_Silver`  
**Parameters:** `landing_timestamp`, `table_name`, `merge_keys`, `load_type`

This notebook cleanses and loads data into the Silver layer with three supported load strategies:

1. **Source filtering** — Reads from `adb_caresync.bronze.{table_name}` filtered to the specified `landing_timestamp`.
2. **Audit column injection** — Adds `insert_timestamp` and `update_timestamp` (both set to `current_timestamp()`).
3. **Load execution** — Based on `load_type` parameter:

| Load Type | Behavior                                                                 |
| --------- | ------------------------------------------------------------------------ |
| `FULL`    | Overwrites the entire Silver table (default if not specified)            |
| `APPEND`  | Appends new records to the existing Silver table                         |
| `MERGE`   | SCD Type 1 merge using specified `merge_keys` — updates matched rows, inserts new ones |

**MERGE details:**
- Validates that all `merge_keys` exist in the source DataFrame
- Creates a temporary view for the MERGE SQL statement
- Updates all columns except `insert_timestamp` on match
- Inserts all columns on no-match
- Creates the target table on first run if it doesn't exist

4. **Record count exit** — Returns the processed record count via `dbutils.notebook.exit()`.

---

### Step 4: Calendar Dimension

**Notebook:** `Prepare calendar table`

Builds a comprehensive **calendar/date dimension** table at `adb_caresync.silver.calendar`:

- **Date range:** 1940-01-01 through 2030-12-31 (33,238 rows, 91 years)
- **35+ columns** including:
  - Date keys and identifiers (`date_key`, `date`, `year_month_key`)
  - Granularity columns (`year`, `quarter`, `month`, `week_of_year`, `day_of_month`)
  - Name columns (`month_name`, `day_name`, short variants)
  - Boolean flags (`is_weekend`, `is_month_start`, `is_month_end`, `is_quarter_start`, `is_year_start`, `is_leap_year`)
  - Period boundaries (`week_start_date`, `month_start_date`, `quarter_start_date`, etc.)

This dimension is joined to fact tables in Gold using `date_key = CAST(date_format(date_col, 'yyyyMMdd') AS INT)`.

---

### Step 5: Silver to Gold

Three Gold notebooks transform Silver data into business-ready aggregated tables. A **Source-to-Target Mapping (STTM)** workbook (`Gold/sttm_silver_to_gold.xlsx`) documents all transformations.

#### 5a. Patient 360 View

**Notebook:** `Gold/NB_patient_360`  
**Target:** `adb_caresync.gold.patient_360` (5,003 rows)

Builds a unified patient profile by joining:
- `silver.patients` (base demographics)
- `silver.hospitals` (hospital name via `registered_hospital_id`)
- `silver.insurance_providers` (provider name via `insurance_provider_id`)
- `silver.lab_results` (aggregated: total tests, abnormal count, critical count, last test date)

**Output columns:**
`patient_id`, `first_name`, `last_name`, `date_of_birth`, `age`, `gender`, `city`, `state`, `hospital_id`, `hospital_name`, `insurance_provider_id`, `insurance_provider_name`, `total_tests`, `abnormal_test_count`, `critical_test_count`, `last_test_date`

#### 5b. Hospital Daily Summary

**Notebook:** `Gold/NB_hospital_daily_summary`  
**Target:** `adb_caresync.gold.hospital_daily_summary` (6,711 rows)

Aggregates lab results at the hospital × day grain with calendar enrichment:
- Daily metrics: `total_tests`, `unique_patients_tested`, `active_doctor_count`
- Quality metrics: `abnormal_test_count`, `critical_test_count`, `abnormal_rate_pct`, `critical_rate_pct`
- Trend metrics: `prev_day_total_tests`, `test_volume_change_pct` (LAG window function)
- Calendar enrichment: `day_name`, `is_weekend` (joined from `silver.calendar`)

#### 5c. Lab Test Trends

**Notebook:** `Gold/NB_lab_test_trends`  
**Target:** `adb_caresync.gold.lab_test_trends` (78 rows)

Monthly aggregation by test type with trend analysis:
- 5 test types: **CBC**, **BMP**, **Thyroid Panel**, **Lipid Panel**, **HbA1c**
- Volume metrics: `total_tests`, `abnormal_test_count`, `critical_test_count`
- Rate metrics: `abnormal_rate_pct`, `critical_rate_pct`
- Trend metrics: `prev_month_abnormal_rate_pct`, `abnormal_rate_change_pct` (LAG window)

**Key clinical insights:**
- Thyroid Panel has the highest abnormal rate (~27.6%)
- HbA1c has the highest critical rate (~11.1%)
- Overall network: ~22.4% abnormal, ~8.2% critical across all tests

---

### Step 6: Dashboard & Visualization

**Asset:** CareSync Clinical Analytics Dashboard (Databricks AI/BI Lakeview Dashboard)  
**Datasets:** 29 SQL datasets  
**Pages:** 6

The dashboard consumes exclusively from the Gold layer and provides interactive, filterable analytics. See the [Dashboard Overview](#dashboard-overview) section for full details.

---

### Step 7: Gmail Integration (Planned)

> **Status: NOT YET IMPLEMENTED** — This section describes the planned architecture for email-based alerting and report delivery via Gmail/SMTP integration.

The planned Gmail integration will close the loop on the analytics pipeline by delivering automated notifications and reports to clinical stakeholders:

#### Planned Components

1. **Critical Threshold Alerts**
   - Monitor Gold tables for abnormal/critical rate spikes exceeding configurable thresholds
   - Trigger Gmail notifications when a hospital's daily abnormal rate exceeds the network average by >2 standard deviations
   - Alert payload includes: hospital name, date, abnormal rate, comparison to baseline

2. **Scheduled Report Delivery**
   - Daily summary email to hospital administrators with key KPIs from `hospital_daily_summary`
   - Weekly trend report highlighting month-over-month changes in abnormal rates by test type
   - Patient risk digest for patients with critical test counts above threshold

3. **Implementation Approach (Recommended)**
   - **Option A — Databricks SQL Alerts:** Configure SQL Alerts on Gold table queries with email notification channels. No custom code required.
   - **Option B — Notebook + SMTP:** Create a Python notebook using `smtplib` with Gmail App Password authentication:
     ```
     Notebook: Email_Notifications
     Parameters: alert_type, recipients, threshold
     Flow: Query Gold tables → Format HTML email → Send via Gmail SMTP (smtp.gmail.com:587)
     ```
   - **Option C — Databricks Workflows + Webhook:** Use Lakeflow Jobs with webhook tasks to trigger email via an external service (e.g., SendGrid, Azure Logic Apps).

4. **Integration Points in the Pipeline**
   - Runs after Gold table refresh completes
   - Orchestrated as a downstream task in the Lakeflow Job
   - Conditional execution: only sends alerts when thresholds are breached

---

## Notebook Reference

| Notebook                        | Layer           | Language     | Purpose                                              |
| ------------------------------- | --------------- | ------------ | ---------------------------------------------------- |
| `Landing_to_Bronze`             | Landing → Bronze| Python       | Ingest raw files from UC Volume, add audit metadata, append to Bronze |
| `Bronze_to_Silver`              | Bronze → Silver | Python       | Cleanse and load with FULL/APPEND/MERGE strategies   |
| `Prepare calendar table`        | Silver          | SQL          | Build calendar dimension (1940–2030, 33K rows)       |
| `Gold/NB_patient_360`           | Silver → Gold   | SQL + Python | Patient 360 view joining patients, hospitals, insurance, lab results |
| `Gold/NB_hospital_daily_summary`| Silver → Gold   | SQL + Python | Daily hospital metrics with calendar enrichment      |
| `Gold/NB_lab_test_trends`       | Silver → Gold   | SQL + Python | Monthly lab test aggregation with MoM trend analysis |
| `Gold/sttm_silver_to_gold.xlsx` | Reference       | —            | Source-to-Target Mapping document for Gold transformations |
| `test`                          | Ad-hoc          | SQL          | Scratch notebook for ad-hoc queries and validation   |

---

## Table Inventory

### Bronze Layer (`adb_caresync.bronze`)

Raw data with audit metadata. All tables include `landing_timestamp` and `insert_timestamp`.

| Table                 | Description                                      |
| --------------------- | ------------------------------------------------ |
| `doctors`             | Physician records with hospital assignments      |
| `hospitals`           | Hospital master data (50 hospitals)              |
| `insurance_providers` | Insurance provider catalog (25 providers)        |
| `lab_results`         | Individual lab test results with status           |
| `patients`            | Patient demographics and registration data       |

### Silver Layer (`adb_caresync.silver`)

Cleansed data with `insert_timestamp` and `update_timestamp` audit columns.

| Table                 | Description                                                 |
| --------------------- | ----------------------------------------------------------- |
| `calendar`            | Date dimension (1940–2030, 33,238 rows, 35+ columns)       |
| `doctors`             | Cleansed physician records                                  |
| `hospitals`           | Cleansed hospital master (50 hospitals)                     |
| `insurance_providers` | Cleansed insurance catalog (25 providers: PPO, HMO, Govt)  |
| `lab_results`         | Cleansed lab results with result_status (Normal/Abnormal/Critical) |
| `patients`            | Cleansed patient demographics (5,003 patients, 19 states)  |

### Gold Layer (`adb_caresync.gold`)

Business-ready aggregated tables for analytics and dashboarding.

| Table                    | Rows  | Grain                      | Key Metrics                                                                 |
| ------------------------ | ----- | -------------------------- | --------------------------------------------------------------------------- |
| `patient_360`            | 5,003 | One row per patient        | total_tests, abnormal_test_count, critical_test_count, age, insurance info  |
| `hospital_daily_summary` | 6,711 | One row per hospital/day   | total_tests, unique_patients, abnormal_rate_pct, test_volume_change_pct    |
| `lab_test_trends`        | 78    | One row per test_type/month| abnormal_rate_pct, critical_rate_pct, abnormal_rate_change_pct (MoM)       |

### Table Relationships

```
patient_360.hospital_id  ──────►  hospital_daily_summary.hospital_id
                                  (all 50 hospitals match)

lab_test_trends  ──────  No FK (pre-aggregated by test_name/month)
```

---

## Dashboard Overview

**CareSync Clinical Analytics Dashboard** — 6 pages, 29 datasets, 25+ widgets

### Page 1: Executive Overview
High-level KPIs and trends for leadership:
- **Counters:** Total Patients, Total Lab Tests, Abnormal Rate (%), Critical Rate (%)
- **Charts:** Monthly Test Volume Trend, Top 10 Hospitals by Volume, Abnormal vs Critical Rate Comparison, Test Distribution by Type
- **Table:** Hospital Performance Scorecard (Top 10)

### Page 2: Lab Test Trends & Analysis
Deep-dive into test-type performance over time:
- Monthly Test Volume by Type (line chart)
- Abnormal Rate Trend by Test Type (line chart)
- Critical Rate Trend by Test Type (line chart)
- Month-over-Month Abnormal Rate Change (bar chart)
- Quarterly Test Volume (bar chart)
- Complete Lab Test Summary (table)

### Page 3: Hospital Performance Analysis
Hospital-level benchmarking and operational patterns:
- Hospital Performance Scorecard (table)
- Abnormal Rate by Hospital — Top 15 (bar chart)
- Critical Rate by Hospital — Top 15 (bar chart)
- Weekday vs Weekend Performance (bar chart)
- Day-of-Week Test Volume (bar chart)

### Page 4: Patient Demographics & Risk
Patient population analysis and risk stratification:
- Patients by Age Group (bar chart)
- Gender Distribution (bar chart)
- Top States by Patient Count (bar chart)
- Insurance Provider Distribution
- High-Risk Patient Identification

### Page 5: Global Filters
Cross-dashboard filtering controls:
- Date Range picker
- Hospital multi-select
- Test Type filter
- State filter
- Insurance Provider filter

### Page 6: Cross-Table Insights
Correlation analysis across Gold tables:
- Hospital Patient Load vs Abnormal Rate (scatter plot)
- Additional cross-dimensional analysis widgets

---

## Repository Structure

```
CareSync_ADB_Repo/
├── README.md                          # This file — project documentation
├── Landing_to_Bronze.py               # Landing → Bronze ingestion notebook
├── Bronze_to_Silver.py                # Bronze → Silver cleansing notebook
├── Prepare calendar table.py          # Calendar dimension builder
├── test.py                            # Ad-hoc query notebook
├── Gold/
│   ├── NB_patient_360.py              # Patient 360 gold table builder
│   ├── NB_hospital_daily_summary.py   # Hospital daily summary builder
│   ├── NB_lab_test_trends.py          # Lab test trends builder
│   └── sttm_silver_to_gold.xlsx       # Source-to-Target Mapping document
└── dashboard/
    └── caresync_dashboard_config.json  # Exported dashboard configuration
```

---

## Execution Order

Run the notebooks in this order for a full pipeline refresh:

```
1. Upload source files to /Volumes/adb_caresync/landing/landing_volume/{source}/{table}/{timestamp}/

2. Landing_to_Bronze  (run once per table)
   Parameters: source_system, table_name, landing_timestamp, source_file_format
   Tables: hospitals → patients → doctors → insurance_providers → lab_results

3. Bronze_to_Silver  (run once per table)
   Parameters: landing_timestamp, table_name, merge_keys, load_type
   Tables: hospitals → patients → doctors → insurance_providers → lab_results

4. Prepare calendar table  (run once, or on schema changes)
   No parameters — builds full 1940–2030 calendar

5. Gold/NB_hospital_daily_summary  (depends on silver.lab_results, silver.hospitals, silver.calendar)

6. Gold/NB_lab_test_trends  (depends on silver.lab_results, silver.calendar)

7. Gold/NB_patient_360  (depends on silver.patients, silver.hospitals, silver.insurance_providers, silver.lab_results)

8. Refresh Dashboard  (reads from gold.* tables — no action needed if auto-refresh is configured)

9. [PLANNED] Email_Notifications  (trigger Gmail alerts for threshold breaches)
```

---

## Parameters & Widgets

### Landing_to_Bronze

| Parameter            | Type   | Example                  | Description                          |
| -------------------- | ------ | ------------------------ | ------------------------------------ |
| `source_system`      | String | `hospital_system`        | Name of the upstream source system   |
| `table_name`         | String | `hospitals`              | Target Bronze table name             |
| `landing_timestamp`  | String | `2026-10-08_06:50:38`    | Timestamp folder in landing volume   |
| `source_file_format` | String | `csv` or `parquet`       | File format to read                  |

### Bronze_to_Silver

| Parameter            | Type   | Example                  | Description                                    |
| -------------------- | ------ | ------------------------ | ---------------------------------------------- |
| `landing_timestamp`  | String | `2026-10-08_06:50:38`    | Filter Bronze data to this load batch          |
| `table_name`         | String | `hospitals`              | Source Bronze / target Silver table name       |
| `merge_keys`         | String | `hospital_id`            | Comma-separated keys for MERGE (when load_type=MERGE) |
| `load_type`          | String | `FULL`, `APPEND`, `MERGE`| Write strategy (defaults to FULL if empty)     |

---

## Data Quality & Validation

Each Gold notebook includes a validation step that counts output records and returns the count via `dbutils.notebook.exit()`. Expected record counts:

| Gold Table                | Expected Rows | Validation                                        |
| ------------------------- | ------------- | ------------------------------------------------- |
| `patient_360`             | ~5,003        | One row per patient (matches silver.patients)     |
| `hospital_daily_summary`  | ~6,711        | One row per hospital × test_date combination      |
| `lab_test_trends`         | ~78           | One row per test_name × year-month combination    |

**Built-in data quality checks:**
- Landing_to_Bronze: Validates landing path exists before reading; exits with message if missing
- Bronze_to_Silver (MERGE): Validates all `merge_keys` exist in the source DataFrame
- Gold tables: NULL handling via `COALESCE` for aggregated counts; `CASE WHEN` guards against division by zero in rate calculations
- Calendar dimension: Validated with aggregate check (total rows, min/max dates, distinct years/months)

---

## Deployment & Run Guide

### Prerequisites
- Azure Databricks workspace with Unity Catalog enabled
- Catalog `adb_caresync` with schemas: `landing`, `bronze`, `silver`, `gold`
- External Volume: `adb_caresync.landing.landing_volume`
- Serverless compute or a cluster with access to the catalog

### First-Time Setup

1. **Clone this repository** into your Databricks workspace:
   ```
   Repos → Add Repo → https://github.com/Hrushithar/CareSync_ADB_Repo.git
   ```

2. **Create the Unity Catalog objects** (if not already existing):
   ```sql
   CREATE CATALOG IF NOT EXISTS adb_caresync;
   CREATE SCHEMA IF NOT EXISTS adb_caresync.landing;
   CREATE SCHEMA IF NOT EXISTS adb_caresync.bronze;
   CREATE SCHEMA IF NOT EXISTS adb_caresync.silver;
   CREATE SCHEMA IF NOT EXISTS adb_caresync.gold;
   ```

3. **Upload source data** to the landing volume.

4. **Run the pipeline** in the execution order documented above.

### Incremental Loads

For subsequent data loads:
1. Upload new files to a new `landing_timestamp` folder
2. Run `Landing_to_Bronze` with the new timestamp
3. Run `Bronze_to_Silver` with appropriate `load_type` (use `MERGE` for dimension tables, `APPEND` for facts)
4. Re-run Gold notebooks to refresh aggregations

---

## Future Enhancements

- [ ] **Gmail Integration** — Automated email alerts and scheduled report delivery (see [Step 7](#step-7-gmail-integration-planned))
- [ ] **Lakeflow Jobs Orchestration** — Orchestrate the full pipeline with a multi-task Lakeflow Job with dependency chains
- [ ] **Data Quality Monitoring** — Add Databricks Lakehouse Monitoring for automated data quality tracking
- [ ] **Streaming Ingestion** — Replace batch file drops with Auto Loader for near-real-time ingestion
- [ ] **Patient Risk Scoring** — ML model for predicting abnormal test likelihood based on patient demographics
- [ ] **Historical Trend Analysis** — Extend Gold tables with year-over-year comparisons
- [ ] **RBAC & Row-Level Security** — Implement attribute-based access control for hospital-specific data access

---

## Author

**Hrushith AR**  
GitHub: [@Hrushithar](https://github.com/Hrushithar)

---

*Built with Databricks on Azure · Medallion Architecture · Unity Catalog · AI/BI Dashboards*
