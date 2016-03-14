/************************************************************************
 Devoir 2 (5% de la Note Finale)
 Matricule: 112 08 473
 Nom: Guérette
 Prénom: Xavier
 Objectif du fichier: Script pour le 2e Devoir Technologie de l'intelligence d'affaires
*************************************************************************/

	-- ASSUMPTIONS:
	-- (1). Inteprétation de 'allant chercher les 100 lignes de commandes ayant
	-- rapporté le plus d'argent en 2008 (basé sur la date de la commande) pour
	-- des clients particuliers': Client Particuliers veut dire les clients aux détails, soit
	-- les 'IN = Individual (retail) customer'. De plus, 'rapporté le plus' est défini,
	-- sur le 'Subtotal' des commandes et non pas le 'TotalDue' qui inclu le 'Freight'
	-- et les 'Taxes' ou bien simplement le 'LineTotal'
	
	-- Initialement, j'avais interpreté avec le 'LineTotal', j'ai laissé mon code
	-- entre parenthèse, si jamais il s'avère que c'était l'interprétation souhaité...

	USE StudentDB;
	GO
	
		-- ALTER TABLE
		
			-- DROP FOREIGN KEYS
			ALTER TABLE [11208473].SalesDetails DROP CONSTRAINT FK_SalesDetails_ProductID;
			ALTER TABLE [11208473].SalesDetails DROP CONSTRAINT FK_SalesDetails_CustomerID;
			ALTER TABLE [11208473].SalesDetails DROP CONSTRAINT FK_SalesDetails_Year_Month;
			
			-- DROP PRIMARY KEYs
			ALTER TABLE [11208473].Customer DROP CONSTRAINT PK_Customer_CustomerID;
			ALTER TABLE [11208473].Calendar DROP CONSTRAINT CK_Calendar_Year_Month;
			ALTER TABLE [11208473].Product DROP CONSTRAINT PK_Product_ProductID;
			ALTER TABLE [11208473].SalesDetails DROP CONSTRAINT PK_SalesDetails_SalesOrderDetailID;

-- QUESTION 1:

	-- CREATE TABLE Calendar
	DROP TABLE [11208473].Calendar;
	CREATE TABLE Calendar
		(
		[Year] INT NOT NULL,
		[Month] INT NOT NULL,
		MonthName NVARCHAR(50)
		);
	
	-- CREATE TABLE Customer
	DROP TABLE [11208473].Customer;
	CREATE TABLE Customer
		(
		CustomerID INT NOT NULL,
		FirstName NVARCHAR(50) NOT NULL,
		MiddleName NVARCHAR(50) NULL,
		LastName NVARCHAR(50) NOT NULL,
		AccountNumber VARCHAR(10) NOT NULL
		);
	
	-- CREATE TABLE Product
	DROP TABLE [11208473].Product;
	CREATE TABLE Product
		(
		ProductID INT NOT NULL,
		Name NVARCHAR(50) NOT NULL,
		ProductSubCategoryName NVARCHAR(50) NOT NULL,
		ProductCategoryName NVARCHAR(50) NOT NULL,
		ListPrice MONEY NOT NULL,
		StandardCost MONEY NOT NULL
		);
	
	-- CREATE TABLE SalesDetails
	DROP TABLE [11208473].SalesDetails;
	CREATE TABLE SalesDetails
		(
		SalesOrderDetailID INT NOT NULL,
		SalesOrderNumber NVARCHAR(25) NOT NULL,
		ProductID INT NOT NULL,
		OrderQty SMALLINT NOT NULL,
		LineTotal NUMERIC(38,6) NOT NULL,
		[Year] INT NOT NULL,
		[Month] INT NOT NULL,
		CustomerID INT NOT NULL
		);

-- QUESTION 2:

	-- Question 2.a SalesDetails Table	
/*	SELECT TOP(100)
		SOD.SalesOrderDetailID, 
		SOH.SalesOrderNumber,
		SOD.ProductID,
		SOD.OrderQty,
		SOD.LineTotal,
		DATEPART(YEAR, SOH.OrderDate) AS 'Year',
		DATEPART(MONTH, SOH.OrderDate) AS 'Month',
		SOH.CustomerID 
			FROM AdventureWorks2008R2.Sales.SalesOrderDetail SOD
			INNER JOIN AdventureWorks2008R2.Sales.SalesOrderHeader SOH ON SOH.SalesOrderID = SOD.SalesOrderID
			INNER JOIN AdventureWorks2008R2.Sales.Customer SC ON SC.CustomerID = SOH.CustomerID
			INNER JOIN AdventureWorks2008R2.Person.Person PP ON PP.BusinessEntityID = SC.PersonID
			WHERE DATEPART(YEAR, SOH.OrderDate) = 2008 AND PP.PersonType = 'IN'
			ORDER BY SOD.LineTotal DESC, 1, 2, 3, 4, 6, 7, 8; */
	
	INSERT INTO [11208473].SalesDetails
	SELECT TOP(100)
		SOD.SalesOrderDetailID, 
		SOH.SalesOrderNumber,
		SOD.ProductID,
		SOD.OrderQty,
		SOD.LineTotal,
		DATEPART(YEAR, SOH.OrderDate) AS 'Year',
		DATEPART(MONTH, SOH.OrderDate) AS 'Month',
		SOH.CustomerID 
			FROM AdventureWorks2008R2.Sales.SalesOrderDetail SOD
			INNER JOIN AdventureWorks2008R2.Sales.SalesOrderHeader SOH ON SOH.SalesOrderID = SOD.SalesOrderID
			INNER JOIN AdventureWorks2008R2.Sales.Customer SC ON SC.CustomerID = SOH.CustomerID
			INNER JOIN AdventureWorks2008R2.Person.Person PP ON PP.BusinessEntityID = SC.PersonID
			WHERE DATEPART(YEAR, SOH.OrderDate) = 2008 AND PP.PersonType = 'IN'
			ORDER BY SOH.SubTotal DESC, 1, 2, 3, 4, 6, 7, 8;
			
	-- Question 2.b Product Table
	INSERT INTO [11208473].Product
	SELECT DISTINCT
		PP.ProductID,
		PP.Name AS 'Name',
		PSC.Name AS 'ProductSubCategoryName',
		PPC.Name AS 'ProductCategoryName',
		PP.ListPrice,
		PP.StandardCost
		FROM AdventureWorks2008R2.Production.Product PP
		INNER JOIN AdventureWorks2008R2.Sales.SalesOrderDetail SOD ON SOD.ProductID = PP.ProductID
		LEFT JOIN AdventureWorks2008R2.Production.ProductSubCategory PSC ON PSC.ProductSubCategoryID = PP.ProductSubCategoryID
		INNER JOIN AdventureWorks2008R2.Production.ProductCategory PPC ON PPC.ProductCategoryID = PSC.ProductCategoryID
		INNER JOIN StudentDB.[11208473].SalesDetails SD ON SD.ProductID = PP.ProductID
		ORDER BY ProductID;

	-- Question 2.c Customer Table
	INSERT INTO [11208473].Customer	
	SELECT 
		SC.CustomerID,
		PP.FirstName,
		PP.MiddleName,
		PP.LastName,
		SC.AccountNumber 
		FROM AdventureWorks2008R2.Sales.Customer SC
		LEFT JOIN AdventureWorks2008R2.Person.Person PP ON PP.BusinessEntityID = SC.PersonID
		WHERE SC.CustomerID IN (SELECT 
			DISTINCT CustomerID FROM [11208473].SalesDetails
			)
		ORDER BY SC.CustomerID;

	-- Question 2.d Calendar Table
	INSERT INTO [11208473].Calendar
	SELECT DISTINCT
		[11208473].SalesDetails.[Year],
		[11208473].SalesDetails.[Month],
		CASE WHEN [Month] = 1 THEN 'January'
			 WHEN [Month] = 2 THEN 'February'
			 WHEN [Month] = 3 THEN 'March'
			 WHEN [Month] = 4 THEN 'April'
			 WHEN [Month] = 5 THEN 'May'
			 WHEN [Month] = 6 THEN 'June'
			 WHEN [Month] = 7 THEN 'July'
			 WHEN [Month] = 8 THEN 'August'
			 WHEN [Month] = 9 THEN 'September'
			 WHEN [Month] = 10 THEN 'October'
			 WHEN [Month] = 11 THEN 'November'
			 WHEN [Month] = 12 THEN 'December'
		END AS [MonthName]
		FROM SalesDetails;
	
	-- ALTER TABLE Section (ADD SECTION)
		-- ADD PRIMARY KEYS
		ALTER TABLE [11208473].Customer ADD CONSTRAINT PK_Customer_CustomerID PRIMARY KEY(CustomerID);
		ALTER TABLE [11208473].Calendar ADD CONSTRAINT CK_Calendar_Year_Month PRIMARY KEY([Year], [Month]);
		ALTER TABLE [11208473].Product ADD CONSTRAINT PK_Product_ProductID PRIMARY KEY (ProductID);
		ALTER TABLE [11208473].SalesDetails ADD CONSTRAINT PK_SalesDetails_SalesOrderDetailID PRIMARY KEY (SalesOrderDetailID);

		-- ADD FOREIGN KEYS
		ALTER TABLE [11208473].SalesDetails ADD CONSTRAINT FK_SalesDetails_ProductID FOREIGN KEY (ProductID) REFERENCES Product(ProductID);
		ALTER TABLE [11208473].SalesDetails ADD CONSTRAINT FK_SalesDetails_CustomerID FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID);
		ALTER TABLE [11208473].SalesDetails ADD CONSTRAINT FK_SalesDetails_Year_Month FOREIGN KEY ([Year], [Month]) REFERENCES Calendar([Year], [Month]);

		SELECT * FROM SalesDetails SD
			WHERE SD.CustomerID NOT IN (SELECT CustomerID FROM [11208473].Customer)
			
		INSERT INTO [11208473].SalesDetails (SalesOrderDetailID, SalesOrderNumber, ProductID, OrderQty, LineTotal, [Year], [Month], CustomerID) 
			VALUES (918835,'SO61957',796,	1,	2443.350000,	2008,	1,	204052);