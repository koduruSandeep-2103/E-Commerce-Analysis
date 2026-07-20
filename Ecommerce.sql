use powerbi;
select * from orders;
select * from customers;
desc orders;
desc customers;
 
#14. a,b,c
WITH CustomerMetrics AS
(SELECT
CustomerID,
SUM(Sale_Price) AS TotalRevenue,
COUNT(OrderID) AS OrderFrequency,
AVG(Sale_Price) AS AverageOrderValue
FROM orders
GROUP BY CustomerID
),
CustomerScore AS
(
SELECT *,
(
(TotalRevenue/(SELECT MAX(TotalRevenue) FROM CustomerMetrics))*0.5+
(OrderFrequency/(SELECT MAX(OrderFrequency) FROM CustomerMetrics))*0.3+
(AverageOrderValue/(SELECT MAX(AverageOrderValue) FROM CustomerMetrics))*0.2
) AS CompositeScore
FROM CustomerMetrics
)
SELECT *
FROM CustomerScore
ORDER BY CompositeScore DESC
LIMIT 5;


#15 .
WITH MonthlyRevenue AS
(
SELECT
DATE_FORMAT(STR_TO_DATE(OrderDate,'%d-%m-%Y'),'%Y-%m') AS Month,
SUM(Sale_Price) AS Revenue
FROM orders
GROUP BY DATE_FORMAT(STR_TO_DATE(OrderDate,'%d-%m-%Y'),'%Y-%m')
)
SELECT
Month,
Revenue,
LAG(Revenue) OVER(ORDER BY Month) AS PreviousRevenue,
ROUND(
((Revenue - LAG(Revenue) OVER(ORDER BY Month))
/ LAG(Revenue) OVER(ORDER BY Month)) * 100,
2
) AS GrowthRate
FROM MonthlyRevenue;

#16.

WITH MonthlySales AS
(
SELECT
ProductCategory,
DATE_FORMAT(STR_TO_DATE(TRIM(OrderDate),'%d-%c-%Y'),'%Y-%m') AS Month,
SUM(Sale_Price) AS Revenue
FROM orders
GROUP BY
ProductCategory,
DATE_FORMAT(STR_TO_DATE(TRIM(OrderDate),'%d-%c-%Y'),'%Y-%m')
)
SELECT
ProductCategory,
Month,
Revenue,
ROUND(
AVG(Revenue) OVER(
PARTITION BY ProductCategory
ORDER BY Month
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
),2) AS Rolling3MonthAverage
FROM MonthlySales;

#17.
SET SQL_SAFE_UPDATES = 0;
UPDATE orders
SET Sale_Price = Sale_Price * 0.85
WHERE CustomerID IN
(
SELECT CustomerID
FROM
(
SELECT CustomerID
FROM orders
GROUP BY CustomerID
HAVING COUNT(OrderID)>=10
)t
);


#18.
WITH OrderHistory AS
(
SELECT
CustomerID,
STR_TO_DATE(TRIM(OrderDate),'%d-%c-%Y') AS Order_Date,
LAG(STR_TO_DATE(TRIM(OrderDate),'%d-%c-%Y'))
OVER(
PARTITION BY CustomerID
ORDER BY STR_TO_DATE(TRIM(OrderDate),'%d-%c-%Y')
) AS PreviousOrder
FROM orders
),
OrderGap AS
(
SELECT
CustomerID,
DATEDIFF(Order_Date,PreviousOrder) AS DaysGap
FROM OrderHistory
WHERE PreviousOrder IS NOT NULL
)
SELECT
CustomerID,
ROUND(AVG(DaysGap),2) AS AverageDaysBetweenOrders
FROM OrderGap
WHERE CustomerID IN
(
SELECT CustomerID
FROM orders
GROUP BY CustomerID
HAVING COUNT(OrderID)>=5
)
GROUP BY CustomerID;

#19.
WITH CustomerRevenue AS
(
SELECT
CustomerID,
SUM(Sale_Price) AS TotalRevenue
FROM orders
GROUP BY CustomerID
)
SELECT *
FROM CustomerRevenue
WHERE TotalRevenue >
(
SELECT AVG(TotalRevenue)*1.30
FROM CustomerRevenue
);

#20.
WITH YearlySales AS
(
SELECT
YEAR(STR_TO_DATE(TRIM(OrderDate),'%d-%c-%Y')) AS SalesYear,
ProductCategory,
SUM(Sale_Price) AS Revenue
FROM orders
GROUP BY
YEAR(STR_TO_DATE(TRIM(OrderDate),'%d-%c-%Y')),
ProductCategory
),
Growth AS
(
SELECT
ProductCategory,
SalesYear,
Revenue,
Revenue -
LAG(Revenue) OVER(
PARTITION BY ProductCategory
ORDER BY SalesYear
) AS IncreaseAmount
FROM YearlySales
)
SELECT
ProductCategory,
IncreaseAmount
FROM Growth
WHERE IncreaseAmount IS NOT NULL
ORDER BY IncreaseAmount DESC
LIMIT 3;