USE ecomm;

Select * from customer_churn;

select distinct CityTier from customer_churn;

select distinct Churn from customer_churn;

select distinct PreferredLoginDevice from customer_churn;

Select count(*) from customer_churn;

Set SQL_safe_updates = 0;

Select * from customer_churn;

-- Impute mean for the following columns, and round off to the nearest integer if
-- required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear,
-- DaySinceLastOrder.

SET @WarehouseToHome_Avg = (Select AVG(WarehouseToHome) From customer_churn);

Select AVG(WarehouseToHome) From customer_churn;

Update customer_churn
Set WarehouseToHome = @WarehouseToHome_Avg
Where WarehouseToHome Is NULL;

Select * from customer_churn;

SET @HourSpendOnApp_Avg = (Select AVG(HourSpendOnApp) From customer_churn);

Select AVG(HourSpendOnApp) From customer_churn;

Update customer_churn
Set HourSpendOnApp = @HourSpendOnApp_Avg
Where HourSpendOnApp Is NULL;

Select * from customer_churn;

SET @OrderAmountHikeFromlastYear_Avg = (Select AVG(OrderAmountHikeFromlastYear) From customer_churn);

Select AVG(OrderAmountHikeFromlastYear) From customer_churn;

Update customer_churn
Set OrderAmountHikeFromlastYear = @OrderAmountHikeFromlastYear_Avg
Where OrderAmountHikeFromlastYear Is NULL;

Select * from customer_churn;

SET @DaySinceLastOrder_Avg = (Select AVG(DaySinceLastOrder) From customer_churn);

Select AVG(DaySinceLastOrder) From customer_churn;

Update customer_churn
Set DaySinceLastOrder = @DaySinceLastOrder_Avg
Where DaySinceLastOrder Is NULL;

Select * from customer_churn;

-- Impute mode for the following columns: Tenure, CouponUsed, OrderCount.

Select Tenure from customer_churn Group by Tenure Order by count(*) Desc limit 1;

Set @Tenure_Mode = (Select Tenure from customer_churn Group by Tenure Order by count(*) Desc limit 1);

Update customer_churn
Set Tenure = @Tenure_Mode
Where Tenure Is NULL;

SELECT CouponUsed FROM customer_churn  
GROUP BY CouponUsed  
ORDER BY COUNT(*) DESC  
LIMIT 1;

UPDATE customer_churn  
SET CouponUsed = (  
    SELECT CouponUsed FROM (  
        SELECT CouponUsed FROM customer_churn  
        GROUP BY CouponUsed  
        ORDER BY COUNT(*) DESC  
        LIMIT 1  
    ) AS subquery  
)  
WHERE CouponUsed IS NULL;

SELECT OrderCount FROM customer_churn  
GROUP BY OrderCount  
ORDER BY COUNT(*) DESC  
LIMIT 1;

UPDATE customer_churn  
SET OrderCount = (  
    SELECT OrderCount FROM (  
        SELECT OrderCount FROM customer_churn  
        GROUP BY OrderCount  
        ORDER BY COUNT(*) DESC  
        LIMIT 1  
    ) AS subquery  
)  
WHERE OrderCount IS NULL;

Select * from customer_churn;

-- Handle outliers in the 'WarehouseToHome' column by deleting rows where the values are greater than 100.

SELECT COUNT(*) 
FROM customer_churn
WHERE WarehouseToHome > 100;

Delete from customer_churn
where WarehouseToHome >100; 

-- Dealing with Inconsistencies:

-- Replace occurrences of “Phone” in the 'PreferredLoginDevice' column and “Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensureuniformity.

Update customer_churn
Set PreferredLoginDevice = REPLACE(PreferredLoginDevice, 'Phone', 'Mobile Phone'),
    PreferedOrderCat = REPLACE(PreferedOrderCat, 'Mobile', 'Mobile Phone');
    
    -- Standardize payment mode values: Replace "COD" with "Cash on Delivery" an "CC" with "Credit Card" in the PreferredPaymentMode column.
    
    Update customer_churn
Set PreferredPaymentMode = REPLACE(PreferredPaymentMode, 'COD', 'Cash on Delivery'),
    PreferredPaymentMode = REPLACE(PreferredPaymentMode, 'CC', 'Credit Card');
    
    Select * from customer_churn;
    
    -- Data Transformation:
    -- Column Renaming:
    
   -- Rename the column "PreferedOrderCat" to "PreferredOrderCat".
   
  ALTER TABLE customer_churn
CHANGE COLUMN PreferedOrderCat PreferredOrderCat VARCHAR(20);

-- Rename the column "HourSpendOnApp" to "HoursSpentOnApp".

 ALTER TABLE customer_churn
CHANGE COLUMN HourSpendOnApp HoursSpentOnApp int;
   
   -- Creating New Columns:
   -- Create a new column named ‘ComplaintReceived’ with values "Yes" if the corresponding value in the ‘Complain’ is 1, and "No" otherwise.
   
   ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived VARCHAR(3);

UPDATE customer_churn
SET ComplaintReceived = CASE 
    WHEN Complain = 1 THEN 'Yes'
    ELSE 'No'
END;

Select * from customer_churn;

-- Create a new column named 'ChurnStatus'. Set its value to “Churned” if the corresponding value in the 'Churn' column is 1, else assign “Active”.

 ALTER TABLE customer_churn
ADD COLUMN ChurnStatus VARCHAR(10);

UPDATE customer_churn
SET ChurnStatus = CASE 
    WHEN Churn = 1 THEN 'Churned'
    ELSE 'Active'
END;

Select * from customer_churn;

-- Column Dropping:

-- Drop the columns "Churn" and "Complain" from the table.

ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

-- Data Exploration and Analysis:

-- Retrieve the count of churned and active customers from the dataset.

SELECT ChurnStatus, COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY ChurnStatus;

-- Display the average tenure and total cashback amount of customers who churned.

SELECT 
    AVG(Tenure) AS AverageTenure, 
    SUM(CashbackAmount) AS TotalCashback
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- Determine the percentage of churned customers who complained.

SELECT 
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_churn WHERE ChurnStatus = 'Churned')) AS ComplaintPercentage
FROM customer_churn
WHERE ChurnStatus = 'Churned' AND ComplaintReceived = 'Yes';

-- Find the gender distribution of customers who complained.

SELECT Gender, COUNT(*) AS CustomerCount
FROM customer_churn
WHERE ComplaintReceived = 'Yes'
GROUP BY Gender;

-- Identify the city tier with the highest number of churned customers whose preferred order category is Laptop & Accessory.

SELECT CityTier, COUNT(*) AS Churned_Customer_Count
FROM customer_churn
WHERE ChurnStatus = 'Churned' 
AND PreferredLoginDevice = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY Churned_Customer_Count DESC
LIMIT 1;

-- Identify the most preferred payment mode among active customers.

SELECT PreferredPaymentMode, COUNT(*) AS UsageCount
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY UsageCount DESC
LIMIT 1;

-- Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering.

SELECT SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHike
FROM customer_churn
WHERE MaritalStatus = 'Single' 
AND PreferredOrderCat = 'Mobile Phone';

-- Find the average number of devices registered among customers who used UPI as their preferred payment mode.

SELECT AVG(NumberOfDeviceRegistered) AS AvgDevicesRegistered
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

-- Determine the city tier with the highest number of customers.

SELECT CityTier, COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY CityTier
ORDER BY CustomerCount DESC
LIMIT 1;

-- Identify the gender that utilized the highest number of coupons.

SELECT Gender, SUM(CouponUsed) AS TotalCouponsUsed
FROM customer_churn
GROUP BY Gender
ORDER BY TotalCouponsUsed DESC
LIMIT 1;

-- List the number of customers and the maximum hours spent on the app in each preferred order category.

SELECT PreferredOrderCat, 
       COUNT(*) AS CustomerCount, 
       MAX(HoursSpentOnApp) AS MaxHoursSpent
FROM customer_churn
GROUP BY PreferredOrderCat;

-- Calculate the total order count for customers who prefer using credit cards and have the maximum satisfaction score.

SELECT SUM(OrderCount) AS TotalOrderCount
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card' 
AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);

-- How many customers are there who spent only one hour on the app and days since their last order was more than 5?

SELECT COUNT(*) AS CustomerCount
FROM customer_churn
WHERE HoursSpentOnApp = 1 
AND DaySinceLastOrder > 5;

-- What is the average satisfaction score of customers who have complained?

SELECT AVG(SatisfactionScore) AS AvgSatisfactionScore
FROM customer_churn
WHERE ComplaintReceived = 'Yes';

-- List the preferred order category among customers who used more than 5 coupons.

SELECT PreferredOrderCat, COUNT(*) AS CustomerCount
FROM customer_churn
WHERE CouponUsed > 5
GROUP BY PreferredOrderCat
ORDER BY CustomerCount DESC;

-- List the top 3 preferred order categories with the highest average cashback amount.

SELECT PreferredOrderCat, AVG(CashbackAmount) AS AvgCashback
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY AvgCashback DESC
LIMIT 3;

-- Find the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders.

SELECT PreferredPaymentMode, COUNT(*) AS CustomerCount
FROM customer_churn
WHERE Tenure = 10
AND OrderCount > 500
GROUP BY PreferredPaymentMode
ORDER BY CustomerCount DESC;

-- Categorize customers based on their distance from the warehouse to home suchas 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km,'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display thechurn status breakdown for each distance category.

SELECT 
    CASE 
        WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
        WHEN WarehouseToHome <= 10 THEN 'Close Distance'
        WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
        ELSE 'Far Distance'
    END AS DistanceCategory,
    ChurnStatus,
    COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY DistanceCategory, ChurnStatus
ORDER BY DistanceCategory, ChurnStatus;

-- List the customer’s order details who are married, live in City Tier-1, and theirorder counts are more than the average number of orders placed by allcustomers.

SELECT CustomerID, OrderCount, PreferredOrderCat, PreferredPaymentMode, OrderAmountHikeFromlastYear
FROM customer_churn
WHERE MaritalStatus = 'Married'
AND CityTier = 1
AND OrderCount > (SELECT AVG(OrderCount) FROM customer_churn);

-- Create a ‘customer_returns’ table in the ‘ecomm’ database and insert the following data:

CREATE TABLE ecomm.customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    ReturnDate DATE NOT NULL,
    RefundAmount DECIMAL(10,2) NOT NULL );

INSERT INTO ecomm.customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount) VALUES
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);

SELECT * FROM ecomm.customer_returns;

-- Display the return details along with the customer details of those who have churned and have made complaints.

SELECT 
    cr.ReturnID, 
    cr.CustomerID, 
    cr.ReturnDate, 
    cr.RefundAmount,
    cc.CityTier, 
    cc.PreferredOrderCat, 
    cc.PreferredPaymentMode, 
    cc.Tenure, 
    cc.CashbackAmount
FROM ecomm.customer_returns cr
JOIN ecomm.customer_churn cc 
    ON cr.CustomerID = cc.CustomerID
WHERE cc.ChurnStatus = 'Churned' 
AND cc.ComplaintReceived = 'Yes';







