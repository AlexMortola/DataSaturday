------------------------------------------------------------------------
-- Event:        Data Saturday #37 - 2023, November 18 2023            -
--               https://datasaturdays.com/2023-11-18-datasaturday0037/-
-- Session:      How to save the Plan Cache                            -
-- Demo:         Simple parameterization                               -
-- Author:       Alessandro Mortola                                    -
-- Notes:        Activate the Actual Plan                              -
------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

use AdventureWorks
go

--*************************************************************************
--How the Simple Parameterization works
--The text is standardized. Compare the original and the parameterized text
--*************************************************************************

dbcc freeproccache;
go
select Name, ProductNumber, StandardCost, SellStartDate from Production.Product where ProductID = 770;
go
select Name, ProductNumber, StandardCost, SellStartDate from Production.Product where ProductID = 771;
go
select Name, ProductNumber, StandardCost, SellStartDate from Production.Product where ProductID = 772;
go

select * 
from master.dbo.CachedPlans 
where Text like '%Production%Product%'
	and Text not like '%CachedPlans%';

--**************************************
--Data Type Inference - The "int" family
--**************************************

dbcc freeproccache;
go

select Name from Production.Product where ProductID = 1;
go
select Name from Production.Product where ProductID = 256;
go
select Name from Production.Product where ProductID = 32768;
go

select * 
from master.dbo.CachedPlans 
where Text like '%Production%Product%'
	and Text not like '%CachedPlans%';
go


--******************************************
--Data Type Inference - The "numeric" family
--******************************************

DROP INDEX if exists [Ixd_Product_ListPrice] ON [Production].[Product]
GO
create nonclustered index Ixd_Product_ListPrice on Production.Product(ListPrice);
go

dbcc freeproccache;
go
select ProductID from Production.Product where ListPrice = 123.1;
go
select ProductID from Production.Product where ListPrice = 123.12;
go
select ProductID from Production.Product where ListPrice = 123.123;
go

select * 
from master.dbo.CachedPlans 
where Text not like '%CachedPlans%';
go

--*************************
--Text manipulation
--Activate the Actual Plan
--*************************
--Cast transformed into CONVERT
select Name, ProductNumber, cast(StandardCost as varchar(20)) as StrCost, SellStartDate from Production.Product where ProductID = 770;
--Function standardized in lowercase except CONVERT
select Name, ProductNumber, FLOOR(StandardCost) as StrCost, SellStartDate from Production.Product where ProductID = 770;

--The following queries are equivalent:
dbcc freeproccache;
go
select Name, ProductNumber, cast(StandardCost as varchar(20)) as StrCost, SellStartDate 
from Production.Product 
where ProductID = 770 and Name <> 'Some Name'
order by Name;
go
/*Modified query*/SELECT      Name, [ProductNumber], convert(varchar(20), StandardCost) StrCost, SellStartDate 
from Production.Product 
where ProductID = 770 and Name != 'Some Name'
order by Name asc;
go

select * 
from master.dbo.CachedPlans 
where Text not like '%CachedPlans%';
go


--*****************************************
--What prevents the Simple Parameterization
--*****************************************
--Several functions. E.g.: ceiling
select Name, ProductNumber, ceiling(StandardCost) as StrCost, SellStartDate 
from Production.Product 
where ProductID = 770;
go
--Constant comparison
select Name, ProductNumber, StandardCost as StrCost, SellStartDate 
from Production.Product 
where ProductID = 770 and 1 = 1;
go
--Some Global variables. E.g.: @@ROWCOUNT
select @@ROWCOUNT, Name, ProductNumber, StandardCost as StrCost, SellStartDate 
from Production.Product 
where ProductID = 770;
go



