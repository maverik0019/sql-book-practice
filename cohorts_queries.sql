DROP TABLE IF EXISTS public.legislators_terms;

CREATE TABLE public.legislators_terms (
  id_bioguide    TEXT,
  term_number    INTEGER,
  term_id        TEXT PRIMARY KEY,
  term_type      TEXT,
  term_start     DATE,
  term_end       DATE,
  state          CHAR(2),
  district       INTEGER,
  "class"        SMALLINT,
  party          TEXT,
  how            TEXT,
  urlURI          TEXT,
  address        TEXT,
  phone          TEXT,
  fax            TEXT,
  contact_form   TEXT,
  office         TEXT,
  state_rank     TEXT,
  rss_url        TEXT,
  caucus         TEXT
);


-- Basic retention
SELECT id_bioguide
,min(term_start) as first_term
FROM legislators_terms 
GROUP BY 1
;


SELECT date_part('year',age(b.term_start,a.first_term)) as periods
,count(distinct a.id_bioguide) as cohort_retained
FROM
(
        SELECT id_bioguide
        ,min(term_start) as first_term
        FROM legislators_terms 
        GROUP BY 1
) a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
GROUP BY 1
;


--% de retención usando el tamaño inicial como base
SELECT period
    ,first_value(cohort_retained) over (order by period) as cohort_size
    ,cohort_retained
    ,cohort_retained /
     first_value(cohort_retained) over (order by period) as pct_retained
    FROM
    (
        SELECT date_part('year',age(b.term_start,a.first_term)) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
            SELECT id_bioguide, min(term_start) as first_term
            FROM legislators_terms
            GROUP BY 1
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
GROUP BY 1 ) aa
;


--

SELECT cohort_size
    ,max(case when period = 0 then pct_retained end) as yr0
    ,max(case when period = 1 then pct_retained end) as yr1
    ,max(case when period = 2 then pct_retained end) as yr2
    ,max(case when period = 3 then pct_retained end) as yr3
    ,max(case when period = 4 then pct_retained end) as yr4
FROM (
        SELECT period
        ,first_value(cohort_retained) over (order by period)
         as cohort_size
        ,cohort_retained
         / first_value(cohort_retained) over (order by period)
         as pct_retained
        FROM
(
SELECT
            date_part('year',age(b.term_start,a.first_term)) as period
            ,count(*) as cohort_retained
            FROM
            (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                GROUP BY 1
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide GROUP BY 1
) aa ) aaa
GROUP BY 1 ;



---con decimal
SELECT cohort_size
    ,max(case when period = 0 then pct_retained end) as yr0
    ,max(case when period = 1 then pct_retained end) as yr1
    ,max(case when period = 2 then pct_retained end) as yr2
    ,max(case when period = 3 then pct_retained end) as yr3
    ,max(case when period = 4 then pct_retained end) as yr4
FROM (
    SELECT period
        ,first_value(cohort_retained) over (order by period) as cohort_size
        ,cohort_retained::numeric
         / first_value(cohort_retained) over (order by period) as pct_retained
    FROM (
        SELECT date_part('year', age(b.term_start, a.first_term)) as period
            ,count(*) as cohort_retained
        FROM (
            SELECT id_bioguide, min(term_start) as first_term
            FROM legislators_terms
            GROUP BY 1
        ) a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
        GROUP BY 1
    ) aa
) aaa
GROUP BY 1;


---
SELECT a.id_bioguide, 
    a.first_term,
    b.term_start, 
    b.term_end
    ,c.date
    ,date_part('year',age(c.date,a.first_term)) as period
    FROM
    (
        SELECT id_bioguide, 
        min(term_start) as first_term
        FROM legislators_terms
        GROUP BY 1
)a
JOIN legislators_terms b 
    on a.id_bioguide = b.id_bioguide
    LEFT JOIN date_dim c on c.date 
    between b.term_start and b.term_end
    and c.month_name = 'December' 
    and c.day_of_month = 31
    ;


--column "term_end" comes from the legislators_terms table
SELECT *
FROM legislators_terms
LIMIT 5;


--generar fechas artificialmente
SELECT generate_series::date AS date
FROM generate_series(
    '1770-12-31',
    '2020-12-31',
    interval '1 year'
)


--Genera una fecha 31 de diciembre por cada año que aparece en term_start
SELECT DISTINCT
    make_date(date_part('year', term_start)::int, 12, 31)
FROM legislators_terms;




--
SELECT
    coalesce(date_part('year',age(c.date,a.first_term)),0) as period
    ,count(distinct a.id_bioguide) as cohort_retained
    FROM
    (
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms
        GROUP BY 1
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c on c.date 
    between b.term_start and b.term_end
    and c.month_name = 'December' 
    and c.day_of_month = 31
    GROUP BY 1
    ;



SELECT period
    ,first_value(cohort_retained) over (order by period) as cohort_size
    ,cohort_retained
    ,cohort_retained * 1.0 /
     first_value(cohort_retained) over (order by period) as pct_retained
    FROM
    (
        SELECT coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
            SELECT id_bioguide, min(term_start) as first_term
            FROM legislators_terms
            GROUP BY 1
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c on c.date between b.term_start and b.term_end and c.month_name = 'December' and c.day_of_month = 31
GROUP BY 1
) aa ;



--reconstruyendo term_end (fecha de término) en caso de que no exista
SELECT a.id_bioguide, a.first_term
    ,b.term_start
    ,case when b.term_type = 'rep' then b.term_start + interval '2 years'
          when b.term_type = 'sen' then b.term_start + interval '6 years'
          end as term_end
    FROM
    (
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms
        GROUP BY 1
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide ;



--resta 1 día para que el mandato actual termine el día anterior

SELECT a.id_bioguide, a.first_term
    ,b.term_start
    ,lead(b.term_start) over (partition by a.id_bioguide order by b.term_start)
     - interval '1 day' as term_end
FROM (
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms
        GROUP BY 1
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide ;


--tabla de cohortes (lista para pivot/heatmap)
SELECT date_part('year',a.first_term) as first_year
    ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
    ,count(distinct a.id_bioguide) as cohort_retained
    FROM
    (
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms
        GROUP BY 1 )a
    JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
    LEFT JOIN date_dim c on c.date between b.term_start and b.term_end
    and c.month_name = 'December' and c.day_of_month = 31
    GROUP BY 1,2
    ;



--tabla de cohortes (por first_year y period) y 
--le agrega tamaño de cohorte y % retenido dentro de cada cohorte
    SELECT first_year, period
    ,first_value(cohort_retained) over (partition by first_year
                                        order by period) as cohort_size
    ,cohort_retained
    ,cohort_retained /
     first_value(cohort_retained) over (partition by first_year
                                        order by period) as pct_retained
FROM (
        SELECT date_part('year',a.first_term) as first_year
        ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
            SELECT id_bioguide, 
            min(term_start) as first_term
            FROM legislators_terms
            GROUP BY 1
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c on c.date between b.term_start and b.term_end and c.month_name = 'December' and c.day_of_month = 31
GROUP BY 1,2
) aa ;


--cohorte no se define por siglo (first_century)
SELECT first_century, period
    ,first_value(cohort_retained) over (partition by first_century
                                        order by period) as cohort_size
    ,cohort_retained
    ,cohort_retained /
     first_value(cohort_retained) over (partition by first_century
                                        order by period) as pct_retained
FROM (
        SELECT date_part('century',a.first_term) as first_century
        ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
            SELECT id_bioguide, min(term_start) as first_term
            FROM legislators_terms
            GROUP BY 1
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c on c.date between b.term_start and b.term_end and c.month_name = 'December' and c.day_of_month = 31
GROUP BY 1,2
    ) aa
    ORDER BY 1,2
    ;


--Para cada legislador, obtiene:primer mandato (first_term) y
--estado por el que entró por primera vez (first_state)
SELECT distinct id_bioguide ,
    min(term_start) over (partition by id_bioguide) as first_term ,
    first_value(state) over (partition by id_bioguide order by term_start)
    as first_state 
FROM legislators_terms ;



--cohorte por estado de entrada
SELECT first_state, period
    ,first_value(cohort_retained) over (partition by first_state
                                        order by period) as cohort_size
    ,cohort_retained
    ,cohort_retained /
     first_value(cohort_retained) over (partition by first_state
                                        order by period) as pct_retained
FROM (
        SELECT a.first_state
        ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
            SELECT distinct id_bioguide
            ,min(term_start) over (partition by id_bioguide) as first_term
            ,first_value(state) over (partition by id_bioguide order by term_start)
             as first_state
            FROM legislators_terms
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c on c.date between b.term_start and b.term_end and c.month_name = 'December' and c.day_of_month = 31
GROUP BY 1,2
) aa ;

--retención por “antigüedad” (period) y por genero(M/F)
-- Defining the cohort from a separate table
--Primero crearemos la tabla par apoder trabajar con esta

--TAbla
DROP TABLE IF EXISTS legislators;

CREATE TABLE legislators (
  full_name text,
  first_name text,
  last_name text,
  middle_name text,
  nickname text,
  suffix text,
  other_names_end text,
  other_names_middle text,
  other_names_last text,
  birthday text,
  gender text,
  id_bioguide text,
  id_bioguide_previous_0 text,
  id_govtrack text,
  id_icpsr text,
  id_wikipedia text,
  id_wikidata text,
  id_google_entity_id text,
  id_house_history text,
  id_house_history_alternate text,
  id_thomas text,
  id_cspan text,
  id_votesmart text,
  id_lis text,
  id_ballotpedia text,
  id_opensecrets text,
  id_fec_0 text,
  id_fec_1 text,
  id_fec_2 text
);

--Solo como opcion dejar birthday como DATE
ALTER TABLE legislators ADD COLUMN birthday_date date;

UPDATE legislators
SET birthday_date = NULLIF(birthday,'')::date;


--
SELECT d.gender
,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
,count(distinct a.id_bioguide) as cohort_retained
FROM
(
        SELECT id_bioguide, 
        min(term_start) as first_term
        FROM legislators_terms 
        GROUP BY 1
) a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
LEFT JOIN date_dim c on c.date between b.term_start and b.term_end 
and c.month_name = 'December' and c.day_of_month = 31
JOIN legislators d on a.id_bioguide = d.id_bioguide
GROUP BY 1,2
ORDER BY 2,1
;

--
SELECT gender, 
    period
    ,first_value(cohort_retained) over (partition by gender
                                        order by period) as cohort_size
    ,cohort_retained
    ,cohort_retained/
     first_value(cohort_retained) over (partition by gender
                                        order by period) as pct_retained
FROM (
        SELECT d.gender
        ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
            SELECT id_bioguide, min(term_start) as first_term
            FROM legislators_terms
            GROUP BY 1
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c on c.date between b.term_start 
and b.term_end 
and c.month_name = 'December' 
and c.day_of_month = 31
JOIN 
legislators d on a.id_bioguide = d.id_bioguide
    GROUP BY 1,2
) aa
;


--EXTRA The first female legislator who take office in 1917(Jeannette Rankin)
SELECT
    l.full_name,
    l.gender,
    MIN(t.term_start) AS first_term
FROM legislators l
JOIN legislators_terms t
  ON l.id_bioguide = t.id_bioguide
WHERE l.gender = 'F'
GROUP BY l.full_name, l.gender
ORDER BY first_term
LIMIT 1;


--mismo que antes pero cohortes entre 1917 y 1999.
SELECT gender, period
,first_value(cohort_retained) over (partition by gender
                                    order by period) as cohort_size
,cohort_retained
,cohort_retained /
 first_value(cohort_retained) over (partition by gender
                                    order by period) as pct_retained
FROM (
    SELECT d.gender
    ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
    ,count(distinct a.id_bioguide) as cohort_retained
    FROM
    (
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms
        GROUP BY 1
)a
JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c on c.date between b.term_start and b.term_end and c.month_name = 'December' and c.day_of_month = 31
JOIN legislators d on a.id_bioguide = d.id_bioguide
WHERE a.first_term between '1917-01-01' and '1999-12-31'
GROUP BY 1,2
) aa ;

----------- Dealing with sparse cohorts
SELECT first_state, 
gender, 
period
,first_value(cohort_retained) over (partition by first_state, gender 
                                    order by period) as cohort_size
,cohort_retained
,cohort_retained *1.0/ 
 first_value(cohort_retained) over (partition by first_state, gender 
                                    order by period) as pct_retained
FROM
(
        SELECT a.first_state, 
        d.gender
        ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
                SELECT distinct id_bioguide
                ,min(term_start) over (partition by id_bioguide) as first_term
                ,first_value(state) over (partition by id_bioguide 
                                          order by term_start) as first_state
                FROM legislators_terms 
        ) a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
        LEFT JOIN date_dim c on c.date between b.term_start and b.term_end 
        and c.month_name = 'December' 
        and c.day_of_month = 31
        JOIN legislators d on a.id_bioguide = d.id_bioguide
        WHERE a.first_term between '1917-01-01' and '1999-12-31'
        GROUP BY 1,2,3
) aa
;



--
SELECT aa.gender, aa.first_state, cc.period, aa.cohort_size
    FROM
    (
        SELECT b.gender, a.first_state
        ,count(distinct a.id_bioguide) as cohort_size
        FROM
        (
            SELECT distinct id_bioguide
            ,min(term_start) over (partition by id_bioguide) as first_term
            ,first_value(state) over (partition by id_bioguide
                                      order by term_start) as first_state
FROM legislators_terms )a
        JOIN legislators b on a.id_bioguide = b.id_bioguide
        WHERE a.first_term between '1917-01-01' and '1999-12-31'
        GROUP BY 1,2
) aa JOIN (
        SELECT generate_series as period
        FROM generate_series(0,20,1)
    ) cc on 1 = 1
;


---aaa = el esqueleto////grilla completa
--
SELECT aaa.gender, aaa.first_state, aaa.period, aaa.cohort_size
    ,coalesce(ddd.cohort_retained,0) as cohort_retained
    ,coalesce(ddd.cohort_retained,0) / aaa.cohort_size as pct_retained
    FROM
    (
        SELECT aa.gender, aa.first_state, cc.period, aa.cohort_size
        FROM
        (
            SELECT b.gender, a.first_state
            ,count(distinct a.id_bioguide) as cohort_size
            FROM
            (
                SELECT distinct id_bioguide
                ,min(term_start) over (partition by id_bioguide)
                 as first_term
                ,first_value(state) over (partition by id_bioguide
                                          order by term_start)
                                          as first_state
            FROM legislators_terms )a
            JOIN legislators b on a.id_bioguide = b.id_bioguide
            WHERE a.first_term between '1917-01-01' and '1999-12-31'
            GROUP BY 1,2
                ) aa JOIN (
            SELECT generate_series as period
            FROM generate_series(0,20,1)
            ) cc on 1 = 1
        ) aaa
        LEFT JOIN
        (
        SELECT d.first_state, g.gender
        ,coalesce(date_part('year',age(f.date,d.first_term)),0) as period
        ,count(distinct d.id_bioguide) as cohort_retained
        FROM (
        SELECT distinct id_bioguide
        ,min(term_start) over (partition by id_bioguide) as first_term
        ,first_value(state) over (partition by id_bioguide
                                  order by term_start) as first_state
FROM legislators_terms )d
    JOIN legislators_terms e on d.id_bioguide = e.id_bioguide
    LEFT JOIN date_dim f on f.date between e.term_start and e.term_end
     and f.month_name = 'December' 
     and f.day_of_month = 31
    JOIN legislators g on d.id_bioguide = g.id_bioguide
    WHERE d.first_term between '1917-01-01' and '1999-12-31'
    GROUP BY 1,2,3
) ddd on aaa.gender = ddd.gender and aaa.first_state = ddd.first_state
and aaa.period = ddd.period


--
SELECT distinct id_bioguide, term_type, date('2000-01-01') as first_term
    ,min(term_start) as min_start
    FROM legislators_terms
    WHERE term_start <= '2000-12-31' and term_end >= '2000-01-01'
    GROUP BY 1,2,3
    ;


--
SELECT term_type, period
    ,first_value(cohort_retained) over (partition by term_type order by period)
     as cohort_size
    ,cohort_retained
    ,cohort_retained *1.0/
     first_value(cohort_retained) over (partition by term_type order by period)
     as pct_retained
    FROM
    (
        SELECT a.term_type
        ,coalesce(date_part('year',age(c.date,a.first_term)),0) as period
        ,count(distinct a.id_bioguide) as cohort_retained
        FROM
        (
            SELECT distinct id_bioguide, 
            term_type
            ,date('2000-01-01') as first_term
            ,min(term_start) as min_start
            FROM legislators_terms
            WHERE term_start <= '2000-12-31' and term_end >= '2000-01-01'
            GROUP BY 1,2,3 )a
        JOIN legislators_terms b on a.id_bioguide = b.id_bioguide
        and b.term_start >= a.min_start
        LEFT JOIN date_dim c on c.date between b.term_start and b.term_end
        and c.month_name = 'December' and c.day_of_month = 31
        and c.year >= 2000
        GROUP BY 1,2
) aa ;


--Survivorship
SELECT id_bioguide
    ,min(term_start) as first_term
    ,max(term_start) as last_term,
   --age(MAX(term_start), MIN(term_start)) AS tenure
    --date_part('year', age(MAX(term_start), MIN(term_start))) AS tenure_years
    FROM legislators_terms
    GROUP BY 1
    ;

--tenure_years
SELECT id_bioguide
    ,date_part('century',min(term_start)) as first_century
    ,min(term_start) as first_term
    ,max(term_start) as last_term
    ,date_part('year',age(max(term_start),min(term_start))) as tenure
    FROM legislators_terms
    GROUP BY 1




SELECT first_century
    ,count(distinct id_bioguide) as cohort_size
    ,count(distinct case when tenure >= 10 then id_bioguide
                         end) as survived_10
    ,count(distinct case when tenure >= 10 then id_bioguide end)
     *1.0/ count(distinct id_bioguide) as pct_survived_10
    FROM
    (
        SELECT id_bioguide
        ,date_part('century',min(term_start)) as first_century
        ,min(term_start) as first_term
        ,max(term_start) as last_term
        ,date_part('year',age(max(term_start),min(term_start))) as tenure
        FROM legislators_terms
        GROUP BY 1
)a
GROUP BY 1 ;

--
SELECT first_century
    ,count(distinct id_bioguide) as cohort_size
    ,count(distinct case when total_terms >= 5 then id_bioguide end)
     as survived_5
    ,count(distinct case when total_terms >= 5 then id_bioguide end)
     *1.0/ count(distinct id_bioguide) as pct_survived_5_terms
    FROM
    (
        SELECT id_bioguide
        ,date_part('century',min(term_start)) as first_century
        ,count(term_start) as total_terms
        FROM legislators_terms
        GROUP BY 1
)a
GROUP BY 1 ;

--survivorship for each number of years or periods
SELECT a.first_century, b.terms
    ,count(distinct id_bioguide) as cohort
    ,count(distinct case when a.total_terms >= b.terms then id_bioguide
                         end) as cohort_survived
    ,count(distinct case when a.total_terms >= b.terms then id_bioguide end)*1.0
     / count(distinct id_bioguide) as pct_survived
FROM (
        SELECT id_bioguide
        ,date_part('century',min(term_start)) as first_century
        ,count(term_start) as total_terms
        FROM legislators_terms
        GROUP BY 1
)a JOIN
(
    SELECT generate_series as terms
    FROM generate_series(1,20,1)
) b on 1 = 1
GROUP BY 1,2
;

--Returnship, or Repeat Purchase Behavior
SELECT date_part('century',a.first_term)::int as cohort_century
,count(id_bioguide) as reps
FROM
(
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY 1
) a
GROUP BY 1
;

--

SELECT date_part('century',a.first_term) as cohort_century
,count(id_bioguide) as reps
FROM
(
        SELECT id_bioguide, min(term_start) as first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY 1
) a
GROUP BY 1
ORDER BY 1
;

--
SELECT aa.cohort_century
,bb.rep_and_sen * 1.0 / aa.reps as pct_rep_and_sen
FROM
(
        SELECT date_part('century',a.first_term) as cohort_century
        ,count(id_bioguide) as reps
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) a
        GROUP BY 1
) aa
LEFT JOIN
(
        SELECT date_part('century',b.first_term) as cohort_century
        ,count(distinct b.id_bioguide) as rep_and_sen
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) b
        JOIN legislators_terms c on b.id_bioguide = c.id_bioguide
        and c.term_type = 'sen' 
        and c.term_start > b.first_term
        GROUP BY 1
) bb 
on aa.cohort_century = bb.cohort_century
;



--


SELECT aa.cohort_century
,bb.rep_and_sen * 1.0 / aa.reps as pct_rep_and_sen
FROM
(
        SELECT date_part('century',a.first_term) as cohort_century
        ,count(id_bioguide) as reps
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) a
        WHERE first_term <= '2009-12-31'
        GROUP BY 1
) aa
LEFT JOIN
(
        SELECT date_part('century',b.first_term) as cohort_century
        ,count(distinct b.id_bioguide) as rep_and_sen
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) b
        JOIN legislators_terms c on b.id_bioguide = c.id_bioguide
        and c.term_type = 'sen' 
        and c.term_start > b.first_term
        WHERE age(c.term_start, b.first_term) <= interval '10 years'
        GROUP BY 1
) bb on aa.cohort_century = bb.cohort_century
;


--
SELECT aa.cohort_century::int as cohort_century
,round(bb.rep_and_sen_5_yrs * 1.0 / aa.reps,4) as pct_5_yrs
,round(bb.rep_and_sen_10_yrs * 1.0 / aa.reps,4) as pct_10_yrs
,round(bb.rep_and_sen_15_yrs * 1.0 / aa.reps,4) as pct_15_yrs
FROM
(
        SELECT date_part('century',a.first_term) as cohort_century
        ,count(id_bioguide) as reps
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) a
        WHERE first_term <= '2009-12-31'
        GROUP BY 1
) aa
LEFT JOIN
(
        SELECT date_part('century',b.first_term) as cohort_century
        ,count(distinct case when age(c.term_start, b.first_term) <= interval '5 years' then b.id_bioguide end) as rep_and_sen_5_yrs
        ,count(distinct case when age(c.term_start, b.first_term) <= interval '10 years' then b.id_bioguide end) as rep_and_sen_10_yrs
        ,count(distinct case when age(c.term_start, b.first_term) <= interval '15 years' then b.id_bioguide end) as rep_and_sen_15_yrs
        FROM
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                WHERE term_type = 'rep'
                GROUP BY 1
        ) b
        JOIN legislators_terms c on b.id_bioguide = c.id_bioguide
        and c.term_type = 'sen' and c.term_start > b.first_term
        GROUP BY 1
) bb on aa.cohort_century = bb.cohort_century
;

----------- Cumulative calculations ----------------------------------
SELECT date_part('century',a.first_term)::int as century
,first_type
,count(distinct a.id_bioguide) as cohort
,count(b.term_start) as terms
FROM
(
        SELECT distinct id_bioguide
        ,first_value(term_type) over (partition by id_bioguide order by term_start) as first_type
        ,min(term_start) over (partition by id_bioguide) as first_term
        ,min(term_start) over (partition by id_bioguide) + interval '10 years' as first_plus_10
        FROM legislators_terms
) a
LEFT JOIN legislators_terms b on a.id_bioguide = b.id_bioguide 
and b.term_start between a.first_term and a.first_plus_10
GROUP BY 1,2
;


-- Cross-section analysis, with a cohort lens 
--Survivorship Bias
SELECT b.date, 
        count(distinct a.id_bioguide) as legislators
FROM legislators_terms a
JOIN date_dim b on b.date between a.term_start and a.term_end
and b.month_name = 'December' 
and b.day_of_month = 31
and b.year <= 2019
GROUP BY 1
;


--Add centyry cohorte
SELECT b.date
,date_part('century',first_term) as century
,count(distinct a.id_bioguide) as legislators
FROM legislators_terms a
JOIN date_dim b on b.date between a.term_start and a.term_end
    and b.month_name = 'December' and b.day_of_month = 31
    and b.year <= 2019
JOIN
(
    SELECT id_bioguide, min(term_start) as first_term
    FROM legislators_terms
    GROUP BY 1
) c on a.id_bioguide = c.id_bioguide
GROUP BY 1,2
;


--
SELECT date
,century
,legislators
,sum(legislators) over (partition by date) as cohort
,legislators * 100.0 / sum(legislators) over (partition by date) as pct_century
FROM
(
        SELECT b.date
        ,date_part('century',first_term)::int as century
        ,count(distinct a.id_bioguide) as legislators
        FROM legislators_terms a
        JOIN date_dim b on b.date between a.term_start and a.term_end and b.month_name = 'December' and b.day_of_month = 31 and b.year <= 2019
        JOIN
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                GROUP BY 1
        ) c on a.id_bioguide = c.id_bioguide        
        GROUP BY 1,2
) a
ORDER BY 1,2
;


--
SELECT date
,coalesce(sum(case when century = 18 then legislators end) * 100.0 / sum(legislators),0) as pct_18
,coalesce(sum(case when century = 19 then legislators end) * 100.0 / sum(legislators),0) as pct_19
,coalesce(sum(case when century = 20 then legislators end) * 100.0 / sum(legislators),0) as pct_20
,coalesce(sum(case when century = 21 then legislators end) * 100.0 / sum(legislators),0) as pct_21
FROM
(
        SELECT b.date
        ,date_part('century',first_term)::int as century
        ,count(distinct a.id_bioguide) as legislators
        FROM legislators_terms a
        JOIN date_dim b on b.date between a.term_start and a.term_end and b.month_name = 'December' and b.day_of_month = 31 and b.year <= 2019
        JOIN
        (
                SELECT id_bioguide, min(term_start) as first_term
                FROM legislators_terms
                GROUP BY 1
        ) c on a.id_bioguide = c.id_bioguide        
        GROUP BY 1,2
) aa
GROUP BY 1
ORDER BY 1
;

--cálculo acumulativo (cumulative / running total)
SELECT id_bioguide, 
    date
,count(date) over (partition by id_bioguide order by date rows between unbounded preceding and current row) as cume_years
FROM
(
        SELECT distinct a.id_bioguide, 
            b.date
        FROM legislators_terms a
        JOIN date_dim b on b.date between a.term_start and a.term_end 
        and b.month_name = 'December' 
        and b.day_of_month = 31 
        and b.year <= 2019
) a
;

--number of legislators for each combination of
--date and cume_years to create a distribution:
SELECT date, 
    cume_years
    ,count(distinct id_bioguide) as legislators
FROM
(
    SELECT id_bioguide, date
    ,count(date) over (partition by id_bioguide order by date rows between unbounded preceding and current row) as cume_years
    FROM
    (
        SELECT distinct a.id_bioguide, b.date
        FROM legislators_terms a
        JOIN date_dim b on b.date between a.term_start and a.term_end
        and b.month_name = 'December' and b.day_of_month = 31
        and b.year <= 2019
        GROUP BY 1,2
    ) aa
) aaa
GROUP BY 1,2
;

--
SELECT date, 
        count(*) as tenures --use max(cume_years):mayor valor de antigüedad acumulada ese año
FROM 
(
        SELECT date, 
        cume_years
        ,count(distinct id_bioguide) as legislators
        FROM
        (
                SELECT id_bioguide, date
                ,count(date) over (partition by id_bioguide order by date rows between unbounded preceding and current row) as cume_years
                FROM
                (
                        SELECT distinct a.id_bioguide, b.date
                        FROM legislators_terms a
                        JOIN date_dim b on b.date between a.term_start and a.term_end 
                        and b.month_name = 'December' 
                        and b.day_of_month = 31 
                        and b.year <= 2019
                        GROUP BY 1,2
                ) aa
        ) aaa
        GROUP BY 1,2
) aaaa
GROUP BY 1
;


--rangos de tenure
SELECT date, 
    tenure
    ,legislators * 100.0 /sum(legislators) over (partition by date) as pct_legislators 
FROM
(
        SELECT date
        ,case when cume_years <= 4 then '1 to 4'
              when cume_years <= 10 then '5 to 10'
              when cume_years <= 20 then '11 to 20'
              else '21+' end as tenure
        ,count(distinct id_bioguide) as legislators
        FROM
        (
                SELECT id_bioguide, 
                    date
                ,count(date) over (partition by id_bioguide order by date rows between unbounded preceding and current row) as cume_years
                FROM
                (
                        SELECT distinct a.id_bioguide, b.date
                        FROM legislators_terms a
                        JOIN date_dim b on b.date between a.term_start and a.term_end and b.month_name = 'December' and b.day_of_month = 31 and b.year <= 2019
                        GROUP BY 1,2
                ) a
        ) aa
        GROUP BY 1,2
) aaa
;