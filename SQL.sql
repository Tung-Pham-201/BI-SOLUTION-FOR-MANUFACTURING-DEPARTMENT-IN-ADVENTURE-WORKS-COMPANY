-- Số lượng sản xuất, hủy bỏ theo năm
SELECT Year(WO.DueDate) AS YEAR ,
		SUM(WO.OrderQty) AS 'TOTAL QUANTITY',
		SUM(wo.StockedQty) AS TotalCompletedQuantity,
		SUM(wo.ScrappedQty) AS TotalScrappedQuantity
FROM Production.Workorder WO
GROUP BY Year(WO.DueDate)
ORDER BY YEAR

-- số lượng sản xuất theo năm của từng sản phẩm
SELECT 
    pc.name AS ProductCategory,
    ps.Name AS ProductSubcategory,
    YEAR(wo.DueDate) AS YEAR,
    COUNT(wo.WorkOrderID) AS TotalWorkOrders,
    SUM(wo.OrderQty) AS TotalOrderQuantity,
    SUM(wo.StockedQty) AS TotalCompletedQuantity,
    SUM(wo.ScrappedQty) AS TotalScrappedQuantity
FROM Production.WorkOrder wo
JOIN Production.Product p ON wo.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name, ps.Name, YEAR(wo.DueDate), DATEPART(QUARTER, wo.DueDate)
ORDER BY Year, ProductCategory, ProductSubcategory;


-- top những lí do xuất hiện hỏng nhiều nhất, chi phí 
SELECT 
    sr.Name AS ScrapReason,
    pc.Name AS ProductCategory,
    COUNT(wo.WorkOrderID) AS AffectedWorkOrders,
    SUM(wo.ScrappedQty) AS TotalScrappedQuantity,
    SUM(wo.ScrappedQty * p.StandardCost	) AS EstimatedScrapCost
FROM Production.WorkOrder wo
JOIN Production.ScrapReason sr ON wo.ScrapReasonID = sr.ScrapReasonID
JOIN Production.Product p ON wo.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE wo.ScrappedQty > 0
GROUP BY sr.Name, pc.Name
ORDER BY TotalScrappedQuantity DESC;


-- volume sản xuất, hiệu quả sản xuất của location
SELECT 
    l.Name AS Location,
    YEAR(wo.EndDate) AS ProductionYear,
    COUNT(DISTINCT wo.WorkOrderID) AS TotalWorkOrders,
    AVG(DATEDIFF(day, wo.StartDate, wo.EndDate)) AS AvgProductionDays,
    SUM(CASE WHEN wo.ScrappedQty > 0 THEN 1 ELSE 0 END) AS OrdersWithScrap,
    SUM(wo.ScrappedQty) AS TotalScrappedQty,
    CAST(SUM(wo.StockedQty) AS FLOAT) / NULLIF(SUM(wo.OrderQty), 0) * 100 AS CompletionRate
FROM Production.WorkOrder wo
JOIN Production.WorkOrderRouting wor ON wo.WorkOrderID = wor.WorkOrderID
JOIN Production.Location l ON wor.LocationID = l.LocationID
WHERE wo.EndDate IS NOT NULL
GROUP BY l.Name, YEAR(wo.EndDate)
ORDER BY ProductionYear, Location;



-- Phân tích xu hướng sản xuất theo thời gian và danh mục sản phẩm
SELECT 
    YEAR(wo.StartDate) AS Year,
    MONTH(wo.StartDate) AS Month,
    pc.Name AS ProductCategory,
    COUNT(wo.WorkOrderID) AS TotalWorkOrders,
    SUM(wo.OrderQty) AS TotalOrderQuantity,
    AVG(DATEDIFF(day, wo.StartDate, wo.EndDate)) AS AvgProductionTime
FROM Production.WorkOrder wo
JOIN Production.Product p ON wo.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE wo.EndDate IS NOT NULL
GROUP BY YEAR(wo.StartDate), MONTH(wo.StartDate), pc.Name
ORDER BY Year, Month, ProductCategory;


--- Đánh giá chất lượng sản phẩm
SELECT 
    p.Name AS ProductName,
    COUNT(wo.WorkOrderID) AS TotalWorkOrders,
    SUM(wo.OrderQty) AS TotalOrdered,
    SUM(wo.StockedQty) AS TotalCompleted,
    SUM(wo.ScrappedQty) AS TotalScrapped,
    CAST(SUM(wo.ScrappedQty) AS FLOAT) / NULLIF(SUM(wo.OrderQty), 0) * 100 AS ScrapRate,
    sr.Name AS ScrapReason
FROM Production.WorkOrder wo
JOIN Production.Product p ON wo.ProductID = p.ProductID
LEFT JOIN Production.ScrapReason sr ON wo.ScrapReasonID = sr.ScrapReasonID
GROUP BY p.Name, p.ProductNumber, sr.Name
HAVING SUM(wo.ScrappedQty) > 0
ORDER BY ScrapRate DESC;
