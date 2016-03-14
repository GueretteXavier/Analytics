/************************************************************************
 Devoir 4 (5% de la Note Finale)
 Matricule: 112 08 473
 Nom: Guérette
 Prénom: Xavier
 Objectif du fichier: Script pour le 4e Devoir Technologie de l'intelligence d'affaires
*************************************************************************/

USE AdventureWorks2008R2
GO

-- QUESTION 1
; WITH Dates AS
		(
		SELECT CAST('2006-01-01' AS DATE) AS [Date]
		UNION ALL
		SELECT DATEADD(DAY, 1, [Date]) AS [Date] FROM Dates WHERE DATEADD(DAY, 1, [Date]) < '2007-01-01'
		)
		SELECT * FROM Dates
		OPTION (MAXRECURSION 366)

	-- Day of Year 2006...
	; WITH Dates AS
		(
		SELECT CAST('2006-01-01' AS DATE) AS [Date]
		UNION ALL
		SELECT DATEADD(DAY, 1, [Date]) AS [Date] FROM Dates WHERE DATEADD(DAY, 1, [Date]) < '2007-01-01'
		)
		SELECT Dates.[Date],
			CASE
				WHEN SUM(SOH.TotalDue) IS NULL THEN 0
				ELSE SUM(SOH.TotalDue) 
			END AS 'Total Sales'
			FROM Dates
				LEFT JOIN Sales.SalesOrderHeader SOH ON CONVERT(DATE, SOH.OrderDate) = Dates.[Date]
				INNER JOIN Sales.Customer SC ON SC.CustomerID = SOH.CustomerID
				INNER JOIN Person.Person PP ON PP.BusinessEntityID = SC.PersonID
				WHERE PP.PersonType = 'IN'
				GROUP BY Dates.[Date]
				-- Note: OPTION MAXRECURSION Must be the Last Statement of the Query
				OPTION (MAXRECURSION 366)
				
-- QUESTION 2
	SELECT
		PSC.Name 'SubCategory',
		PP.Name 'Product',
		CASE 
			WHEN SUM(OrderQTY) IS NULL THEN 0
			ELSE SUM(OrderQTY)
		END
		AS 'Order QTY',
		CASE
			WHEN SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY) IS NULL THEN 0
			ELSE SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY)
		END AS 'TotalRevenue',
		RANK() OVER (ORDER BY SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY) DESC) AS 'RankByRevenue',
		RANK() OVER (ORDER BY CASE WHEN SUM(OrderQTY) IS NULL THEN 0 ELSE SUM(OrderQTY) END DESC) AS 'RankByOrderQTY'
		FROM Production.Product PP
		LEFT JOIN Production.ProductSubCategory PSC ON PSC.ProductSubCategoryID = PP.ProductSubCategoryID
		LEFT JOIN Production.ProductCategory PC ON PC.ProductCategoryID = PSC.ProductCategoryID
		LEFT JOIN Sales.SalesOrderDetail SOD ON SOD.ProductID = PP.ProductID
		WHERE PC.Name = 'Clothing'
		GROUP BY PSC.Name, PP.Name
		ORDER BY 6, 5
	-- Basé sur ces informations, est-ce que les 3 meilleurs vendeurs sont ceux qui ont rapporté le plus d'argent à AdventureWorks...
	/*
		Les 3 meilleurs vendeurs sont (1). 'AWC Logo Cap', (2). 'Long-Sleeve Logo Jersey. L' (3). 'Classic Vest. S', tandis
		que les produits qui ont rapporté le plus sont (1). 'Classic Vest. S' (2). 'Women's Mountain Shorts. S' (3). 'Women's Mountain Shorts. L'
	*/

-- QUESTION 3
	-- Le devoir était challengeant, mais raisonnable. J'aimerais qu'on fasse un example additionnel de CTE Recursive par contre,
	-- l'exemple des notes de cours est difficile à comprend puisqu'il utilise une jointure de la CTE contrairement à la
	-- question du devoir... J'ai passé avoir 4.30 h pour faire le devoir (Q1 1H30, Q2 1H30, Revision & Test 1h30), toutefois, j'avais passé 8 heures la veille pour
	-- repasser à travers une partie des notes de cours et les Exercises pour la semaine.

------------------------------------------------ TESTs ----------------------------------------------------------------

	-- T1: Day of Year 2006...
	; WITH Dates AS
		(
		SELECT CAST('2006-01-01' AS DATE) AS [Date]
		UNION ALL
		SELECT DATEADD(DAY, 1, [Date]) AS [Date] FROM Dates WHERE DATEADD(DAY, 1, [Date]) < '2007-01-01'
		)
		SELECT * FROM Dates OPTION (MAXRECURSION 366)
	
	-- T2: Date...
	SELECT CONVERT(DATE, SOH.OrderDate) AS 'Date',
		SUM(SOH.TotalDue) AS 'Total Sales'
		FROM Sales.SalesOrderHeader SOH 
			INNER JOIN Sales.Customer SC ON SC.CustomerID = SOH.CustomerID
			INNER JOIN Person.Person PP ON PP.BusinessEntityID = SC.PersonID
		WHERE PP.PersonType = 'IN' AND DATENAME(YEAR, SOH.OrderDate) = 2006
		GROUP BY CONVERT(DATE, SOH.OrderDate)
		ORDER BY 1
		
			
	SELECT * FROM SalesDetails SD
		WHERE SD.CustomerID NOT IN (SELECT CustomerID FROM [11208473].Customer)
			
	INSERT INTO [11208473].SalesDetails (SalesOrderDetailID, SalesOrderNumber, ProductID, OrderQty, LineTotal, [Year], [Month], CustomerID) 
		VALUES (918835,'SO61957',796,	1,	2443.350000,	2008,	1,	204052);