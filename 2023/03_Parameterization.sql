------------------------------------------------------------------------
-- Event:        Data Saturday #37 - 2023, November 18 2023            -
--               https://datasaturdays.com/2023-11-18-datasaturday0037/-
-- Session:      How to save the Plan Cache                            -
-- Demo:         Parameterization                                      -
-- Author:       Alessandro Mortola                                    -
-- Notes:                                                              -
------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

use AdventureWorks
go

--********************
--Statistics
--********************
dbcc show_statistics('Sales.SalesOrderDetailEnlarged', 'IX_SalesOrderDetailEnlarged_ProductID'); 
go

--********************
--How to parameterize
--********************

/*
1. Stored Procedure
   CacheObjType: Compiled Plan
   ObjType:      Proc
*/
drop procedure if exists dbo.spGetOrderDetailsFromProductID;
go

create procedure dbo.spGetOrderDetailsFromProductID (@productID int)
as
	select SalesOrderID, CarrierTrackingNumber 
	from Sales.SalesOrderDetailEnlarged 
	where ProductID = @productID 
	order by rowguid;
go

dbcc freeproccache;
go
execute dbo.spGetOrderDetailsFromProductID @productID = 870;
execute dbo.spGetOrderDetailsFromProductID @productID = 897;
execute dbo.spGetOrderDetailsFromProductID @productID = 922;
go

--Check the cache
select * 
from master.dbo.CachedPlans
where QueryText not like '%CachedPlans%';
go

/*
2. Dynamic SQL
   CacheObjType: Compiled Plan
   ObjType:      Prepared
*/
dbcc freeproccache;
go

declare @Stmt nvarchar(max),
	@Params nvarchar(max),
	@pProductID int;

set @Stmt = N'select SalesOrderID, CarrierTrackingNumber 
	from Sales.SalesOrderDetailEnlarged 
	where ProductID = @productID 
	order by rowguid;';

set @Params = N'@productID as int';

set @pProductID = 870;
execute sp_executesql @statement = @Stmt, @params = @Params, @productID = @pProductID;
set @pProductID = 897;
execute sp_executesql @statement = @Stmt, @params = @Params, @productID = @pProductID;
set @pProductID = 922;
execute sp_executesql @statement = @Stmt, @params = @Params, @productID = @pProductID;
go

--Check the cache
select * 
from master.dbo.CachedPlans
where QueryText not like '%CachedPlans%';
go

/*
3. sp_prepare and sp_execute
   CacheObjType: Compiled Plan
   ObjType:      Prepared
*/
dbcc freeproccache;
go

DECLARE @PreparedStatementNumber INT;
EXEC sp_prepare @PreparedStatementNumber OUTPUT,
    N'@productID as int',
    N'select SalesOrderID, CarrierTrackingNumber 
	from Sales.SalesOrderDetailEnlarged 
	where ProductID = @productID 
	order by rowguid;';
 
SELECT @PreparedStatementNumber;

--The execution
print '#1'
exec sp_execute @PreparedStatementNumber, 870;
print '#2'
exec sp_execute @PreparedStatementNumber, 897;
print '#3'
exec sp_execute @PreparedStatementNumber, 922;

--Check the cache
select * 
from master.dbo.CachedPlans
where QueryText not like '%CachedPlans%';

--Destroying the 'Prepared'
exec sp_unprepare @PreparedStatementNumber;
go

--********************
--Statistics
--********************
dbcc show_statistics('Sales.SalesOrderDetailEnlarged', 'IX_SalesOrderDetailEnlarged_ProductID'); 
go







--****************************
--Variables are NOT parameters
--****************************

--Variables
dbcc freeproccache;
go

declare @pid int = 870; 

select od.SalesOrderDetailID, od.OrderQty, od.ProductID
from Sales.SalesOrderDetailEnlarged od
where od.ProductID = @pid;
go

--Check the cache
select * 
from master.dbo.CachedPlans
where QueryText not like '%CachedPlans%';


