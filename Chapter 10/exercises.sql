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
