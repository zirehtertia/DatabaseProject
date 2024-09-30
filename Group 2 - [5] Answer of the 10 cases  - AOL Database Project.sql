USE JigitalclouN
--1. 
SELECT 
    MS.StaffID, 
    Ms.StaffName, 
    MS.StaffGender,
    MS.StaffSalary,MAX(RTD.RentalDuration) [LongestPeriod]
FROM MsStaff MS JOIN RentalTransactionHeader RTH
ON MS.StaffID = RTH.StaffID
JOIN RentalTransactionDetail RTD
ON RTH.RentalID = RTD.RentalID
    WHERE MS.StaffSalary < 15000000 AND YEAR(MS.StaffDOB) < 2003
    GROUP BY MS.StaffID, Ms.StaffName, MS.StaffGender, MS.StaffSalary

--2. 
SELECT
    CONCAT(ML.City, ' ', ML.Country) [Location],
    MIN(ServerPrice) [CheapestServerPrice]
FROM MsLocation ML JOIN MsServer MS
ON ML.LocationID = MS.LocationID
JOIN MsProcessor MP
ON MS.ProcessorID = MP.ProcessorID
    WHERE MP.ProcessorClockSpeedMHz > 3000 
    AND (ML.Latitude >= -30 AND ML.Latitude <= 30)
    GROUP BY ML.City, ML.Country

--3.
SELECT RTH.RentalID, 
    CONCAT(MAX(MM.MemoryFrequencyMHz), ' MHz') [MaxMemoryFrequency],
    CONCAT(SUM(MM.MemoryCapacityGB), ' GB') [TotalMemoryCapacity]
FROM RentalTransactionDetail RTD JOIN RentalTransactionHeader RTH
ON RTD.RentalID = RTH.RentalID
JOIN MsServer MSR
ON RTD.ServerID = MSR.ServerID
JOIN MsMemory MM
ON MSR.MemoryID = MM.MemoryID
    WHERE YEAR(RTH.StartingDate) = 2020 AND DATENAME(QUARTER,RTH.StartingDate) = 4 
    GROUP BY RTH.RentalID

--4.
SELECT
    STH.SaleID,
    COUNT(*) [ServerCount],
    CONCAT(AVG(ServerPrice)/ 1000000, ' million(s) IDR')[AverageServerPrice]
FROM SaleTransactionDetail STD JOIN MsServer MS
ON STD.ServerID = MS.ServerID
JOIN SaleTransactionHeader STH 
ON STD.SaleID = STH.SaleID
    WHERE YEAR(STH.TransactionDate) BETWEEN 2016 AND 2020
    GROUP BY STH.SaleID
    HAVING AVG(MS.ServerPrice) > 50000000

--5.
SELECT STD.SaleID, 
    MAX(ServerPrice) [MostExpensiveServerPrice],   
    (SELECT ((0.55 * MP.ProcessorClockSpeedMHz * MP.ProcessorNumberCores) + 
    (MM.MemoryfrequencyMHz * MM.MemoryCapacityGB * 0.05)) / 143200 )[HardwareRatingIndex]
FROM SaleTransactionHeader STH JOIN SaleTransactionDetail STD 
ON STH.SaleID = STD.SaleID 
JOIN MsServer MS 
ON STD.ServerID = MS.ServerID 
JOIN MsProcessor MP 
ON MP.ProcessorID = MS.ProcessorID 
JOIN MsMemory MM 
ON MM.MemoryID = MS.MemoryID

WHERE MS.ServerID IN (
    SELECT TOP 10 ServerID
    FROM MsServer
    ORDER BY ServerPrice DESC
)
AND STD.SaleID IN (
    SELECT SaleID
    FROM SaleTransactionHeader
    WHERE YEAR(TransactionDate) % 2 = 1
 )
 GROUP BY STD.SaleID, MP.ProcessorClockSpeedMHz, MP.ProcessorNumberCores, MM.MemoryfrequencyMHz, MM.MemoryCapacityGB

--6.
SELECT
    CONCAT(LEFT(ProcessorName, CHARINDEX(' ', ProcessorName + ' ') - 1), ' ', ProcessorModelCode) [ProcessorName],
    CONCAT(ProcessorNumberCores, ' core(s)') [CoreCount],
    MAX(ProcessorPrice) [ProcessorPriceIDR]
FROM MsProcessor AS MP JOIN MsServer AS MS 
ON MP.ProcessorID = MS.ProcessorID
JOIN MsLocation AS ML ON MS.LocationID = ML.LocationID
WHERE ML.Latitude >= 0 AND ML.Latitude <= 90
    AND ProcessorNumberCores IN (
        SELECT ProcessorNumberCores
        FROM MsProcessor
        GROUP BY ProcessorNumberCores
        HAVING COUNT(*) > 1
    )
    GROUP BY
    ProcessorName, ProcessorModelCode, ProcessorNumberCores

--7. 
SELECT TOP 10 
    CONCAT(LEFT(CustomerName,1),'***** *****') [HiddenCustomerName],
    COUNT(STD.SaleID)[CurrentPurchaseAmount],
    COUNT(STD.SaleID)[CountedPurchaseAmount],
    SUM(MS.ServerPrice) AS CurrentPurchaseAmount,
    CAST(SUM(MS.ServerPrice) / 1000000 AS VARCHAR ) + ' point(s)' [RewardPointsGiven]
FROM  SaleTransactionHeader STH JOIN SaleTransactionDetail STD 
ON STH.SaleID = STD.SaleID JOIN MsServer MS 
ON STD.ServerID = MS.ServerID 
JOIN MsCustomer MC 
ON MC.CustomerID = STH.CustomerID
    WHERE MC.CustomerName IN (SELECT TOP 10 MC.CustomerName
    WHERE STH.TransactionDate BETWEEN '2015-01-01' AND '2019-12-31'
    )
    GROUP BY MC.CustomerName, Ms.ServerPrice
    ORDER BY MS.ServerPrice DESC

--8. 
SELECT
    CONCAT('Staff ', SUBSTRING(StaffName, 1, CHARINDEX(' ', StaffName + ' ') - 1)) [StaffName],
    CONCAT(SUBSTRING(StaffEmail, 1, CHARINDEX('@', StaffEmail) - 1), '@jigitalcloun.net') [StaffEmail],
    StaffAddress,
    CONCAT(StaffSalary / 10000000, ' million(s) IDR') [StaffSalary], [TotalValue]
FROM
    (
     SELECT
        STF.StaffID,
        STF.StaffName,
        STF.StaffEmail,
        STF.StaffAddress,
        STF.StaffSalary,
        SUM(MS.ServerPrice / 120 * RTD.RentalDuration) AS TotalValue
        FROM MsStaff AS STF JOIN RentalTransactionHeader RTH 
        ON STF.StaffID = RTH.StaffID
        JOIN RentalTransactionDetail RTD 
        ON RTH.RentalID = RTD.RentalID
        JOIN MsServer MS 
        ON RTD.ServerID = MS.ServerID
        WHERE
            STF.StaffSalary < (
            SELECT AVG(StaffSalary)
            FROM MsStaff
            )
    GROUP BY STF.StaffID, STF.StaffName, STF.StaffEmail, STF.StaffAddress, STF.StaffSalary
    ) AS Subquery
    WHERE TotalValue > 10000000

--9. 
GO
 CREATE VIEW ServerRentalDurationView AS
SELECT
    REPLACE(MS.ServerID, 'JCN-V', 'No.') [Server],
    CONCAT(SUM(RTD.RentalDuration), ' month(s)') [TotalRentalDuration],
    CONCAT(MAX(RTD.RentalDuration), ' month(s)') [MaxSingleRentalDuration]
FROM RentalTransactionDetail RTD JOIN MsServer MS 
ON RTD.ServerID = MS.ServerID
JOIN MsLocation ML 
ON MS.LocationID = ML.LocationID
    WHERE ML.Latitude < 0 AND ML.Latitude >= -90
    GROUP BY MS.ServerID
    HAVING SUM(RTD.RentalDuration) > 50

--10.
GO 
CREATE VIEW SoldProcessorPerformanceView AS
SELECT
    STH.SaleID,
    CONCAT(CAST(MIN(MP.ProcessorClockSpeedMHz * MP.ProcessorNumberCores * 0.675) AS DECIMAL(10,1)), ' MHz') [MinEffectiveClock],
    CONCAT(CAST(MAX(MP.ProcessorClockSpeedMHz * MP.ProcessorNumberCores * 0.675) AS DECIMAL(10,1)), ' MHz') [MaxEffectiveClock]
FROM SaleTransactionHeader STH JOIN SaleTransactionDetail STD 
ON STH.SaleID = STD.SaleID
JOIN MsServer MS 
ON STD.ServerID = MS.ServerID
JOIN MsProcessor MP 
ON MS.ProcessorID = MP.ProcessorID
    WHERE 
    MP.ProcessorNumberCores & (MP.ProcessorNumberCores - 1) = 0 
    AND MP.ProcessorClockSpeedMHz * MP.ProcessorNumberCores * 0.675 >= 10000 
    GROUP BY STH.SaleID