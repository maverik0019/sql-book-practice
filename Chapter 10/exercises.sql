--Ejercicio 1 — Screening (quién califica para el estudio)
-- los usuarios que:
--se registraron en enero 2020
--y realizaron al menos una acción

--tablas:
--game_users
--game_actions
--game_purchases


SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'game_actions';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'game_users';

SELECT DISTINCT action
FROM game_actions;


SELECT u.user_id, u.created
From game_users u 
WHERE u.created >= '2020-01-01'
AND u.created < '2020-02-01'
    AND EXISTS(
        SELECT 1
        FROM game_actions a 
        WHERE a.user_id = u.user_id
        AND a.action_date >= '2020-01-01'
        AND a.action_date < '2020-02-01'
    );
-------
SELECT u.user_id
FROM game_users u
WHERE u.created >= '2020-01-01'
  AND u.created <  '2020-02-01'
  AND EXISTS (
      SELECT 1
      FROM game_actions a
      WHERE a.user_id = u.user_id
        AND a.action = 'onboarding complete'
  );
 
-----
SELECT DISTINCT u.user_id
FROM game_users u
JOIN game_actions a  
ON u.user_id = a.user_id
WHERE u.created >= '2020-01-01' AND 
u.created < '2020-02-01'
AND a.action = 'onboarding complete';
-----

SELECT u.user_id
FROM game_users u
WHERE u.created >= '2020-01-01'
  AND u.created <  '2020-02-01'
  AND EXISTS (
      SELECT 1
      FROM game_actions a
      WHERE a.user_id = u.user_id
        AND a.action = 'onboarding complete'
  );

--Ejercicio/Pregunta 2: Cohorte por mes de registro (enrolamiento).
--Por mes de created calcular:
--total de usuarios (enrolled)
--cuántos hicieron al menos 1 acción (activated / screened-in)
--tasa de activación = activated / total


--tablas:
--game_users
--game_actions
--game_purchases

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'game_users';

SELECT
    date_trunc('month',created):: date as cohort_month, 
    COUNT(*) AS total_users,
    COUNT(a.user_id) as total_users_actions
FROM game_users u
LEFT JOIN (
    SELECT DISTINCT user_id
    FROM game_actions
) a
ON a.user_id = u.user_id
GROUP BY 1
ORDER BY 1;


--Ejercicio/Pregunta 3 Baseline vs Follow-up
--Para cada usuario:
--fecha de registro
--fecha de primera acción
--días entre ambas


SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'game_actions';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'game_users';


SELECT u.user_id, 
        u.created,
        f.first_action_date,
        f.first_action_date - u.created as days_to_first_action
FROM game_users u
LEFT JOIN
(
SELECT user_id, MIN(action_date) AS first_action_date
FROM game_actions
GROUP BY user_id
) f
ON u.user_id = f.user_id;

-- ¿Cuál es el tiempo promedio al primer evento?
WITH tabla_tiempo AS (
SELECT u.user_id, 
        u.created,
        f.first_action_date,
        f.first_action_date - u.created as days_to_first_action
FROM game_users u
LEFT JOIN
(
SELECT user_id, MIN(action_date) AS first_action_date
FROM game_actions
GROUP BY user_id
) f
ON u.user_id = f.user_id)
SELECT AVG(days_to_first_action)::int AS avg_days_to_first_action
FROM tabla_tiempo
WHERE first_action_date IS NOT NULL;

--Tiempo promedio al primer evento (overall)-cohorte mensual


WITH tabla_tiempo AS (
SELECT u.user_id, 
        u.created,
        f.first_action_date,
        f.first_action_date - u.created as days_to_first_action
FROM game_users u
LEFT JOIN
(
SELECT user_id, MIN(action_date) AS first_action_date
FROM game_actions
GROUP BY user_id
) f
ON u.user_id = f.user_id)

SELECT 
    date_trunc('month', created)::date AS cohort_month, 
    AVG(days_to_first_action)
FROM tabla_tiempo
WHERE first_action_date IS NOT NULL
GROUP BY 1
Order By 1;

----Los usuarios hicieron su primera 
--acción el 
--mismo día que se registraron
--Activación inmediata, No hay delay en el primer evento
--proceso altamente eficiente, dato generado el mismo día



--Time-to-event analysis

WITH tabla_tiempo AS (
SELECT u.user_id, 
        u.created,
        f.first_action_date,
        f.first_action_date - u.created as days_to_first_action
FROM game_users u
LEFT JOIN
(
SELECT user_id, MIN(action_date) AS first_action_date
FROM game_actions
GROUP BY user_id
) f
ON u.user_id = f.user_id)

SELECT
PERCENTILE_CONT(0.5)
WITHIN GROUP (ORDER BY days_to_first_action) AS median_days
FROM tabla_tiempo
WHERE days_to_first_action IS NOT NULL;



-----Tasa de follow-up por cohorte

WITH tabla_tiempo AS (
  SELECT u.user_id, 
         u.created,
         f.first_action_date,
         f.first_action_date - u.created AS days_to_first_action
  FROM game_users u
  LEFT JOIN (
    SELECT user_id, MIN(action_date) AS first_action_date
    FROM game_actions
    GROUP BY user_id
  ) f
  ON u.user_id = f.user_id
)

SELECT
  date_trunc('month', created)::date AS cohort_month,

  COUNT(*) AS total_users,

  COUNT(days_to_first_action) AS users_with_followup,

  ROUND(
    COUNT(days_to_first_action)::numeric / COUNT(*) * 100,
    2
  ) AS followup_rate_pct

FROM tabla_tiempo
GROUP BY 1
ORDER BY 1;

--Análisis de outcome (métrica de negocio / clínica)

WITH tabla_tiempo AS (
  SELECT u.user_id, 
         u.created,
         f.first_action_date,
         f.first_action_date - u.created AS days_to_first_action
  FROM game_users u
  LEFT JOIN (
    SELECT user_id, MIN(action_date) AS first_action_date
    FROM game_actions
    GROUP BY user_id
  ) f
  ON u.user_id = f.user_id
)

SELECT
  date_trunc('month', created)::date AS cohort_month,

  COUNT(*) AS total_users,

  COUNT(p.user_id) AS users_with_purchase,

  ROUND(
    COUNT(p.user_id)::numeric / COUNT(*) * 100,
    2) AS conversion_rate_pct

FROM tabla_tiempo t 
LEFT JOIN
(
SELECT DISTINCT user_id
FROM game_purchases
) p
  ON t.user_id = p.user_id

GROUP BY 1
ORDER BY 1;
--~10% de los pacientes responde al tratamiento
--
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'game_users';


WITH user_funnel AS (
  SELECT
        u.user_id, 
        date_trunc('month', created)::date as cohort_month,
        CASE WHEN a.user_id IS NOT NULL THEN 1 ELSE 0 END AS has_followup,
        CASE WHEN p.user_id IS NOT NULL THEN 1 ELSE 0 END AS has_purchase
FROM game_users u 
LEFT JOIN
(
SELECT DISTINCT user_id
FROM game_actions
) a ON a.user_id = u.user_id
LEFT JOIN(
SELECT DISTINCT user_id
FROM game_purchases
) p  ON p.user_id = u.user_id)
SELECT 
    cohort_month, 
    COUNT(*) AS enrolled,
    SUM(has_followup) AS followup,
    SUM(has_purchase) AS purchase, 


    ROUND(SUM(has_followup)::numeric /COUNT(*) * 100, 2) AS followup_rate_pct,
    ROUND(SUM(has_purchase)::numeric /COUNT(*) * 100, 2) AS convertion_rate_pct,

    -- conversión condicionada: de los que hicieron follow-up, ¿cuántos compraron?
  ROUND(SUM(has_purchase)::numeric / NULLIF(SUM(has_followup), 0) * 100, 2) AS purchase_given_followup_pct
FROM user_funnel
GROUP BY 1
ORDER BY 1;


WITH cohort_stats AS (

SELECT
  DATE '2020-01-01' AS cohort,
  62993 AS n,
  55750 AS followup

UNION ALL

SELECT
  DATE '2020-02-01',
  37179,
  31374

)
SELECT *
FROM cohort_stats;


----
WITH cohort_stats AS (

SELECT
DATE '2020-01-01' AS cohort,
62993 AS n,
55750 AS x

UNION ALL

SELECT
DATE '2020-02-01',
37179,
31374
),

rates AS (

SELECT
cohort,
n,
x,
x::numeric/n AS p
FROM cohort_stats

),

pooled AS (

SELECT
SUM(x)::numeric / SUM(n) AS p_pool
FROM cohort_stats

)

SELECT
r1.p AS jan_rate,
r2.p AS feb_rate,

(r1.p - r2.p) /
SQRT(
p_pool*(1-p_pool)*(1.0/r1.n + 1.0/r2.n)
) AS z_score

FROM rates r1
JOIN rates r2
ON r1.cohort < r2.cohort
CROSS JOIN pooled;

---Just a python code to do the same
# Two-proportion z-test (follow-up rate): Jan vs Feb
# Inputs from SQL funnel output:
n1 = 62993   # enrolled (Jan)
x1 = 55750   # follow-up (Jan)
n2 = 37179   # enrolled (Feb)
x2 = 31374   # follow-up (Feb)

import math

# Observed proportions
p1 = x1 / n1
p2 = x2 / n2

# Pooled proportion under H0: p1 == p2
p_pool = (x1 + x2) / (n1 + n2)

# Standard error (pooled)
se = math.sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))

# z-score
z = (p1 - p2) / se

# Two-sided p-value (normal approx)
# Using the error function to compute Phi(z) without extra libs
def norm_cdf(z_val: float) -> float:
    return 0.5 * (1.0 + math.erf(z_val / math.sqrt(2.0)))

p_value_two_sided = 2 * (1 - norm_cdf(abs(z)))

print(f"p1 (Jan) = {p1:.6f}")
print(f"p2 (Feb) = {p2:.6f}")
print(f"z        = {z:.6f}")
print(f"p-value  = {p_value_two_sided:.6g}")

# Rule of thumb at alpha=0.05:
# if p_value_two_sided < 0.05 -> reject H0 (rates differ)

--ARPU (Average Revenue Per User)-----

WITH revenue_user as ( 
  
SELECT
user_id,
SUM(amount) AS total_revenue
FROM game_purchases
GROUP BY user_id
)
SELECT
    date_trunc('month', u.created)::date AS cohort_month,
    COUNT(*) AS enrolled, 
    SUM(COALESCE(r.total_revenue, 0)) AS total_revenue,
    ROUND(
      SUM(COALESCE(r.total_revenue, 0))::numeric/COUNT(*), 2
      ) AS ARPU

FROM game_users u
LEFT JOIN revenue_user r
ON u.user_id = r.user_id
GROUP BY 1
ORDER BY 1;

---Average Revenue Per Paying User---
WITH revenue_user AS (
  SELECT
    user_id,
    SUM(amount) AS total_revenue
  FROM game_purchases
  GROUP BY user_id
)

SELECT
  date_trunc('month', u.created)::date AS cohort_month,

  COUNT(*) AS enrolled,

  COUNT(r.user_id) AS buyers,

  SUM(COALESCE(r.total_revenue,0)) AS total_revenue,

  ROUND(
    SUM(COALESCE(r.total_revenue,0))::numeric / COUNT(*),
    2
  ) AS arpu,

  ROUND(
    SUM(COALESCE(r.total_revenue,0))::numeric / NULLIF(COUNT(r.user_id),0),
    2
  ) AS arppu

FROM game_users u

LEFT JOIN revenue_user r
ON u.user_id = r.user_id

GROUP BY 1
ORDER BY 1;

--(80/20 revenue)