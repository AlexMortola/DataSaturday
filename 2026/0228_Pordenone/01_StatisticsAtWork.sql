-----------------------------------------------------------------------------------------------------------
-- Event:        Data Satrurdays #80, Pordenone, February 28 2026	                                      -
--               https://datasaturdays.com/Event/20260228-datasaturday0080                                -
-- Session:      Climb up towards Sql Server Statistics				                                      -
-- Demo:         Statistics at work                                	                                      -
-- Author:       Alessandro Mortola                                                                       -
-- Notes:        Enlarging the AdventureWorks Sample Databases:                                           -
--               https://www.sqlskills.com/blogs/jonathan/enlarging-the-adventureworks-sample-databases/  -
-----------------------------------------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

use AdventureWorks;
go

--*****************************************
--Histogram at work
--*****************************************



--Create the statistics on SalesOrderHeaderEnlarged for OrderDate
create statistics st_SalesOrderHeaderEnlarged_01 on Sales.SalesOrderHeaderEnlarged (OrderDate);
go


--*****************************************
--Filter for Key Value with Equal operator
--*****************************************
dbcc show_statistics ('Sales.SalesOrderHeaderEnlarged', 'st_SalesOrderHeaderEnlarged_01') with histogram;

select SalesOrderID, CustomerID, TerritoryID, ModifiedDate
from Sales.SalesOrderHeaderEnlarged
where OrderDate = '20230731';
go




--*****************************************
--Filter for 'Range' Value with Equal operator
--*****************************************
dbcc show_statistics ('Sales.SalesOrderHeaderEnlarged', 'st_SalesOrderHeaderEnlarged_01') with histogram;

select SalesOrderID, CustomerID, TerritoryID, ModifiedDate
from Sales.SalesOrderHeaderEnlarged
where OrderDate = '20230701';
go


--********************************************************************
--There is not an index or statistics for TerritoryID...
--********************************************************************

--This is the current situation:
--exec sp_helpstats 'Sales.SalesOrderHeaderEnlarged', 'ALL';

select p.stats_id, s.name StatsName, string_agg (c.name, ', ') within group (order by sc.stats_column_id) Cols 
from sys.stats s
inner join sys.stats_columns sc on s.object_id = sc.object_id and s.stats_id = sc.stats_id
inner join sys.columns c on c.object_id = sc.object_id and c.column_id = sc.column_id
cross apply sys.dm_db_stats_properties(s.object_id, s.stats_id) p
where s.object_id = OBJECT_ID('Sales.SalesOrderHeaderEnlarged')
group by p.stats_id, s.name
order by p.stats_id;

--Filter for both columns, with Equal operator
select SalesOrderID, CustomerID, TerritoryID, ModifiedDate
from Sales.SalesOrderHeaderEnlarged
where OrderDate = '20230731' and TerritoryID = 7;
--
--

dbcc show_statistics ('Sales.SalesOrderHeaderEnlarged', 'st_SalesOrderHeaderEnlarged_01') with stat_header, histogram;
dbcc show_statistics ('Sales.SalesOrderHeaderEnlarged', '_WA_Sys_0000000D_70FDBF69') with stat_header, histogram;

--Evaluation with selectivity
select 1088.28 / 1290065 as OrderDateSelectivity, 
       108977.2 / 1290065 as TerritoryIDSelectivity;



--By just multiplying the two separate computed densities, 
--the optimizer assumes that values in both participating columns are independent of each other
--The new formula is called Exponential Backoff
select 0.0008435854 * sqrt(0.084474193) * 1290065
go



--*****************************************
--What if I had a double column statistics?
--*****************************************
--Evaluation with Density Vector
drop statistics Sales.SalesOrderHeaderEnlarged.st_SalesOrderHeaderEnlarged_01;
go

create statistics st_SalesOrderHeaderEnlarged_01 on Sales.SalesOrderHeaderEnlarged (OrderDate, TerritoryID);
go

select SalesOrderID, CustomerID, TerritoryID, ModifiedDate
from Sales.SalesOrderHeaderEnlarged
where OrderDate = '20230731' and TerritoryID = 7;

--In this case, Density Vector is used
dbcc show_statistics ('Sales.SalesOrderHeaderEnlarged', 'st_SalesOrderHeaderEnlarged_01') with stat_header, density_vector;
go

select 0.0001208751 * 1290065;
go


--*******************************************************************
--Have a look at the histogram and try guessing the estimated rows...
--*******************************************************************
dbcc show_statistics ('Sales.SalesOrderHeaderEnlarged', 'st_SalesOrderHeaderEnlarged_01') with histogram;

select SalesOrderID, CustomerID, TerritoryID, ModifiedDate
from Sales.SalesOrderHeaderEnlarged
where OrderDate < '20230731';
go


--***********************************************
--Variables: Filter by variable  - Density Vector
--***********************************************

dbcc show_statistics ('Sales.SalesOrderHeaderEnlarged', 'st_SalesOrderHeaderEnlarged_01') with stat_header, density_vector;
go

declare @d datetime = '20230731';

select SalesOrderID, CustomerID, TerritoryID, ModifiedDate
from Sales.SalesOrderHeaderEnlarged
where OrderDate = @d;
go

select 0.000870322 * 1290065
go


--*******************************************************************
--Be careful of "DISTINCT"
--*******************************************************************

select p.stats_id, s.name StatsName, string_agg (c.name, ', ') within group (order by sc.stats_column_id) Cols 
from sys.stats s
inner join sys.stats_columns sc on s.object_id = sc.object_id and s.stats_id = sc.stats_id
inner join sys.columns c on c.object_id = sc.object_id and c.column_id = sc.column_id
cross apply sys.dm_db_stats_properties(s.object_id, s.stats_id) p
where s.object_id = OBJECT_ID('Sales.SalesOrderHeaderEnlarged')
group by p.stats_id, s.name
order by p.stats_id;
go

select /*DISTINCT*/ RevisionNumber, DueDate, ShipDate, Status, AccountNumber, TotalDue
from Sales.SalesOrderHeaderEnlarged
where SalesPersonID = 277;




--Back to the slides




--********************
-- set showplan_all 
--********************
set showplan_all on;
go

declare @d datetime = '20230731';

select h.SalesOrderID, h.CustomerID, h.TerritoryID, h.ModifiedDate, d.ProductID, d.UnitPrice
from Sales.SalesOrderHeaderEnlarged h
inner join Sales.SalesOrderDetailEnlarged d on h.SalesOrderID = d.SalesOrderID
where OrderDate = @d;
go

set showplan_all off;
go


--**************************
-- set statistics profile 
--**************************
set statistics profile on;
go

declare @d datetime = '20230731';

select h.SalesOrderID, h.CustomerID, h.TerritoryID, h.ModifiedDate, d.ProductID, d.UnitPrice
from Sales.SalesOrderHeaderEnlarged h
inner join Sales.SalesOrderDetailEnlarged d on h.SalesOrderID = d.SalesOrderID
where OrderDate = @d;
go

set statistics profile off;
go



--Particular cases #1
dbcc show_statistics ('Sales.SalesOrderHeaderEnlarged', 'st_SalesOrderHeaderEnlarged_01');

select MIN(orderdate) as MinValue, MAX(orderdate) as MaxValue from Sales.SalesOrderHeaderEnlarged;

--************************************
--Beyond the max key value
--Look at the Estimated Execution Plan
--************************************

--Sql Server 2012
select SalesOrderID, OrderDate, TerritoryID
from Sales.SalesOrderHeaderEnlarged
where OrderDate = '20280325'
option (recompile, use hint ('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_110'));

--Sql Server 2014
select SalesOrderID, OrderDate, TerritoryID
from Sales.SalesOrderHeaderEnlarged
where OrderDate = '20380325'
option (recompile, use hint ('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_120'));
go

--Sql Server 2025
select SalesOrderID, OrderDate, TerritoryID
from Sales.SalesOrderHeaderEnlarged
where OrderDate = '20380325'
option (recompile, use hint ('QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_170'));
go


--**************************************************
--Particular cases #2 - Table variable
--Execute the queries with the Actual Execution Plan
--**************************************************

--Sql Server 2017
ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 140;
go

declare @t table (id int, f1 int);

insert into @t
select ROW_NUMBER() over (order by (select null)), ROW_NUMBER() over (order by (select null)) % 10 
from sys.all_columns;

select *
from @t
where f1 = 5;
go

--Sql Server 2019
ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 150;
go

declare @t table (id int, f1 int);

insert into @t
select ROW_NUMBER() over (order by (select null)), ROW_NUMBER() over (order by (select null)) % 10 
from sys.all_columns;

select *
from @t
where f1 = 5;
go


--****************************************
--Particular cases #3 - Multistatement TVF
--Look at the Estimated Execution Plan
--****************************************

--Sql Server 2012
ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 110;
go

select *
from dbo.ufnGetContactInformation(290) ms
where ms.FirstName = 'Ranjit';
go

--Sql Server 2014
ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 120;
go

select *
from dbo.ufnGetContactInformation(290) ms
where ms.FirstName = 'Ranjit';
go

--Sql Server 2025
ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 170;
go


--********************************************
--OPENJSON
--Execute the queries with the Actual Execution Plan
--********************************************
drop table if exists tjson;
go
create table tjson (
	id int primary key,
	j1 varchar(max),
	j2 varchar(max),
	j3 varchar(max));

insert into tjson (id, j1) 
values 
(1,
'[{"c11":"value11A", "c12":"value12A"},{"c11":"value11B", "c12":"value12B"}]');

select id, c1.c11, c1.c12
from tjson
cross apply openjson(j1) with(
	c11 varchar(50) '$.c11',
	c12 varchar(50) '$.c12') c1
where c1.c11 = 'xxx';


--*******
--Cleanup
--*******

--Drop statistics
drop statistics [Sales].[SalesOrderHeaderEnlarged].[st_SalesOrderHeaderEnlarged_01];
drop table if exists tjson;


