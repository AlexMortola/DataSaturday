------------------------------------------------------------------------
-- Event:        Data Saturday #37 - 2023, November 18 2023            -
--               https://datasaturdays.com/2023-11-18-datasaturday0037/-
-- Session:      How to save the Plan Cache                            -
-- Demo:         Optimize for Ad hoc workloads                         -
-- Author:       Alessandro Mortola                                    -
-- Notes:                                                              -
------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

use AdventureWorks
GO
ALTER DATABASE [AdventureWorks] SET PARAMETERIZATION SIMPLE WITH NO_WAIT;
GO

--Set the 'optimize for ad hoc workloads' to 0
EXEC sys.sp_configure N'optimize for ad hoc workloads', N'0'
GO
RECONFIGURE WITH OVERRIDE
GO

--***********************************************************
--Let's check the impact of an Ad-hoc query on the Plan Cache
--***********************************************************

dbcc freeproccache;
go

select ProductID, TRIM(Name) as ProducDescription
from Production.Product
where ProductID = 1;
go

select * 
from master.dbo.CachedPlans
where Text like '%Production.Product%'
	and Text not like '%CachedPlans%';
go

--********************************************************************
--Now, change the 'optimize for ad hoc workloads' setting and retry...
--********************************************************************

set statistics time on;
go

EXEC sys.sp_configure N'optimize for ad hoc workloads', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO

dbcc freeproccache;
go
select ProductID, TRIM(Name) as ProducDescription
from Production.Product
where ProductID = 1;
go
select * 
from master.dbo.CachedPlans 
where Text not like '%CachedPlans%';
go

