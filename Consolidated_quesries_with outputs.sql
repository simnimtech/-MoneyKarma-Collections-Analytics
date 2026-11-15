CREATE DATABASE IF NOT EXISTS collections_analytics;

USE collections_analytics;
SHOW DATABASES;
USE collections_analytics;

-- 1. ACCOUNTS
CREATE TABLE IF NOT EXISTS accounts (
    account_id VARCHAR(20),
    borrower_id VARCHAR(20),
    loan_type VARCHAR(30),
    principal_amount DECIMAL(14,2),
    outstanding_amount DECIMAL(14,2),
    dpd INT,
    risk_segment VARCHAR(20),
    status VARCHAR(30),
    opened_at DATETIME,
    timezone VARCHAR(50),
    schema_version VARCHAR(10),
    outstanding_above_principal_flag BOOLEAN,
    borrower_id_missing_flag BOOLEAN
);

-- 2. BORROWERS
CREATE TABLE IF NOT EXISTS borrowers (
    borrower_id VARCHAR(20),
    name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(150),
    city VARCHAR(100),
    created_at DATETIME,
    updated_at DATETIME,
    state VARCHAR(100),
    phone_missing BOOLEAN,
    email_missing BOOLEAN,
    timestamp_inconsistent BOOLEAN
);

-- 3. PAYMENTS
CREATE TABLE IF NOT EXISTS payments (
    payment_id VARCHAR(30),
    account_id VARCHAR(20),
    borrower_id VARCHAR(20),
    event_at DATETIME,
    payment_reference VARCHAR(50),
    amount DECIMAL(14,2),
    payment_status VARCHAR(30),
    payment_method VARCHAR(30),
    provider_id VARCHAR(20)
);
SHOW TABLES;

USE collections_analytics;

SHOW TABLES;
-- Add your queries here query1.sql

SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'main'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
SELECT COUNT(*) AS total_accounts
FROM "accounts_cleaned.csv";

SELECT *
FROM "payments_cleaned.csv"
LIMIT 10;

--monthly recovery
SELECT
    STRFTIME(TRY_CAST(event_at AS TIMESTAMP), '%Y-%m') AS month,
    COUNT(*) AS successful_transactions,
    ROUND(SUM(amount), 2) AS total_recovery
FROM "payments_cleaned.csv"
WHERE UPPER(payment_status) = 'SUCCESS'
GROUP BY 1
ORDER BY 1;

--MONEYKARMA COLLECTIONS ANALYTICS
--Analysis 01: Monthly Recovery Trend
--Objective: Validate the reported 11% month-on-month recovery improvement.

SELECT
    STRFTIME(TRY_CAST(event_at AS TIMESTAMP), '%Y-%m') AS month,
    ROUND(SUM(amount), 2) AS total_recovery
FROM "payments_cleaned.csv"
WHERE UPPER(TRIM(payment_status)) = 'SUCCESS'
GROUP BY 1
ORDER BY 1;

--month	total_recovery
2026-01	18,72,29,127.59
2026-02	17,01,42,453.76
2026-03	18,89,12,374.02
2026-04	17,51,38,043.41
2026-05	18,42,50,278.50
2026-06	17,55,59,726.97
2026-07	18,72,42,265.08
2026-08	4,71,09,695.31--

--here the monthly sales shows no such improvments
--Key finding: March alone recorded approximately 11% growth. From January to July, 
--total monthly recovery increased by just 0.01% — effectively flat. August is incomplete, so exclude it from the comparison.

--04_recovery_coverage.sql 
SELECT
    COUNT(*) AS total_accounts,
    COUNT(DISTINCT p.account_id) AS accounts_with_recovery,
    ROUND(
        100.0 * COUNT(DISTINCT p.account_id) / COUNT(*), 2
    ) AS recovery_coverage_pct
FROM "accounts_cleaned.csv" a
LEFT JOIN (
    SELECT DISTINCT account_id
    FROM "payments_cleaned.csv"
    WHERE UPPER(TRIM(payment_status)) = 'SUCCESS'
) p
ON a.account_id = p.account_id;

--output total_accounts	accounts_with_recovery	recovery_coverage_pct
30,000	13,284 44.28
--Only 44.28% of accounts generated at least one successful payment.

--Total accounts: 30,000
--Accounts with recovery: 13,284
--Accounts without recovery: 16,716 (55.72%)

--05_dpd_recovery_analysis.sql
SELECT
    a.dpd,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    COUNT(DISTINCT p.account_id) AS recovered_accounts,
    ROUND(
        100.0 * COUNT(DISTINCT p.account_id)
        / COUNT(DISTINCT a.account_id), 2
    ) AS recovery_coverage_pct
FROM "accounts_cleaned.csv" a
LEFT JOIN (
    SELECT DISTINCT account_id
    FROM "payments_cleaned.csv"
    WHERE UPPER(TRIM(payment_status)) = 'SUCCESS'
) p ON a.account_id = p.account_id
GROUP BY a.dpd
ORDER BY a.dpd;

--The recovery coverage across DPD values is quite stable.
--Key findings: Highest coverage: DPD 45 — 45.81%, Lowest coverage: DPD 1 — 42.79%, Overall range: just 3.02 percentage points.

--06_loan_type_recovery.sql.
SELECT
    a.loan_type,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    COUNT(DISTINCT p.account_id) AS recovered_accounts,
    ROUND(
        100.0 * COUNT(DISTINCT p.account_id)
        / COUNT(DISTINCT a.account_id), 2
    ) AS recovery_coverage_pct
FROM "accounts_cleaned.csv" a
LEFT JOIN (
    SELECT DISTINCT account_id
    FROM "payments_cleaned.csv"
    WHERE UPPER(TRIM(payment_status)) = 'SUCCESS'
) p ON a.account_id = p.account_id
GROUP BY a.loan_type
ORDER BY recovery_coverage_pct DESC;

--Loan type coverage is also quite similar. 
--output
Highest: CONSUMER — 45.28%, Lowest: BNPL — 43.52%, Difference: only 1.76 percentage points.
--Insight: Loan type does not appear to be a major differentiator in recovery coverage.


--Recovery by geography
DESCRIBE "accounts_cleaned.csv";
DESCRIBE "borrowers_cleaned.csv";


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT borrower_id) AS unique_borrowers
FROM "borrowers_cleaned.csv";


--duplicateids completing with location
SELECT
    COUNT(*) AS duplicate_borrower_ids,
    SUM(CASE WHEN city_count > 1 OR state_count > 1 THEN 1 ELSE 0 END)
        AS conflicting_location_ids
FROM (
    SELECT
        borrower_id,
        COUNT(DISTINCT city) AS city_count,
        COUNT(DISTINCT state) AS state_count
    FROM "borrowers_cleaned.csv"
    WHERE borrower_id IS NOT NULL
    GROUP BY borrower_id
    HAVING COUNT(*) > 1
) x;

---output
---duplicate_borrower_ids	conflicting_location_ids
8,518	8,159
---This confirms a major data-quality issue. Duplicate borrower IDs: 8,518, IDs with conflicting city/state: 8,159 Business insight: Geographical recovery analysis is unreliable with the current borrower mapping. We should flag this rather than force a join.---



---recovery by risk segment
SELECT
    a.risk_segment,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    COUNT(DISTINCT p.account_id) AS recovered_accounts,
    ROUND(
        100.0 * COUNT(DISTINCT p.account_id)
        / COUNT(DISTINCT a.account_id), 2
    ) AS recovery_coverage_pct
FROM "accounts_cleaned.csv" a
LEFT JOIN (
    SELECT DISTINCT account_id
    FROM "payments_cleaned.csv"
    WHERE UPPER(TRIM(payment_status)) = 'SUCCESS'
) p ON a.account_id = p.account_id
GROUP BY a.risk_segment
ORDER BY recovery_coverage_pct DESC;

---output
---risk_segment	total_accounts	recovered_accounts	recovery_coverage_pct
LOW	7,513	3,381	45.00
MEDIUM	7,533	3,335	44.27
NPA	7,402	3,268	44.15
HIGH	7,552	3,300	43.70



---ppt performanace
SELECT
    UPPER(TRIM(status)) AS ptp_status,
    COUNT(*) AS total_ptps,
    COUNT(DISTINCT account_id) AS unique_accounts
FROM "ptp_cleaned.csv"
GROUP BY 1
ORDER BY 2 DESC;

---output
ptp_status	total_ptps	unique_accounts
BROKEN	4,553	4,268
CANCELLED	4,543	4,219
KEPT	4,489	4,164
OPEN	4,415	4,093

---ptp_performance.sql
SELECT
    COUNT(*) AS resolved_ptps,
    SUM(CASE WHEN UPPER(TRIM(status)) = 'KEPT' THEN 1 ELSE 0 END) AS kept_ptps,
    ROUND(
        100.0 * SUM(CASE WHEN UPPER(TRIM(status)) = 'KEPT' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS ptp_kept_rate
FROM "ptp_cleaned.csv"
WHERE UPPER(TRIM(status)) IN ('KEPT', 'BROKEN');

---output
resolved_ptps	kept_ptps	ptp_kept_rate
9,042	4,489	49.65


---ppt performance by source
SELECT
    UPPER(TRIM(source)) AS channel,
    COUNT(*) AS total_ptps,
    SUM(CASE WHEN UPPER(TRIM(status)) = 'KEPT' THEN 1 ELSE 0 END) AS kept,
    ROUND(
        100.0 * SUM(CASE WHEN UPPER(TRIM(status)) = 'KEPT' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS kept_rate_pct
FROM "ptp_cleaned.csv"
WHERE UPPER(TRIM(status)) IN ('KEPT', 'BROKEN')
GROUP BY 1
ORDER BY kept_rate_pct DESC;

---output
channel	total_ptps	kept	kept_rate_pct
CALL	2,345	1,176	50.15
SMS	2,282	1,140	49.96
WHATSAPP	2,149	1,059	49.28
FIELD	2,266	1,114	49.16
---Insight: No channel clearly outperforms the others. CALL leads, but by less than 1 percentage point over FIELD.



--- analyse campaign performance.  
SELECT
    campaign_id,
    COUNT(*) AS total_attempts,
    COUNT(DISTINCT account_id) AS accounts_targeted
FROM "daily_targeting_cleaned.csv"
GROUP BY campaign_id
ORDER BY total_attempts DESC
LIMIT 10;

---output
campaign_id	total_attempts	accounts_targeted
CMP0000109	399	397
CMP0000093	417	414
CMP0000088	406	403
CMP0000082	403	402
CMP0000042	399	398
CMP0000041	402	400
CMP0000029	404	401
CMP0000023	421	417
CMP0000021	397	395
CMP0000021	397	395
Query duration: 65ms


DESCRIBE "daily_targeting_cleaned.csv";

---campaign analysis
SELECT
    d.campaign_id,
    COUNT(DISTINCT d.account_id) AS targeted_accounts,
    COUNT(DISTINCT p.account_id) AS recovered_accounts,
    ROUND(
        100.0 * COUNT(DISTINCT p.account_id)
        / COUNT(DISTINCT d.account_id), 2
    ) AS recovery_coverage_pct
FROM "daily_targeting_cleaned.csv" d
LEFT JOIN (
    SELECT DISTINCT account_id
    FROM "payments_cleaned.csv"
    WHERE UPPER(TRIM(payment_status)) = 'SUCCESS'
) p ON d.account_id = p.account_id
GROUP BY d.campaign_id
ORDER BY recovery_coverage_pct DESC
LIMIT 10;


---analyse recommended channels
SELECT
    d.recommended_channel,
    COUNT(DISTINCT d.account_id) AS targeted_accounts,
    COUNT(DISTINCT p.account_id) AS recovered_accounts,
    ROUND(
        100.0 * COUNT(DISTINCT p.account_id)
        / COUNT(DISTINCT d.account_id), 2
    ) AS recovery_coverage_pct
FROM "daily_targeting_cleaned.csv" d
LEFT JOIN (
    SELECT DISTINCT account_id
    FROM "payments_cleaned.csv"
    WHERE UPPER(TRIM(payment_status)) = 'SUCCESS'
) p ON d.account_id = p.account_id
GROUP BY d.recommended_channel
ORDER BY recovery_coverage_pct DESC;

---output

recommended_channel	targeted_accounts	recovered_accounts	recovery_coverage_pct
SMS	9,360	4,201	44.88
WHATSAPP	9,363	4,157	44.40
FIELD	9,493	4,196	44.20
VOICE	9,393	4,137	44.04
Recommended-channel coverage is very close.

* SMS: 44.88%
* WhatsApp: 44.40%
* Field: 44.20%
* Voice: 44.04%

Insight: SMS leads, but the difference is less than 1 percentage point. Don’t recommend shifting the entire budget to SMS based on this alone.


---Data quality — payment duplicates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT payment_id) AS unique_payment_ids,
    COUNT(*) - COUNT(DISTINCT payment_id) AS duplicate_rows
FROM "payments_cleaned.csv";

---output
total_rows	unique_payment_ids	duplicate_rows
25,000	25,000	0


--any missing payment id

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN payment_id IS NULL THEN 1 ELSE 0 END) AS missing_payment_ids,
    SUM(CASE WHEN account_id IS NULL THEN 1 ELSE 0 END) AS missing_account_ids,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS missing_amounts
FROM "payments_cleaned.csv";

--output

total_rows	missing_payment_ids	missing_account_ids	missing_amounts
25,000	0	0	0