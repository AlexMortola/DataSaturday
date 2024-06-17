------------------------------------------------------------------------
-- Event:        Data Saturday #37 - 2023, November 18 2023            -
--               https://datasaturdays.com/2023-11-18-datasaturday0037/-
-- Session:      How to save the Plan Cache                            -
-- Demo:         Set up the environment                                -
-- Author:       Alessandro Mortola                                    -
-- Notes:                                                              -
------------------------------------------------------------------------

use master;
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--Based on Guy Glanster's version
CREATE OR ALTER view [dbo].[CachedPlans]
as
/*
sql_handle        Is a token that uniquely identifies the batch or stored procedure that the query is part of
query_hash        Binary hash value calculated on the query and used to identify queries with similar logic. 
                  You can use the query hash to determine the aggregate resource usage for queries that differ 
			      only by literal values.
plan_handle       Is a token that uniquely identifies a query execution plan for a batch that has executed
query_plan_hash   Binary hash value calculated on the query execution plan and used to identify similar query execution plans. 
                  You can use query plan hash to find the cumulative cost of queries with similar execution plans.
*/
select
    qs.sql_handle,
	convert(varchar(32), qs.query_hash, 1) as query_hash,
	qs.plan_handle,
	qs.query_plan_hash,
	qs.statement_start_offset, 
	qs.statement_end_offset, 
	cp.cacheobjtype as CacheObjType,
	cp.objtype as ObjType,
	--It returns the number of times a specific cache object has been looked up
	--Not incremented when parameterized queries find a plan in the cache
	--basically indicating the number of times the plan has been reused
	cp.usecounts as UseCount, 	
	--Number of times that the plan has been executed since it was last compiled.
	--qs.execution_count as ExecutionCount,
	qt.text as [Text], 
	SUBSTRING(qt.text, 
                (qs.statement_start_offset / 2) + 1,
				(case qs.statement_end_offset
				when -1 then DATALENGTH(qt.text)  
				else qs.statement_end_offset end - qs.statement_start_offset) / 2 + 1) as QueryText,
	qp.query_plan as QueryPlan,
	cp.size_in_bytes / 1024. as SizeKB,
	qs.last_execution_time as LastExecTime,

	qs.total_worker_time,
	qs.total_logical_reads,
	qs.total_elapsed_time,
	qs.total_grant_kb,
	qs.total_used_grant_kb,
	qs.total_spills
from sys.dm_exec_cached_plans cp
cross apply sys.dm_exec_query_plan(cp.plan_handle) qp
cross apply sys.dm_exec_sql_text(cp.plan_handle) qt
left join sys.dm_exec_query_stats qs on qs.plan_handle = cp.plan_handle
GO

--Set the 'optimize for ad hoc workloads' to false
EXEC sys.sp_configure N'optimize for ad hoc workloads', N'0'
GO
RECONFIGURE WITH OVERRIDE
GO

ALTER DATABASE [AdventureWorks] SET COMPATIBILITY_LEVEL = 160
GO

--Set Parameterization as SIMPLE (db level)
ALTER DATABASE [AdventureWorks] SET PARAMETERIZATION SIMPLE WITH NO_WAIT
GO

--Activate the Query Store
ALTER DATABASE [AdventureWorks] SET QUERY_STORE = ON
GO
ALTER DATABASE [AdventureWorks] SET QUERY_STORE (OPERATION_MODE = READ_WRITE)
GO


