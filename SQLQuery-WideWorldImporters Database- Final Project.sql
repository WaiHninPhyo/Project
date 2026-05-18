
---  customer transactions year comparison

Select 
year(TransactionDate) as Year,
Count(Distinct(customerID)) as 'Number of CustomerID',
Sum(AmountExcludingTax) as 'Total amount excluding tax',
ISNULL(LAG(Sum(AmountExcludingTax),1) over(order by year(transactiondate)),0) as 'vs. Last 1 year Total amount excluding tax',
ISNULL(LEAD(Sum(AmountExcludingTax),1) over(order by year(transactiondate)),0) as 'vs. Next 1 year Total amount excluding tax'
From Sales.CustomerTransactions
Group by year(transactionDate)


--- Growth rate in vs.last year for customer transactions 

Select 
year(TransactionDate) as Year,
Sum(AmountExcludingTax) as 'Total amount excluding tax',
ISNULL(LAG(Sum(AmountExcludingTax),1) over(order by year(transactiondate)),0) as 'vs. Last 1 year Total amount excluding tax',
[Growth rate] = (Sum(AmountExcludingTax) -LAG(Sum(AmountExcludingTax),1) over(order by year(transactiondate)))/LAG(Sum(AmountExcludingTax),1) over(order by year(transactiondate))*100
From Sales.CustomerTransactions
Group by year(transactionDate)


---Customer Category Name by year in amount excluding tax

Select 
year(ct.TransactionDate) as Year,
cc. CustomerCategoryName,
[Total Transaction amount excluding tax] = ISNULL(Sum(ct.AmountExcludingTax),0)
From sales.CustomerTransactions ct
Join Sales.Customers c on c.CustomerID = ct.CustomerID
Join Sales.CustomerCategories cc on cc.CustomerCategoryID = c.CustomerCategoryID
Group by cc. CustomerCategoryName,year(ct.TransactionDate)
Order by year(ct.TransactionDate)


---Customers in BuyinggroupName

Select 
bg.BuyingGroupID,
bg.BuyingGroupName,
Count(c.CustomerID) as 'Number of customerID'
From Sales.BuyingGroups bg
Join Sales.Customers c on c.BuyingGroupID = bg.BuyingGroupID
Group by bg.BuyingGroupID,bg.BuyingGroupName



----Top 10 customers' rank year by year

with customer_year as(
Select year(ct.transactiondate) Year,
ct.customerID,
c.CustomerName,
[Total amount excluding tax by customer]= Sum(ct.AmountExcludingTax),
[Customers' Rank] = DENSE_RANK() over(partition by year(ct.transactiondate) order by Sum(ct.AmountExcludingTax) desc)
From Sales.Customers c
Join sales.CustomerTransactions ct on ct.CustomerID = c.CustomerID
Group by c.CustomerName,ct.CustomerID,year(ct.transactiondate)
),
Top_10_customers as (
Select * from customer_year
Where [Customers' Rank] >= 1 and [Customers' Rank] <= 10)
Select * From Top_10_customers


----customers' contribution % year by year

Select a.Year,
a.CustomerID,
a.CustomerName,
a.[Total amount excluding tax by customer],
[Total amount excluding tax for year] = Sum(a.[Total amount excluding tax by customer]) over(partition by a.year),
[Contribution % ] =a.[Total amount excluding tax by customer]/Sum(a.[Total amount excluding tax by customer]) over(partition by a.year)*100
From
(Select year(ct.transactiondate) Year,
ct.customerID,
c.CustomerName,
[Total amount excluding tax by customer]= Sum(ct.AmountExcludingTax)
From Sales.Customers c
Join sales.CustomerTransactions ct on ct.CustomerID = c.CustomerID
Group by c.CustomerName,ct.CustomerID,year(ct.transactiondate))a


--- Contribution % in all total sales invoice by StockItem name for years

Select a.Year,
a.StockItemID,
a.StockItemName,
a.[Total Sales],
[Total Sales in years] = Sum(a.[Total Sales]) over(partition by a.year),
[Contribution % ] = a.[Total Sales]/Sum(a.[Total Sales]) over(partition by a.year)*100
From
(Select Year(i.invoiceDate) as Year,
il.StockItemID,
st.StockItemName,
[Total Sales] = Sum(il.Quantity * il.UnitPrice)
From Sales.InvoiceLines il
Join Sales.Invoices i on il.InvoiceID = i.InvoiceID
Join Warehouse.StockItems st on st.StockItemID = il.StockItemID
Join Sales.Customers c on c.CustomerID = i.CustomerID
Group by il.StockItemID,st.StockItemName,Year(i.invoiceDate))a


-- Rank in all total sales invoice by StockItem Name(Top 1-5) for years

Select * from
(Select 
Year(i.invoiceDate) as Year,
st.StockItemName,
[Total Sales] = Sum(il.Quantity * il.UnitPrice),
[StockItem Name Rank in sales invoice] =DENSE_RANK() over(partition by year(i.invoicedate) order by Sum(il.Quantity * il.UnitPrice) desc)
From Sales.InvoiceLines il
Join Sales.Invoices i on il.InvoiceID = i.InvoiceID
Join Warehouse.StockItems st on st.StockItemID = il.StockItemID
Group by Year(i.invoiceDate),st.StockItemName) a
Where a.[StockItem Name Rank in sales invoice] <=5

----Number of StockItemID, Expected Duration between order & delivery date in orderID for sales orders

Select 
ol.orderID,
Count(ol.stockItemID) as 'Number of StockItemID',
o.OrderDate,
o.ExpectedDeliveryDate,
Datediff(day,o.OrderDate,o.ExpectedDeliveryDate) as 'Expected Duration'
From Sales.Orders o
Join Sales.OrderLines ol on ol.orderID = o.OrderID
Group by ol.orderID,o.OrderDate,o.ExpectedDeliveryDate
Order by Datediff(day,o.OrderDate,o.ExpectedDeliveryDate) desc

----PaymentmethodName in customer transactions

Select 
ct.PaymentMethodID,
pm.paymentmethodName,
Sum(ct.Transactionamount) as 'Total transactions'
From sales.CustomerTransactions ct
Right Join Application.PaymentMethods pm on pm.PaymentMethodID = ct.PaymentMethodID
Group by  ct.PaymentMethodID,pm.paymentmethodName

----Transactions Type Name in customer transactions

Select 
tt.TransactionTypeID,
tt.transactionTypeName,
[Total Amount excluding tax]=Sum(ct.TransactionAmount)
From Sales.CustomerTransactions ct
Right Join Application.TransactionTypes tt on tt.TransactionTypeID = ct.TransactionTypeID
Group by tt.TransactionTypeID,tt.transactionTypeName


----- Gap amount between Sales invoice and Sales order in stockitemID

Select * into Total_Sales_order
From(
Select StockItemID,
Sum(UnitPrice*Quantity) as TotalSalesinorder
From Sales.OrderLines
Group by StockItemID)a

Select * From Total_Sales_order

Select * into Total_Sales_invoice
From(
Select StockItemID,
Sum(UnitPrice*Quantity) as TotalSalesininvoice
From Sales.InvoiceLines
Group by StockItemID)b

Select * From Total_Sales_invoice

Select 
so.StockItemID,
st.StockItemName,
so.Totalsalesinorder,
si.Totalsalesininvoice,
[Gap Amount] = so.TotalSalesinorder-si.TotalSalesininvoice
From Total_Sales_order so
Join Total_Sales_invoice si on si.StockItemID = so.StockItemID
Join Warehouse.StockItems st on st.StockItemID = si.StockItemID
Order by [Gap amount] desc


---location sales by customer

Select 
year(st.TransactionDate) Year,
st.CustomerID,
sc.CustomerName,
c.CityName,
sp.StateProvinceName,
Sum(st.amountexcludingtax) as 'Total amount excluding tax'
From Sales.CustomerTransactions st
Join Sales.Customers sc on st.customerID = sc.customerID
Join Application.Cities c on c.CityID = sc.DeliveryCityID
Join Application.StateProvinces sp on sp.StateProvinceID = c.StateProvinceID
Group by st.CustomerID,st.CustomerID,c.CityName,sp.StateProvinceName,year(st.TransactionDate),sc.CustomerName
Order by year(st.TransactionDate) 



---packagetype in sales order for year

Select 
year(o.OrderDate) as Year,
ol.packagetypeID,
pt.packageTypeName,
Count(ol.PackageTypeID) as 'Total number of package type'
From sales.OrderLines ol
Join sales.Orders o on o.OrderID = ol.OrderID
Join Warehouse.PackageTypes pt on pt.PackageTypeID = ol.PackageTypeID
Group by ol.packagetypeID,pt.packageTypeName,year(o.OrderDate)
Order by Year 



--- Delivery methods in year for customers

Select 
dm.DeliveryMethodName,
Sum(ct.amountexcludingtax) as 'Total amount excluding ax'
From sales.CustomerTransactions ct
Join Sales.Customers c on c.CustomerID = ct.CustomerID
Join Application.DeliveryMethods  dm on dm.DeliveryMethodID = c.DeliveryMethodID
Group by dm.DeliveryMethodName


---- Number of customers in SalesPersonID for sales invoice in years

Select 
year(i.invoiceDate) as Year,
i.SalespersonPersonID,
p.FullName,
Count(Distinct(i.customerID)) as 'Number of customers'
From Sales.Invoices i
Join Application.People p on p.PersonID = i.SalespersonPersonID
Group by i.SalespersonPersonID,p.FullName,year(i.invoiceDate)
Order by year(i.invoiceDate)


--- No. of StockItemID in StockGroupName for Sales invoice 

Select a.[StockItem Group ID],
a.[StockGroup Name],
Count(a.[Stock Item ID]) as 'No. of StockItem ID '
From
(Select 
ssg.StockGroupID as 'StockItem Group ID',
sg.StockGroupName as 'StockGroup Name',
il.StockItemID as 'Stock Item ID'
From Warehouse.StockItemStockGroups ssg 
Right Join Sales.InvoiceLines il on ssg.StockItemID = il.StockItemID
Join Warehouse.StockGroups sg on sg.StockGroupID = ssg.StockGroupID
Group by ssg.StockGroupID,il.StockItemID,sg.StockGroupName)a
Group by a.[StockItem Group ID],a.[StockGroup Name]

---  supplier transactions year comparison

Select 
year(transactiondate) as Year,
Count(distinct(SupplierID)) as 'No of suppliers',
Sum(amountexcludingtax) as 'Total amount excluding tax',
ISNULL(LAG(Sum(AmountExcludingTax),1) over(order by year(transactiondate)),0) as 'vs. Last 1 year Total amount excluding tax',
ISNULL(LEAD(Sum(AmountExcludingTax),1) over(order by year(transactiondate)),0) as 'vs. Next 1 year Total amount excluding tax'
From Purchasing.SupplierTransactions
Group by year(transactiondate)


-----Total amount excluding tax in supplier/suppliercategoryName in supplier transations

Select 
st.SupplierID,
sc.SupplierCategoryID,
s.SupplierName,
sc.SupplierCategoryName,
[Total Amount excluding tax]=Sum(AmountExcludingTax)
From purchasing.suppliers s
Right Join Purchasing.SupplierCategories sc on sc.SupplierCategoryID = s.SupplierCategoryID
left Join purchasing.SupplierTransactions st on s.supplierID = st.SupplierID
Group by st.SupplierID,s.SupplierName,sc.SupplierCategoryName,sc.SupplierCategoryID
Order by Sum(AmountExcludingTax) desc

---Total receivedouters,Rank in stockItemName(Top 1-10) by year for purchase orders

with stockItemName_year as (
Select 
year(po.orderdate) As Year,
st.StockItemName,
Sum(pol.ReceivedOuters) as 'Total Received outers',
Dense_Rank() over(partition by year(po.orderdate) order by Sum(pol.ReceivedOuters) desc) as 'Rank'
From Purchasing.PurchaseOrders po
Join Purchasing.PurchaseOrderLines pol on po.PurchaseOrderID = pol.PurchaseOrderID
Join Warehouse.StockItems st on st.StockItemID = pol.StockItemID
Group by st.StockItemName,year(po.orderdate)),
Top_10_stockItemname as (
Select * From stockItemName_year
Where Rank >=1 and Rank <= 10)
Select* From Top_10_stockItemname



----- Number of stockItems in purchaseOrderID

Select purchaseorderID ,
Count(stockItemID) as 'Number of StockItems'
From Purchasing.PurchaseOrderLines
Group by purchaseorderID
Order by Count(stockItemID) desc



--- Total amount excluding tax in SupplierCategoryName by years

Select 
year(po.OrderDate) as Year,
sc.SupplierCategoryName,
s.supplierName,
Sum(st.amountexcludingtax) as 'Total amount excluding tax'
From Purchasing.PurchaseOrders po
Join Purchasing.PurchaseOrderLines pol on pol.PurchaseOrderID = po.PurchaseOrderID
Join Purchasing.Suppliers s on s.SupplierID = po.SupplierID
Join Purchasing.SupplierCategories sc on sc.SupplierCategoryID = s.SupplierCategoryID
Join Purchasing.SupplierTransactions st on st.PurchaseOrderID = pol.PurchaseOrderID
Group by sc.SupplierCategoryName,year(orderdate),s.supplierName
Order by year(orderdate) 

---Oustanding balance in Supplier transaction

Select 
st.SupplierID,
s.SupplierName,
Sum(OutstandingBalance) as 'Total outstanding amount'
From Purchasing.SupplierTransactions st
Join Purchasing.Suppliers s on s.SupplierID = st.SupplierID
Group by st.SupplierID,s.SupplierName
Having Sum(OutstandingBalance) <> 0



---Total Received outers by order date

Select 
po.OrderDate,
Sum(ReceivedOuters) as 'Total Received Outers'
From Purchasing.PurchaseOrderLines  pol
Join Purchasing.PurchaseOrders po on pol.PurchaseOrderID = po.PurchaseOrderID
Group by OrderDate
Order by Sum(ReceivedOuters) desc

---Total Received outers in Top 1 StockItem by order date

Select 
po.orderDate, 
st.StockItemName,
s.supplierName,
Sum(pol.receivedouters) as 'Total Received outers in Top 1 StockItem'
From Purchasing.PurchaseOrders po
Join purchasing.PurchaseOrderLines pol on pol.PurchaseOrderID = po.PurchaseOrderID
Join Warehouse.StockItems st on st.StockItemID = pol.StockItemID
Join Purchasing.Suppliers s on s.supplierID = po.SupplierID
Where pol.StockItemID  IN (
select Top 1 StockItemID 
from Purchasing.PurchaseOrderLines 
Group by StockItemID 
order by sum(receivedouters) desc)
Group by po.OrderDate,st.StockItemName,s.SupplierName


---- No. of Order is or not Finalized for purchase orders

Select 
[Total Orders line Finalized] = Count(StockItemID),
[Total Orders line is not Finalized] = (select Count(stockItemID) from Purchasing.PurchaseOrderLines where IsOrderLineFinalized != 1)
From Purchasing.PurchaseOrderLines 
Where IsorderlineFinalized = 1


---Expected Duration between orderdate and Delivery Date for purchase orders

Select 
PurchaseOrderID,
orderdate,
ExpectedDeliveryDate,
DATEDIFF(day,OrderDate,ExpectedDeliveryDate) as 'Duration in days',
[Waiting week] =
case when DATEDIFF(day,OrderDate,ExpectedDeliveryDate) <=7 then 'About One week'
     when DATEDIFF(day,OrderDate,ExpectedDeliveryDate) <=14 then 'About two weeks'
else 'About three weeks'
end
From Purchasing.PurchaseOrders
Order by [Duration in days] desc



----transaction type name in suppliertransactions

Select 
tt.TransactionTypeID,
tt.transactionTypeName,
[Total transaction amount]=Sum(st.TransactionAmount)
From Purchasing.SupplierTransactions st
Right Join Application.TransactionTypes tt on tt.TransactionTypeID = st.TransactionTypeID
Group by tt.TransactionTypeID,tt.transactionTypeName

----payment method name in supplier transaction

Select
st.PaymentMethodID,
pt.PaymentMethodName,
Sum(st.TransactionAmount)
From Purchasing.SupplierTransactions st
Right Join Application.PaymentMethods pt on pt.PaymentMethodID = st.PaymentMethodID
Group by st.PaymentMethodID,pt.PaymentMethodName


--- Delivery methods in Supplier Name for all years

Select year(st.transactiondate) Year,
s.SupplierName,
dm.DeliveryMethodName,
Sum(st.amountexcludingtax) as 'Total amount excluding tax',
DENSE_RANK() over(partition by year(st.transactiondate) order by Sum(st.amountexcludingtax) desc ) as 'Delivery methods in Supplier Name for all years'
From Purchasing.PurchaseOrders po
Right Join Application.DeliveryMethods dm on dm.DeliveryMethodID = po.DeliveryMethodID
Join Purchasing.Suppliers s on s.SupplierID = po.SupplierID
Join Purchasing.Suppliertransactions st on st.purchaseorderID = po.purchaseorderID
Group by s.SupplierName,dm.DeliveryMethodName,year(st.transactiondate)


---Rank in delivery methods in supplier transactions for years

Select 
year(st.transactiondate) Year, 
dm.DeliveryMethodName,
Sum(st.amountexcludingtax) as 'Total amount excluding tax',
DENSE_RANK() over(partition by year(st.transactiondate) order by Sum(st.amountexcludingtax) desc ) as'Rank in delivery methods for years'
From Purchasing.PurchaseOrders po
Right Join Application.DeliveryMethods dm on dm.DeliveryMethodID = po.DeliveryMethodID
Join Purchasing.Suppliertransactions st on st.purchaseorderID = po.purchaseorderID
Group by dm.DeliveryMethodName,year(st.transactiondate)


---- No. of StockItemID in warehouse by supplier name

Select 
s.SupplierName,
Count(st.StockItemID) as 'No. of StockItemID'
From Purchasing.Suppliers s
Join Warehouse.StockItems st on st.SupplierID = s.SupplierID
Group by s.SupplierName

----Supplier's sales in location

Select 
year(st.TransactionDate) as Year,
s.SupplierName,
c.CityName,
sp.StateProvinceName,
Sum(st.AmountExcludingTax) as 'Total amount excluding tax'
From Purchasing.Suppliers s
Join Application.Cities c on c.CityID = s.DeliveryCityID
Join Purchasing.SupplierTransactions st on st.SupplierID = s.SupplierID
Join Application.StateProvinces sp on sp.StateProvinceID = c.StateProvinceID
Group by year(st.TransactionDate),s.SupplierName,c.CityName,sp.StateProvinceName
Order by Year asc


---Package Type in purchase order for year

Select 
year(po.orderDate) as Year,
pol.PackageTypeID,
pt.packageTypeName,
Count(pol.PackageTypeID) as 'Total number of package type'
From Purchasing.PurchaseOrderLines pol 
Join Purchasing.PurchaseOrders po on pol.PurchaseOrderID = po.PurchaseOrderID
Join Warehouse.PackageTypes pt on pt.PackageTypeID = pol.PackageTypeID
Group by year(po.orderDate),pol.PackageTypeID,pt.packageTypeName
Order by Year


---- Total Quantity StockItem, No. of customers & No. of StockItemID for invoiceID and suppierID in years

Select
year(transactionoccurredwhen) as Year,
Sum(Quantity) as 'Total Quantity StockItem in InvoiceID',
Sum(Quantity) as 'Total Quantity StockItem in SupplierID',
Count(Distinct(CustomerID)) as 'Number of customerID',
Count(Distinct(StockItemID)) as 'Number of StockItemID'
From Warehouse.StockItemTransactions
Group by year(transactionoccurredwhen) 
Order by Year asc


----StockItemTransactions Type in warehouse

Select st.TransactionTypeID,
tt.TransactionTypeName,
Sum(st.Quantity) as 'Total Quantity'
From Warehouse.StockItemTransactions st
Join Application.TransactionTypes tt on tt.TransactionTypeID = st.TransactionTypeID
Group by st.TransactionTypeID,tt.TransactionTypeName



---- amount in QuantityonHand and laststocktakequantity

Select
st.StockItemID,
st.StockItemName,
Quantityonhand,
laststocktakequantity
From Warehouse.StockItemHoldings sth
Join Warehouse.StockItems st on sth.StockItemID = st.StockItemID


