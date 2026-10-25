-- Active: 1790801754508@@127.0.0.1@5432@retail
-- Run while connected to retail; CREATE DATABASE does not switch databases.

SET datestyle TO 'ISO, DMY';

CREATE TABLE IF NOT EXISTS retail_sales (
    invoice_no   VARCHAR(20),
    stock_code   VARCHAR(50),
    description  TEXT,
    quantity     INTEGER,
    invoice_date TIMESTAMP,
    unit_price   NUMERIC(10, 2),
    customer_id  INTEGER,
    country      VARCHAR(100)
);

COPY retail_sales (
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country
)


FROM '/Users/lksn/Downloads/online_retail.csv'
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ';', NULL '');


SELECT COUNT(*) AS imported_rows
FROM retail_sales;

SELECT *
FROM retail_sales
LIMIT 100;

