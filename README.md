# SaaS Revenue & Churn Analysis
SQL + Power BI analysis of churn, retention, and unit economics (CLV/CAC) for a B2B SaaS company

Analysis of customer retention, monthly recurring revenue (MRR), and unit economics for a fictional B2B SaaS company (CloudTask Pro), built to support a board presentation on churn trends and growth levers.

**Stack:** SQL (MySQL) · Power BI

---

## Context

CloudTask Pro is a B2B SaaS company (project management software) that has grown from 0 to 600 customers since 2022. The board is concerned about a high churn rate. This analysis answers four business questions:

1. What is the overall churn rate, and how has it trended over the past 4 years?
2. Which subscription plan and billing cycle have the biggest impact on retention?
3. What are the top reasons customers churn, and do they differ by plan or company size?
4. What is the Customer Lifetime Value (CLV) by plan, compared to Customer Acquisition Cost (CAC)?

A fifth section identifies active customers at risk of churning, based on their product engagement level.

---

## Dashboard overview

The Power BI dashboard is organized into 3 pages:

| Page | Content |
|---|---|
| **Overview** | Overall churn rate, % of active customers at risk, monthly churn trend over 4 years, churn by plan and billing cycle |
| **Churn Drivers** | Top churn reasons, and how their relative weight differs by plan and company size |
| **Unit Economics & Risk** | CLV and CLV:CAC ratio by plan, customer base breakdown (Healthy / At Risk / Churned) |

*(Screenshots of the 3 pages available in `/dashboard/screenshots`)*

---

## Methodology & key decisions

A few methodological choices were made to ensure the analysis is reliable — documented here rather than left implicit:

- **Churn rate by segment**: defined as `churned customers in segment / total customers who ever belonged to the segment` (not `/ total customer base`), to avoid under-weighting smaller segments like Enterprise.
- **Overall churn rate (52.17%)** vs **average monthly churn rate (~3.9%)**: two distinct metrics, calculated on different denominators (cumulative over 4 years vs. monthly average). Both are presented separately to avoid confusion.
- **Uniform CAC across plans**: the dataset only provides a company-wide average monthly CAC, not segmented by plan. The same CAC (~$200) was therefore applied across all 4 plans to compute the CLV:CAC ratio — a simplifying assumption documented directly in the dashboard. The relative ranking across plans is expected to hold, but the exact magnitude of the ratios (particularly the 438:1 figure for Enterprise) should be read directionally, as acquiring an Enterprise customer is likely more expensive in reality.
- **At-risk threshold (< 35% feature usage)**: justified by the data itself — already-churned customers show an average usage of 27.5%, vs. 55% for active customers. The 35% threshold captures active customers trending toward the churned profile before they actually churn.
- **Data cleaning**: handled empty strings (`''`) distinct from `NULL` on `churn_date`/`churn_reason`, converted text-based dates to proper `DATE` type, and fixed numeric values corrupted during CSV export (decimal separator loss, resolved via SQL casting + Power Query reconversion with explicit locale).

---

## Key findings

- **Overall churn rate: 52.17%** (cumulative since 2022) — **average monthly churn: ~3.9%**, improving steadily since 2022 (6.8% → 3.6%), with a plateau since 2024.
- **Starter** has the highest churn rate (70.5%), **Enterprise** the lowest (22%). Annual billing retains better than monthly (40.3% vs. 60.5%), though likely partly explained by a self-selection bias.
- **Top 3 churn reasons**: Budget Cuts, Price Too High, Company Closed. Pricing dominates on entry-level plans; missing features dominates on Business; poor support is the #1 driver for accounts with 500+ employees.
- **Enterprise** has the best CLV:CAC ratio (438:1), driven by a much longer customer lifespan and higher monthly revenue — to be read with the CAC caveat noted above.
- **23.3% of active customers** are currently flagged as at risk of churning.



