----------------------------------------------------------------------------
-- Event:        Data Satrurdays #80, Pordenone, February 28 2026	       -
--               https://datasaturdays.com/Event/20260228-datasaturday0080 -
-- Session:      Climb up towards Sql Server Statistics				       -
-- Demo:         Filtered Statistics                                       -
-- Author:       Alessandro Mortola                                        -
-- Credits:      Joe Chang												   -
----------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

use TestDb;
go

/*
create table ord (
	id int identity(1, 1) primary key,
	orderdate date,
	ordertype char(2),
	filler varchar(400) default 'X',
	amount money default 0);
go

create table orddet (
	id int identity(1,1) primary key,
	idord int not null,
	prod char(36),
	price money not null,
	constraint fk_orddet_ord foreign key (idord) references ord(id));
go

--Inserimento dati in ord
declare @RefDate date = '20241220';

--210 Valori con 20.000 righe
insert into ord (orderdate, ordertype)
select dateadd(DAY, -1 * gs.value, @RefDate), 'H'
from generate_series(1, 6284500) gs
cross join generate_series(1, 20000) gs20000
where gs.value % 100 = 0 and gs.value <= 21000;

--1895 Valori con 700 righe
insert into ord (orderdate, ordertype)
select dateadd(DAY, -1 * gs.value, @RefDate), 'M'
from generate_series(1, 6284500) gs
cross join generate_series(1, 700) gs700
where gs.value % 10 = 0 and gs.value % 100 != 0 and gs.value <= 21055;

--18950 Valori con 40 righe
insert into ord (orderdate, ordertype)
select dateadd(DAY, -1 * gs.value, @RefDate), 'L'
from generate_series(1, 6284500) gs
cross join generate_series(1, 40) gs40
where gs.value % 10 != 0 and gs.value <= 21055;
go

create nonclustered index Idx_ord_01 on ord(orderdate);
go

--Inserimento dati in orddet. 1 riga per ordine
insert into orddet (idord, prod, price)
select id, CAST(newid() as varchar(36)), 0
from ord;
go

create nonclustered index Idx_orddet_01 on orddet(idord) include(prod, price);
go
*/

--Distribuzione dati su ord
select orderdate, count(*) cnt
from ord
group by orderdate
order by orderdate;

dbcc show_statistics('ord', 'Idx_ord_01') with histogram;



--The query !!!
--Activate *** actual *** execution plan and execute
select *
from ord o
inner join orddet d on o.id = d.idord
where o.orderdate = '19670623' and o.ordertype = 'H'
order by d.prod
option (recompile);
go







create statistics st_ord_01 on dbo.ord(orderdate) where ordertype = 'H' with fullscan;
go




--Verify
dbcc show_statistics('ord', 'st_ord_01') with stat_header;

select s.name, p.last_updated, p.rows, p.rows_sampled, p.steps, s.filter_definition, p.unfiltered_rows, p.modification_counter
from sys.stats s
cross apply sys.dm_db_stats_properties(s.object_id, s.stats_id) p
where s.name = 'st_ord_01';




