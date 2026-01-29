DROP TABLE IF EXISTS retail_sales;

CREATE TABLE retail_sales
(
    sales_month DATE,
    naics_code VARCHAR,
    kind_of_business VARCHAR,
    reason_for_null VARCHAR,
    sales NUMERIC
);


-- populate the table with data from the csv file. Download the file locally before completing this step
\copy retail_sales 
FROM '/.../us_retail_sales.csv'
DELIMITER ','
CSV HEADER;



