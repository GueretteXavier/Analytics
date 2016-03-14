/************************************************************************
 Devoir 3 (5% de la Note Finale)
 Matricule: 112 08 473
 Nom: Gu�rette
 Pr�nom: Xavier
 Objectif du fichier: Script pour le 2e Devoir Technologie de l'intelligence d'affaires
*************************************************************************/

-- QUESTION 1
	USE StudentDB;
	IF EXISTS(
		SELECT * FROM INFORMATION_SCHEMA.VIEWS 
		WHERE [TABLE_SCHEMA] = CURRENT_USER AND [TABLE_NAME] = 'vw_Devoir3_BikesSalesByGender')
			BEGIN
				DROP VIEW vw_Devoir3_BikesSalesByGender;
			END
	GO -- Msg. 111: CREATE Statement Must be the 1st in the Query Batch...	
	CREATE VIEW vw_Devoir3_BikesSalesByGender AS
		SELECT 
			PP.LastName AS 'Nom de famille du client',
			PP.FirstName AS 'Pr�nom du client',
			PP.Gender AS 'Sexe du client',
			SOH.AccountNumber AS 'Num�ro de compte du client',
			PROD.Name AS 'Nom du v�lo',
			PSC.Name AS 'Nom de la sous-cat�gorie du v�lo',
			PROD.Color AS 'Nom de la couleur du v�lo',
			PROD.Style AS 'Style du produit',
			SOH.SalesOrderID AS 'Num�ro de commande du client'
			FROM AdventureWorks2008R2.Sales.SalesOrderHeader SOH
			INNER JOIN AdventureWorks2008R2.Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
			INNER JOIN AdventureWorks2008R2.Sales.Customer SC ON SC.CustomerID = SOH.CustomerID
			INNER JOIN AdventureWorks2008R2.Person.Person PP ON PP.BusinessEntityID = SC.CustomerID
			INNER JOIN AdventureWorks2008R2.Production.Product PROD ON PROD.ProductID = SOD.ProductID
			LEFT JOIN AdventureWorks2008R2.Production.ProductSubCategory PSC ON PSC.ProductSubCategoryID = PROD.ProductSubCategoryID
			INNER JOIN AdventureWorks2008R2.Production.ProductCategory PPC ON PPC.ProductCategoryID = PSC.ProductCategoryID
			WHERE (PP.PersonType = 'IN' AND PPC.Name = 'Bikes');
	GO
	-- Requ�te qui interroge la 1�re Vue
	SELECT [Sexe du client] AS 'Sexe', 
		[Nom de la sous-cat�gorie du v�lo], 
		[Nom de la couleur du v�lo] AS 'Couleur du V�lo', 
		COUNT(*) AS 'Nombre de Commandes' 
		FROM [11208473].vw_Devoir3_BikesSalesByGender
		GROUP BY [Sexe du client], [Nom de la sous-cat�gorie du v�lo], [Nom de la couleur du v�lo]
		ORDER BY 2, 3, 1, 4;
	
	-- QUESTION: Quel est l'int�r�t d'avoir inclus le num�ro de compte du client dans la vue?
	-- On peut voir tout les achats de v�los de ce client puisqu'on a son 'Num�ro de Compte'.
	
-- QUESTION 2

	IF EXISTS(
		SELECT * FROM INFORMATION_SCHEMA.VIEWS 
		WHERE [TABLE_SCHEMA] = CURRENT_USER AND [TABLE_NAME] = 'vw_Devoir3_BikeMargin')
			BEGIN
				DROP VIEW vw_Devoir3_BikeMargin;
			END
	GO -- Msg. 111: CREATE Statement Must be the 1st in the Query Batch...
	CREATE VIEW vw_Devoir3_BikeMargin AS
	SELECT PROD.ProductID AS 'ID du v�lo',
		PROD.Name AS 'Nom du v�lo',
		PSC.Name AS 'Nom de la sous-cat�gorie du v�lo',
		(PROD.ListPrice - PROD.StandardCost) AS 'Marge de profit du v�lo',
		DATEDIFF(DAY, PROD.SellStartDate, GETDATE()) AS [Nombre de jours �coul�es depuis l'introduction du produit]
		FROM AdventureWorks2008R2.Production.Product PROD
		LEFT JOIN AdventureWorks2008R2.Production.ProductSubCategory PSC ON PROD.ProductSubCategoryID = PSC.ProductSubCategoryID
		INNER JOIN AdventureWorks2008R2.Production.ProductCategory PPC ON PPC.ProductCategoryID = PSC.ProductCategoryID
		WHERE PPC.Name = 'Bikes' AND PROD.SellEndDate IS NULL;
	GO
		
	-- Requ�te qui interroge la 2e Vue
	SELECT VW.[Nom du v�lo], 
		SUM((SOD.OrderQTY * VW.[Marge de profit du v�lo])) AS 'Profit', 
		VW.[Nombre de jours �coul�es depuis l'introduction du produit] 
		FROM [11208473].vw_Devoir3_BikeMargin VW
		INNER JOIN AdventureWorks2008R2.Sales.SalesOrderDetail SOD ON SOD.ProductID = VW.[ID du v�lo]
		GROUP BY VW.[Nom du v�lo], VW.[Nombre de jours �coul�es depuis l'introduction du produit]
		ORDER BY 2 DESC,3 ASC, 1;
	
	-- QUESTION: En vous basant uniquement sur cette information, quel v�lo pourriez-vous conseiller � AdventureWorks d'arr�ter de vendre?
	-- Le v�lo 'Moutain-500 Black, 52' est vendu depuis 3135 jours et a uniquement g�n�r� des profits de '66751.6016'
	-- D'autres v�los on aussi rapport� peu, mais celui mentionn� pr�c�demment est le v�lo qui a la pire performance,
	-- en terme de profit absolu. Il serait pr�f�rable cependant de regarder le profit / jour, mais nous devons
	-- nous limiter � l'information des 3 colonnes uniquement dans le cadre de cette question.

-- QUESTION 3
	
	-- ASSUMPTION: La moyenne est calcul�e sur les 'Clients Particuliers' et exclus les clients corporatifs.
	SELECT
	PP.Gender,
	AVG(SubQuery.[Number of Lines in Order]) AS 'Nombre Moyen de Lignes dans une Commande',
	MAX(SubQuery.[Number of Lines in Order]) AS 'Nombre de Lignes Maximal Observ� dans une Commande pour ce Sexe'
		FROM AdventureWorks2008R2.Sales.SalesOrderHeader SOH 
		INNER JOIN (SELECT SOD.SalesOrderID, 
				CONVERT(float, COUNT(SOD.SalesOrderDetailID)) AS 'Number of Lines in Order' 
				FROM AdventureWorks2008R2.Sales.SalesOrderHeader SOH
				INNER JOIN AdventureWorks2008R2.Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
				GROUP BY SOD.SalesOrderID) AS SubQuery
			ON SOH.SalesOrderID = SubQuery.SalesOrderID
		INNER JOIN AdventureWorks2008R2.Sales.Customer SC ON SC.CustomerID = SOH.CustomerID
		INNER JOIN AdventureWorks2008R2.Person.Person PP ON PP.BusinessEntityID = SC.PersonID
		WHERE PP.PersonType = 'IN'
		GROUP BY PP.Gender;
		
		-- QUESTION: On ne peut pas conclure rien quand au pattern d'achats des femmes et des hommes,
		-- en moyenne les femmes ou les hommes achetent le m�me nombre d'items dans une commande...
		-- le nombre d'items achet�s dans la m�me commande est le m�me �galement pour les hommes et les femmes.
	
---------------------------------------------------- TESTs --------------------------------------------------------
	
	-- QUESTION 2
		
		-- Test COALESCE
		SELECT PROD.ProductID, 
			COALESCE(PROD.SellEndDate, GETDATE()) AS 'Case 1', 
			COALESCE(GETDATE(), PROD.SellEndDate) AS 'Case 2'
			FROM AdventureWorks2008R2.Production.Product PROD
			WHERE PROD.ProductID = 1 OR PROD.ProductID = 725

		-- Test Standard Margin
		SELECT PROD.ProductID, PROD.ListPrice - PROD.StandardCost 
			FROM AdventureWorks2008R2.Production.Product PROD
			WHERE PROD.ProductID = 749
	
	-- QUESTION 3
	
		-- Test Number of Lines in Order.
		SELECT * FROM AdventureWorks2008R2.Sales.SalesOrderDetail SOD 
			WHERE SOD.SalesOrderID = 43659;
			
		-- There is SalesOrderDetail data, but no SalesOrderHeader? Makes no sense!
		-- In 'SalesOrderDetail', there is 5 records with 'SalesOrderID' that are not in 'SalesOrderHeader'
		SELECT DISTINCT SalesOrderID
			FROM AdventureWorks2008R2.Sales.SalesOrderDetail
			WHERE SalesOrderID NOT IN (SELECT DISTINCT SalesOrderID
			FROM AdventureWorks2008R2.Sales.SalesOrderHeader)
		
		-- In 'SalesOrderHeader', there is 2 records with 'SalesOrderID' that are not in 'SalesOrderDetail'
		SELECT DISTINCT SalesOrderID, TotalDue, Freight, TaxAmt
			FROM AdventureWorks2008R2.Sales.SalesOrderHeader
			WHERE SalesOrderID NOT IN (SELECT DISTINCT SalesOrderID
			FROM AdventureWorks2008R2.Sales.SalesOrderDetail)
			
		SELECT
		PP.Gender,
		SubQuery.[Number of Lines in Order]
			FROM AdventureWorks2008R2.Sales.SalesOrderHeader SOH 
			INNER JOIN (SELECT SOD.SalesOrderID, 
					CONVERT(float, COUNT(SOD.SalesOrderDetailID)) AS 'Number of Lines in Order' 
					FROM AdventureWorks2008R2.Sales.SalesOrderHeader SOH
					INNER JOIN AdventureWorks2008R2.Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
					GROUP BY SOD.SalesOrderID) AS SubQuery
				ON SOH.SalesOrderID = SubQuery.SalesOrderID
			INNER JOIN AdventureWorks2008R2.Sales.Customer SC ON SC.CustomerID = SOH.CustomerID
			-- Est-ce que la prochaine JOINTURE est un INNER JOIN ? (M�me nombre de record... avec et sans la JOINTURE)
			INNER JOIN AdventureWorks2008R2.Person.Person PP ON PP.BusinessEntityID = SC.PersonID
			WHERE PP.PersonType = 'IN'
			ORDER BY 2 DESC;
		