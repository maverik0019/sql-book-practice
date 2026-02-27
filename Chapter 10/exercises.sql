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