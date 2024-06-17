------------------------------------------------------------------------
-- Event:        Data Saturday #37 - 2023, November 18 2023            -
--               https://datasaturdays.com/2023-11-18-datasaturday0037/-
-- Session:      How to save the Plan Cache                            -
-- Demo:         PSP Optimization                                      -
-- Author:       Alessandro Mortola                                    -
-- Notes:        Activate the XE Session                               -
------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

USE [master]
GO

ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 160
GO

use AdventureWorks
go

ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SENSITIVE_PLAN_OPTIMIZATION = ON;
go

--********************
--Setup Extended Event
--********************

CREATE EVENT SESSION [XE_CheckPSPOSkippedReason] ON SERVER 
--Occurs when the parameter sensitive plan feature is skipped
ADD EVENT sqlserver.parameter_sensitive_plan_optimization_skipped_reason(
    ACTION(sqlserver.sql_text)),
--This event is fired when a query is discovered to have parameter sensitivity
--ADD EVENT sqlserver.query_with_parameter_sensitivity(
--    ACTION(sqlserver.sql_text)),
--This event is fired when a query uses Parameter Sensitive Plan (PSP) Optimization feature
ADD EVENT sqlserver.parameter_sensitive_plan_optimization(
    ACTION(sqlserver.sql_text)) 
--Fired when parameter sensitive plan is tested
--ADD EVENT sqlserver.parameter_sensitive_plan_testing(
--    ACTION(sqlserver.sql_text))
GO


--***********************
--Create the 'demo' table
--***********************

drop table if exists [dbo].[SalesOrderDetailEnlarged]
go
CREATE TABLE [dbo].[SalesOrderDetailEnlarged](
	[SalesOrderID] [int] NOT NULL,
	[SalesOrderDetailID] [int] NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL,
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[LineTotal] [numeric](38,6),
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_DboSalesOrderDetailEnlarged_SalesOrderID_SalesOrderDetailID] PRIMARY KEY CLUSTERED 
(
	[SalesOrderID] ASC,
	[SalesOrderDetailID] ASC
) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_DboSalesOrderDetailEnlarged_rowguid] ON [dbo].[SalesOrderDetailEnlarged]
(
	[rowguid] ASC
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_DboSalesOrderDetailEnlarged_ProductID] ON [dbo].[SalesOrderDetailEnlarged]
(
	[ProductID] ASC
) ON [PRIMARY]
GO

--******************************************
--Fill the demo table with the original data
--******************************************

insert into dbo.SalesOrderDetailEnlarged
select * 
from Sales.SalesOrderDetailEnlarged;
go

--*********************************************************************************************************
--Delete several records from dbo.SalesOrderDetailEnlarged in order to reach the desired "skewness" of data
--*********************************************************************************************************

with  
C as (select *, ROW_NUMBER() over (partition by ProductID order by SalesOrderDetailID) Rn
		from dbo.SalesOrderDetailEnlarged
		where ProductID not in (
		870,
		708,
		922,
		902,
		942,
		897
		))
delete from C
where Rn > 1;

--************************************************************************
--Look at the number of records returned for both the products 870 and 897
--************************************************************************

select ProductID, count(*) as Cnt
from Sales.SalesOrderDetailEnlarged
where ProductID in (870, 897)
group by ProductID
order by 2 desc;
go

--***********************
--Activate the XE Session
--***********************
--**************************************************************************************************************
--With the following queries and the Sales.SalesOrderDetailEnlarged table, the PSP optimization is not triggered
--because of "SkewnessThresholdNotMet" reason
--**************************************************************************************************************

dbcc freeproccache
go
declare @stmt nvarchar(max) = N'select SalesOrderID, CarrierTrackingNumber from Sales.SalesOrderDetailEnlarged where ProductID = @prodid order by rowguid;',
	@params nvarchar(max) = N'@prodid int',
	@pid int = 870;
execute sp_executesql @stmt, @params, @prodid = @pid;
go
declare @stmt nvarchar(max) = N'select SalesOrderID, CarrierTrackingNumber from Sales.SalesOrderDetailEnlarged where ProductID = @prodid order by rowguid;',
	@params nvarchar(max) = N'@prodid int',
	@pid int = 897;
execute sp_executesql @stmt, @params, @prodid = @pid;
go

select * 
from master.dbo.CachedPlans
where Text not like '%CachedPlans%';

--*******************************************************************
--With the table dbo.SalesOrderDetailEnlarged, PSP optimization works
--*******************************************************************

dbcc freeproccache
go
declare @stmt nvarchar(max) = N'select SalesOrderID, CarrierTrackingNumber from dbo.SalesOrderDetailEnlarged where ProductID = @prodid order by rowguid;',
	@params nvarchar(max) = N'@prodid int',
	@pid int = 870;
execute sp_executesql @stmt, @params, @prodid = @pid;
go
declare @stmt nvarchar(max) = N'select SalesOrderID, CarrierTrackingNumber from dbo.SalesOrderDetailEnlarged where ProductID = @prodid order by rowguid;',
	@params nvarchar(max) = N'@prodid int',
	@pid int = 897;
execute sp_executesql @stmt, @params, @prodid = @pid;
go

select * 
from master.dbo.CachedPlans
where Text not like '%CachedPlans%';
go


--**************************************************************************************************
--Small problem - We still have the parameter sniffing. Try with ProductId 922 and 942 and vice versa
--**************************************************************************************************

select ProductID, count(*) as Cnt
from Sales.SalesOrderDetailEnlarged
where ProductID in (922, 942)
group by ProductID
order by 2 desc;
go

dbcc freeproccache
go
declare @stmt nvarchar(max) = N'select SalesOrderID, CarrierTrackingNumber from dbo.SalesOrderDetailEnlarged where ProductID = @prodid order by rowguid;',
	@params nvarchar(max) = N'@prodid int',
	@pid int = 922; 
execute sp_executesql @stmt, @params, @prodid = @pid;
go
declare @stmt nvarchar(max) = N'select SalesOrderID, CarrierTrackingNumber from dbo.SalesOrderDetailEnlarged where ProductID = @prodid order by rowguid;',
	@params nvarchar(max) = N'@prodid int',
	@pid int = 942;
execute sp_executesql @stmt, @params, @prodid = @pid;
go

select * 
from master.dbo.CachedPlans
where Text not like '%CachedPlans%';
go

--Inversion
dbcc freeproccache
go
declare @stmt nvarchar(max) = N'select SalesOrderID, CarrierTrackingNumber from dbo.SalesOrderDetailEnlarged where ProductID = @prodid order by rowguid;',
	@params nvarchar(max) = N'@prodid int',
	@pid int = 942; 
execute sp_executesql @stmt, @params, @prodid = @pid;
go
declare @stmt nvarchar(max) = N'select SalesOrderID, CarrierTrackingNumber from dbo.SalesOrderDetailEnlarged where ProductID = @prodid order by rowguid;',
	@params nvarchar(max) = N'@prodid int',
	@pid int = 922;
execute sp_executesql @stmt, @params, @prodid = @pid;
go

select * 
from master.dbo.CachedPlans
where Text not like '%CachedPlans%';
go

--**************************************************************************
--Medium problem - direct equality searches only : UnsupportedComparisonType
--**************************************************************************

declare @stmt nvarchar(max) = N'select * from dbo.SalesOrderDetailEnlarged where ProductID between @prodid1 and @prodid2 order by rowguid;',
	@params nvarchar(max) = N'@prodid1 int, @prodid2 int',
	@pid1 int = 784,
	@pid2 int = 790;

execute sp_executesql @stmt, @params, @prodid1 = @pid1, @prodid2 = @pid2;
go


--*************************************************************************************
--Another example for the Medium Problem - It raises the XE but it uses the PSPO !?!?!?
--*************************************************************************************

drop procedure if exists spGetOrderDetailsPerProduct;
go

create procedure spGetOrderDetailsPerProduct (@prodid int)
as
	select en.SalesOrderID, en.CarrierTrackingNumber, en.OrderQty, pr.Name
	from dbo.SalesOrderDetailEnlarged en
	inner join Production.Product pr on en.ProductID = pr.ProductID
	where en.ProductID = @prodid;
go

dbcc freeproccache;
go

execute spGetOrderDetailsPerProduct @prodid = 870;
go

select * 
from master.dbo.CachedPlans
where Text not like '%CachedPlans%';
go


