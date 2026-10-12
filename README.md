# Customer Acquisition Marketing 

# Project Overview
The Customer Acquisition Marketing Mix Assessment analyzes marketing spending, customer acquisition, campaign performance, and customer value to support better marketing investment decisions.
The business challenge is to understand which marketing channels bring valuable customers, whether customers return and purchase again, and how an additional ₹25 crore budget could be allocated across channels and interventions.
This project uses Excel, MySQL, and Power BI to clean data, perform analysis, and present findings through interactive dashboards.

# Business Objectives
- Audit and clean marketing and customer data.
- Compare acquisition channels using spend, customers, orders, GMV, and margin.
- Analyze first-order and repeat-order economics.
- Compare first-touch, last-touch, and simplified multi-touch attribution.
- Rank campaigns by spend and examine spend growth against reported conversion growth.
- Analyze customer retention and lifetime value (LTV) by cohort and acquisition channel.
- Compare observed metrics with channel CAC and ROAS targets.
- Explore conservative, base, and aggressive scenarios for an additional ₹25 crore investment.
- Identify where management should consider scaling, reducing, rebalancing, or testing marketing investment.
Tools and Technologies
- Microsoft Excel: Data quality audit, cleaning, validation, and exploratory analysis.
- MySQL: Data aggregation, joins, CTEs, window functions, attribution analysis, and analytical views.
- Microsoft Power BI: Interactive KPI cards, charts, tables, slicers, and dashboards.

# Project Workflow
# 1. Excel: Data Cleaning and Analysis
Data cleaning performed:
- Checked for duplicate records and missing values.
- Reviewed inconsistent channel labels, formatting issues, and unusual values.
- Standardized channel labels by combining Unmatched and Unknown as Unknown for reporting.
- Documented data quality issues instead of automatically treating missing values as zero.
Analysis performed after cleaning:
- Summarized marketing spend by channel to compare how spend was distributed.
- Compared campaign budgets with recorded marketing spend.
- Reviewed channel-level campaign and marketing performance data.
- Organized the cleaned data for further analysis in MySQL and Power BI.
# 2. MySQL: SQL Analysis
The SQL analysis covers:
1. Acquisition-to-LTV funnel: Joined customer, order, retention, marketing spend, and channel target information to compare acquisition and customer value by channel.
2. First-order vs. repeat-order economics: Compared order counts, customers, GMV, margin, average order value, and average margin per order.
3. Campaign ranking and channel contribution: Ranked campaigns by spend and calculated each channel's share and cumulative contribution to total spend.
4. Attribution comparison: Compared first-touch, last-touch, and simplified multi-touch attribution using session and order data.
5. Spend growth vs. conversion growth: Compared month-over-month campaign spend and reported conversion changes to flag campaigns for further review.
SQL techniques used include JOIN, GROUP BY, aggregate functions, CASE WHEN, CTEs (WITH), DENSE_RANK(), LAG(), and window functions.
# 3. MySQL: Analytical Views
Created five reusable analytical views for Power BI:
- vw_executive_growth
- vw_channel_economics
- vw_cohort_retention_ltv
- vw_campaign_performance
- vw_budget_simulator
# 4. Power BI: Interactive Dashboards
Five dashboard pages were created:
1. Executive Growth Scorecard
Provides an overview of acquisition and marketing performance using KPI cards and channel-level comparisons.
2. Channel Economics
Compares channel spending, customer acquisition metrics, GMV, and observed performance against target CAC and ROAS.
3. Cohort Retention & LTV
Explores customer activity, retention, repeat customers, lifetime GMV, and lifetime order behavior by cohort and acquisition channel.
4. Campaign Performance
Compares campaign budgets with spend, ranks campaigns by spend, and displays reported conversions and cost metrics.
5. ₹25 Crore Budget Simulator
Explores proposed additional budget allocation and conservative, base, and aggressive scenarios using assumed ROAS and CAC inputs.

# Business Value
The project provides a structured way to:
- Understand how marketing spend is distributed across channels and campaigns.
- Compare recorded acquisition, order, and customer value metrics.
- Investigate campaigns where spend and reported outcomes move differently.
- Review retention and repeat-purchase patterns.
- Explore budget scenarios before making investment decisions.
- Identify data quality issues that should be resolved before making high-confidence recommendations.
The decision framework is to scale channels with reliable evidence of profitable incremental returns, reduce persistently weak spend, rebalance investment toward stronger opportunities, and test uncertain channels before making larger commitments.
