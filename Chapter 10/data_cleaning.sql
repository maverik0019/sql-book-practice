--PROJECT CREATED IN BIGQUERY OF GOOGLE


WITH base AS (
    SELECT  
        shipment_id, 
        TRIM(origin_warehouse) AS origin_warehouse,
        TRIM(destination_city) AS destination_city,
        TRIM(destination_state) AS destination_state,
        TRIM(carrier) AS carrier,
        damage_reported,
        weight_kg,
        freight_cost,
        ship_date,
        delivery_date
    FROM `practica-sandbox.practice_sql_sandbox.shipments`
),

formatted AS (
    SELECT
        shipment_id,
        INITCAP(origin_warehouse) AS origin_warehouse,
        INITCAP(destination_city) AS destination_city,
        UPPER(destination_state) AS destination_state,
        INITCAP(carrier) AS carrier,
        damage_reported,
        weight_kg,
        freight_cost,
        ship_date,
        delivery_date
    FROM base
),

nulls_handled AS (
    SELECT
        shipment_id,
        origin_warehouse,
        destination_city,
        destination_state,
        carrier,

        CASE
            WHEN damage_reported IS NULL OR damage_reported = 'NULL' THEN NULL
            ELSE INITCAP(TRIM(damage_reported))
        END AS damage_reported,

        weight_kg,
        freight_cost,
        ship_date,
        delivery_date
    FROM formatted
),

deduplicated AS (
    SELECT * EXCEPT(row_number)
    FROM (
        SELECT *,
            ROW_NUMBER() OVER(
                PARTITION BY origin_warehouse, destination_city, carrier, ship_date, CAST(weight_kg AS STRING)
                ORDER BY shipment_id
            ) AS row_number
        FROM nulls_handled
    )
    WHERE row_number = 1
),

weight_cleaned AS (
    SELECT
        *,
        CASE
            WHEN weight_kg < 0 THEN ABS(weight_kg)
            WHEN weight_kg = 0 THEN NULL
            ELSE weight_kg
        END AS weight_kg_cleaned
    FROM deduplicated
),

dates_parsed AS (
    SELECT
        *,
        SAFE.PARSE_DATE('%Y-%m-%d', ship_date) AS ship_dt,
        SAFE.PARSE_DATE('%Y-%m-%d', delivery_date) AS delivery_dt
    FROM weight_cleaned
),

date_features AS (
    SELECT
        *,
        DATE_DIFF(delivery_dt, ship_dt, DAY) AS transit_days,
        CASE
            WHEN delivery_dt < ship_dt THEN 'INVALID'
            WHEN delivery_dt = ship_dt THEN 'SAME DAY DELIVERY'
            ELSE 'VALID'
        END AS data_quality_flag
    FROM dates_parsed
),

stats AS (
    SELECT
        APPROX_QUANTILES(freight_cost, 100)[OFFSET(25)] AS q1,
        APPROX_QUANTILES(freight_cost, 100)[OFFSET(75)] AS q3
    FROM date_features
    WHERE freight_cost > 0
),

bounds AS (
    SELECT
        q1 - 1.5 * (q3 - q1) AS lower_bound,
        q3 + 1.5 * (q3 - q1) AS upper_bound
    FROM stats
),

final AS (
    SELECT
        df.*,

        CASE
            WHEN freight_cost > upper_bound THEN upper_bound
            WHEN freight_cost < lower_bound THEN lower_bound
            ELSE freight_cost
        END AS freight_cost_cleaned,

        CASE
            WHEN freight_cost > upper_bound OR freight_cost < lower_bound THEN TRUE
            ELSE FALSE
        END AS was_outlier

    FROM date_features df
    CROSS JOIN bounds
)

SELECT *
FROM final
LIMIT 100