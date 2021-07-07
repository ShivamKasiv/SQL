CREATE DATABASE Retail;
USE Retail;

select * from customer;
select * from prod_cat_info;
select * from transactions;

--DATA PREPARATION AND UNDERSTANDING

--1.	What is the total number of rows in each of the 3 tables in the database?

SELECT 'Customer' AS 'Table',COUNT(*) AS Total_Rows FROM Customer
UNION 
SELECT 'Transactions' AS 'Table',COUNT(*) AS Total_Rows FROM Transactions
UNION
SELECT 'Prod_Cat_Info' AS 'Table',COUNT(*) AS Total_Rows FROM prod_cat_info


--2.	What is the total number of transactions that have a return?
SELECT distinct * FROM Transactions WHERE QTY<1 ;




--3.	As you would have noticed, the dates provided across the datasets are not in a correct format. As first steps, pls convert the date variables into valid date formats before proceeding ahead.
BEGIN TRANSACTION
ALTER TABLE Transactions ALTER COLUMN tran_date DATE NOT NULL
ALTER TABLE Customer ALTER COLUMN DOB DATE NOT NULL
COMMIT;



--4.	What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously in different columns.SELECT * FROM TRANSACTIONS;
select MIN(tran_date) as [start date], MAX(tran_date) as [end date]
,DATEDIFF(day,MIN(tran_date),MAX(tran_date)) [difference in days],
DATEDIFF(MONTH,MIN(tran_date),MAX(tran_date)) [difference in months],
DATEDIFF(year,MIN(tran_date),MAX(tran_date)) [difference in years]from Transactions

---5.	Which product category does the sub-category “DIY” belong to?
select prod_cat AS PRODUCT_CATEGORY FROM prod_cat_info where prod_subcat='DIY';







--DATA ANALYSIS

ALTER TABLE CUSTOMER ADD PRIMARY KEY(CUSTOMER_ID);
ALTER TABLE TRANSACTIONS ADD FOREIGN KEY(CUST_ID) REFERENCES CUSTOMER(CUSTOMER_ID);
ALTER TABLE TRANSACTIONS ALTER COLUMN Qty int not null


--1.Which channel is most frequently used for transactions?
SELECT STORE_TYPE FROM TRANSACTIONS GROUP BY STORE_TYPE HAVING COUNT(*)=
(SELECT MAX(CNT) FROM 
(SELECT STORE_TYPE,COUNT(*) CNT FROM TRANSACTIONS GROUP BY STORE_TYPE) 
AS DKSK);


--2.	What is the count of Male and Female customers in the database?
SELECT GENDER,COUNT(*) AS count FROM CUSTOMER where Gender in ('f','m') GROUP BY GENDER;


--3.	From which city do we have the maximum number of customers and how many?

SELECT CITY_CODE ,COUNT(*) AS COUNT_OF_CUSTOMERS FROM CUSTOMER GROUP BY CITY_CODE HAVING COUNT(*)=
(SELECT MAX(FREQ) FROM (SELECT COUNT(*) AS FREQ  FROM CUSTOMER GROUP BY CITY_CODE) AS DKSK);

--4.	How many sub-categories are there under the Books category?
SELECT prod_subcat FROM Prod_cat_info where prod_cat='Books';
----------------------or------------------------------
select prod_cat,COUNT(prod_subcat) from prod_cat_info where prod_cat ='Books' group by prod_cat;

--5.	What is the maximum quantity of products ever ordered?
---------if  product with max quantity ordered is asked---------------
select top 1 prod_cat,SUM(Qty)[max quantity by prod_cat]  from Transactions inner join prod_cat_info on Transactions.prod_cat_code=prod_cat_info.prod_cat_code
group by prod_cat order by sum(qty) desc 
--------if max quantity of any product ordered is asked--------------
select ABS(max(qty))[maximum quantity of a product ever ordered] from Transactions 

--6.	What is the net total revenue generated in categories Electronics and Books?
SELECT prod_cat,sum(total_amt) FROM TRANSACTIONS INNER JOIN PROD_CAT_INFO ON transactions.prod_cat_code=PROD_CAT_INFO.Prod_cat_code AND transactions.prod_subcat_code=PROD_CAT_INFO.Prod_sub_cat_code
where prod_cat in ('Electronics','Books') group by prod_cat;


--7.	How many customers have >10 transactions with us, excluding returns?
SELECT CUST_ID,freq FROM (SELECT CUST_ID,COUNT(TRANSACTION_ID) AS FREQ FROM TRANSACTIONS where QTY>=1  GROUP BY CUST_ID) AS SMPL WHERE FREQ>10 ;
----------------or-------------------------------------------------------------------------------------------
SELECT count(CUST_ID) FROM (SELECT CUST_ID,COUNT(TRANSACTION_ID) AS FREQ FROM TRANSACTIONS where QTY>=1  GROUP BY CUST_ID) AS SMPL WHERE FREQ>10 ;

--8.	What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?
SELECT sum(total_amt) AS [COMBINED REVENUE] FROM TRANSACTIONS left JOIN PROD_CAT_INFO ON transactions.prod_cat_code=PROD_CAT_INFO.Prod_cat_code AND transactions.prod_subcat_code=PROD_CAT_INFO.Prod_sub_cat_code 
WHERE PROD_CAT IN ('Electronics','Clothing') group by store_type HAVING STORE_TYPE='Flagship store'

--9.	What is the total revenue generated from “Male” customers in “Electronics” category? Output should display total revenue by prod sub-cat.
SELECT prod_cat,prod_subcat,sum(total_amt) [total revenue by product category for male customers] FROM ((TRANSACTIONS INNER JOIN CUSTOMER  ON CUSTOMER.CUSTOMER_ID=TRANSACTIONS.CUST_ID)
INNER JOIN 
PROD_CAT_INFO ON transactions.prod_cat_code=PROD_CAT_INFO.Prod_cat_code AND transactions.prod_subcat_code=PROD_CAT_INFO.Prod_sub_cat_code) 
where gender ='M' group by prod_cat,prod_subcat having prod_cat='Electronics'



--10.	What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
        select TOP 5 prod_subcat,round(((sum(CASE WHEN Qty>=1 then total_amt else 0 end)/(select sum(total_amt) from transactions where qty>=1))*100),2) as [sales percentage],round(((sum(CASE WHEN Qty<1 then total_amt else 0 end)/(select sum(total_amt) from transactions where qty<1))*100),2)  as [returns percentage]
		from transactions inner join prod_cat_info on transactions.prod_cat_code=prod_cat_info.prod_cat_code and transactions.prod_subcat_code=PROD_CAT_INFO.Prod_sub_cat_code
	    group by prod_subcat order by [sales percentage] desc 

		
--11.	For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30 days of transactions from max transaction date available in the data?
select sum(total_amt) as summ from transactions where tran_date in (select distinct top 30  tran_date from transactions)  and cust_id in (select distinct customer_id from customer where datediff(year,dob,convert(date,getdate())) between 25 and 35);




--12.	Which product category has seen the max value of returns in the last 3 months of transactions?
select prod_cat from transactions inner join prod_cat_info on transactions.prod_cat_code=PROD_CAT_INFO.Prod_cat_code AND transactions.prod_subcat_code=PROD_CAT_INFO.Prod_sub_cat_code
where tran_date >= (select dateadd(month,-3,(select top 1 tran_date from transactions order by tran_date desc))) and qty<1 group by prod_cat having count(qty)=
(select max(sam_qty) from 
(select count(qty) sam_qty from transactions where tran_date >= (select dateadd(month,-3,(select top 1 tran_date from transactions order by tran_date desc))) and qty<1 group by prod_cat_code) as dksk);

--13.	Which store-type sells the maximum products; by value of sales amount and by quantity sold?
select 'By Sales Amount' as criteria, store_type  from transactions  group by store_type having sum(total_amt)=(select max(sales_amount) from (select sum(total_amt) as sales_amount from transactions group by store_type) as mkdk)
union
select 'By Quantity Sold' as criteria, store_type  from transactions where qty>=1 group by store_type having sum(qty)=(select max(quant_sum) from (select store_type,sum(qty) quant_sum from transactions where qty>=1 group by store_type) as dksk);



--14.	What are the categories for which average revenue is above the overall average.
select prod_cat from transactions inner join prod_cat_info on transactions.prod_cat_code=prod_cat_info.prod_cat_code and transactions.prod_subcat_code=prod_cat_info.prod_sub_cat_code group by prod_cat having avg(total_amt)>(select avg(total_amt) from transactions);


--15.	Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold
select prod_cat,prod_subcat,sum(total_amt) as total_revenu,avg(total_amt) as average_revenue from transactions left join prod_cat_info on transactions.prod_cat_code=prod_cat_info.prod_cat_code and transactions.prod_subcat_code=prod_cat_info.prod_sub_cat_code 
where qty>=1 group by prod_cat,prod_subcat having prod_cat in 
(select  top 5 prod_cat from transactions left join prod_cat_info on transactions.prod_cat_code=prod_cat_info.prod_cat_code and transactions.prod_subcat_code=prod_cat_info.prod_sub_cat_code 
where qty>=1 group by prod_cat order by sum(qty) desc);


