--JUST FOR MAC 
------en termiinal---
---"""debo remplazar mi_database por el nombre de mi database"""
--psql -U postgres -d mi_database

--brew install postgresql
--psql --version
--psql
--SELECT current_database(); #Solo para revisar cual es nuestra database

--\dt   -- mostrar todas las carpetas
--\d table_name--- muestra la tabla especifica

--\copy videogame_sales FROM '/Path/earthquakes1.csv' CSV HEADER;

--\q #exit




--PROJECT CREATED IN BIGQUERY OF GOOGLE
--“Proyecto de análisis de funnel utilizando BigQuery, optimizado para entornos analíticos modernos.”
--“Funnel analysis project using BigQuery, optimized for modern analytical environments.

--This project analyzes user behavior across a marketing funnel using Google BigQuery.

--It focuses on:
-- - Funnel stage analysis
-- - Conversion rates
-- - Time-to-conversion
-- - Revenue metrics

--1funnel stages
WITH funnel_stages AS(
  SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS stage_1_views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS stage_2_carts,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage_3_checkout,
        COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS stage_4_payment,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS stage_5_purchase

  FROM `practica-sandbox.practice_sql_sandbox.marketing_users` 
  WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
)
SELECT * 
FROM funnel_stages
--
--convertion rater
SELECT
  traffic_source,
  views,
  carts,
  purchase,
  ROUND(purchase * 100.0 / NULLIF(views, 0), 2) AS conversion_rate,
  ROUND(carts * 100.0 / NULLIF(views, 0), 2) AS cart_conversion_rate,
  ROUND(purchase * 100.0 / NULLIF(carts, 0), 2) AS cart_to_purchase_rate
FROM source_funnel
ORDER BY purchase DESC;

--

--traffic source

SELECT
      traffic_source,
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase

  FROM `practica-sandbox.practice_sql_sandbox.marketing_users` 
  --WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  GROUP BY traffic_source
--
WITH source_funnel AS(

  SELECT
      traffic_source,
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS carts,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase

  FROM `practica-sandbox.practice_sql_sandbox.marketing_users` 
  GROUP BY traffic_source
)
SELECT
  traffic_source,
  views,
  carts, 
  purchase,
  carts * 100 / views AS cart_convertion_rate,
  purchase * 100 / views AS purchase_convertion_rate,
  purchase * 100 / carts AS cart_purchase_convertion_rate,

FROM source_funnel
ORDER BY purchase DESC

--time to travel

WITH user_journey AS(

  SELECT
      user_id,
        MIN(CASE WHEN event_type = 'page_view' THEN event_date END) AS views_time,
        MIN(CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN event_date END) AS purchase_time

  FROM `practica-sandbox.practice_sql_sandbox.marketing_users` 
  --WHERE event_date >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
  GROUP BY user_id
  HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
)

SELECT 
    COUNT(*) AS converted_users,
    AVG(TIMESTAMP_DIFF(cart_time, views_time, MINUTE)) AS avg_view_to_cart_minute,
    AVG(TIMESTAMP_DIFF(purchase_time, cart_time, MINUTE)) AS avg_cart_to_purchase_minute, 
    AVG(TIMESTAMP_DIFF(purchase_time, views_time, MINUTE)) AS avg_total_jorney_minute

FROM user_journey


-- revenue funnel analysis
WITH funnel_revenue AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitors,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS total_buyers,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS total_orders,
    SUM(CASE WHEN event_type = 'purchase' THEN amount END) AS total_revenue
  FROM `practica-sandbox.practice_sql_sandbox.marketing_users`
)
SELECT
  total_visitors,
  total_buyers,
  total_orders,
  total_revenue,
  ROUND(total_revenue / NULLIF(total_orders, 0), 2) AS avg_order_value,
  ROUND(total_revenue / NULLIF(total_buyers, 0), 2) AS revenue_per_buyer,
  ROUND(total_revenue / NULLIF(total_visitors, 0), 2) AS revenue_per_visitor
FROM funnel_revenue;