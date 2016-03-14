/************************************************************************
 Devoir 5 (5% de la Note Finale)
 Matricule: 112 08 473
 Nom: Guérette
 Prénom: Xavier
 Objectif du Fichier: Script pour le 5e Devoir Technologie de l'intelligence d'affaires
*************************************************************************/

-- ASSUMPTION(s):
-- (1). J'ai remplacé les valeurs NULL pour les colonnes 'TotalOrderQuantity', 'TotalOrderCount, 'TotalProfit',
-- 'RankByOrderQuantity', 'RankByOrderCount', 'RankByProfit' par '0'
-- (2). Rien m'indiquais que je devais écrire la partie 'UPDATE' de 'SP_Devoir5_GenerateSales' exactement comme
-- spécifié dans l'énoncé du devoir. J'ai donc opté pour une méthode que me semblait plus facile (j'ai pas compris
-- l'énoncé)

USE StudentDB
GO
	
-- Start with Managing Keys...

	-- Drop Constraints Fact Table
	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Devoir5_fact_Sales')
		BEGIN
		IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'CK_factSales_YearMonth_ProductID')
			BEGIN
			ALTER TABLE [11208473].Devoir5_fact_Sales DROP CONSTRAINT CK_factSales_YearMonth_ProductID;
			END
		IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'CK_factSales_YearMonth_ProductID')
			BEGIN
			ALTER TABLE [11208473].Devoir5_fact_Sales DROP CONSTRAINT FK_Calendar_YearMonth;
			END
		DROP TABLE [11208473].Devoir5_fact_Sales
		END;
	
	-- Drop Constraints Dimension Table
	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Devoir5_dim_SalesCalendar')
		BEGIN
		IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS WHERE CONSTRAINT_NAME = 'PK_SalesCalendar_YearMonth')
			BEGIN
			ALTER TABLE [11208473].Devoir5_dim_SalesCalendar DROP CONSTRAINT PK_SalesCalendar_YearMonth;
			END
		DROP TABLE [11208473].Devoir5_dim_SalesCalendar
		END;
	
	-- QUESTION 1: Create 'Devoir5_dim_SalesCalendar
	
		-- 'DROP' 'Devoir5_dim_SalesCalendar
		IF EXISTS	
			(
			SELECT * FROM SYS.TABLES ST
				WHERE ST.name = 'Devoir5_dim_SalesCalendar'
			)
		BEGIN
			DROP TABLE [11208473].Devoir5_dim_SalesCalendar
		END
		
		IF NOT EXISTS
			(
			SELECT * FROM SYS.TABLES ST
				WHERE ST.name = 'Devoir5_dim_SalesCalendar'
			)
			BEGIN
				CREATE TABLE [11208473].Devoir5_dim_SalesCalendar
					(
					[YearMonth] INT NOT NULL,
					[Month] SMALLINT NOT NULL,
					[Quarter] INT NOT NULL,
					[YearQuarter] CHAR(7) NOT NULL,
					[Year] SMALLINT NOT NULL
					);
			END
		
	-- QUESTION 2: Create 'Devoir5_Fact_Sales' IF NOT EXISTS...
		
		-- 'DROP' 'Devoir5_Fact_Sales'
		IF EXISTS	
			(
			SELECT * FROM SYS.TABLES ST
				WHERE ST.name = 'Devoir5_Fact_Sales'
			)
		BEGIN
			DROP TABLE [11208473].Devoir5_Fact_Sales
		END
		
		IF NOT EXISTS
			(
			SELECT * FROM SYS.TABLES ST
				WHERE ST.name = 'Devoir5_Fact_Sales'
			)
			BEGIN
				CREATE TABLE [11208473].Devoir5_Fact_Sales
					(
					[YearMonth] INT NOT NULL,
					[ProductID] INT NOT NULL,
					[ProductName] NVARCHAR(50) NOT NULL,
					[ProductSubCategory] NVARCHAR(50),
					[ProductCategory] NVARCHAR(50),
					[TotalOrderQuantity] INT,
					[TotalOrderCount] INT,
					[TotalProfit] MONEY,
					[RankByOrderQuantity] INT,
					[RankByOrderCount] INT,
					[RankByProfit] INT
					);
			END	
	
	-- QUESTION 3: Stock Prok -> 'Devoir5_GenerateSalesCalendar'
	IF EXISTS
		(
		SELECT * FROM INFORMATION_SCHEMA.ROUTINES
			WHERE ROUTINE_NAME = 'SP_Devoir5_GenerateSalesCalendar'
		)
	BEGIN
		DROP PROCEDURE SP_Devoir5_GenerateSalesCalendar
	END	
	
	GO
	-- Create Stock Prok 'Devoir5_GenerateSalesCalendar'...
	CREATE PROCEDURE SP_Devoir5_GenerateSalesCalendar(@aYear CHAR(4))
		AS
		IF EXISTS
			(
			SELECT * FROM [11208473].Devoir5_dim_SalesCalendar DSC
				WHERE DSC.[YEAR] = @aYear
			)
			BEGIN
				PRINT '(1.0). Data for ' + @aYear + ' in Devoir5_dim_SalesCalendar already exists...'
			END
		ELSE
			BEGIN
			PRINT '(1.1). Inserting data for ' + @aYear + ' in Devoir5_dim_SalesCalendar...'; 
			WITH CTE([Date]) AS
				(
				SELECT CONVERT(DATE, @aYear + '-01-01') AS [Date]
				UNION ALL
				SELECT DATEADD(MONTH, 1, [Date]) AS [Date]
				FROM CTE WHERE [Date] < CONVERT(DATE, @aYear + '-12-01')
				)
			INSERT INTO [11208473].Devoir5_dim_SalesCalendar ([YearMonth], [Month], [Quarter], [YearQuarter], [Year]) 
			SELECT 
				-- YearMonth
				CASE WHEN MONTH([Date]) < 10 THEN 
					STR(YEAR([Date]), 4) + '0' + STR(MONTH([Date]), 1)
					ELSE STR(YEAR([Date]), 4) + '' + STR(MONTH([Date]), 2)
				END,
				-- Month
				MONTH([Date]),
				-- Quarter
				CASE WHEN MONTH([Date]) < 4 THEN 1
					WHEN MONTH([Date]) > 3 AND MONTH([Date]) < 7 THEN 2
					WHEN MONTH([Date]) > 6 AND MONTH([Date]) < 10 THEN 3
					ELSE 4
				END,
				-- YearQuarter
				STR(YEAR([Date]), 4) + '-' + 
					CASE WHEN MONTH([Date]) < 4 THEN 'Q1'
						WHEN MONTH([Date]) >= 4 AND MONTH([Date]) < 7 THEN 'Q2'
						WHEN MONTH([Date]) >= 7 AND MONTH([Date]) < 10 THEN 'Q3'
						ELSE 'Q4'
				END,
				-- Year
				YEAR([Date])
				FROM CTE
			END
	GO
	
	-- QUESTION 4: Stock Prok -> 'Devoir5_GenerateSales'
	
	IF EXISTS
		(
		SELECT * FROM INFORMATION_SCHEMA.ROUTINES 
			WHERE ROUTINE_NAME = 'SP_Devoir5_GenerateSales'
		)
		BEGIN
			DROP PROCEDURE [11208473].SP_Devoir5_GenerateSales
		END
		
	GO
	CREATE PROCEDURE SP_Devoir5_GenerateSales(@Year CHAR(4))
		AS
		IF EXISTS
			(
			SELECT * FROM [11208473].Devoir5_Fact_Sales
				WHERE @Year = SUBSTRING(STR([YearMonth], 6), 1, 4)
			)
			BEGIN
				PRINT '(2.0). Data for ' + @Year + ' in Devoir5_fact_Sales already exists...' 
			END
		ELSE
			BEGIN
				-- (0). CALL 'SP_DEVOIR5_GenerateSalesCalendar'...
				EXEC [11208473].SP_Devoir5_GenerateSalesCalendar @aYear = @Year
				-- QUESTION 4.1:
				-- (1). Insertion de YearMonth, ProductID, ProductName, ProductSubCategory, ProductCategory
				PRINT '(2.1). Inserting YearMonth, ProductID, ProductName, ProductSubCategory, ProductCategory for year ' + @Year + ' in Devoir5_GenerateSalesCalendar'
				; WITH CTE([Date]) AS
					(
					SELECT CONVERT(DATE, @Year + '-01-01') AS [Date]
					UNION ALL
					SELECT DATEADD(MONTH, 1, [Date]) AS [Date]
					FROM CTE WHERE [Date] < CONVERT(DATE, @Year + '-12-01')
					)
				INSERT INTO [Devoir5_fact_Sales] ([YearMonth], [ProductID], [ProductName], [ProductSubCategory], [ProductCategory], 
				[TotalOrderQuantity], [TotalOrderCount], [TotalProfit])
				SELECT 
					-- YearMonth
					CASE WHEN MONTH([Date]) < 10 THEN 
							STR(YEAR([Date]), 4) + '0' + STR(MONTH([Date]), 1)
							ELSE STR(YEAR([Date]), 4) + '' + STR(MONTH([Date]), 2)
					END AS [YearMonth],
					-- ProductID
					Products.ProductID,
					-- ProductName
					Products.ProductName,
					-- ProductSubCategory
					CASE WHEN Products.ProductSubCategory IS NULL THEN 'N/A'
						ELSE Products.ProductSubCategory
					END AS 'ProductSubCategory',
					-- ProductCategory
					CASE WHEN Products.ProductCategory IS NULL THEN 'N/A'
						ELSE Products.ProductCategory
					END AS 'ProductCategory',
					0, 0, 0
					FROM CTE
					CROSS JOIN 
						(SELECT 
						PP.ProductID AS [ProductID],
						PP.Name AS [ProductName],
						PSC.Name AS [ProductSubCategory],
						PC.Name AS [ProductCategory]
						FROM AdventureWorks2008R2.Production.Product PP
						LEFT JOIN AdventureWorks2008R2.Production.ProductSubCategory PSC ON PP.ProductSubCategoryID = PSC.ProductSubCategoryID
						LEFT JOIN AdventureWorks2008R2.Production.ProductCategory PC ON PC.ProductCategoryID = PSC.ProductCategoryID) AS Products
				ORDER BY 2, 1
				-- QUESTION 4.2:
				-- (3). UPDATE with LEFT JOIN
				PRINT '(2.2). Updating Devoir5_Fact_Sales with mesures...'
					UPDATE [11208473].Devoir5_Fact_Sales
					SET YearMonth = DFS.YearMonth,
					ProductID = DFS.ProductID,
					ProductSubCategory = DFS.ProductSubCategory,
					ProductCategory = DFS.ProductCategory,
					TotalOrderQuantity = CASE WHEN Derived.TotalOrderQuantity IS NULL THEN 0
										 ELSE Derived.TotalOrderQuantity
										 END,
					TotalOrderCount = CASE WHEN Derived.TotalOrderCount IS NULL THEN 0
									  ELSE Derived.TotalOrderCount
									  END,
					TotalProfit = CASE WHEN Derived.TotalProfit IS NULL THEN 0
							      ELSE Derived.TotalProfit
							      END,
					RankByOrderQuantity = CASE WHEN Derived.RankByOrderQuantity IS NULL THEN 0
										  ELSE Derived.RankByOrderQuantity
										  END,
					RankByOrderCount = CASE WHEN Derived.RankByOrderCount IS NULL THEN 0
									   ELSE Derived.RankByOrderCount
									   END,
					RankByProfit = CASE WHEN Derived.RankByProfit IS NULL THEN 0
								   ELSE Derived.RankByProfit
								   END
					FROM [11208473].Devoir5_Fact_Sales DFS
					LEFT JOIN 
						(SELECT 
							CASE WHEN MONTH(SOH.OrderDate) < 10 THEN 
								STR(YEAR(SOH.OrderDate), 4) + '0' + STR(MONTH(SOH.OrderDate), 1)
								ELSE STR(YEAR(SOH.OrderDate), 4) + '' + STR(MONTH(SOH.OrderDate), 2)
							END AS [YearMonth],
							PP.ProductID,
							SUM(SOD.OrderQTY) AS 'TotalOrderQuantity',
							COUNT(SOD.ProductID) AS 'TotalOrderCount',
							SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY) AS 'TotalProfit',
							RANK() OVER (ORDER BY SUM(SOD.OrderQTY) DESC) AS 'RankByOrderQuantity',
							RANK() OVER (ORDER BY COUNT(SOD.ProductID) DESC) AS 'RankByOrderCount',
							RANK() OVER (ORDER BY SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY) DESC) AS 'RankByProfit'
							FROM AdventureWorks2008R2.Production.Product PP
							INNER JOIN AdventureWorks2008R2.Sales.SalesOrderDetail SOD ON PP.ProductID = SOD.ProductID
							INNER JOIN AdventureWorks2008R2.Sales.SalesOrderHeader SOH ON SOH.SalesOrderID = SOD.SalesOrderID
							WHERE YEAR(SOH.OrderDate) = @Year
							GROUP BY YEAR(SOH.OrderDATE), MONTH(SOH.OrderDATE), PP.ProductID
						) AS Derived
						ON Derived.YearMonth = DFS.YearMonth AND Derived.ProductID = DFS.ProductID
					WHERE SUBSTRING(STR(DFS.YearMonth, 6), 1, 4) = @Year
			END	
	GO
		-- QUESTION 4.3
		
			-- GenerateSales for Year 2007
			EXEC [11208473].SP_Devoir5_GenerateSales @Year = '2007'
			-- GenerateSales for Year 2008
			EXEC [11208473].SP_Devoir5_GenerateSales @Year = '2008'
			-- Attempt to ReGenerateSales for Year 2007
			EXEC [11208473].SP_Devoir5_GenerateSales @Year = '2007'
			
			-- Create FK and PK Constraints...
			IF NOT EXISTS
				(
				SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
					WHERE CONSTRAINT_NAME = 'CK_factSales_YearMonth_ProductID'
				)
				BEGIN
				ALTER TABLE [11208473].Devoir5_fact_Sales ADD CONSTRAINT CK_factSales_YearMonth_ProductID PRIMARY KEY([YearMonth], [ProductID]);
				END
			
			IF NOT EXISTS
				(
				SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
					WHERE CONSTRAINT_NAME = 'PK_SalesCalendar_YearMonth'
				)
				BEGIN
				ALTER TABLE [11208473].Devoir5_dim_SalesCalendar ADD CONSTRAINT PK_SalesCalendar_YearMonth PRIMARY KEY(YearMonth);
				END

			IF NOT EXISTS
				(
				SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
					WHERE CONSTRAINT_NAME = 'FK_Calendar_YearMonth'
				)
				BEGIN
				ALTER TABLE [11208473].Devoir5_fact_Sales ADD CONSTRAINT FK_Calendar_YearMonth FOREIGN KEY (YearMonth) REFERENCES Devoir5_dim_SalesCalendar(YearMonth);
				END

		-- QUESTION 4.4.
		-- Dans 'Devoir5_Fact_Sales', nous n'avons pas les ventes, mais le profit.
		-- Voici une des requêtes que j'ai utilisé pour tester mon code. Je l'ai légèrement modifié pour répondre à la question...
		-- La requête est très complexe, si on devait la modifier légèrement, le risque d'erreur serait élevé...
		-- Il est donc préférable de programmer une SP, de la tester pour s'assurer qu'elle fonctionne et de la réutiliser
		-- lorsque nous en avons besoin!
		SELECT 
		Derived.YearMonth,
		Derived.ProductCategory,
		SUM(Derived.TotalProfit) AS [TotalProfit]
		FROM 
			(
			SELECT 
				STR(YEAR(SOH.OrderDate), 4) + 
					CASE WHEN MONTH(SOH.OrderDate) < 10 THEN '0' + STR(MONTH(SOH.OrderDate), 1)
					ELSE STR(MONTH(SOH.OrderDate), 2)
					END AS [YearMonth],
				PP.ProductID AS 'ProductID',
				PP.Name AS 'ProductName',
				PSC.Name AS 'ProductSubCategory',
				PC.Name AS 'ProductCategory',
				SUM(SOD.OrderQTY) AS [TotalOrderQuantity],
				COUNT(SOD.ProductID) AS [TotalOrderCount],
				SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY) AS [TotalProfit],
				RANK() OVER(ORDER BY SUM(SOD.OrderQTY) DESC) AS [RankByOrderQuantity],
				RANK() OVER(ORDER BY COUNT(SOD.ProductID) DESC) AS [RankByOrderCount],
				RANK() OVER(ORDER BY SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY) DESC) AS [RankByProfit]
				FROM AdventureWorks2008R2.Production.Product PP
				LEFT JOIN AdventureWorks2008R2.Production.ProductSubCategory PSC ON PSC.ProductSubCategoryID = PP.ProductSubCategoryID
				LEFT JOIN AdventureWorks2008R2.Production.ProductCategory PC ON PC.ProductCategoryID = PSC.ProductCategoryID
				LEFT JOIN AdventureWorks2008R2.Sales.SalesOrderDetail SOD ON SOD.ProductID = PP.ProductID
				LEFT JOIN AdventureWorks2008R2.Sales.SalesOrderHeader SOH ON SOH.SalesOrderID = SOD.SalesOrderID
				WHERE YEAR(SOH.OrderDate) IS NOT NULL AND YEAR(SOH.OrderDate) = '2008'
				GROUP BY YEAR(SOH.OrderDate), MONTH(SOH.OrderDate), PP.ProductID, PP.Name, PSC.Name, PC.Name
				-- ORDER BY 1,2,3,4,5,6,7,8,9,10,11
				) AS Derived
			GROUP BY Derived.YearMonth, Derived.ProductCategory
			ORDER BY 1,2,3
			
		-- Requête sur 'Devoir5_Fact_Sales'
		-- Effectivement, la requête est beaucoup plus simple!
		SELECT 
			DFS.YearMonth,
			DFS.ProductCategory,
			SUM(DFS.TotalProfit) AS [TotalProfit]
			FROM [11208473].Devoir5_Fact_Sales DFS
			WHERE DFS.TotalOrderQuantity != 0 AND SUBSTRING(STR(DFS.[YearMonth], 6), 1, 4) = '2008'
			GROUP BY DFS.YearMonth, DFS.ProductCategory
			ORDER BY 1,2,3
				
----------------------------------------------------------- Tests -------------------------------------------------------------------
	
	-- SELECTs
	SELECT * FROM [11208473].Devoir5_dim_SalesCalendar
	SELECT * FROM [11208473].Devoir5_fact_Sales
	
	-- Aucun CAS... Notre UPDATE: UPDATE toute la table DFS...
	SELECT * FROM [11208473].Devoir5_Fact_Sales DFS
		WHERE SUBSTRING(STR(DFS.YearMonth, 6), 1, 4) = '2007' and DFS.TotalOrderQuantity != 0
	SELECT * FROM [11208473].Devoir5_Fact_Sales DFS
		WHERE SUBSTRING(STR(DFS.YearMonth, 6), 1, 4) = '2008' and DFS.TotalOrderQuantity != 0
	
	-- Create Request on 'Devoir5_Fact_Sales'
	SELECT 
	SUBSTRING(STR([YearMonth], 6), 1, 4) AS 'Year',
	SUBSTRING(STR([YearMonth], 6), 5, 2) AS 'Month',
	DFS.ProductCategory,
	SUM(DFS.TotalOrderQuantity) AS 'Total Order Quantity'
	FROM [11208473].Devoir5_Fact_Sales DFS
		GROUP BY SUBSTRING(STR(DFS.[YearMonth], 6), 1, 4), SUBSTRING(STR(DFS.[YearMonth], 6), 5, 2), DFS.ProductCategory

	SELECT DISTINCT YearMonth FROM [11208473].Devoir5_dim_SalesCalendar
	SELECT YearMonth FROM [11208473].Devoir5_dim_SalesCalendar
		WHERE YearMonth = '200501'

	SELECT YearMonth FROM [11208473].Devoir5_dim_SalesCalendar
		WHERE YearMonth = '200501'
	
	-- Test for Non-Existing Year FAILED?
	EXEC [11208473].SP_Devoir5_GenerateSales @Year = '2004'
	EXEC [11208473].SP_Devoir5_GenerateSales @Year = '2007'
	EXEC [11208473].SP_Devoir5_GenerateSales @Year = '2008'
	
	-- Test for Existing Year PASSED
	EXEC [11208473].SP_Devoir5_GenerateSales @Year = '2005'
	EXEC [11208473].SP_Devoir5_GenerateSales @Year = '2005'
	EXEC [11208473].SP_Devoir5_GenerateSales @Year = '2006'
		
	SELECT DISTINCT DFS.YearMonth FROM [11208473].Devoir5_Fact_Sales DFS
	
	-- 506 Product(s): 506 Products Times 12 Months -> 6072 Records per Year
	SELECT DISTINCT PP.Name FROM AdventureWorks2008R2.Production.Product PP
	
	-- 995 Records for Year 2007
	SELECT 
		STR(YEAR(SOH.OrderDate), 4) + 
			CASE WHEN MONTH(SOH.OrderDate) < 10 THEN '0' + STR(MONTH(SOH.OrderDate), 1)
			ELSE STR(MONTH(SOH.OrderDate), 2)
			END AS [YearMonth],
		PP.ProductID AS 'ProductID',
		PP.Name AS 'ProductName',
		PSC.Name AS 'ProductSubCategory',
		PC.Name AS 'ProductCategory',
		SUM(SOD.OrderQTY) AS [TotalOrderQuantity],
		COUNT(SOD.ProductID) AS [TotalOrderCount],
		SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY) AS [TotalProfit],
		RANK() OVER(ORDER BY SUM(SOD.OrderQTY) DESC) AS [RankByOrderQuantity],
		RANK() OVER(ORDER BY COUNT(SOD.ProductID) DESC) AS [RankByOrderCount],
		RANK() OVER(ORDER BY SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY) DESC) AS [RankByProfit]
		FROM AdventureWorks2008R2.Production.Product PP
		LEFT JOIN AdventureWorks2008R2.Production.ProductSubCategory PSC ON PSC.ProductSubCategoryID = PP.ProductSubCategoryID
		LEFT JOIN AdventureWorks2008R2.Production.ProductCategory PC ON PC.ProductCategoryID = PSC.ProductCategoryID
		LEFT JOIN AdventureWorks2008R2.Sales.SalesOrderDetail SOD ON SOD.ProductID = PP.ProductID
		LEFT JOIN AdventureWorks2008R2.Sales.SalesOrderHeader SOH ON SOH.SalesOrderID = SOD.SalesOrderID
		WHERE YEAR(SOH.OrderDate) IS NOT NULL AND YEAR(SOH.OrderDate) = '2008'
		GROUP BY YEAR(SOH.OrderDate), MONTH(SOH.OrderDate), PP.ProductID, PP.Name, PSC.Name, PC.Name
		ORDER BY 1,2,3,4,5,6,7,8,9,10,11
	
	-- Records
	SELECT * FROM [11208473].Devoir5_Fact_Sales DFS
		WHERE DFS.TotalOrderQuantity != 0 AND SUBSTRING(STR(DFS.[YearMonth], 6), 1, 4) = '2008'
	    ORDER BY 1,2,3,4,5,6,7,8,9,10,11
	 
	SELECT DISTINCT YEAR(SOH.OrderDate) FROM AdventureWorks2008R2.Sales.SalesOrderHeader SOH
	  
	SELECT * FROM AdventureWorks2008R2.Production.Product
	
	-- No 'NULL' ProductID in SOD
	SELECT * FROM AdventureWorks2008R2.Sales.SalesOrderDetail SOD
		WHERE SOD.ProductID IS NULL
	
	-- No NULL 'ProductID' or 'ProductName'
	SELECT PP.Name, PP.ProductID FROM AdventureWorks2008R2.Production.Product PP
		WHERE PP.Name IS NULL OR PP.ProductID IS NULL
		
	-- Beyond Compare Both Sets...
	
	SELECT * FROM AdventureWorks2008R2.Sales.SalesOrderDetail SOD
		
---------------------------------------------------------- Scrap Code ---------------------------------------------------------------
			
	SELECT
		DFS.YearMonth,
		DFS.ProductID,
		DFS.ProductSubCategory,
		DFS.ProductCategory,
		CASE WHEN Derived.TotalOrderQuantity IS NULL THEN 0
		ELSE Derived.TotalOrderQuantity
		END AS [TotalOrderQuantity],
		CASE WHEN Derived.TotalOrderCount IS NULL THEN 0
		ELSE Derived.TotalOrderQuantity
		END AS [TotalOrderCount],
		CASE WHEN Derived.TotalProfit IS NULL THEN 0
		ELSE Derived.TotalProfit
		END AS [TotalProfit]
		FROM [11208473].Devoir5_Fact_Sales DFS
		LEFT JOIN 
			(SELECT 
				CASE WHEN MONTH(SOH.OrderDate) < 10 THEN 
					STR(YEAR(SOH.OrderDate), 4) + '0' + STR(MONTH(SOH.OrderDate), 1)
					ELSE STR(YEAR(SOH.OrderDate), 4) + '' + STR(MONTH(SOH.OrderDate), 2)
				END AS [YearMonth],
				PP.ProductID,
				SUM(SOD.OrderQTY) AS 'TotalOrderQuantity',
				COUNT(SOD.ProductID) AS 'TotalOrderCount',
				SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY) AS 'TotalProfit'
				FROM AdventureWorks2008R2.Production.Product PP
				INNER JOIN AdventureWorks2008R2.Sales.SalesOrderDetail SOD ON PP.ProductID = SOD.ProductID
				INNER JOIN AdventureWorks2008R2.Sales.SalesOrderHeader SOH ON SOH.SalesOrderID = SOD.SalesOrderID
				WHERE YEAR(SOH.OrderDate) = '2007'
				GROUP BY YEAR(SOH.OrderDATE), MONTH(SOH.OrderDATE), PP.ProductID
			) AS Derived
			ON Derived.YearMonth = DFS.YearMonth AND Derived.ProductID = DFS.ProductID
	
	UPDATE [11208473].Devoir5_Fact_Sales
		SET YearMonth=DFS.YearMonth,
		ProductID=DFS.ProductID,
		ProductSubCategory=DFS.ProductSubCategory,
		ProductCategory=DFS.ProductCategory,
		TotalOrderQuantity=Derived.TotalOrderQuantity,
		TotalOrderCount=Derived.TotalOrderCount,
		TotalProfit=Derived.TotalProfit
		FROM [11208473].Devoir5_Fact_Sales DFS
		LEFT JOIN 
			(SELECT 
				CASE WHEN MONTH(SOH.OrderDate) < 10 THEN 
					STR(YEAR(SOH.OrderDate), 4) + '0' + STR(MONTH(SOH.OrderDate), 1)
					ELSE STR(YEAR(SOH.OrderDate), 4) + '' + STR(MONTH(SOH.OrderDate), 2)
				END AS [YearMonth],
				PP.ProductID,
				SUM(SOD.OrderQTY) AS 'TotalOrderQuantity',
				COUNT(SOD.ProductID) AS 'TotalOrderCount',
				SUM((PP.ListPrice - PP.StandardCost) * SOD.OrderQTY) AS 'TotalProfit'
				FROM AdventureWorks2008R2.Production.Product PP
				INNER JOIN AdventureWorks2008R2.Sales.SalesOrderDetail SOD ON PP.ProductID = SOD.ProductID
				INNER JOIN AdventureWorks2008R2.Sales.SalesOrderHeader SOH ON SOH.SalesOrderID = SOD.SalesOrderID
				WHERE YEAR(SOH.OrderDate) = '2007'
				GROUP BY YEAR(SOH.OrderDATE), MONTH(SOH.OrderDATE), PP.ProductID
			) AS Derived
			ON Derived.YearMonth = DFS.YearMonth AND Derived.ProductID = DFS.ProductID
	
	SELECT DISTINCT PP.ProductID, 
		LEN(PP.ProductID) AS [ProductIDLength],
		LEN(STR(PP.ProductID, LEN(PP.ProductID))) AS [STRLength]
		FROM AdventureWorks2008R2.Production.Product PP 
		WHERE LEN(PP.ProductID) != 3
		
	SELECT * FROM AdventureWorks2008R2.Sales.SalesOrderDetail SOD
		WHERE SOD.ProductID IN (1,2,3,4)
	
	SELECT * FROM AdventureWorks2008R2.Production.Product PP 
		INNER JOIN AdventureWorks2008R2.Production.ProductSubCategory PSC ON PSC.ProductSubCategoryID = PP.ProductSubCategoryID -- AND PSC.ProductSubCategoryID = PP.ProductSubCategoryID