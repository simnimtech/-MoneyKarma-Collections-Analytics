# MoneyKarma Collections Analytics

## Project Overview

This project analyses collections and payment data to understand whether
the reported **11% month-on-month improvement in recovery** is supported
by the data.

The work focuses on: 1. Understanding the actual recovery trend. 2.
Checking data quality and possible drivers of collections performance.
3. Recommending a practical next step based on the available evidence.

The datasets cover accounts, borrowers, payments, calls, agents,
campaigns, digital interactions, field visits and promises-to-pay
(PTPs).

## Business Questions

-   **What happened?** How did recovery change over time?
-   **Why did it happen?** What do portfolio, DPD, risk segment, loan
    type, campaign and channel comparisons show?
-   **Is the 11% improvement real?** Does the payment data support
    sustained improvement?
-   **Where should ₹10 Cr be invested?** What is the most reasonable
    direction given the evidence and its limitations?

## Key Findings So Far

  Measure                                                        Finding
  ----------------------------------------------- ----------------------
  Successful payment amount                                   ₹131.56 Cr
  Cleaned payment records                                         25,000
  Accounts analysed                                               30,000
  Accounts with at least one successful payment                   13,284
  Account recovery coverage                                       44.28%
  Resolved PTP kept rate                                          49.65%
  March 2026 month-on-month recovery change                      +11.03%
  January--July 2026 total recovery change          Approximately +0.01%

**Main takeaway:** March showed an increase of approximately 11.03%
compared with February. However, the January--July trend was essentially
flat. The available analysis therefore does not support a claim of
sustained 11% month-on-month improvement.

August 2026 is partial in the analysed data and is not treated as a
full-month comparison.

## Data Quality Investigation

Data quality is important because duplicated or inconsistent records can
distort collections performance.

Issues identified so far include:

-   500 duplicate payment records were removed during cleaning.
-   Payment references were not consistently unique and should not be
    used alone as transaction identifiers.
-   Some accounts had missing borrower IDs.
-   Borrower IDs had conflicting identity or location information.
-   Agent IDs mapped to multiple employee, vendor or team identities.
-   Call and call-disposition records had account-matching issues.
-   SMS and WhatsApp event identifiers were not always reliable for
    account-level attribution.
-   Some complaint and account-status timestamps were inconsistent.

These issues limit the reliability of some comparisons, especially
geography, agent productivity, vendor performance and channel
attribution.

## Tools and Technologies

-   **Python:** data cleaning and preparation
-   **SQL / SQLite:** data storage, querying and analysis
-   **Tableau:** data visualisation and dashboard development
-   **CSV:** cleaned datasets and analysis outputs

## Project Structure

The working project is organised into the following folders (the exact
files included in this repository may vary):

``` text
MoneyKarma-Collections-Analytics/
├── Data/
│   ├── Raw/
│   └── Cleaned/
├── Notebooks/
├── SQL/
├── Outputs/
├── Dashboard/
└── README.md
```

-   `Data/Raw/` -- original input data, where permitted.
-   `Data/Cleaned/` -- prepared datasets used for analysis.
-   `Notebooks/` -- Python-based cleaning and investigation.
-   `SQL/` -- SQL queries used for analysis.
-   `Outputs/` -- exported tables and analysis results.
-   `Dashboard/` -- Tableau dashboard files or screenshots, if included.

## Preliminary Investment Direction

The preliminary recommendation is to prioritise **better borrower
targeting**, supported by stronger data quality and account-level
measurement.

This is a direction for further testing, not a proven financial
forecast. The current analysis does not support a reliable numerical
estimate of incremental recovery, ROI or break-even. A controlled pilot
should compare improved targeting with the existing approach before the
full ₹10 Cr is committed.

## Limitations and Next Steps

This is an interim analysis. The work completed so far does not fully
establish the cause of monthly recovery changes.

Further work should include: - Completing the full 12-month recovery
reconstruction. - Investigating client, language, calling time and
attempt frequency. - Resolving borrower, agent and vendor identity
mappings. - Validating payment attribution and operational cost data. -
Testing targeting changes through a controlled experiment. - Estimating
incremental recovery and ROI from measured pilot results.

Observed differences between segments or channels are descriptive and
should not be interpreted as proof of cause and effect.

## Conclusion

This project takes an evidence-first approach to collections analytics.
Rather than accepting the reported 11% improvement at face value, it
independently examines successful payments, account recovery coverage,
PTP outcomes and data quality.

The current evidence identifies an isolated March increase, an
essentially flat January--July recovery trend and several data
limitations that should be resolved before major operational or
investment decisions are made.
