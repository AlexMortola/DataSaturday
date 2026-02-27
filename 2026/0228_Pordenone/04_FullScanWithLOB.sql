----------------------------------------------------------------------------
-- Event:        Data Satrurdays #80, Pordenone, February 28 2026	       -
--               https://datasaturdays.com/Event/20260228-datasaturday0080 -
-- Session:      Climb up towards Sql Server Statistics				       -
-- Script:       Full scan with LOB                	                       -
-- Author:       Alessandro Mortola                                        -
-- Credits:      Fabiano Amorim				                               -
----------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

use TestDb
go

/*
drop table if exists t1;
go

--1m 16s
select gs.value id, gs.value n1, replicate(cast(newid() as varchar(max)), 2000) flob
into t1
from generate_series(1, 150000, 1) gs
*/

--12 GB
exec sp_spaceused 't1';




--The query! Exec it...
select count(*) as Cnt 
from t1
where flob like 'AB%';
go


--Look inside the table
select 
   OBJECT_NAME(p.object_id) as TabName, 
   p.rows,
   au.type_desc,
   au.total_pages, 
   au.total_pages * 8 / 1024. TotalSpaceMB,
   p.index_id, 
   fg.name, fg.type_desc
from sys.allocation_units as au 
join sys.partitions p on au.container_id = p.partition_id
join sys.filegroups as fg on fg.data_space_id = au.data_space_id
where OBJECT_NAME(p.object_id) = 't1'
go


select s.name, p.*
from sys.stats s
cross apply sys.dm_db_stats_properties(s.object_id, s.stats_id) p
where s.object_id = OBJECT_ID('dbo.t1');
go

--Consider the NORECOMPUTE option and do the update manually


