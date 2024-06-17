------------------------------------------------------------------------
-- Event:        Data Saturday #37 - 2023, November 18 2023            -
--               https://datasaturdays.com/2023-11-18-datasaturday0037/-
-- Session:      How to save the Plan Cache                            -
-- Demo:         Plan cache pollution                                  -
-- Author:       Alessandro Mortola                                    -
-- Notes:                                                              -
------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

use AdventureWorks
go

set statistics time on;
go

--****************************************************
--Ad-hoc query - Plan Pollution with different filters
--****************************************************

dbcc freeproccache;
go
select p.ProductID, p.Name as ProductName, m.Name as ModelName 
from Production.Product p
inner join Production.ProductModel m on p.ProductModelID = m.ProductModelID
where m.Name = 'Cycling Cap';
go
select p.ProductID, p.Name as ProductName, m.Name as ModelName 
from Production.Product p
inner join Production.ProductModel m on p.ProductModelID = m.ProductModelID
where m.Name = 'HL Mountain Frame';
go
select p.ProductID, p.Name as ProductName, m.Name as ModelName 
from Production.Product p
inner join Production.ProductModel m on p.ProductModelID = m.ProductModelID
where m.Name = 'ML Mountain Frame-W';
go

select * from master.dbo.CachedPlans
where Text not like '%CachedPlans%'
	and Text like '%Production.Product%';
go

--*******************************************************************
--Ad-hoc query - Plan pollution - A little causes a new plan in cache
--Look at the hash value of the query text
--*******************************************************************

dbcc freeproccache
go

--#1
select p.ProductID, p.Name as ProductName, m.Name as ModelName 
from Production.Product p
inner join Production.ProductModel m on p.ProductModelID = m.ProductModelID
where m.Name = 'Cycling Cap';
go

--#2
Select p.ProductID, p.Name as ProductName, m.Name as ModelName 
from Production.Product p
inner join Production.ProductModel m on p.ProductModelID = m.ProductModelID
where m.Name = 'Cycling Cap';
go

--#3
select p.ProductID, p.Name ProductName, m.Name ModelName 
from Production.Product p
inner join Production.ProductModel m on p.ProductModelID = m.ProductModelID
where m.Name = 'Cycling Cap';
go

--#4
select p.ProductID, p.Name as  ProductName, m.Name as ModelName 
from Production.Product p
inner join Production.ProductModel m on p.ProductModelID = m.ProductModelID
where m.Name = 'Cycling Cap';
go

--#5
select p.ProductID, p.Name as ProductName, m.Name as ModelName from Production.Product p
inner join Production.ProductModel m on p.ProductModelID = m.ProductModelID where m.Name = 'Cycling Cap';
go

select * from master.dbo.CachedPlans 
where Text not like '%CachedPlans%'
	and Text like '%Production.Product%';
go


--*************************************************************
--sys.dm_os_memory_cache_entries
--Look at the Original and Current Cost of each entry in Cache
--*************************************************************
SELECT text, objtype, refcounts, usecounts, size_in_bytes, 
        disk_ios_count, context_switches_count, 
		e.original_cost, e.current_cost 
FROM sys.dm_exec_cached_plans p
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
INNER JOIN sys.dm_os_memory_cache_entries e ON p.memory_object_address = e.memory_object_address 
WHERE cacheobjtype = 'Compiled Plan' AND type in ('CACHESTORE_SQLCP', 'CACHESTORE_OBJCP') 
ORDER BY objtype desc, usecounts DESC;



