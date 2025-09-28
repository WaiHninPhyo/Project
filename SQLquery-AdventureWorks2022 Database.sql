
--Employees Hired before 2010


Select 
       p.FirstName,
       p.LastName,
	   e.HireDate
From HumanResources.Employee e
left Join Person.Person p 
on p.BusinessEntityID = e.BusinessEntityID
Where Year(e.HireDate) < 2010



--Product Inventory less than 100 

Select 
       p.ProductID,
       p.name 'Product Name',
       pi.Quantity 'Inventory Quantity'
From Production.Product p
Join Production.ProductInventory pi
on pi.ProductID = p.ProductID
Where pi.Quantity < 100
Order by Quantity Asc



--Sales by Territory 

Select 
     st.Name,
     sum(soh.TotalDue) TotalSales
From Sales.SalesOrderHeader soh
Join Sales.SalesTerritory st
on soh.TerritoryID = st.TerritoryID
Group by st.Name
Having sum(soh.TotalDue) > 10000000
Order by TotalSales Desc



--Monthly Sales Trend 


Select 
       Format(OrderDate,'MMMM') Month,
       sum(TotalDue) TotalSales
From Sales.SalesOrderHeader 
Group by Format(OrderDate,'MMMM') ,
         Year(OrderDate),
		 Month(OrderDate)
Having Year(OrderDate) =2013
Order by Month(OrderDate) Asc




--Product Category Performance

With CategoryNameSales As
(
Select 
     pc.Name CategoryName,
     sum(sod.lineTotal) TotalSales
From Sales.SalesOrderDetail sod
Join Production.Product p 
on p.ProductID = sod.ProductID
Join Production.ProductSubcategory psc 
on psc.ProductSubcategoryID = p.ProductSubcategoryID
Join Production.ProductCategory pc 
on pc.ProductCategoryID = psc.ProductCategoryID
Group by pc.Name)
Select *,
(TotalSales/sum(TotalSales) over()) *100 PercentageOfTotal
From CategoryNameSales
Order by TotalSales Desc



--Customer Purchase Frequency 


Select 
       CONCAT(pp.firstName,' ',pp.LastName) CustomerName,
       pea.EmailAddress,
	   count(soh.customerID) PurchaseCount
From Sales.Customer c
Join Sales.SalesOrderHeader soh 
on soh.CustomerID = c.CustomerID
Join Person.EmailAddress pea 
on pea.BusinessEntityID = c.PersonID
Join Person.Person pp 
on pp.BusinessEntityID = pea.BusinessEntityID
Group by CONCAT(pp.firstName,' ',pp.LastName), 
         pea.EmailAddress
Having  count(soh.customerID) > 20
Order by PurchaseCount Desc




--Employee Sales Performance 

Select 
      Concat(pp.FirstName,' ',pp.LastName) EmployeeName,
	  e.JobTitle,
	  sum(soh.TotalDue) TotalSales,
	  Rank() over(order by sum(soh.TotalDue) Desc) Rank_sales
From Sales.SalesOrderHeader soh
Join HumanResources.Employee e
on e.BusinessEntityID = soh.SalesPersonID
Join Person.Person pp
on pp.BusinessEntityID = e.BusinessEntityID
Group by Concat(pp.FirstName,' ',pp.LastName) ,
         e.JobTitle
Having sum(soh.TotalDue) > 2000000
Order by TotalSales Desc




--Sales Forecasting with Moving Averages 

With MonthlySales as
(
Select
   Concat(Year(orderDate),'-',Format(orderDate,'MM'))YearMonth,
   sum(totaldue) MonthlySale
From Sales.SalesOrderHeader soh
Group by Concat(Year(orderDate),'-',Format(orderDate,'MM')),
         Year(OrderDate) ,
		 Month(OrderDate))
Select *,
AVG(MonthlySale) over(Order by YearMonth rows 2 preceding)ThreeMonthsMovingAvg
From MonthlySales





--Product Category Growth Analysis 


With MonthlySales As
(
Select 
     pc.Name CategoryName,
	 Concat(Year(soh.orderDate),'-',Format(soh.orderDate,'MM'))YearMonth,
     sum(sod.lineTotal) MonthlySales
From Sales.SalesOrderDetail sod
Join Production.Product p 
on p.ProductID = sod.ProductID
Join Production.ProductSubcategory psc 
on psc.ProductSubcategoryID = p.ProductSubcategoryID
Join Production.ProductCategory pc 
on pc.ProductCategoryID = psc.ProductCategoryID
Join Sales.SalesOrderHeader soh
on sod.SalesOrderID = soh.SalesOrderID
Group by pc.Name,
         Concat(Year(soh.orderDate),'-',Format(soh.orderDate,'MM'))
), 
PreviousMonthSalesData As
(
Select * ,
      lag(Monthlysales) over(partition by CategoryName Order by YearMonth) PreviousMonthSales
From MonthlySales)

Select *,
    ((MonthlySales - PreviousMonthSales)/PreviousMonthSales) * 100  GrowthPct

From PreviousMonthSalesData



-- Product Sales Trends with Market Share Analysis 

With MonthlySales As
(
Select 
     p.Name ProductName,
     pc.Name CategoryName,
	 Concat(Year(soh.orderDate),'-',Format(soh.orderDate,'MM'))YearMonth,
     sum(sod.lineTotal) MonthlySales
From Sales.SalesOrderDetail sod
Join Production.Product p 
on p.ProductID = sod.ProductID
Join Production.ProductSubcategory psc 
on psc.ProductSubcategoryID = p.ProductSubcategoryID
Join Production.ProductCategory pc 
on pc.ProductCategoryID = psc.ProductCategoryID
Join Sales.SalesOrderHeader soh
on sod.SalesOrderID = soh.SalesOrderID
Group by p.Name,
         pc.Name,
         Concat(Year(soh.orderDate),'-',Format(soh.orderDate,'MM'))
),
CategoryAvgSalesData As
(
Select * ,
      Avg(MonthlySales) over(partition by CategoryName,YearMonth) CategoryAverageSales
From MonthlySales
)

Select *,
      Case 
	     when MonthlySales > CategoryAverageSales  then 'Above Average'
		 else 'Below Average'
	  End  As PerformanceStatus
From CategoryAvgSalesData
Order by CategoryName,
          YearMonth,
		 ProductName



