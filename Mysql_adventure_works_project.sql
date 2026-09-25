CREATE DATABASE adventure_works;
USE adventure_works;

SELECT * FROM adventure_works.dimcustomer;
SELECT * FROM adventure_works.dimdate;
SELECT * FROM adventure_works.`dimproduct.xlsx`;
SELECT * FROM adventure_works.dimproductcategory;
SELECT * FROM adventure_works.dimproductsubcategory;
SELECT * FROM adventure_works.dimsalesterritory;
SELECT * FROM adventure_works.factinternetsales;
USE adventure_works;
# combined tables
CREATE TABLE combined_sales AS
SELECT * FROM factinternetsales
UNION ALL
SELECT * FROM fact_internet_sales_new;
# merged tables
    CREATE TABLE dimproduct_complete AS
SELECT 
    p.*,
    psc.EnglishProductSubcategoryName,
    pc.EnglishProductCategoryName
FROM `dimproduct.xlsx` p
LEFT JOIN dimproductsubcategory psc 
    ON CAST(NULLIF(p.ProductSubcategoryKey, '') AS UNSIGNED) = CAST(NULLIF(psc.ProductSubcategoryKey, '') AS UNSIGNED)
LEFT JOIN dimproductcategory pc 
    ON CAST(NULLIF(psc.ProductCategoryKey, '') AS UNSIGNED) = CAST(NULLIF(pc.ProductCategoryKey, '') AS UNSIGNED);
   -- question 1 Product names
   SELECT 
    s.SalesOrderNumber,
    s.ProductKey,
    p.EnglishProductName
FROM combined_sales s
LEFT JOIN dimproduct_complete p 
    ON CAST(NULLIF(s.ProductKey, '') AS UNSIGNED) = CAST(NULLIF(p.ProductKey, '') AS UNSIGNED);
    
-- question2- customer name--
SELECT 
    s.SalesOrderNumber,
    s.CustomerKey,
    CONCAT(COALESCE(c.FirstName, ''), ' ', COALESCE(c.LastName, '')) AS CustomerFullName,
    s.ProductKey
FROM combined_sales s
LEFT JOIN dimcustomer c 
    ON CAST(NULLIF(s.CustomerKey, '') AS UNSIGNED) = CAST(NULLIF(c.CustomerKey, '') AS UNSIGNED)
LEFT JOIN dimproduct_complete p 
    ON CAST(NULLIF(s.ProductKey, '') AS UNSIGNED) = CAST(NULLIF(p.ProductKey, '') AS UNSIGNED);
    
    -- question 3 date fields --
    SELECT 
    OrderDate,
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS MonthNo,
    MONTHNAME(OrderDate) AS MonthFullName,
    CONCAT('Q', QUARTER(OrderDate)) AS Quarter,
    DATE_FORMAT(OrderDate, '%Y-%b') AS YearMonth,
    WEEKDAY(OrderDate) + 1 AS WeekdayNo,
    DAYNAME(OrderDate) AS WeekdayName,
    
    -- Financial Month (April = 1)
    CASE WHEN MONTH(OrderDate) >= 4 THEN MONTH(OrderDate) - 3 ELSE MONTH(OrderDate) + 9 END AS FinancialMonth,
    
    -- Financial Quarter
    CASE 
        WHEN MONTH(OrderDate) BETWEEN 4 AND 6 THEN 'FQ1'
        WHEN MONTH(OrderDate) BETWEEN 7 AND 9 THEN 'FQ2'
        WHEN MONTH(OrderDate) BETWEEN 10 AND 12 THEN 'FQ3'
        ELSE 'FQ4'
    END AS FinancialQuarter

FROM (
    SELECT STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d') AS OrderDate 
    FROM combined_sales
) AS sub;

-- 4 - sales amount--
SELECT 
    SalesOrderNumber,
    ProductKey,
    UnitPrice,
    OrderQuantity,
    UnitPriceDiscountPct,
    (UnitPrice * OrderQuantity) * (1 - UnitPriceDiscountPct) AS SalesAmount
FROM combined_sales;
-- 5- production cost--
SELECT 
    SalesOrderNumber,
    ProductKey,
    (UnitPrice * OrderQuantity) AS ProductionCost
FROM combined_sales;
-- 6 - total profit --
SELECT 
    SalesOrderNumber,
    ProductKey,
    SalesAmount,
    TotalProductCost,
    (SalesAmount - TotalProductCost) AS Profit
FROM combined_sales;
-- 7 - month sales --
SELECT 
    MONTHNAME(OrderDate) AS MonthName,
    SUM(SalesAmount) AS TotalSales
FROM (
    SELECT 
        STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d') AS OrderDate,
        SalesAmount
    FROM combined_sales
) AS sub
WHERE YEAR(OrderDate) = 2014
GROUP BY MONTH(OrderDate), MONTHNAME(OrderDate)
ORDER BY MONTH(OrderDate);
-- year wise sales --
SELECT 
    YEAR(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS Year,
    SUM(SalesAmount) AS TotalSales
FROM combined_sales
GROUP BY Year
ORDER BY Year;
-- month wise sales --
SELECT 
    YEAR(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS Year,
    MONTHNAME(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')) AS MonthName,
    SUM(SalesAmount) AS TotalSales
FROM combined_sales
GROUP BY 
    YEAR(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')),
    MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d')),
    MONTHNAME(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d'))
ORDER BY 
    Year, 
    MONTH(STR_TO_DATE(CAST(OrderDateKey AS CHAR), '%Y%m%d'));