/* ============================================================================
   Project: Hospital Resource Management (SQL Server / T-SQL)
   Prepared by: Foram Shah
   Tables:
     - dbo.[Detail data dataset] (2,506 patient/encounter records)
     - dbo.Department (10 departments)
     - dbo.Staff_Detail (262 staff records)
     - dbo.Bed_Detail (2,847 bed records)
   ============================================================================ */

USE Hospital;

-- 0. Quick Table Checks
SELECT TOP 10 * FROM dbo.[Detail data dataset];
SELECT * FROM dbo.Department ORDER BY Dpt_ID;
SELECT COUNT(*) AS Total_Staff FROM dbo.Staff_Detail;
SELECT COUNT(*) AS Total_Beds FROM dbo.Bed_Detail;


-- ============================================================================
-- 1. PATIENT FLOW ANALYSIS
-- ============================================================================

-- 1A. Average Length of Stay (LOS) per Department
SELECT
    d.Dpt_ID,
    d.Department_Name,
    COUNT(*) AS Total_Encounters,
    ROUND(AVG(CAST(dd.LOS AS FLOAT)), 2) AS Avg_Length_of_Stay
FROM dbo.[Detail data dataset] dd
INNER JOIN dbo.Department d
    ON dd.Dpt_ID = d.Dpt_ID
WHERE dd.LOS IS NOT NULL
GROUP BY d.Dpt_ID, d.Department_Name
ORDER BY Avg_Length_of_Stay DESC;

-- 1B. Peak Admission Days (by Weekday)
SELECT
    DATENAME(WEEKDAY, dd.[Date]) AS Peak_Day,
    COUNT(*) AS Patients_Count
FROM dbo.[Detail data dataset] dd
WHERE dd.[Date] IS NOT NULL
GROUP BY DATENAME(WEEKDAY, dd.[Date])
ORDER BY Patients_Count DESC;

-- 1C. Patient Status Distribution
SELECT
    dd.[Status],
    COUNT(*) AS Status_Count
FROM dbo.[Detail data dataset] dd
GROUP BY dd.[Status]
ORDER BY Status_Count DESC;

-- 1D. Overall Readmission Rate (%)
SELECT
    COUNT(*) AS Total_Admissions,
    SUM(CASE WHEN dd.[Status] = 'Readmit' THEN 1 ELSE 0 END) AS Readmissions,
    ROUND(
        CAST(SUM(CASE WHEN dd.[Status] = 'Readmit' THEN 1 ELSE 0 END) AS FLOAT) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Readmission_Rate_Percent
FROM dbo.[Detail data dataset] dd;

-- 1E. Readmission Rate by Age Bucket
SELECT
    dd.Age_Bucket,
    COUNT(*) AS Total_Patients,
    SUM(CASE WHEN dd.[Status] = 'Readmit' THEN 1 ELSE 0 END) AS Readmissions,
    ROUND(
        CAST(SUM(CASE WHEN dd.[Status] = 'Readmit' THEN 1 ELSE 0 END) AS FLOAT) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Readmission_Rate_Percent
FROM dbo.[Detail data dataset] dd
GROUP BY dd.Age_Bucket
ORDER BY Readmission_Rate_Percent DESC;

-- 1F. Readmission Rate by Department
SELECT
    d.Department_Name,
    COUNT(*) AS No_Of_Patients,
    SUM(CASE WHEN dd.[Status] = 'Readmit' THEN 1 ELSE 0 END) AS Readmit_Count,
    ROUND(
        CAST(SUM(CASE WHEN dd.[Status] = 'Readmit' THEN 1 ELSE 0 END) AS FLOAT) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Readmission_Rate_Percent
FROM dbo.[Detail data dataset] dd
INNER JOIN dbo.Department d
    ON dd.Dpt_ID = d.Dpt_ID
GROUP BY d.Department_Name
ORDER BY Readmission_Rate_Percent DESC;


-- ============================================================================
-- 2. RESOURCE UTILIZATION
-- ============================================================================

-- 2A. Bed Usage and Patient Count by Department
SELECT
    d.Department_Name,
    COUNT(DISTINCT dd.Bed_ID) AS Distinct_Beds_Used,
    COUNT(*) AS Patient_Count
FROM dbo.[Detail data dataset] dd
INNER JOIN dbo.Department d
    ON dd.Dpt_ID = d.Dpt_ID
WHERE dd.Bed_ID IS NOT NULL
GROUP BY d.Department_Name
ORDER BY Distinct_Beds_Used DESC;

-- 2B. Total Unique Beds Available
SELECT COUNT(*) AS Total_Beds
FROM dbo.Bed_Detail;

-- 2C. Distinct Beds Used in Patient Records
SELECT COUNT(DISTINCT Bed_ID) AS Distinct_Beds_Used
FROM dbo.[Detail data dataset]
WHERE Bed_ID IS NOT NULL;

-- 2D. Overall Bed Utilization Rate (%)
SELECT
    COUNT(DISTINCT dd.Bed_ID) AS Distinct_Beds_Used,
    (SELECT COUNT(*) FROM dbo.Bed_Detail) AS Total_Beds,
    CAST(
        COUNT(DISTINCT dd.Bed_ID) * 100.0
        / NULLIF((SELECT COUNT(*) FROM dbo.Bed_Detail), 0)
        AS DECIMAL(5, 2)
    ) AS Bed_Occupancy_Percent
FROM dbo.[Detail data dataset] dd
WHERE dd.Bed_ID IS NOT NULL;

-- 2E. Inpatient Share (%) by Department
SELECT
    d.Department_Name,
    COUNT(*) AS No_Of_Patients,
    SUM(CASE WHEN dd.Patient_type = 'Inpatient' THEN 1 ELSE 0 END) AS Inpatient_Count,
    ROUND(
        CAST(SUM(CASE WHEN dd.Patient_type = 'Inpatient' THEN 1 ELSE 0 END) AS FLOAT) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS Inpatient_Share_Percent
FROM dbo.[Detail data dataset] dd
INNER JOIN dbo.Department d
    ON dd.Dpt_ID = d.Dpt_ID
GROUP BY d.Department_Name
ORDER BY Inpatient_Share_Percent DESC;

-- 2F. Distinct Staff and Patients per Department
SELECT
    dd.Dpt_ID,
    d.Department_Name,
    COUNT(DISTINCT dd.Staff_Id) AS Distinct_Staff_Count,
    COUNT(DISTINCT dd.ID) AS Distinct_Patient_Count
FROM dbo.[Detail data dataset] dd
LEFT JOIN dbo.Department d
    ON dd.Dpt_ID = d.Dpt_ID
GROUP BY dd.Dpt_ID, d.Department_Name
ORDER BY dd.Dpt_ID;

-- 2G. Underutilized Beds (Used Fewer Than 3 Times)
SELECT
    b.Bed_ID,
    b.Bed_Number,
    COUNT(dd.ID) AS Usage_Count
FROM dbo.Bed_Detail b
LEFT JOIN dbo.[Detail data dataset] dd
    ON b.Bed_ID = dd.Bed_ID
GROUP BY b.Bed_ID, b.Bed_Number
HAVING COUNT(dd.ID) < 3
ORDER BY Usage_Count ASC, b.Bed_ID ASC;


-- ============================================================================
-- 3. OPERATIONAL EFFICIENCY & ER WAIT TIMES
-- ============================================================================

-- 3A. Rank Patients by ER Wait Time (RANK vs. DENSE_RANK)
SELECT
    ID,
    [Name],
    ER_Time,
    RANK() OVER (ORDER BY ER_Time DESC) AS ER_Wait_Rank,
    DENSE_RANK() OVER (ORDER BY ER_Time DESC) AS ER_Wait_DenseRank
FROM dbo.[Detail data dataset]
WHERE ER_Time IS NOT NULL
ORDER BY ER_Time DESC, ID ASC;

-- 3B. Average ER Wait Time by Patient Rating
SELECT
    Rating,
    COUNT(*) AS Rated_Patients,
    ROUND(AVG(CAST(ER_Time AS FLOAT)), 2) AS Avg_ER_Wait_Minutes
FROM dbo.[Detail data dataset]
WHERE ER_Time IS NOT NULL
  AND Rating IS NOT NULL
GROUP BY Rating
ORDER BY Avg_ER_Wait_Minutes ASC;

-- 3C. Average ER Wait Time by Weekday
SELECT
    DATENAME(WEEKDAY, [Date]) AS Weekday_Name,
    COUNT(*) AS Encounter_Count,
    ROUND(AVG(CAST(ER_Time AS FLOAT)), 2) AS Avg_ER_Wait_Minutes
FROM dbo.[Detail data dataset]
WHERE ER_Time IS NOT NULL
  AND [Date] IS NOT NULL
GROUP BY DATENAME(WEEKDAY, [Date])
ORDER BY Avg_ER_Wait_Minutes DESC;

-- 3D. Average ER Wait Time by Staff ID
SELECT
    Staff_Id,
    COUNT(*) AS Encounter_Count,
    ROUND(AVG(CAST(ER_Time AS FLOAT)), 2) AS Avg_ER_Wait_Minutes
FROM dbo.[Detail data dataset]
WHERE ER_Time IS NOT NULL
GROUP BY Staff_Id
ORDER BY Avg_ER_Wait_Minutes DESC;

-- 3E. Staff Patient Volume vs. Average Patient Rating
SELECT
    Staff_Id,
    COUNT(ID) AS Patient_Count,
    ROUND(AVG(TRY_CAST(Rating AS FLOAT)), 2) AS Avg_Rating
FROM dbo.[Detail data dataset]
WHERE Rating IS NOT NULL
GROUP BY Staff_Id
ORDER BY Patient_Count DESC, Avg_Rating DESC;
