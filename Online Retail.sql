-- inspect dataset
select * from [dbo].[My_Personal_DataBases];

-- total records = 541909

-- cleaning data
select top (1000)
		[InvoiceNo],
		[StockCode],
		[Quantity],
		[InvoiceData],
		[UnitPrice],
		[CustomerID],
		[Country]
from [dbo].[My_Personal_DataBases];

-- How Many Records have customer with 0 -- there are (135080)
select top (1000)
		[InvoiceNo],
		[StockCode],
		[Quantity],
		[InvoiceData],
		[UnitPrice],
		[CustomerID],
		[Country]
from [dbo].[My_Personal_DataBases]
where customer_id = 0;

-- we are working records that have a customerID
-- 
with online_retail as
	(select top (1000)
			[InvoiceNo],
			[StockCode],
			[Quantity],
			[InvoiceData],
			[UnitPrice],
			[CustomerID],
			[Country]
	from [dbo].[My_Personal_DataBases]
	where customer_id != 0
),

Quantity_Unit_Price  as
(
	select *
	from online_retail
	where quantity > 0 and UnitPrice > 0
),

duplicate_check as
(
	-- duplicate check
	select * ,
	ROW_NUMBER() over (partition by InvoiceNo, StockCode, Quantity order by InvoiceData) as duplicate_data
	from Quantity_Unit_Price
)

-- working with no duplicate data
-- Now we have clean data
-- let's create a new temporary table because we don't want to call the above CTE everytime

select *
	into #online_retail_main -- local table
	from duplicate_check 
where duplicate_data = 1; -- run everything from top to this point


-- Begin Cohort Analysis

-- select everything
select * from #online_retail_main;

-- 1) when was the first time a user purchased something
select 
	CustomerID,
	min(InvoiceData) as First_Purchase,
	DATEFROMPARTS(year(min(InvoiceData), MONTH(min(InvoiceData), 1)) as Cohort_date -- 1 represents  day,
into #cohort  --  put the results of this query into this table
from #online_retail_main
group by CustomerID;


select *
from cohort;

-- a cohort is a group of people with common characteristics.
-- a cohort analysis is an analysis of several different cohorts to get a better understanding of behaviours, patterns and trends

--Types of cohort analysis
-- 1) Time-Based Cohort Analysis
-- 2) Size Based Cohort Analysis
-- 3) Segment-Based Cohort

-- why do a cohort analysis:
-- 1)  understand behaviour of customers
-- 2)  to see patterns and trends of the group


-- 2) create cohort index
-- A Cohort Index is an integer representation of the number of months that has passed since the customer's first engagement

select
	mmm.*,
	Cohort_Index = year_diff * 12 - month_diff + 1
into #cohort_retention -- temp table
from
(
select
	mm.*,
	year_diff = Invoice_Year - Cohort_Year,
	month_diff = Invoice_Month - Cohort_Month
from
(
	select
		m.*,
		c.Cohort_date,
		year(m.InvoiceDate) as Invoice_Year,
		month(m.InvoiceDate) as Invoice_Month,
		year(c.Cohort_date) as Cohort_Year,
		month(c.Cohort_date) as Cohort_Month
	from #online_retail_main m
	left join #cohort c
	on m.CustomerID = c.CustomerID) as mm
) as mmm

-- select everything 
select * from #cohort_retention;

-- save the data as csv for tableau
-------------------------------------------------------------------------------------------------

-- 3) Grouping Customers Per Cohort index
select 
	CustomerID,
	Cohort_date,
	Cohort_index
from #cohort_retention
order by 1,3;

-- 4) Pivot Data to see Cohort table

select *
into #cohort_pivot
from
(select distinct
	CustomerID,
	Cohort_date,
	Cohort_index
from #cohort_retention) as tbl
pivot (
count(CustomerID)
for Cohort_index in (
					[1],
					[2],
					[3],
					[4],
					[5],
					[6],
					[7],
					[8],
					[9],
					[10],
					[11],
					[12],
					[13]
				)
) as pivot_table
order by Cohort_date;

-- 5) create cohort retention rate
select Cohort_date

(1.0 * [1]/[1] * 100) as [1],
1.0 * [2]/[1] * 100 as [2],
1.0 * [3]/[1] * 100 as [3],
1.0 * [4]/[1] * 100 as [4],
1.0 * [5]/[1] * 100 as [5],
1.0 * [6]/[1] * 100 as [6],
1.0 * [7]/[1] * 100 as [7],
1.0 * [8]/[1] * 100 as [8],
1.0 * [9]/[1] * 100 as [9],
1.0 * [10]/[1] * 100 as [10],
1.0 * [11]/[1] * 100 as [11],
1.0 * [12]/[1] * 100 as [12],
1.0 * [13]/[1] * 100 as [13]


from #cohort_pivot
order by Cohort_date;