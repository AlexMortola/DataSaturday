----------------------------------------------------------------------------
-- Event:        Data Satrurdays #80, Pordenone, February 28 2026	       -
--               https://datasaturdays.com/Event/20260228-datasaturday0080 -
-- Session:      Climb up towards Sql Server Statistics				       -
-- Script:       Cleanup environment                             	       -
-- Author:       Alessandro Mortola                                        -
-- Notes:											                       -
----------------------------------------------------------------------------

use AdventureWorks
go

declare @stmt nvarchar(max);

select @stmt = string_agg(concat('drop statistics ', sh.name, '.', object_name(s.object_id), '.', s.name), ';')
from sys.stats s
inner join sys.all_objects o on o.object_id = s.object_id and o.is_ms_shipped = 0
inner join sys.schemas sh on sh.schema_id = o.schema_id
where (s.name like '[_]WA[_]Sys[_]%' or s.name = 'st_SalesOrderHeaderEnlarged_01');

exec sp_executesql @stmt;
go

if exists (select * from sys.columns where object_id = OBJECT_ID('Sales.SalesOrderDetailEnlarged') and name = 'LinePrice')
	alter table Sales.SalesOrderDetailEnlarged drop column LinePrice;
go


USE master
GO
ALTER DATABASE TestDb SET QUERY_STORE = OFF;
GO
ALTER DATABASE TestDb SET QUERY_STORE CLEAR ALL;

use TestDb;
go

declare @stmt nvarchar(max);

select @stmt = string_agg(concat('drop statistics ', sh.name, '.', object_name(s.object_id), '.', s.name), ';')
from sys.stats s
inner join sys.all_objects o on o.object_id = s.object_id and o.is_ms_shipped = 0
inner join sys.schemas sh on sh.schema_id = o.schema_id
where (s.name like '[_]WA[_]Sys[_]%' or s.name = 'st_ord_01');

exec sp_executesql @stmt;
go

--For the last demo...
begin tran
truncate table t0;
rollback




