--SELECT * FROM INFORMATION_SCHEMA.COLUMNS;
INFORMATION_SCHEMA.COLUMNS.TABLE_NAME

---- Text characteristics
SELECT length(sighting_report),
 count(*) as records
FROM ufo
GROUP BY 1
ORDER BY 1
;

---- Text parsing
SELECT left(sighting_report,8) as left_digits
,count(*)
FROM ufo
GROUP BY 1
;

SELECT right(left(sighting_report,25),14) as occurred
FROM ufo
;

SELECT split_part('This is an example of an example string'
                      ,'an example'
,1);


SELECT split_part(sighting_report,'Occurred : ',2) as split_1
FROM ufo
;


SELECT split_part(
             split_part(sighting_report,' (Entered',1)
             ,'Occurred : ',2) as occurred
FROM ufo

--
SELECT
    split_part(
      split_part(
        split_part(sighting_report,' (Entered',1)
        ,'Occurred : ',2)
        ,'Reported',1) as occurred
FROM ufo ;

--
SELECT split_part(split_part(split_part(sighting_report,' (Entered',1),'Occurred : ',2),'Reported',1) as occurred
,split_part(split_part(sighting_report,')',1),'Entered as : ',2) as entered_as
,split_part(split_part(split_part(split_part(sighting_report,'Post',1),'Reported: ',2),' AM',1),' PM',1) as reported
,split_part(split_part(sighting_report,'Location',1),'Posted: ',2) as posted
,split_part(split_part(sighting_report,'Shape',1),'Location: ',2) as location
,split_part(split_part(sighting_report,'Duration',1),'Shape: ',2) as shape
,split_part(sighting_report,'Duration:',2) as duration
FROM ufo
;

---Text Transformations---
SELECT distinct shape, initcap(shape) as shape_clean
FROM
(
        SELECT split_part(
        split_part(sighting_report,'Duration',1)
        ,'Shape: ',2) as shape
        FROM ufo
) a
;

--Extra --Frequency of shapes in UFO sightings--
SELECT
    shape_clean AS shape,
    count(*) AS sightings
FROM (
    SELECT
        initcap(trim(
            split_part(
                split_part(sighting_report,'Duration',1),
                'Shape: ',2
            )
        )) AS shape_clean
    FROM ufo
) a
GROUP BY 1
ORDER BY sightings DESC;


----Extra con python
import pandas as pd
import matplotlib.pyplot as plt

--# df viene directamente del resultado SQL
df = pd.read_sql("""
    SELECT
        coalesce(shape_clean, 'Unknown') AS shape,
        count(*) AS sightings
    FROM (
        SELECT
            initcap(trim(
                split_part(
                    split_part(sighting_report,'Duration',1),
                    'Shape: ',2
                )
            )) AS shape_clean
        FROM ufo
    ) a
    GROUP BY 1
    ORDER BY sightings DESC;
""", conn)

plt.barh(df['shape'], df['sightings'])
plt.gca().invert_yaxis()
plt.title('Number of sightings by shape')
plt.show()



--
SELECT duration, trim(duration) as duration_clean
FROM
(
    SELECT split_part(sighting_report,'Duration:',2) as duration
    FROM ufo
) a
;

--
SELECT duration, trim(duration) as duration_clean
FROM
(
    SELECT split_part(sighting_report,'Duration:',2) as duration
    FROM ufo
) a
;

--
SELECT
CASE
    WHEN occurred ~ '^\d{4}-\d{2}-\d{2}' THEN occurred::timestamp
    ELSE NULL
  END AS occurred_ts,

  NULLIF(reported, '')::timestamp AS reported_ts,

  NULLIF(posted, '')::date AS posted_date
FROM 
(
        SELECT split_part(split_part(split_part(sighting_report,' (Entered',1),'Occurred : ',2),'Reported',1) as occurred   
        ,split_part(split_part(split_part(split_part(sighting_report,'Post',1),'Reported: ',2),' AM',1),' PM',1) as reported
        ,split_part(split_part(sighting_report,'Location',1),'Posted: ',2) as posted
        FROM ufo
        limit 10
) a
;


--fix the problem with the query
/*

case when occurred = '' then null 
     when length(occurred) < 8 then null
     else occurred::timestamp 
end as occurred

*/


SELECT 
case when occurred = '' then null 
     when length(occurred) < 8 then null
     else occurred::timestamp 
     end as occurred
,case when length(reported) < 8 then null
      else reported::timestamp 
      end as reported
,case when posted = '' then null
      else posted::date  
      end as posted
FROM
(
        SELECT split_part(split_part(split_part(sighting_report,'(Entered',1),'Occurred : ',2),'Reported',1) as occurred 
        ,split_part(split_part(split_part(split_part(sighting_report,'Post',1),'Reported: ',2),' AM',1),' PM',1) as reported
        ,split_part(split_part(sighting_report,'Location',1),'Posted: ',2) as posted
        FROM ufo
) a
;


SELECT replace('Some unidentified flying objects were noticed
    above...','unidentified flying objects','UFOs');



--
    SELECT location
    ,replace(replace(location,'close to','near')
             ,'outside of','near') as location_clean
FROM (
        SELECT split_part(split_part(sighting_report,'Shape',1)
                          ,'Location: ',2) as location
FROM ufo )a
;

SELECT 
case when occurred = '' then null 
     when length(occurred) < 8 then null
     else occurred::timestamp 
     end as occurred
,entered_as
,case when length(reported) < 8 then null
      else reported::timestamp 
      end as reported
,case when posted = '' then null
      else posted::date  
      end as posted
,replace(replace(location,'close to','near'),'outside of','near') as location
,initcap(shape) as shape
,trim(duration) as duration
FROM
(
        SELECT split_part(split_part(split_part(sighting_report,' (Entered',1),'Occurred : ',2),'Reported',1) as occurred
        ,split_part(split_part(sighting_report,')',1),'Entered as : ',2) as entered_as   
        ,split_part(split_part(split_part(split_part(sighting_report,'Post',1),'Reported: ',2),' AM',1),' PM',1) as reported
        ,split_part(split_part(sighting_report,'Location',1),'Posted: ',2) as posted
        ,split_part(split_part(sighting_report,'Shape',1),'Location: ',2) as location
        ,split_part(split_part(sighting_report,'Duration',1),'Shape: ',2) as shape
        ,split_part(sighting_report,'Duration:',2) as duration
        FROM ufo
) a
;

---- Finding elements within larger blocks of text
-- Wildcard matches
SELECT count(*)
FROM ufo
WHERE description like '%wife%'
;

SELECT 'this is an example string' like '%example%';
    true
    SELECT 'this is an example string' like '%abc%';
    false
    SELECT 'this is an example string' like '%this_is%';
    true


SELECT count(*)
FROM ufo
WHERE lower(description) like '%wife%'
;

SELECT count(*)
FROM ufo
WHERE description ilike '%wife%'
;


SELECT count(*)
FROM ufo
WHERE description ilike '%wife%'
;

SELECT count(*)
FROM ufo
WHERE lower(description) not like '%wife%'
;

--
SELECT count(*)
FROM ufo
WHERE lower(description) like '%wife%'
or lower(description) like '%husband%'
;
---
SELECT count(*)
FROM ufo
WHERE lower(description) like '%wife%'
or lower(description) like '%husband%'
and lower(description) like '%mother%'
;
--

SELECT count(*)
FROM ufo
WHERE (lower(description) like '%wife%'
       or lower(description) like '%husband%'
       )
and lower(description) like '%mother%'
;


SELECT 
case when lower(description) like '%driving%' then 'driving'
     when lower(description) like '%walking%' then 'walking'
     when lower(description) like '%running%' then 'running'
     when lower(description) like '%cycling%' then 'cycling'
     when lower(description) like '%swimming%' then 'swimming'
     else 'none' end as activity
,count(*)
FROM ufo
GROUP BY 1
ORDER BY 2 desc
;



SELECT description ilike '%south%' as south
    ,description ilike '%north%' as north
    ,description ilike '%east%' as east
    ,description ilike '%west%' as west
    ,count(*)
FROM ufo
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4
;


SELECT
  ( (description ILIKE '%south%')::int
  + (description ILIKE '%north%')::int
  + (description ILIKE '%east%')::int
  + (description ILIKE '%west%')::int ) AS num_dirs,
  count(*) AS n
FROM ufo
GROUP BY 1
ORDER BY 1;

--que direccion se menciona mas ??
SELECT 'north' dir, count(*) FROM ufo WHERE description ILIKE '%north%'
UNION ALL
SELECT 'south', count(*) FROM ufo WHERE description ILIKE '%south%'
UNION ALL
SELECT 'east',  count(*) FROM ufo WHERE description ILIKE '%east%'
UNION ALL
SELECT 'west',  count(*) FROM ufo WHERE description ILIKE '%west%';


--Cuantas direcciones se mencionan por relato?
SELECT
  ((description ILIKE '%north%')::int +
   (description ILIKE '%south%')::int +
   (description ILIKE '%east%')::int  +
   (description ILIKE '%west%')::int) AS num_dirs,
  count(*)
FROM ufo
GROUP BY 1
ORDER BY 1;



-- Exact matches
SELECT first_word, description
FROM
(
    SELECT split_part(description,' ',1) as first_word
    ,description
    FROM ufo
) a
WHERE first_word = 'Red'
or first_word = 'Orange'
or first_word = 'Yellow'
or first_word = 'Green'
or first_word = 'Blue'
or first_word = 'Purple'
or first_word = 'White'
;


SELECT first_word, description
FROM
(
    SELECT split_part(description,' ',1) as first_word
    ,description
    FROM ufo
) a
WHERE first_word in ('Red','Orange','Yellow','Green','Blue','Purple','White')
;


SELECT first_word AS color, count(*) AS count
FROM (
  SELECT split_part(description,' ',1) AS first_word
  FROM ufo
) a
WHERE first_word IN ('Red','Orange','Yellow','Green','Blue','Purple','White')
GROUP BY 1
ORDER BY count DESC;

--

SELECT 
case 
when lower(first_word) in ('red','orange','yellow','green', 
'blue','purple','white') then 'Color'
when lower(first_word) in ('round','circular','oval','cigar') then 'Shape'
when first_word ilike 'triang%' then 'Shape'
when first_word ilike 'flash%' then 'Motion'
when first_word ilike 'hover%' then 'Motion'
when first_word ilike 'pulsat%' then 'Motion'
else 'Other' 
end as first_word_type
,count(*)
FROM
(
    SELECT split_part(description,' ',1) as first_word
    ,description
    FROM ufo
) a
GROUP BY 1
ORDER BY 2 desc
;

-- Regular expressions
-- Finding and replacing with Regex
SELECT left(description,50)
FROM ufo
WHERE left(description,50) ~ '[0-9]+ light[s ,.]'
;

--contine 'data'
SELECT 'The data is about UFOs' ~ 'data' as comparison;

--sin importar mayuscula
SELECT 'The data is about UFOs' ~* 'DATA' as comparison;

--
SELECT 'The data is about UFOs' !~ 'alligators' as comparison;

-- ~ Compares two statements and returns TRUE if one is contained in the other 
-- ~* Compares two statements and returns TRUE if one is contained in the other 
-- !~ Compares two statements and returns FALSE if one is contained in the other 
-- !~* Compares two statements and returns FALSE if one is contained in the other


SELECT
    'The data is about UFOs' ~ '. data' as comparison_1
    ,'The data is about UFOs' ~ '.The' as comparison_2
    ;


SELECT (regexp_matches(description,'[0-9]+ light[s ,.]'))[1]
,count(*)
FROM ufo
WHERE description ~ '[0-9]+ light[s ,.]'
GROUP BY 1
ORDER BY 2 desc
; 
--
SELECT 'The data is about UFOs' ~ 'data *' as comparison_1
    ,'The data is about UFOs' ~ 'data %' as comparison_2
    ;
--
SELECT min(split_part(matched_text,' ',1)::int) as min_lights
,max(split_part(matched_text,' ',1)::int) as max_lights
FROM
(
        SELECT (regexp_matches(description,'[0-9]+ light[s ,.]'))[1] as matched_text
        ,count(*)
        FROM ufo
        WHERE description ~ '[0-9]+ light[s ,.]'
        GROUP BY 1
) a
; 
--
SELECT 'The data is about UFOs' ~ '[Tt]he' as comparison;
--

SELECT 'The data is about UFOs' ~ '[Tt]he' as comparison_1
    ,'the data is about UFOs' ~ '[Tt]he' as comparison_2
    ,'tHe data is about UFOs' ~ '[Tt]he' as comparison_3
    ,'THE data is about UFOs' ~ '[Tt]he' as comparison_4
;

--
SELECT 'sighting lasted 8 minutes' ~ '[789] minutes' 
as comparison;

--
SELECT 'sighting lasted 8 minutes' ~ '[7-9] minutes' as comparison;
--

SELECT 'driving on 495 south' ~ 'on [0-9][0-9][0-9]' as comparison;


SELECT split_part(sighting_report,'Duration:',2) as duration
,count(*) as reports
FROM ufo
GROUP BY 1
;


SELECT duration
,(regexp_matches(duration,'\m[Mm][Ii][Nn][A-Za-z]*\y'))[1] as matched_minutes
FROM
(
        SELECT split_part(sighting_report,'Duration:',2) as duration
        ,count(*) as reports
        FROM ufo
        GROUP BY 1
) a
;

--
SELECT
    'driving on 495 south' ~ 'on [0-9]+' as comparison_1
    ,'driving on 1 south' ~ 'on [0-9]+' as comparison_2
    ,'driving on 38east' ~ 'on [0-9]+' as comparison_3
    ,'driving on route one' ~ 'on [0-9]+' as comparison_4
    ;

    --
SELECT
    'driving on 495 south' ~ 'on [0-9]+' as comparison_1
    ,'driving on 495 south' ~ 'on ^[0-9]+' as comparison_2
    ,'driving on 495 south' ~ '^on [0-9]+' as comparison_3
    ;

--
SELECT
    '"Is there a report?" she asked' ~ '\?' as comparison_1
    ,'it was filed under ^51.' ~ '^[0-9]+' as comparison_2
    ,'it was filed under ^51.' ~ '\^[0-9]+' as comparison_3
    ;



SELECT duration
,(regexp_matches(duration,'\m[Mm][Ii][Nn][A-Za-z]*\y'))[1] as matched_minutes
,regexp_replace(duration,'\m[Mm][Ii][Nn][A-Za-z]*\y','min') as replaced_text
FROM
(
        SELECT split_part(sighting_report,'Duration:',2) as duration
        ,count(*) as reports
        FROM ufo
        GROUP BY 1
) a
;

SELECT duration
,(regexp_matches(duration,'\m[Hh][Oo][Uu][Rr][A-Za-z]*\y'))[1] as matched_hour
,(regexp_matches(duration,'\m[Mm][Ii][Nn][A-Za-z]*\y'))[1] as matched_minutes
,regexp_replace(regexp_replace(duration,'\m[Mm][Ii][Nn][A-Za-z]*\y','min'),'\m[Hh][Oo][Uu][Rr][A-Za-z]*\y','hr') as replaced_text
FROM
(
        SELECT split_part(sighting_report,'Duration:',2) as duration
        ,count(*) as reports
        FROM ufo
        GROUP BY 1
) a
;

SELECT
    'spinning
    flashing
    and whirling' ~ '\n' as comparison_1
    ,'spinning
    flashing
    and whirling' ~ '\s' as comparison_2
    ,'spinning flashing' ~ '\s' as comparison_3
    ,'spinning' ~ '\s' as comparison_4
    ;
--

SELECT
    'valid codes have the form 12a34b56c' ~ '([0-9]{2}[a-z]){3}'
      as comparison_1
    ,'the first code entered was 123a456c' ~ '([0-9]{2}[a-z]){3}'
      as comparison_2
    ,'the second code entered was 99x66y33z' ~ '([0-9]{2}[a-z]){3}'
      as comparison_3
    ;


SELECT
    'I was in my car going south toward my home' ~ 'car'
      as comparison_1
    ,'UFO scares cows and starts stampede breaking' ~ 'car'
      as comparison_2
    ,'I''m a carpenter and married father of 2.5 kids' ~ 'car'
      as comparison_3
    ,'It looked like a brown boxcar way up into the sky' ~ 'car'
      as comparison_4
    ;


SELECT 'Car lights in the sky passing over the highway' ~* '\ycar\y'
     as comparison_1
    ,'Car lights in the sky passing over the highway' ~* ' car '
     as comparison_2
;

SELECT
    'Car lights in the sky passing over the highway' ~* '\Acar\y'
      as comparison_1
    ,'I was in my car going south toward my home' ~* '\Acar\y'
      as comparison_2
    ,'An object is sighted hovering in place over my car' ~* '\ycar\Z'
      as comparison_3
    ,'I was in my car going south toward my home' ~* '\ycar\Z'
      as comparison_4
    ;

--
SELECT duration
,(regexp_matches(duration,'\m[Hh][Oo][Uu][Rr][A-Za-z]*\y'))[1] as matched_hour
,(regexp_matches(duration,'\m[Mm][Ii][Nn][A-Za-z]*\y'))[1] as matched_minutes
,regexp_replace(regexp_replace(duration,'\m[Mm][Ii][Nn][A-Za-z]*\y','min'),'\m[Hh][Oo][Uu][Rr][A-Za-z]*\y','hr') as replaced_text
FROM
(
        SELECT split_part(sighting_report,'Duration:',2) as duration
        ,count(*) as reports
        FROM ufo
        GROUP BY 1
) a
;

--
--Finding and replacing with regex
SELECT left(description,50)
    FROM ufo
    WHERE left(description,50) ~ '[0-9]+ light[s ,.]'
    ;

--
SELECT (regexp_matches(description,'[0-9]+ light[s ,.]'))[1]
    ,count(*)
    FROM ufo
    WHERE description ~ '[0-9]+ light[s ,.]'
    GROUP BY 1
    ORDER BY 2 desc
    ;
--
--Grafico type
SELECT
  (regexp_matches(description,'[0-9]+ light[s ,.]'))[1] AS lights_text,
  count(*) AS n
FROM ufo
WHERE description ~ '[0-9]+ light[s ,.]'
GROUP BY 1
ORDER BY n DESC
LIMIT 10;


SELECT min(split_part(matched_text,' ',1)::int) as min_lights
    ,max(split_part(matched_text,' ',1)::int) as max_lights
    FROM
    (
        SELECT (regexp_matches(description
                               ,'[0-9]+ light[s ,.]')
                               )[1] as matched_text
        ,count(*)
        FROM ufo
        WHERE description ~ '[0-9]+ light[s ,.]'
        GROUP BY 1
    ) a;

SELECT duration
    ,(regexp_matches(duration
                     ,'\m[Hh][Oo][Uu][Rr][A-Za-z]*\y')
                     )[1] as matched_hour
    ,(regexp_matches(duration
                     ,'\m[Mm][Ii][Nn][A-Za-z]*\y')
                     )[1] as matched_minutes
    ,regexp_replace(
            regexp_replace(duration
                           ,'\m[Mm][Ii][Nn][A-Za-z]*\y'
                           ,'min')
            ,'\m[Hh][Oo][Uu][Rr][A-Za-z]*\y'
            ,'hr') as replaced_text
    FROM
    (
        SELECT split_part(sighting_report,'Duration:',2) as duration
        ,count(*) as reports
        FROM ufo
        GROUP BY 1
)a


----- Constructing and reshaping text
SELECT concat(shape, ' (shape)') as shape
,concat(reports, ' reports') as reports
FROM
(
        SELECT split_part(split_part(sighting_report,'Duration',1),'Shape: ',2) as shape
        ,count(*) as reports
        FROM ufo
        GROUP BY 1
) a
;
--

SELECT concat(shape,' - ',location) as shape_location
,reports
FROM
(
        SELECT split_part(split_part(sighting_report,'Shape',1),'Location: ',2) as location
        ,split_part(split_part(sighting_report,'Duration',1),'Shape: ',2) as shape
        ,count(*) as reports
        FROM ufo
        GROUP BY 1,2
) a
;
--

SELECT 
concat('There were '
       ,reports
       ,' reports of '
       ,lower(shape)
       ,' objects. The earliest sighting was '
       ,trim(to_char(earliest,'Month'))
       , ' '
       , date_part('day',earliest)
       , ', '
       , date_part('year',earliest)
       ,' and the most recent was '
       ,trim(to_char(latest,'Month'))
       , ' '
       , date_part('day',latest)
       , ', '
       , date_part('year',latest)
       ,'.'
       )
FROM
(
        SELECT shape
        ,min(occurred::date) as earliest
        ,max(occurred::date) as latest
        ,sum(reports) as reports
        FROM
        (
                SELECT split_part(split_part(split_part(sighting_report,' (Entered',1),'Occurred : ',2),'Reported',1) as occurred
                ,split_part(split_part(sighting_report,'Duration',1),'Shape: ',2) as shape
                ,count(*) as reports
                FROM ufo
                GROUP BY 1,2
        ) a
        WHERE length(occurred) >= 8
        GROUP BY 1
) aa    
;

-- Reshaping
SELECT location
,string_agg(shape,', ' order by shape asc) as shapes
FROM
(
        SELECT 
        case when split_part(split_part(sighting_report,'Duration',1),'Shape: ',2) = '' then 'Unknown'
             when split_part(split_part(sighting_report,'Duration',1),'Shape: ',2) = 'TRIANGULAR' then 'Triangle'
             else split_part(split_part(sighting_report,'Duration',1),'Shape: ',2)  
             end as shape
        ,split_part(split_part(sighting_report,'Shape',1),'Location: ',2) as location
        ,count(*) as reports
        FROM ufo
        GROUP BY 1,2
) a
GROUP BY 1
;
--

SELECT word, 
count(*) as frequency
FROM
(
        SELECT regexp_split_to_table(lower(description),'\s+') as word
        FROM ufo
        --LIMIT 30
) a
GROUP BY 1
ORDER BY 2 desc
;

SELECT word,
 count(*) as frequency
FROM
(
        SELECT regexp_split_to_table(lower(description),'\s+') as word
        FROM ufo
) a
LEFT JOIN stop_words b on a.word = b.stop_word
WHERE b.stop_word is null
GROUP BY 1
ORDER BY 2 desc
--LIMIT 10
;

---verificar JOIN
SELECT a.word, b.stop_word
FROM (
  SELECT regexp_split_to_table(lower(description), '\s+') AS word
  FROM ufo
) a
JOIN stop_words b ON a.word = b.stop_word
LIMIT 30;


--
SELECT word, count(*) AS frequency
FROM (
  SELECT regexp_split_to_table(lower(description), '\s+') AS word
  FROM ufo
) a
LEFT JOIN stop_words b ON a.word = b.stop_word
WHERE b.stop_word IS NULL
GROUP BY word
ORDER BY frequency DESC
LIMIT 20;


--Just a test
SELECT column_name-- ,data_type
FROM information_schema.columns
WHERE table_name = 'ufo';

