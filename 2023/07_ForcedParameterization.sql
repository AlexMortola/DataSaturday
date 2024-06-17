------------------------------------------------------------------------
-- Event:        Data Saturday #37 - 2023, November 18 2023            -
--               https://datasaturdays.com/2023-11-18-datasaturday0037/-
-- Session:      How to save the Plan Cache                            -
-- Demo:         Forced parameterization                               -
-- Author:       Alessandro Mortola                                    -
-- Notes:        Activate the Actual plan                              -
------------------------------------------------------------------------

/* Doorstop */
raiserror(N'Did you mean to run the whole thing?', 20, 1) with log;
go

use AdventureWorks;
go

ALTER DATABASE [AdventureWorks] SET PARAMETERIZATION FORCED WITH NO_WAIT;
go

--Check it!
select is_parameterization_forced
from sys.databases
where name = 'AdventureWorks';
go

--*************************
--Text manipulation
--Activate the Actual Plan
--*************************
/*
KEYWORDS: lowercase
NO brackets
There is a space either side of the 'dot' between schema and object names
*/

dbcc freeproccache;
go

--Look at the Statement property for the SELECT operator
SELECT * 
FROM Person.Address a
inner join person.BusinessEntityAddress as bea on bea.AddressID = a.AddressID
WHERE a.AddressID = 100
order by City;
go

select * 
from master.dbo.CachedPlans
where Text like '%BusinessEntityAddress%'
	and Text not like '%CachedPlans%';
go


--****************************************
--Text manipulation - Data type inference
--Activate the Actual Plan
--****************************************
/*
Observe the following:
a. 100 in the SELECT is NOT parameterized
b. 1 parameterize to int
c. Numbers larger than int parameterize to NUMERIC, minimum size required (i.e. 4000000000)
d. But... if it is part of predicates, it parameterize to DECIMAL(38,0) (i.e. 3000000000)
*/
select 100 as OneHundred, p.ProductId, p.Name, ap.x
from Production.Product p
cross apply (select * from (values (1), (4000000000)) t(x)) ap
where p.ProductSubcategoryID = 3000000000;
go

--
--If Forced Parameterization is not possible, Simple parameterization can still occur
/*
Forced parameterization can't happen because of the Constant-foldable expression
StatementParameterizationType: 2 (Simple)
*/
SELECT * 
FROM Person.Address a
WHERE a.AddressID = 1 + 2;
go


