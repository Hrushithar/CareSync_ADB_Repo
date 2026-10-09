-- =============================================================================
-- CareSync Clinical Analytics Dashboard - Dataset Queries
-- =============================================================================
-- Dashboard: CareSync Clinical Analytics Dashboard
-- UUID: 01f1c3a056731556b9ce46e287e3e3b6
-- Pages: 6 | Datasets: 29 | Widgets: 25+
-- Source Tables: adb_caresync.gold.{patient_360, hospital_daily_summary, lab_test_trends}
-- =============================================================================

-- =============================================================================
-- PAGE 1: Executive Overview
-- =============================================================================

-- Dataset: Executive Patient KPIs
SELECT
  COUNT(DISTINCT patient_id) AS total_patients,
  ROUND(AVG(total_tests), 2) AS avg_tests_per_patient
FROM
  adb_caresync.gold.patient_360;

-- Dataset: Executive Hospital KPIs
SELECT
  SUM(total_tests) AS total_tests,
  ROUND(SUM(abnormal_test_count) * 100.0 / SUM(total_tests), 1) AS abnormal_rate_pct,
  ROUND(SUM(critical_test_count) * 100.0 / SUM(total_tests), 1) AS critical_rate_pct,
  COUNT(DISTINCT hospital_id) AS total_hospitals
FROM
  adb_caresync.gold.hospital_daily_summary;

-- Dataset: Monthly Test Volume Trend
SELECT
  DATE_TRUNC('month', summary_date) AS month,
  SUM(total_tests) AS total_tests,
  SUM(abnormal_test_count) AS abnormal_tests,
  SUM(critical_test_count) AS critical_tests
FROM
  adb_caresync.gold.hospital_daily_summary
GROUP BY
  1
ORDER BY
  1;

-- Dataset: Monthly Abnormal & Critical Rate Trend
SELECT
  DATE_TRUNC('month', summary_date) AS month,
  ROUND(SUM(abnormal_test_count) * 100.0 / SUM(total_tests), 2) AS abnormal_rate_pct,
  ROUND(SUM(critical_test_count) * 100.0 / SUM(total_tests), 2) AS critical_rate_pct
FROM
  adb_caresync.gold.hospital_daily_summary
GROUP BY
  1
ORDER BY
  1;

-- Dataset: Test Distribution by Lab Type
SELECT
  test_name,
  SUM(total_tests) AS total_tests
FROM
  adb_caresync.gold.lab_test_trends
GROUP BY
  test_name
ORDER BY
  total_tests DESC;

-- Dataset: Top 10 Hospitals by Volume
SELECT
  hospital_name,
  SUM(total_tests) AS total_tests
FROM
  adb_caresync.gold.hospital_daily_summary
GROUP BY
  hospital_name
ORDER BY
  total_tests DESC
LIMIT 10;

-- =============================================================================
-- PAGE 2: Lab Test Trends & Analysis
-- =============================================================================

-- Dataset: Monthly Test Volume by Type (2025)
SELECT
  test_name,
  MAKE_DATE(year, month, 1) AS test_month,
  total_tests
FROM
  adb_caresync.gold.lab_test_trends
WHERE
  year = 2025
ORDER BY
  test_name,
  test_month;

-- Dataset: Abnormal Rate Trend by Test Type (2025)
SELECT
  test_name,
  MAKE_DATE(year, month, 1) AS test_month,
  abnormal_rate_pct
FROM
  adb_caresync.gold.lab_test_trends
WHERE
  year = 2025
ORDER BY
  test_name,
  test_month;

-- Dataset: Critical Rate Trend by Test Type (2025)
SELECT
  test_name,
  MAKE_DATE(year, month, 1) AS test_month,
  critical_rate_pct
FROM
  adb_caresync.gold.lab_test_trends
WHERE
  year = 2025
ORDER BY
  test_name,
  test_month;

-- Dataset: Month-over-Month Abnormal Rate Change (2025)
-- (Query uses lab_test_trends with abnormal_rate_change_pct)

-- Dataset: Quarterly Test Volume (2025)
-- (Query aggregates lab_test_trends by quarter_name)

-- Dataset: Complete Lab Test Summary
-- (Full summary from lab_test_trends)

-- =============================================================================
-- PAGE 3: Hospital Performance Analysis
-- =============================================================================

-- Dataset: Hospital Performance Scorecard
SELECT
  hospital_name,
  COUNT(DISTINCT summary_date) AS days_active,
  SUM(total_tests) AS total_tests,
  SUM(unique_patients_tested) AS total_patients_tested,
  SUM(abnormal_test_count) AS abnormal_tests,
  SUM(critical_test_count) AS critical_tests,
  ROUND(SUM(abnormal_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS abnormal_rate_pct,
  ROUND(SUM(critical_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS critical_rate_pct,
  ROUND(AVG(active_doctor_count), 1) AS avg_doctors
FROM
  adb_caresync.gold.hospital_daily_summary
GROUP BY
  hospital_name
ORDER BY
  total_tests DESC;

-- Dataset: Top 15 Hospitals by Abnormal Rate
SELECT
  hospital_name,
  ROUND(SUM(abnormal_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS abnormal_rate_pct
FROM
  adb_caresync.gold.hospital_daily_summary
GROUP BY
  hospital_name
ORDER BY
  abnormal_rate_pct DESC
LIMIT 15;

-- Dataset: Top 15 Hospitals by Critical Rate
SELECT
  hospital_name,
  ROUND(SUM(critical_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS critical_rate_pct
FROM
  adb_caresync.gold.hospital_daily_summary
GROUP BY
  hospital_name
ORDER BY
  critical_rate_pct DESC
LIMIT 15;

-- Dataset: Weekday vs Weekend Performance
SELECT
  CASE
    WHEN is_weekend THEN 'Weekend'
    ELSE 'Weekday'
  END AS day_type,
  SUM(total_tests) AS total_tests,
  ROUND(SUM(abnormal_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS abnormal_rate_pct,
  ROUND(SUM(critical_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS critical_rate_pct
FROM
  adb_caresync.gold.hospital_daily_summary
GROUP BY
  1;

-- Dataset: Day-of-Week Test Volume
SELECT
  day_name,
  SUM(total_tests) AS total_tests,
  ROUND(SUM(abnormal_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS abnormal_rate_pct
FROM
  adb_caresync.gold.hospital_daily_summary
GROUP BY
  day_name
ORDER BY
  CASE day_name
    WHEN 'Monday' THEN 1
    WHEN 'Tuesday' THEN 2
    WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4
    WHEN 'Friday' THEN 5
    WHEN 'Saturday' THEN 6
    WHEN 'Sunday' THEN 7
  END;

-- =============================================================================
-- PAGE 4: Patient Demographics & Risk
-- =============================================================================

-- Dataset: Patients by Age Group
SELECT
  CASE
    WHEN age < 18 THEN '0-17 (Pediatric)'
    WHEN age BETWEEN 18 AND 30 THEN '18-30 (Young Adult)'
    WHEN age BETWEEN 31 AND 45 THEN '31-45 (Adult)'
    WHEN age BETWEEN 46 AND 60 THEN '46-60 (Middle Age)'
    ELSE '61+ (Senior)'
  END AS age_group,
  COUNT(*) AS patient_count,
  SUM(total_tests) AS total_tests,
  ROUND(SUM(abnormal_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS abnormal_rate_pct,
  ROUND(SUM(critical_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS critical_rate_pct
FROM
  adb_caresync.gold.patient_360
GROUP BY
  1
ORDER BY
  1;

-- Dataset: Gender Distribution & Outcomes
SELECT
  gender,
  COUNT(*) AS patient_count,
  SUM(total_tests) AS total_tests,
  SUM(abnormal_test_count) AS abnormal_tests,
  ROUND(SUM(abnormal_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS abnormal_rate_pct,
  ROUND(SUM(critical_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS critical_rate_pct
FROM
  adb_caresync.gold.patient_360
GROUP BY
  gender;

-- Dataset: Top 15 States by Patient Count
SELECT
  state,
  COUNT(*) AS patient_count,
  SUM(total_tests) AS total_tests,
  ROUND(SUM(abnormal_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS abnormal_rate_pct
FROM
  adb_caresync.gold.patient_360
GROUP BY
  state
ORDER BY
  patient_count DESC
LIMIT 15;

-- Dataset: Insurance Provider Comparison
SELECT
  insurance_provider_name,
  COUNT(*) AS patient_count,
  SUM(total_tests) AS total_tests,
  ROUND(SUM(abnormal_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS abnormal_rate_pct,
  ROUND(SUM(critical_test_count) * 100.0 / NULLIF(SUM(total_tests), 0), 2) AS critical_rate_pct
FROM
  adb_caresync.gold.patient_360
GROUP BY
  insurance_provider_name
ORDER BY
  abnormal_rate_pct DESC;

-- Dataset: High-Risk Patients (Top 50)
SELECT
  patient_id,
  first_name,
  last_name,
  age,
  gender,
  hospital_name,
  insurance_provider_name,
  total_tests,
  abnormal_test_count,
  critical_test_count,
  ROUND(abnormal_test_count * 100.0 / NULLIF(total_tests, 0), 2) AS abnormal_rate_pct,
  last_test_date
FROM
  adb_caresync.gold.patient_360
WHERE
  abnormal_test_count > 0
ORDER BY
  abnormal_test_count DESC,
  critical_test_count DESC
LIMIT 50;

-- =============================================================================
-- PAGE 5: Global Filters
-- =============================================================================
-- Filter widgets: Date Range, Hospital, Test Type, State, Insurance Provider
-- These use a combined filter dataset from hospital_daily_summary

-- =============================================================================
-- PAGE 6: Cross-Table Insights
-- =============================================================================

-- Dataset: Hospital Patient Load vs Abnormal Rate (Scatter Plot)
-- Combines patient counts from patient_360 with hospital metrics
-- from hospital_daily_summary for correlation analysis
