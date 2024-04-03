
# Creating the master table

CREATE TABLE adbms.MasterTable AS
SELECT 
    t1.*, 
    t2.Name, t2.Age, t2.Address, 
    t3.MerchantName, t3.Location,
    t4.Account_ID,t4.AccountBalance,t4.LastLogin
FROM 
    adbms.transaction_data t1
LEFT JOIN 
    adbms.customer_data t2 ON t1.CustomerID = t2.CustomerID
LEFT JOIN 
    adbms.merchant_data t3 ON t1.MerchantID = t3.MerchantID
LEFT JOIN 
    adbms.account t4 ON t1.CustomerID = t4.CustomerID;


# (Appendix 1) Anamoly scoring query with CTE

CREATE VIEW score_view AS(
WITH MonthlyTransactionCounts AS (
    SELECT
        Account_ID,
        YEAR(Timestamp) AS Year,
        MONTH(Timestamp) AS Month,
        COUNT(*) AS NumTransactions
    FROM
        mastertable
    GROUP BY
        Account_ID, YEAR(Timestamp), MONTH(Timestamp)
),
TotalAccountsPerMonth AS (
    SELECT
        Year,
        Month,
        COUNT(DISTINCT Account_ID) AS TotalAccounts
    FROM
        MonthlyTransactionCounts
    GROUP BY
        Year, Month
),
Top5PercentThresholds AS (
    SELECT
        m.Year,
        m.Month,
        FLOOR(TotalAccounts * 0.05) AS Threshold
    FROM
        TotalAccountsPerMonth m
),
RankedTransactions AS (
    SELECT
        m.*,
        RANK() OVER (PARTITION BY m.Year, m.Month ORDER BY m.NumTransactions DESC) AS TransactionRank
    FROM
        MonthlyTransactionCounts m
),
Top5PercentAccountsPerMonth AS (
    SELECT
        r.Account_ID,
        r.Year,
        r.Month
    FROM
        RankedTransactions r
    INNER JOIN Top5PercentThresholds t ON r.Year = t.Year AND r.Month = t.Month
    WHERE r.TransactionRank <= t.Threshold
),
SimplifiedCategories AS (
    SELECT
        TransactionID,
        Account_ID,
        Amount,
        Timestamp,
        MerchantID,
        CASE
            WHEN Category IN ('Online', 'Travel', 'Food', 'Retail') THEN 'GroupedOtherCategories'
            ELSE 'Others'
        END AS SimplifiedCategory,
        LastLogin
    FROM
        mastertable
),
AnomalyScores AS (
    SELECT
        sc.TransactionID,
        sc.Account_ID,
        sc.Amount,
        sc.Timestamp,
        sc.MerchantID,
        sc.SimplifiedCategory,
        sc.LastLogin,
        CASE
            WHEN sc.Amount > 75.86 THEN 1
            ELSE 0
        END AS AmountScore,
        CASE
            WHEN HOUR(sc.Timestamp) BETWEEN 0 AND 5 THEN 1
            ELSE 0
        END AS TimeScore,
        0 AS RepeatedTransactionScore,
        CASE
            WHEN DATEDIFF(sc.Timestamp, sc.LastLogin) > 180 THEN 1
            ELSE 0
        END AS InactivityScore,
        (
            SELECT
                CASE
                    WHEN COUNT(*) < 5 THEN 1
                    ELSE 0
                END
            FROM
                SimplifiedCategories sub
            WHERE
                sub.MerchantID = sc.MerchantID AND sub.SimplifiedCategory = sc.SimplifiedCategory
        ) AS UncommonMerchantCategoryScore
    FROM
        SimplifiedCategories sc
),
FinalScores AS (
    SELECT
        a.*,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM Top5PercentAccountsPerMonth tp
                WHERE tp.Account_ID = a.Account_ID AND tp.Year = YEAR(a.Timestamp) AND tp.Month = MONTH(a.Timestamp)
            ) THEN 0.05
            ELSE 0
        END AS Top5PercentAccountRiskWeightage,
        (
            0.25 * a.RepeatedTransactionScore +
            0.3 * a.AmountScore +
            0.15 * a.InactivityScore +
            0.2 * a.TimeScore +
            0.03 * a.UncommonMerchantCategoryScore
        ) + CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM Top5PercentAccountsPerMonth tp
                    WHERE tp.Account_ID = a.Account_ID AND tp.Year = YEAR(a.Timestamp) AND tp.Month = MONTH(a.Timestamp)
                ) THEN 0.07
                ELSE 0
            END AS FinalAnomalyScore
    FROM
        AnomalyScores a
)
SELECT TransactionId,FinalAnomalyScore FROM FinalScores);

SELECT *
FROM score_view;










# (Appendix 2.1) A query to identify the top 5 customers by total transaction amount within each category, including their rank based on the transaction amount.

WITH TransactionSums AS (
  SELECT
    CustomerID,
    Category,
    SUM(Amount) AS TotalAmount
  FROM Transaction_data
  GROUP BY CustomerID, Category
), RankedTransactions AS (
  SELECT
    CustomerID,
    Category,
    TotalAmount,
    RANK() OVER (PARTITION BY Category ORDER BY TotalAmount DESC) AS `Rank`
  FROM TransactionSums
)
SELECT CustomerID, Category, TotalAmount, `Rank`
FROM RankedTransactions
WHERE `Rank` <= 5;






# (Appendix 2.2) This query aims to identify each customer's most frequent transaction category, utilizing a combination of joins, string functions, and window functions to rank categories by frequency.

    WITH CategoryFrequencies AS (
  SELECT
    t.CustomerID,
    t.Category,
    COUNT(*) AS TransactionsCount,
    RANK() OVER (PARTITION BY t.CustomerID ORDER BY COUNT(*) DESC) AS CategoryRank
  FROM Transaction_data t
  GROUP BY t.CustomerID, t.Category
)
SELECT 
  cf.CustomerID,
  cf.Category,
  cf.TransactionsCount
FROM CategoryFrequencies cf
WHERE cf.CategoryRank = 1;






#  (Appendix 2.3) When you execute this query, you're asking the database to provide you with a financial profile for each customer based on the data stored across different tables.

SET sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
CREATE VIEW CustomerFinancialHealth AS
SELECT DISTINCT
  c.CustomerID,
  c.Name AS Cust_Name,
  FIRST_VALUE(a.AccountBalance) OVER (
    PARTITION BY c.CustomerID 
    ORDER BY a.LastLogin DESC 
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  ) AS LatestBalance,
  AVG(t.Amount) AS AverageTransactionAmount,
  MAX(a.LastLogin) AS LastLoginDate
FROM customer_data c
JOIN account a ON c.CustomerID = a.CustomerID
JOIN transaction_data t ON c.CustomerID = t.CustomerID
GROUP BY c.CustomerID, c.Name;

SELECT *
FROM CustomerFinancialHealth;







#  (Appendix 2.4) This query aims to detect accounts with irregular patterns by looking for anomalies in transaction amounts compared to the usual account activity.

WITH AccountActivity AS (
  SELECT
    a.CustomerID,
    AVG(t.Amount) AS AverageAmountSpent,
    STDDEV(t.Amount) AS StdDevAmount
  FROM account a
  JOIN transaction_data t ON a.CustomerID = t.CustomerID
  GROUP BY a.CustomerID
)
SELECT
  a.Account_ID,
  a.CustomerID,
  aa.AverageAmountSpent,
  aa.StdDevAmount,
  t.Amount AS RecentTransactionAmount,
  sv.FinalAnomalyScore
FROM account a
JOIN AccountActivity aa ON a.CustomerID = aa.CustomerID
JOIN transaction_data t ON a.CustomerID = t.CustomerID
JOIN score_view sv ON t.TransactionID = sv.TransactionId
WHERE sv.FinalAnomalyScore > 0.3 -- Threshold for high risk
ORDER BY sv.FinalAnomalyScore DESC;





#  (Appendix 2.5) Check for merchants with an unusually high number of high-risk transactions.

SELECT
   m.MerchantID,
   m.MerchantName,
   COUNT(t.TransactionID) AS HighRiskTransactionCount
FROM merchant_data m
JOIN transaction_data t ON m.MerchantID = t.MerchantID
JOIN score_view sv ON t.TransactionID = sv.TransactionID
WHERE sv.FinalAnomalyScore > 0.3
GROUP BY m.MerchantID, m.MerchantName
HAVING COUNT(t.TransactionID) > (
  SELECT AVG(HighRiskTransactionCount) * 2 FROM (
    SELECT COUNT(t.TransactionID) AS HighRiskTransactionCount
    FROM transaction_data t
    JOIN score_view sv ON t.TransactionID = sv.TransactionID
    WHERE sv.FinalAnomalyScore > 0.3
    GROUP BY t.MerchantID
  ) AS SubQuery
);





#  (Appendix 2.6) This query detects customers whose transaction risk scores have significantly changed recently, indicating potential account compromise or change in spending behavior.

WITH RiskScoreChanges AS (
  SELECT
    t.CustomerID,
    LAG(sv.FinalAnomalyScore) OVER (PARTITION BY t.CustomerID ORDER BY t.Timestamp) AS PreviousScore,
    sv.FinalAnomalyScore,
    t.TransactionID
  FROM transaction_data t
  JOIN score_view sv ON t.TransactionID = sv.TransactionID
)
SELECT
  CustomerID,
  COUNT(TransactionID) AS TransactionsWithIncreasedRisk
FROM RiskScoreChanges
WHERE FinalAnomalyScore > PreviousScore + 0.25
GROUP BY CustomerID;






#  (Appendix 2.7) This query calculates the average anomaly score across different age groups, helping to identify if certain age demographics are more associated with transactions that have high anomaly scores.

SELECT
  CASE
    WHEN c.Age BETWEEN 18 AND 25 THEN '18-25'
    WHEN c.Age BETWEEN 26 AND 35 THEN '26-35'
    WHEN c.Age BETWEEN 36 AND 45 THEN '36-45'
    WHEN c.Age BETWEEN 46 AND 55 THEN '46-55'
    WHEN c.Age BETWEEN 56 AND 65 THEN '56-65'
    ELSE '65+'
  END AS AgeGroup,
  AVG(sv.FinalAnomalyScore) AS AverageAnomalyScore,
  COUNT(*) AS TotalTransactions
FROM customer_data c
INNER JOIN transaction_data t ON c.CustomerID = t.CustomerID
INNER JOIN score_view sv ON t.TransactionID = sv.TransactionID
GROUP BY AgeGroup
ORDER BY AverageAnomalyScore DESC;




#  (Appendix 2.8) Analyze transactions based on the merchant's location to identify regions with a higher occurrence of high-anomaly-score transactions, which could indicate regions more susceptible to fraudulent activities.

SELECT
  m.Location,
  COUNT(t.TransactionID) AS TotalTransactions,
  AVG(sv.FinalAnomalyScore) AS AverageAnomalyScore,
  SUM(CASE WHEN sv.FinalAnomalyScore > 0.3 THEN 1 ELSE 0 END) AS HighRiskTransactions
FROM merchant_data m
JOIN transaction_data t ON m.MerchantID = t.MerchantID
JOIN score_view sv ON t.TransactionID = sv.TransactionID
GROUP BY m.Location
HAVING HighRiskTransactions >= 3
ORDER BY HighRiskTransactions DESC, AverageAnomalyScore DESC;


