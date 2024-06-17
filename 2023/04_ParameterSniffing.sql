------------------------------------------------------------------------
-- Event:        Data Saturday #37 - 2023, November 18 2023            -
--               https://datasaturdays.com/2023-11-18-datasaturday0037/-
-- Session:      How to save the Plan Cache                            -
-- Demo:         Parameter sniffing                                    -
-- Author:       Alessandro Mortola                                    -
-- Notes:        Activate the Actual plan                              -
------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

USE [master]
GO

ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 150
GO

use AdventureWorks
go

set statistics io on;
set statistics time on;
go

--Let's look at the different plans depending on the value used as a filter
--Activate the Actual plan before running the query

--60325
select en.SalesOrderID, en.CarrierTrackingNumber
from Sales.SalesOrderDetailEnlarged en 
where en.ProductID = 870;
go
--265
select en.SalesOrderID, en.CarrierTrackingNumber
from Sales.SalesOrderDetailEnlarged en 
where en.ProductID = 897;
go

dbcc freeproccache;
go

declare @stmt nvarchar(max),
        @params nvarchar(max);

set @stmt = N'select en.SalesOrderID, en.CarrierTrackingNumber
from Sales.SalesOrderDetailEnlarged en
where en.ProductID = @pid;';

set @params = N'@pid int';

--exec sp_executesql @stmt, @params, 897; -->     82 rows
--exec sp_executesql @stmt, @params, 870; --> 192208 rows

exec sp_executesql @stmt, @params, 870; --> 192208 rows
exec sp_executesql @stmt, @params, 897; -->     82 rows
go

select * 
from master.dbo.CachedPlans 
where Text like '%SalesOrderDetailEnlarged%' 
	and Text not like '%CachedPlans%';

