----- Code organization 

SELECT type, mag
,case when place like '%CA%' then 'California'
      when place like '%AK%' then 'Alaska'
      else trim(split_part(place,',',2)) 
      end as place
,count(*)
FROM earthquakes
WHERE date_part('year',time) >= 2019
and mag between 0 and 1
GROUP BY 1,2,3
;

----- Organizing computations

SELECT state
,count(*) as terms
FROM legislators_terms
GROUP BY 1
HAVING count(*) >= 1000
ORDER BY 2 desc
;

SELECT state
,count(*) as terms
,avg(count(*)) over () as avg_terms
FROM legislators_terms
GROUP BY 1
;

SELECT state
,count(*) as terms
,rank() over (order by count(*) desc)
FROM legislators_terms
GROUP BY 1
;


--lateral
--subquery

SELECT date_part('year',c.first_term) as first_year
,a.party
,count(a.id_bioguide) as legislators
FROM
(
        SELECT distinct id_bioguide, party
        FROM legislators_terms
        WHERE term_end > '2020-06-01'
) a,
LATERAL
(
        SELECT b.id_bioguide
        ,min(term_start) as first_term
        FROM legislators_terms b
        WHERE b.id_bioguide = a.id_bioguide
        and b.party <> a.party
        GROUP BY 1
) c
GROUP BY 1,2
;
/*Lo mismo pero mas facil*/
WITH current_legislators AS (
    SELECT DISTINCT id_bioguide, party
    FROM legislators_terms
    WHERE term_end > '2020-06-01'
),

first_other_party AS (
    SELECT b.id_bioguide,
           c.party AS current_party,
           MIN(b.term_start) AS first_term
    FROM legislators_terms b
    JOIN current_legislators c
      ON b.id_bioguide = c.id_bioguide
    WHERE b.party <> c.party
    GROUP BY b.id_bioguide, c.party
)

SELECT date_part('year', first_term) AS first_year,
       current_party AS party,
       COUNT(*) AS legislators
FROM first_other_party
GROUP BY 1,2
ORDER BY 1,2;

--TEMMP TABLE

CREATE temporary table temp_states
(
state varchar primary key
)
;

INSERT into temp_states
SELECT distinct state
FROM legislators_terms
;

CREATE temporary table temp_states
as
SELECT distinct state
FROM legislators_terms
;    
