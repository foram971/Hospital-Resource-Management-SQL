# Hospital Resource Management (SQL & Data Analysis)

SQL Server (SSMS) analysis of hospital operations across **2,506 patient records**, **262 staff members**, **10 departments**, and **2,847 beds** (`Detail data dataset`, `Staff_Detail`, `Department`, and `Bed_Detail`).

## Key Analyses
- **Patient Flow:** Average Length of Stay (LOS) per department, peak admission days (`DATENAME(WEEKDAY, ...)`), and readmission rates overall, by age bucket, and by department.
- **Resource Utilization:** Bed usage by department, total vs. distinct beds used, overall bed occupancy rate, inpatient share by department, staff/patient counts, and underutilized beds (`LEFT JOIN` + `HAVING COUNT(...) < 3`).
- **Operational Efficiency:** ER wait time ranking (`RANK()` vs. `DENSE_RANK()`), ER wait time vs. ratings, average wait time by weekday, staff average ER wait time, and staff patient volume vs. rating.

## Files in This Repository
- `hospital_health_care.sql` — Organized T-SQL queries for exploration, joins, aggregations, window functions, and operational metrics.
- `Hospital  Health Care Management Data set.xlsx` — Source Excel workbook with 4 sheets.
- `Hospital_Health_care.docx` — Full project documentation, import workflow, query outputs, and insights.
