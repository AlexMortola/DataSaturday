-----------------------------------------------------------------------------------------------------------
-- Event:        Data Satrurdays #80, Pordenone, February 28 2026	                                      -
--               https://datasaturdays.com/Event/20260228-datasaturday0080                                -
-- Session:      Climb up towards Sql Server Statistics				                                      -
-- Script:       Computed Columns               	                                                      -
-- Author:       Alessandro Mortola                                                                       -
-- Credits:      Benjamin Nevarez                         				                                  -
-- Notes:        Enlarging the AdventureWorks Sample Databases:                                           -
--               https://www.sqlskills.com/blogs/jonathan/enlarging-the-adventureworks-sample-databases/  -
-----------------------------------------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

use AdventureWorks;
go


--Number of rows currently in Sales.SalesOrderDetailEnlarged: 4973997
--
select OBJECTPROPERTYEX(object_id('Sales.SalesOrderDetailEnlarged'), 'cardinality');
go

--Look at the Estimated Plan
select * 
from Sales.SalesOrderDetailEnlarged
where OrderQty * UnitPrice > 25000
option (recompile);
go



alter table Sales.SalesOrderDetailEnlarged add LinePrice as (OrderQty * UnitPrice);
go



--Look at the Estimated Plan again
select * 
from Sales.SalesOrderDetailEnlarged
where OrderQty * UnitPrice > 25000
option (recompile);
go


dbcc show_statistics('Sales.SalesOrderDetailEnlarged', LinePrice);

--Cleanup
drop statistics [Sales].[SalesOrderDetailEnlarged].[_WA_Sys_0000000D_72E607DB];
