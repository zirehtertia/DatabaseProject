USE JigitalclouN

--Sale Transaction Simulate
--1. Yuna Sya want to see the price of all memory product
SELECT MemoryProductName, MemoryPrice
FROM MsMemory

--2. Yuna sya want to buy Sandisk memory
SELECT MemoryProductName, MemoryPrice
FROM MsMemory
WHERE MemoryProductName LIKE 'Sandisk'

--RENTAL SIMULATE
--1. Lodi Victor want to see all price of Processor product
SELECT ProcessorName, ProcessorPrice
FROM MsProcessor

--2. Lodi Victor want to rent pentium processor withthe code'1004' and choose the starting date
SELECT ProcessorName, ProcessorPrice
FROM MsProcessor
WHERE ProcessorName LIKE 'Pentium' AND ProcessorModelCode = 1004


