------ Detecting outliers
-- Sorting to find anomalies
--Primero necesitamos crear la tabla para despues cargar los archivos CSVs y formar solo uno

--CREAR LA TABLA 
DROP TABLE IF EXISTS earthquakes;

CREATE TABLE earthquakes (
  time             timestamp,
  latitude         double precision,
  longitude        double precision,
  depth            double precision,
  mag              double precision,
  magtype          varchar(10),
  nst              integer,
  gap              double precision,
  dmin             double precision,
  rms              double precision,
  net              varchar(10),
  id               varchar(50),
  updated          timestamp,
  place            text,
  type             varchar(30),
  horizontalerror  double precision,
  deptherror       double precision,
  magerror         double precision,
  magnst           integer,
  status           varchar(20),
  locationsource   varchar(10),
  magsource        varchar(10)
);


------en termiinal---
--psql -U postgres -d mi_database

--brew install postgresql
--psql --version
--psql
--SELECT current_database(); #Solo para revisar cual es nuestra database

--\dt
--\d table_name

--\copy ufo FROM '/Path/earthquakes1.csv' CSV HEADER;

--\q #exit

SELECT column_name
FROM information_schema.columns
WHERE table_name = 'earthquakes';

--
SELECT mag
FROM earthquakes
WHERE mag is not null
ORDER BY 1 desc
LIMIT 20
;

--
SELECT mag
    ,count(id) as earthquakes
    ,round(count(id) * 100.0 / sum(count(id)) over (partition by 1),8)
     as pct_earthquakes
    FROM earthquakes
    WHERE mag is not null
    GROUP BY 1
    ORDER BY 1 desc
    ;
--

SELECT place, mag, count(*)
FROM earthquakes
WHERE mag is not null
and place = 'Northern California'
GROUP BY 1,2
ORDER BY 1,2 desc
;

-- Calculating percentiles to find anomalies

SELECT place
,mag
,percentile
,count(*)
FROM
(
    SELECT place
    ,mag
    ,percent_rank() over (partition by place order by mag) as percentile
    FROM earthquakes
    WHERE mag is not null
    and place = 'Northern California'
) a
GROUP BY 1,2,3
ORDER BY 1,2 desc
;

--
 SELECT place, mag  
    ,ntile(100) over (partition by place order by mag) as ntile
    FROM earthquakes
    WHERE mag is not null
    and place = 'Central Alaska'
    ORDER BY 1,2 desc
    ;

--Only a extra one for CHile
SELECT place, mag, time
FROM earthquakes
WHERE place ILIKE '%Chile%'
  AND mag IS NOT NULL
ORDER BY mag DESC
LIMIT 10;

--Terremoto de Japan
SELECT place, mag, time
FROM earthquakes
WHERE mag IS NOT NULL
ORDER BY mag DESC
LIMIT 1;

--1th and 2nd Chile y Japan
SELECT place, mag, time
FROM earthquakes
WHERE mag IS NOT NULL
ORDER BY mag DESC
LIMIT 10;

-- just a test for myself
--1
SELECT string_to_array(place, ',') AS parts
FROM earthquakes
WHERE place IS not NULL
LIMIT 10;

--2
SELECT array_length(string_to_array(place, ','), 1) AS n_parts
FROM earthquakes
WHERE place IS NOT NULL
LIMIT 10;

--3
SELECT split_part(place, ',', array_length(string_to_array(place, ','), 1)) AS country_raw
FROM earthquakes
WHERE place IS NOT NULL
LIMIT 10;

--4
SELECT trim(split_part(place, ',', array_length(string_to_array(place, ','), 1))) AS country
FROM earthquakes
WHERE place IS NOT NULL
LIMIT 10;


--5
SELECT
  trim(split_part(place, ',', array_length(string_to_array(place, ','), 1))) AS country,
  place,
  mag,
  time
FROM earthquakes
WHERE mag IS NOT NULL
ORDER BY mag DESC
LIMIT 10;
--

SELECT
  place,
  ntile,
  max(mag) AS maximum,
  min(mag) AS minimum
FROM (
  SELECT
    place,
    mag,
    ntile(4) OVER (PARTITION BY place ORDER BY mag) AS ntile
  FROM earthquakes
  WHERE mag IS NOT NULL
    AND place = 'Central Alaska'
) a
GROUP BY place, ntile
ORDER BY place, ntile DESC;

--
SELECT 
percentile_cont(0.25) within group (order by mag) as pct_25
,percentile_cont(0.5) within group (order by mag) as pct_50
,percentile_cont(0.75) within group (order by mag) as pct_75
FROM earthquakes
WHERE mag is not null
and place = 'Central Alaska'
;

--
SELECT 
percentile_cont(0.25) within group (order by mag) as pct_25_mag
,percentile_cont(0.25) within group (order by depth) as pct_25_depth
FROM earthquakes
WHERE mag is not null
and place = 'Central Alaska'
;

--
SELECT
  place,
  percentile_cont(0.25) within group (order by mag)   AS pct_25_mag,
  percentile_cont(0.25) within group (order by depth) AS pct_25_depth
FROM earthquakes
WHERE mag IS NOT NULL
  AND place IN ('Central Alaska', 'Southern Alaska')
GROUP BY place;


--
SELECT stddev_pop(mag) as stddev_pop_mag
,stddev_samp(mag) as stddev_samp_mag
FROM earthquakes
;

SELECT 
  stddev_pop(mag)  AS stddev_pop_mag,
  stddev_samp(mag) AS stddev_samp_mag
FROM earthquakes
WHERE mag IS NOT NULL;
--

SELECT a.place
,a.mag
,b.avg_mag
,b.std_dev
,(a.mag - b.avg_mag) / b.std_dev as z_score
FROM earthquakes a
JOIN
(
    SELECT avg(mag) as avg_mag
    ,stddev_pop(mag) as std_dev
    FROM earthquakes
    WHERE mag is not null
) b on 1 = 1
WHERE a.mag is not null
ORDER BY 2 desc
;

-- Graphing to find anomalies visually

SELECT mag
,count(*) as earthquakes
FROM earthquakes
GROUP BY 1
ORDER BY 1
;

SELECT mag, depth
    ,count(*) as earthquakes
    FROM earthquakes
    GROUP BY 1,2
    ORDER BY 1,2
    ;


SELECT mag
FROM earthquakes
WHERE place like '%Japan%'
ORDER BY 1
;

--
SELECT ntile_25, median, ntile_75
,(ntile_75 - ntile_25) * 1.5 as iqr
,ntile_25 - (ntile_75 - ntile_25) * 1.5 as lower_whisker
,ntile_75 + (ntile_75 - ntile_25) * 1.5 as upper_whisker
FROM
(
        SELECT percentile_cont(0.25) within group (order by mag) as ntile_25
        ,percentile_cont(0.5) within group (order by mag) as median
        ,percentile_cont(0.75) within group (order by mag) as ntile_75
        FROM earthquakes
        WHERE place like '%Japan%'
) a
;

-- the previous query can be written without the subquery:
SELECT percentile_cont(0.25) within group (order by mag) as ntile_25
,percentile_cont(0.5) within group (order by mag) as median
,percentile_cont(0.75) within group (order by mag) as ntile_75
,1.5 * (percentile_cont(0.75) within group (order by mag) - percentile_cont(0.25) within group (order by mag)) as iqr 
,percentile_cont(0.25) within group (order by mag) - (1.5 * (percentile_cont(0.75) within group (order by mag) - percentile_cont(0.25) within group (order by mag))) as lower_whisker
,percentile_cont(0.75) within group (order by mag) + (1.5 * (percentile_cont(0.75) within group (order by mag) - percentile_cont(0.25) within group (order by mag))) as upper_whisker
FROM earthquakes
WHERE place like '%Japan%'
;
--

SELECT date_part('year',time)::int as year
,mag
FROM earthquakes
WHERE place like '%Japan%'
ORDER BY 1,2
;

------ Forms of anomalies
-- Anomalous values

SELECT mag, count(*)
FROM earthquakes
WHERE mag > 1
GROUP BY 1
ORDER BY 1
limit 100
;

--
SELECT net, count(*)
FROM earthquakes
WHERE depth > 600
GROUP BY 1
;

SELECT place, count(*)
    FROM earthquakes
    WHERE depth > 600
    GROUP BY 1
;
--
SELECT 
case 
  when place like '% of %' then split_part(place,' of ',2) 
     else place end as place_name
,count(*)
FROM earthquakes
WHERE depth > 600
GROUP BY 1
ORDER BY 2 desc
;
--

SELECT count(distinct type) as distinct_types
,count(distinct lower(type)) as distinct_lower
FROM earthquakes
;

SELECT type,
       lower(type),
       type = lower(type) AS flag,
       count(*) AS records
FROM earthquakes
GROUP BY 1,2,3
ORDER BY 2,4 DESC;
--

 SELECT type, count(*) as records
    FROM earthquakes
    GROUP BY 1
    ORDER BY 2 desc
;

-- Anomalous counts or frequencies
SELECT date_trunc('year',time)::date as earthquake_year
,count(*) as earthquakes
FROM earthquakes
GROUP BY 1
;
--

SELECT date_trunc('month',time)::date as earthquake_month
    ,count(*) as earthquakes
    FROM earthquakes
    GROUP BY 1
;

SELECT date_trunc('month',time)::date as earthquake_month
,count(*) as earthquakes
FROM earthquakes
GROUP BY 1
;

SELECT date_trunc('month',time)::date as earthquake_month
,status
,count(*) as earthquakes
FROM earthquakes
GROUP BY 1,2
ORDER BY 1
;

SELECT place, count(*) as earthquakes
FROM earthquakes
WHERE mag >= 6
GROUP BY 1
ORDER BY 2 desc
;

--
SELECT
    case when place like '% of %' then split_part(place,' of ',2)
else place
         end as place
    ,count(*) as earthquakes
    FROM earthquakes
    WHERE mag >= 6
    GROUP BY 1
    ORDER BY 2 desc
    ;

    --

  SELECT place
,extract('days' from '2020-12-31 23:59:59' - latest) 
 as days_since_latest
,count(*) as earthquakes
,extract('days' from avg(gap)) as avg_gap
,extract('days' from max(gap)) as max_gap
FROM
(
        SELECT place
        ,time
        ,lead(time) over (partition by place order by time) as next_time
        ,lead(time) over (partition by place order by time) - time as gap
        ,max(time) over (partition by place) as latest
        FROM
        (
                SELECT 
                replace(
                  initcap(
                  case when place ~ ', [A-Z]' then split_part(place,', ',2)
                       when place like '% of %' then split_part(place,' of ',2)
                       else place end
                )
                ,'Region','')
                as place
                ,time
                FROM earthquakes
                WHERE mag > 5
        ) a
) a         
GROUP BY 1,2        
;