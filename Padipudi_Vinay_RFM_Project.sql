-- Project: RFM Customer Prioritization
-- Name: Padipudi Vinay
-- Tool: MySQL


-- CREATION OF DATABASE AND IMPORTING CSV

-- STEP-1: Create database or Schema
CREATE DATABASE retail_db;
USE retail_db;
-- STEP-2: Create table 
CREATE TABLE online_retail(
InvoiceNo VARCHAR(30),
StockCode VARCHAR(30),
Description TEXT,
Quantity INT,
InvoiceDate DATETIME,
UnitPrice DECIMAL (10,2),
CustomerID INT,
Country VARCHAR(50)
);

-- STEP-3: Check table structure
DESC online_retail;
-- STEP-4: Importing cleaned online_retail_csv file
-- HAVE TO IMPORT CSV FILE CLEANED FROM EXCEL: 
-- RIGHT CLICK ON RELATED SCHEMA -> SELECT OPTION TABLE DATA IMPORT WIZARD
-- WAIT FOR A WHILE THE DATA WILL BE IMPORTED.

-- STEP-5: Check total records
SELECT COUNT(*) FROM Online_retail;
-- STEP-6: Reviewing the data 
SELECT * FROM online_retail LIMIT 20;

-- DATA CLEANING AND QUALITY checks

-- STEP-1: Checking null values
SELECT COUNT(*) AS null_customers
FROM online_retail
WHERE CustomerID IS NULL;

-- STEP-2: Check for zero or negative quantities
SELECT COUNT(*) AS invalid_qty
FROM online_retail WHERE Quantity<=0;

-- STEP-3: Check duplicate transactions
SELECT InvoiceNo, StockCode, CustomerID, COUNT(*) AS cnt
FROM online_retail 
GROUP BY InvoiceNo, StockCode, CustomerID
HAVING COUNT(*) >1;

-- STEP-4: Check for zero or negative prices
SELECT COUNT(*) AS invalid_price
FROM online_retail WHERE UnitPrice<=0;

-- Here i found 4 invalid prices so need to clean it
-- Initially set safe mode into 0 then we can perform UPDATE and DELETE
SELECT * FROM Online_retail;
SET SQL_SAFE_UPDATES=0;
DELETE FROM online_retail
WHERE UnitPrice <= 0;
SELECT COUNT(*) AS invalid_price_after_clean
FROM online_retail
WHERE UnitPrice <= 0;

-- RFM Calculation
-- (Recency- How recently customer purchased, 
-- Frequency- How often customer purchased,
-- M- How much customer spent)

-- STEP-1: Find latest transaction date
SELECT MAX(InvoiceDate) as max_date
FROM online_retail;

-- STEP-2: Customer level calculation
ALTER TABLE online_retail 
ADD COLUMN TotalAmount DECIMAL(12,2); -- Adding extra column for Total-values
UPDATE online_retail
SET TotalAmount = Quantity * UnitPrice;

SELECT CustomerID, MAX(InvoiceDate) AS last_purchase_date,
COUNT(DISTINCT InvoiceNo) AS frequency,
SUM(TotalAmount) AS monetary
from online_retail GROUP BY customerID;

-- STEP-3: Calculating final RFM values
SELECT 
customerID, DATEDIFF('2011-12-09', MAX(InvoiceDate)) AS recency,
COUNT(DISTINCT InvoiceNo) AS frequency,
SUM(TotalAmount) AS monetary
FROM online_retail group by customerID ORDER BY monetary DESC; 

-- STEP-4: Create RFM view
CREATE OR REPLACE VIEW rfm_base as
SELECT CustomerID, 
DATEDIFF('2011-12-09', MAX(InvoiceDate)) AS recency,
COUNT(DISTINCT InvoiceNo) as frequency,
SUM(TotalAmount) as monetary
from online_retail
group by customerID;

SELECT * FROM rfm_base LIMIT 10;

-- STEP-5: Create scores of RFM using CASE WHEN method
SELECT *,
CASE WHEN RECENCY <=30 THEN 4
WHEN RECENCY <=90 THEN 3
WHEN RECENCY <=100 THEN 2
ELSE 1 END as Rec_score,
CASE WHEN frequency>=20 THEN 4
WHEN frequency >=10 then 3
WHEN frequency >=5 then 2
ELSE 1 END AS F_score,
CASE WHEN monetary>=5000 THEN 4
 WHEN monetary>=2000 THEN 3
 WHEN monetary>=1000 THEN 2
else 1 end as M_score 
FROM rfm_base;

-- STEP-6: Dividing customers with priority using SUB QUERY method 
-- Just add a division of customers query and inside it paste the above query
SELECT *, 
CASE WHEN R_score=4 AND F_score=4 and M_score=4 then 'champions'
WHEN R_score>= 3 AND F_score>=3 THEN 'Loyal  customers'
WHEN R_score>=4 AND F_score>= 2 THEN 'Regular customers'
WHEN R_score>= 2 AND F_score>=3 THEN 'Risky'
ELSE 'others'
end as customer_priority
from(SELECT *,
CASE WHEN RECENCY <=30 THEN 4
WHEN RECENCY <=90 THEN 3
WHEN RECENCY <=100 THEN 2
ELSE 1 END as R_score,
CASE WHEN frequency>=20 THEN 4
WHEN frequency >=10 then 3
WHEN frequency >=5 then 2
ELSE 1 END AS F_score,
CASE WHEN monetary>=5000 THEN 4
 WHEN monetary>=2000 THEN 3
 WHEN monetary>=1000 THEN 2
else 1 end as M_score 
FROM rfm_base
) V;

-- END OF THE PROJECT RFM CUSTOMER PRIORITIZATION