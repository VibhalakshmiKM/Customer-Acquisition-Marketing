use customer;
#Executive Growth Scorecard
CREATE OR REPLACE VIEW vw_executive_growth AS

WITH channel_list AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel
    FROM marketing_spend

    UNION

    SELECT
        CASE
            WHEN source IN ('Unmatched', 'Unknown')
                 OR source IS NULL
            THEN 'Unknown'
            ELSE source
        END AS channel
    FROM orders
),

spend_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        SUM(spend) AS total_spend,
        SUM(impressions) AS total_impressions,
        SUM(clicks) AS total_clicks,
        SUM(conversions) AS total_conversions
    FROM marketing_spend
    GROUP BY
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END
),

campaign_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        COUNT(DISTINCT campaign_id) AS total_campaigns,
        SUM(budget) AS total_campaign_budget
    FROM marketing_campaigns
    GROUP BY
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END
),

customer_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM customers
    GROUP BY
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END
),

order_summary AS (
    SELECT
        CASE
            WHEN source IN ('Unmatched', 'Unknown')
                 OR source IS NULL
            THEN 'Unknown'
            ELSE source
        END AS channel,
        COUNT(*) AS total_orders,
        COUNT(DISTINCT customer_id) AS ordering_customers,
        SUM(gmv) AS total_gmv,
        AVG(margin) AS avg_margin
    FROM orders
    GROUP BY
        CASE
            WHEN source IN ('Unmatched', 'Unknown')
                 OR source IS NULL
            THEN 'Unknown'
            ELSE source
        END
),

target_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        MAX(target_cac) AS target_cac,
        MAX(target_roas) AS target_roas
    FROM channel_targets
    GROUP BY
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END
)

SELECT
    cl.channel,
    COALESCE(cs.total_customers, 0) AS total_customers,
    COALESCE(ss.total_spend, 0) AS total_spend,
    COALESCE(ss.total_clicks, 0) AS total_clicks,
    COALESCE(ss.total_impressions, 0) AS total_impressions,
    COALESCE(ss.total_conversions, 0) AS total_conversions,
    COALESCE(cps.total_campaigns, 0) AS total_campaigns,
    COALESCE(cps.total_campaign_budget, 0)
        AS total_campaign_budget,
    COALESCE(os.total_orders, 0) AS total_orders,
    COALESCE(os.ordering_customers, 0) AS ordering_customers,
    COALESCE(os.total_gmv, 0) AS total_gmv,

    ROUND(
        COALESCE(os.avg_margin, 0),
        2
    ) AS avg_margin,

    ROUND(
        100.0 * COALESCE(ss.total_spend, 0)
        / NULLIF(cps.total_campaign_budget, 0),
        2
    ) AS budget_utilization_pct,

    ROUND(
        COALESCE(ss.total_spend, 0)
        / NULLIF(cs.total_customers, 0),
        2
    ) AS observed_spend_per_customer,

    ROUND(
        COALESCE(os.total_gmv, 0)
        / NULLIF(ss.total_spend, 0),
        2
    ) AS observed_roas_proxy,

    ts.target_cac,
    ts.target_roas

FROM channel_list cl

LEFT JOIN spend_summary ss
    ON cl.channel = ss.channel

LEFT JOIN campaign_summary cps
    ON cl.channel = cps.channel

LEFT JOIN customer_summary cs
    ON cl.channel = cs.channel

LEFT JOIN order_summary os
    ON cl.channel = os.channel

LEFT JOIN target_summary ts
    ON cl.channel = ts.channel;

#• Channel Economics
CREATE OR REPLACE VIEW vw_channel_economics AS

WITH channel_list AS (
    SELECT channel FROM marketing_spend
    UNION
    SELECT channel FROM marketing_campaigns
    UNION
    SELECT channel FROM channel_targets
    UNION
    SELECT channel FROM customers
    UNION
    SELECT source AS channel FROM orders
),

normalized_channels AS (
    SELECT DISTINCT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel
    FROM channel_list
),

spend_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        SUM(spend) AS total_spend,
        SUM(impressions) AS total_impressions,
        SUM(clicks) AS total_clicks,
        SUM(conversions) AS total_conversions
    FROM marketing_spend
    GROUP BY 1
),

customer_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM customers
    GROUP BY 1
),

order_summary AS (
    SELECT
        CASE
            WHEN source IN ('Unmatched', 'Unknown')
                 OR source IS NULL
            THEN 'Unknown'
            ELSE source
        END AS channel,
        COUNT(*) AS total_orders,
        COUNT(DISTINCT customer_id) AS ordering_customers,
        SUM(gmv) AS total_gmv,
        SUM(margin) AS total_margin
    FROM orders
    GROUP BY 1
),

campaign_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        COUNT(DISTINCT campaign_id) AS total_campaigns,
        SUM(budget) AS total_campaign_budget
    FROM marketing_campaigns
    GROUP BY 1
),

target_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        MAX(target_cac) AS target_cac,
        MAX(target_roas) AS target_roas
    FROM channel_targets
    GROUP BY 1
)

SELECT
    nc.channel,

    COALESCE(ss.total_spend, 0) AS total_spend,
    COALESCE(ss.total_impressions, 0) AS total_impressions,
    COALESCE(ss.total_clicks, 0) AS total_clicks,
    COALESCE(ss.total_conversions, 0) AS total_conversions,

    COALESCE(cs.total_customers, 0) AS total_customers,

    COALESCE(os.total_orders, 0) AS total_orders,
    COALESCE(os.ordering_customers, 0) AS ordering_customers,
    COALESCE(os.total_gmv, 0) AS total_gmv,
    COALESCE(os.total_margin, 0) AS total_margin,

    COALESCE(cps.total_campaigns, 0) AS total_campaigns,
    COALESCE(cps.total_campaign_budget, 0)
        AS total_campaign_budget,

    ROUND(
        ss.total_spend / NULLIF(cs.total_customers, 0),
        2
    ) AS observed_cac,

    ROUND(
        100.0 * ss.total_clicks
        / NULLIF(ss.total_impressions, 0),
        2
    ) AS ctr_pct,

    ROUND(
        100.0 * ss.total_conversions
        / NULLIF(ss.total_clicks, 0),
        2
    ) AS conversion_rate_pct,

    ROUND(
        os.total_gmv / NULLIF(ss.total_spend, 0),
        2
    ) AS observed_roas_proxy,

    ROUND(
        100.0 * ss.total_spend
        / NULLIF(cps.total_campaign_budget, 0),
        2
    ) AS budget_utilization_pct,

    ts.target_cac,
    ts.target_roas,

    ROUND(
        ss.total_spend / NULLIF(cs.total_customers, 0)
        - ts.target_cac,
        2
    ) AS cac_variance,

    ROUND(
        os.total_gmv / NULLIF(ss.total_spend, 0)
        - ts.target_roas,
        2
    ) AS roas_variance

FROM normalized_channels nc

LEFT JOIN spend_summary ss
    ON nc.channel = ss.channel

LEFT JOIN customer_summary cs
    ON nc.channel = cs.channel

LEFT JOIN order_summary os
    ON nc.channel = os.channel

LEFT JOIN campaign_summary cps
    ON nc.channel = cps.channel

LEFT JOIN target_summary ts
    ON nc.channel = ts.channel;

SELECT *
FROM vw_channel_economics
ORDER BY total_spend DESC;

#Cohort Retention & LTV
CREATE OR REPLACE VIEW vw_cohort_retention_ltv AS

WITH retention_summary AS (
    SELECT
        cohort_month,
        month_no,
        CASE
            WHEN acquisition_channel IN ('Unmatched', 'Unknown')
                 OR acquisition_channel IS NULL
            THEN 'Unknown'
            ELSE acquisition_channel
        END AS acquisition_channel,
        COUNT(DISTINCT customer_id) AS cohort_customers,
        COUNT(DISTINCT CASE
            WHEN active = 1 THEN customer_id
        END) AS active_customers,
        SUM(orders) AS retention_orders
    FROM retention
    WHERE customer_id IS NOT NULL
    GROUP BY
        cohort_month,
        month_no,
        CASE
            WHEN acquisition_channel IN ('Unmatched', 'Unknown')
                 OR acquisition_channel IS NULL
            THEN 'Unknown'
            ELSE acquisition_channel
        END
),

customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS lifetime_orders,
        SUM(gmv) AS lifetime_gmv,
        SUM(margin) AS lifetime_margin
    FROM orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),

customer_cohorts AS (
    SELECT DISTINCT
        customer_id,
        cohort_month,
        CASE
            WHEN acquisition_channel IN ('Unmatched', 'Unknown')
                 OR acquisition_channel IS NULL
            THEN 'Unknown'
            ELSE acquisition_channel
        END AS acquisition_channel
    FROM retention
    WHERE customer_id IS NOT NULL
)

SELECT
    rs.cohort_month,
    rs.month_no,
    rs.acquisition_channel,
    rs.cohort_customers,
    rs.active_customers,
    rs.retention_orders,

    ROUND(
        100.0 * rs.active_customers /
        NULLIF(rs.cohort_customers, 0),
        2
    ) AS retention_rate_pct,

    COUNT(DISTINCT cc.customer_id) AS customers_in_cohort,

    ROUND(
        AVG(co.lifetime_gmv),
        2
    ) AS avg_lifetime_gmv,

    ROUND(
        AVG(co.lifetime_margin),
        2
    ) AS avg_lifetime_margin,

    ROUND(
        AVG(co.lifetime_orders),
        2
    ) AS avg_lifetime_orders,

    COUNT(DISTINCT CASE
        WHEN co.lifetime_orders > 1 THEN cc.customer_id
    END) AS repeat_customers

FROM retention_summary rs

LEFT JOIN customer_cohorts cc
    ON rs.cohort_month = cc.cohort_month
   AND rs.acquisition_channel = cc.acquisition_channel

LEFT JOIN customer_orders co
    ON cc.customer_id = co.customer_id

GROUP BY
    rs.cohort_month,
    rs.month_no,
    rs.acquisition_channel,
    rs.cohort_customers,
    rs.active_customers,
    rs.retention_orders;

# Campaign Performance
CREATE OR REPLACE VIEW vw_campaign_performance AS
WITH campaign_summary AS (
    SELECT
        campaign_id,
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        MAX(budget) AS campaign_budget,
        MAX(target_roas) AS target_roas
    FROM marketing_campaigns
    GROUP BY
        campaign_id,
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END
),
spend_summary AS (
    SELECT
        campaign_id,
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        SUM(spend) AS total_spend,
        SUM(impressions) AS total_impressions,
        SUM(clicks) AS total_clicks,
        SUM(conversions) AS total_conversions
    FROM marketing_spend
    GROUP BY
        campaign_id,
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END
),
campaign_data AS (
    SELECT
        COALESCE(c.campaign_id, s.campaign_id) AS campaign_id,
        COALESCE(c.channel, s.channel) AS channel,
        c.campaign_budget,
        c.target_roas,
        COALESCE(s.total_spend, 0) AS total_spend,
        COALESCE(s.total_impressions, 0) AS total_impressions,
        COALESCE(s.total_clicks, 0) AS total_clicks,
        COALESCE(s.total_conversions, 0) AS total_conversions
    FROM campaign_summary c
    LEFT JOIN spend_summary s
        ON c.campaign_id = s.campaign_id
       AND c.channel = s.channel

    UNION ALL

    SELECT
        s.campaign_id,
        s.channel,
        NULL AS campaign_budget,
        NULL AS target_roas,
        s.total_spend,
        s.total_impressions,
        s.total_clicks,
        s.total_conversions
    FROM spend_summary s
    LEFT JOIN campaign_summary c
        ON c.campaign_id = s.campaign_id
       AND c.channel = s.channel
    WHERE c.campaign_id IS NULL
)
SELECT
    campaign_id,
    channel,
    campaign_budget,
    total_spend,
    total_impressions,
    total_clicks,
    total_conversions,
    target_roas,

    ROUND(
        total_spend / NULLIF(total_conversions, 0),
        2
    ) AS cost_per_conversion,

    ROUND(
        total_spend / NULLIF(campaign_budget, 0) * 100,
        2
    ) AS budget_utilization_pct,

    DENSE_RANK() OVER (
        ORDER BY total_spend DESC
    ) AS spend_rank

FROM campaign_data;

SELECT *
FROM vw_campaign_performance
ORDER BY spend_rank
LIMIT 20;

#25 Crore Budget Simulator
USE customer;

CREATE OR REPLACE VIEW vw_budget_simulator AS
WITH spend_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        SUM(spend) AS current_spend
    FROM marketing_spend
    GROUP BY
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END
),
budget_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        SUM(budget) AS campaign_budget,
        COUNT(DISTINCT campaign_id) AS total_campaigns
    FROM marketing_campaigns
    GROUP BY
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END
),
customer_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM customers
    GROUP BY
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END
),
order_summary AS (
    SELECT
        CASE
            WHEN source IN ('Unmatched', 'Unknown')
                 OR source IS NULL
            THEN 'Unknown'
            ELSE source
        END AS channel,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(gmv) AS total_gmv,
        SUM(margin) AS total_margin
    FROM orders
    GROUP BY
        CASE
            WHEN source IN ('Unmatched', 'Unknown')
                 OR source IS NULL
            THEN 'Unknown'
            ELSE source
        END
),
target_summary AS (
    SELECT
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END AS channel,
        MAX(target_cac) AS target_cac,
        MAX(target_roas) AS target_roas
    FROM channel_targets
    GROUP BY
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                 OR channel IS NULL
            THEN 'Unknown'
            ELSE channel
        END
),
channel_list AS (
    SELECT channel FROM spend_summary
    UNION
    SELECT channel FROM budget_summary
    UNION
    SELECT channel FROM customer_summary
    UNION
    SELECT channel FROM order_summary
    UNION
    SELECT channel FROM target_summary
)
SELECT
    cl.channel,
    COALESCE(s.current_spend, 0) AS current_spend,
    COALESCE(b.campaign_budget, 0) AS campaign_budget,
    COALESCE(b.total_campaigns, 0) AS total_campaigns,
    COALESCE(c.total_customers, 0) AS total_customers,
    COALESCE(o.total_orders, 0) AS total_orders,
    COALESCE(o.total_gmv, 0) AS total_gmv,
    COALESCE(o.total_margin, 0) AS total_margin,
    t.target_cac,
    t.target_roas,
    ROUND(
        s.current_spend / NULLIF(c.total_customers, 0),
        2
    ) AS observed_spend_per_customer,
    ROUND(
        o.total_gmv / NULLIF(s.current_spend, 0),
        2
    ) AS observed_roas_proxy,
    ROUND(
        s.current_spend / NULLIF(b.campaign_budget, 0) * 100,
        2
    ) AS budget_utilization_pct
FROM channel_list cl
LEFT JOIN spend_summary s ON cl.channel = s.channel
LEFT JOIN budget_summary b ON cl.channel = b.channel
LEFT JOIN customer_summary c ON cl.channel = c.channel
LEFT JOIN order_summary o ON cl.channel = o.channel
LEFT JOIN target_summary t ON cl.channel = t.channel;

SELECT *
FROM vw_budget_simulator
ORDER BY current_spend DESC;