use adbms;

-- 1. Missing Values
SELECT * FROM transaction_data
WHERE TransactionID IS NULL
OR Timestamp IS NULL
OR Amount IS NULL
OR CustomerID IS NULL
OR MerchantID IS NULL
OR Category IS NULL;

SELECT * FROM merchant_data
WHERE MerchantID IS NULL
OR MerchantName IS NULL
OR Location IS NULL;

SELECT * FROM customer_data
WHERE CustomerID IS NULL
OR Name IS NULL
OR Age IS NULL
OR Address IS NULL;

-- 2. Duplicate Records
SELECT TransactionID, COUNT(*)
FROM transaction_data
GROUP BY TransactionID
HAVING COUNT(*) > 1;

-- 3. Valid Ranges
SELECT * FROM transaction_data
WHERE Amount < 0;

SELECT * FROM customer_data
WHERE Age NOT BETWEEN 18 AND 100;

SELECT * FROM account
WHERE AccountBalance < 0;

-- 4. Spelling inconsistencies or variations in names or column dates
SELECT Category, COUNT(*)
FROM transaction_data
GROUP BY Category;

-- 5. Table Data type check 
SELECT column_name, data_type from information_schema.columns
where table_name = 'transaction_data';

SELECT column_name, data_type from information_schema.columns
where table_name = 'merchant_data';

SELECT column_name, data_type from information_schema.columns
where table_name = 'customer_data';

SELECT column_name, data_type from information_schema.columns
where table_name = 'account';

-- 6. Date – Time Correction: Text to Timestamp 
ALTER TABLE account ADD COLUMN TempLastLogin DATE;
UPDATE account
SET TempLastLogin = STR_TO_DATE(`LastLogin`, '%Y-%m-%d');
ALTER TABLE account DROP COLUMN `LastLogin`;
ALTER TABLE account CHANGE COLUMN TempLastLogin `LastLogin` DATE;

ALTER TABLE transaction_data ADD COLUMN TempTimestamp TIMESTAMP;
UPDATE transaction_data
SET TempTimestamp = STR_TO_DATE(`Timestamp`, '%Y-%m-%d %H:%i:%s');
ALTER TABLE transaction_data DROP COLUMN `Timestamp`;
ALTER TABLE transaction_data CHANGE COLUMN TempTimestamp `Timestamp` TIMESTAMP;