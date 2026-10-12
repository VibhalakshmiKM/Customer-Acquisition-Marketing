create database customer;
use customer;
#• Join 5+ tables to create an acquisition-to-LTV funnel.
USE customer;

WITH order_summary AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(gmv) AS lifetime_gmv,
        SUM(margin) AS lifetime_profit
    FROM orders
    GROUP BY customer_id
),
retention_summary AS (
    SELECT
        customer_id,
        MAX(active) AS is_active
    FROM retention
    GROUP BY customer_id
),
customer_summary AS (
    SELECT
        c.channel,
        COUNT(DISTINCT c.customer_id) AS customers,
        SUM(COALESCE(o.total_orders, 0)) AS total_orders,
        SUM(COALESCE(o.lifetime_gmv, 0)) AS total_gmv,
        SUM(COALESCE(o.lifetime_profit, 0)) AS total_profit,
        AVG(o.lifetime_gmv) AS avg_customer_ltv_gmv,
        AVG(o.lifetime_profit) AS avg_customer_ltv_profit,
        ROUND(
    100.0 * AVG(COALESCE(r.is_active, 0)),
    2
) AS retention_rate_pct
    FROM customers c
    LEFT JOIN order_summary o
        ON c.customer_id = o.customer_id
    LEFT JOIN retention_summary r
        ON c.customer_id = r.customer_id
    GROUP BY c.channel
),
spend_summary AS (SELECT
    CASE
        WHEN channel IN ('Unmatched', 'Unknown') THEN 'Unknown'
        ELSE channel
    END AS channel,
    SUM(spend) AS total_spend,
    SUM(clicks) AS total_clicks,
    SUM(conversions) AS total_conversions
FROM marketing_spend
GROUP BY
    CASE
        WHEN channel IN ('Unmatched', 'Unknown') THEN 'Unknown'
        ELSE channel
    END
),
target_summary AS (
    SELECT
        channel,
        AVG(NULLIF(target_cac, -999)) AS avg_target_cac,
        AVG(NULLIF(target_roas, -999)) AS avg_target_roas
    FROM channel_targets
    GROUP BY channel
)
SELECT
    cs.channel,
    cs.customers,
    ss.total_clicks,
    ss.total_conversions,
    cs.total_orders,
    ROUND(cs.total_gmv, 2) AS total_gmv,
    ROUND(cs.total_profit, 2) AS total_profit,
    ROUND(cs.avg_customer_ltv_gmv, 2) AS avg_customer_ltv_gmv,
    ROUND(cs.avg_customer_ltv_profit, 2) AS avg_customer_ltv_profit,
    ROUND(cs.retention_rate_pct, 2) AS retention_rate_pct,
    ROUND(ss.total_spend, 2) AS total_spend,
    ROUND(
        ss.total_spend / NULLIF(ss.total_conversions, 0), 2
    ) AS cost_per_conversion,
    ROUND(
        cs.total_gmv / NULLIF(ss.total_spend, 0), 2
    ) AS actual_roas,
    ROUND(ts.avg_target_cac, 2) AS avg_target_cac,
    ROUND(ts.avg_target_roas, 2) AS avg_target_roas
FROM customer_summary cs
LEFT JOIN spend_summary ss
    ON cs.channel = ss.channel
LEFT JOIN target_summary ts
    ON cs.channel = ts.channel
ORDER BY cs.avg_customer_ltv_profit DESC;


# Use CTEs for first-order and repeat-order economics.

WITH order_economics AS (
    SELECT
        CASE
            WHEN First_Order_Flag = 'First Recorded'
                THEN 'First Order'
            WHEN First_Order_Flag = 'Repeat'
                THEN 'Repeat Order'
        END AS order_type,

        COUNT(order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS total_customers,
        SUM(gmv) AS total_gmv,
        SUM(margin) AS total_profit,
        AVG(gmv) AS avg_order_value,
        AVG(margin) AS avg_profit_per_order

    FROM orders
    WHERE First_Order_Flag IN ('First Recorded', 'Repeat')
    GROUP BY
        CASE
            WHEN First_Order_Flag = 'First Recorded'
                THEN 'First Order'
            WHEN First_Order_Flag = 'Repeat'
                THEN 'Repeat Order'
        END
)

SELECT
    order_type,
    total_orders,
    total_customers,
    ROUND(total_gmv, 2) AS total_gmv,
    ROUND(total_profit, 2) AS total_profit,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(avg_profit_per_order, 2) AS avg_profit_per_order,
    ROUND(
        total_profit / NULLIF(total_gmv, 0) * 100,
        2
    ) AS profit_margin_pct
FROM order_economics
ORDER BY total_gmv DESC;

#Use windows to rank campaigns and calculate cumulative channel contribution.
WITH campaign_summary AS (
    SELECT
        campaign_id,
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                THEN 'Unknown'
            ELSE channel
        END AS channel,
        SUM(spend) AS total_spend,
        SUM(clicks) AS total_clicks,
        SUM(conversions) AS total_conversions
    FROM marketing_spend
    GROUP BY
        campaign_id,
        CASE
            WHEN channel IN ('Unmatched', 'Unknown')
                THEN 'Unknown'
            ELSE channel
        END
),
ranked_campaigns AS (
    SELECT
        campaign_id,
        channel,
        total_spend,
        total_clicks,
        total_conversions,
        DENSE_RANK() OVER (
            ORDER BY total_spend DESC
        ) AS campaign_rank
    FROM campaign_summary
),
channel_summary AS (
    SELECT
        channel,
        SUM(total_spend) AS channel_spend
    FROM ranked_campaigns
    GROUP BY channel
),
channel_contribution AS (
    SELECT
        channel,
        channel_spend,
        SUM(channel_spend) OVER (
            ORDER BY channel_spend DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_spend
    FROM channel_summary
)
SELECT
    channel,
    ROUND(channel_spend, 2) AS channel_spend,
    ROUND(
        channel_spend /
        NULLIF(SUM(channel_spend) OVER (), 0) * 100,
        2
    ) AS contribution_pct,
    ROUND(
        cumulative_spend /
        NULLIF(SUM(channel_spend) OVER (), 0) * 100,
        2
    ) AS cumulative_contribution_pct
FROM channel_contribution
ORDER BY channel_spend DESC;

#• Compare first-touch, last-touch and simplified multi-touch attribution.
WITH session_ranked AS (
    SELECT
        customer_id,
        source,
        session_id,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY session_id ASC
        ) AS first_rank,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY session_id DESC
        ) AS last_rank
    FROM sessions
    WHERE customer_id IS NOT NULL
),

first_touch AS (
    SELECT customer_id, source AS channel
    FROM session_ranked
    WHERE first_rank = 1
),

last_touch AS (
    SELECT customer_id, source AS channel
    FROM session_ranked
    WHERE last_rank = 1
),

customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(gmv) AS total_gmv,
        SUM(margin) AS total_margin
    FROM orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),

customer_touches AS (
    SELECT
        customer_id,
        source AS channel,
        COUNT(*) AS channel_touches
    FROM sessions
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, source
),

total_touches AS (
    SELECT
        customer_id,
        COUNT(*) AS total_touchpoints
    FROM sessions
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),

first_results AS (
    SELECT
        'First Touch' AS attribution_model,
        COALESCE(ft.channel, 'Unknown') AS channel,
        SUM(o.total_orders) AS attributed_orders,
        SUM(o.total_gmv) AS attributed_gmv,
        SUM(o.total_margin) AS attributed_margin
    FROM customer_orders o
    LEFT JOIN first_touch ft
        ON o.customer_id = ft.customer_id
    GROUP BY COALESCE(ft.channel, 'Unknown')
),

last_results AS (
    SELECT
        'Last Touch' AS attribution_model,
        COALESCE(lt.channel, 'Unknown') AS channel,
        SUM(o.total_orders) AS attributed_orders,
        SUM(o.total_gmv) AS attributed_gmv,
        SUM(o.total_margin) AS attributed_margin
    FROM customer_orders o
    LEFT JOIN last_touch lt
        ON o.customer_id = lt.customer_id
    GROUP BY COALESCE(lt.channel, 'Unknown')
),

multi_results AS (
    SELECT
        'Multi Touch' AS attribution_model,
        COALESCE(ct.channel, 'Unknown') AS channel,
        SUM(
            o.total_orders * ct.channel_touches /
            NULLIF(tt.total_touchpoints, 0)
        ) AS attributed_orders,
        SUM(
            o.total_gmv * ct.channel_touches /
            NULLIF(tt.total_touchpoints, 0)
        ) AS attributed_gmv,
        SUM(
            o.total_margin * ct.channel_touches /
            NULLIF(tt.total_touchpoints, 0)
        ) AS attributed_margin
    FROM customer_orders o
    JOIN customer_touches ct
        ON o.customer_id = ct.customer_id
    JOIN total_touches tt
        ON o.customer_id = tt.customer_id
    GROUP BY COALESCE(ct.channel, 'Unknown')
),

attribution_results (
    attribution_model,
    channel,
    attributed_orders,
    attributed_gmv,
    attributed_margin
) AS (
    SELECT
        attribution_model, channel, attributed_orders,
        attributed_gmv, attributed_margin
    FROM first_results

    UNION ALL

    SELECT
        attribution_model, channel, attributed_orders,
        attributed_gmv, attributed_margin
    FROM last_results

    UNION ALL

    SELECT
        attribution_model, channel, attributed_orders,
        attributed_gmv, attributed_margin
    FROM multi_results
)

SELECT
    attribution_model,
    channel,
    ROUND(attributed_orders, 2) AS attributed_orders,
    ROUND(attributed_gmv, 2) AS attributed_gmv,
    ROUND(attributed_margin, 2) AS attributed_margin,
    ROUND(
        attributed_gmv /
        NULLIF(
            SUM(attributed_gmv) OVER (
                PARTITION BY attribution_model
            ),
            0
        ) * 100,
        2
    ) AS gmv_contribution_pct
FROM attribution_results
ORDER BY attribution_model, attributed_gmv DESC;

#• Identify campaigns where spend grew faster than incremental customers.
WITH campaign_monthly AS (
    SELECT
        campaign_id,
        STR_TO_DATE(`date`, '%Y-%m-%d') AS spend_date,
        SUM(spend) AS total_spend,
        SUM(conversions) AS total_conversions
    FROM marketing_spend
    GROUP BY campaign_id, STR_TO_DATE(`date`, '%Y-%m-%d')
),

campaign_periods AS (
    SELECT
        campaign_id,
        DATE_FORMAT(spend_date, '%Y-%m') AS spend_month,
        SUM(total_spend) AS monthly_spend,
        SUM(total_conversions) AS monthly_conversions
    FROM campaign_monthly
    GROUP BY campaign_id, DATE_FORMAT(spend_date, '%Y-%m')
),

campaign_growth AS (
    SELECT
        campaign_id,
        spend_month,
        monthly_spend,
        monthly_conversions,
        LAG(monthly_spend) OVER (
            PARTITION BY campaign_id
            ORDER BY spend_month
        ) AS previous_spend,
        LAG(monthly_conversions) OVER (
            PARTITION BY campaign_id
            ORDER BY spend_month
        ) AS previous_conversions
    FROM campaign_periods
)

SELECT
    campaign_id,
    spend_month,
    ROUND(previous_spend, 2) AS previous_spend,
    ROUND(monthly_spend, 2) AS current_spend,
    previous_conversions,
    monthly_conversions,
    ROUND(
        (monthly_spend - previous_spend) /
        NULLIF(previous_spend, 0) * 100,
        2
    ) AS spend_growth_pct,
    ROUND(
        (monthly_conversions - previous_conversions) /
        NULLIF(previous_conversions, 0) * 100,
        2
    ) AS conversion_growth_pct
FROM campaign_growth
WHERE previous_spend > 0
  AND previous_conversions > 0
  AND monthly_spend > previous_spend
  AND (
      monthly_conversions <= previous_conversions
      OR
      (monthly_spend - previous_spend) /
          previous_spend
      >
      (monthly_conversions - previous_conversions) /
          previous_conversions
  )
ORDER BY spend_growth_pct DESC;



