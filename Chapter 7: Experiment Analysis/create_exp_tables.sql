--JUST FOR MAC 
------en termiinal---
--psql -U postgres -d mi_database

--brew install postgresql
--psql --version
--psql
--SELECT current_database(); #Solo para revisar cual es nuestra database

--\dt-- mostrar todas las carpetas
--\d table_name--- muestra la tabla especifica

--\copy ufo FROM '/Path/earthquakes1.csv' CSV HEADER;

--\q #exit


DROP TABLE IF EXISTS game_users;
CREATE TABLE game_users
(
  user_id  int,
  created  date,
  country  varchar
);

\copy game_users FROM 'PATH/game_users.csv' 
DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS game_actions;
CREATE TABLE game_actions
(
  user_id     int,
  action      varchar,
  action_date date
);

\copy game_actions FROM '/PATH/game_actions.csv' 
DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS game_purchases;
CREATE TABLE game_purchases
(
  user_id    int,
  purch_date date,
  amount     numeric(10,2)
);

\copy game_purchases FROM '/PATH/game_purchases.csv' 
DELIMITER ',' CSV HEADER;

DROP TABLE IF EXISTS exp_assignment;
CREATE TABLE exp_assignment
(
  exp_name varchar,
  user_id  int,
  exp_date date,
  variant  varchar
);

\copy exp_assignment FROM '/PATH/exp_assignment.csv' 
DELIMITER ',' CSV HEADER;

--

 SELECT a.variant
    ,count(a.user_id) as total_cohorted
    ,count(b.user_id) as completions
    ,count(b.user_id) / count(a.user_id) as pct_completed
    FROM exp_assignment a
    LEFT JOIN game_actions b on a.user_id = b.user_id
     and b.action = 'onboarding complete'
    WHERE a.exp_name = 'Onboarding'
    GROUP BY 1
    ;


