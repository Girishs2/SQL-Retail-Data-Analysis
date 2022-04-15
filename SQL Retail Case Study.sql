create database Retail

select * from Customer
select * from prod_cat_info
select * from transactions

--Data Preperation and Understanding

--1. What is the total number of rows in each of the 3 tables in the database?

select 'customer' as table_name, count(*) total_rows from Customer
union all
select 'prod_cat_code', count(*) from prod_cat_info
union all
select 'Transaction_id', count(*) from Transactions

--2. What is the total number of transactions that have a return?

select count(*) as total_return from Transactions where Qty<0

--3. Convert date variables into valid date formats

alter table customer
alter column DOB date
alter table transactions
alter column tran_date date

/*4. What is the time range of transaction data available for analysis? show the 
output in number of days, months and years simultaneously in different columns*/

select DATEDIFF(day, (select min(tran_date) from transactions), (select max(tran_date) from transactions)) as days_diff,
DATEDIFF(month,  (select min(tran_date) from transactions), (select max(tran_date) from transactions)) as month_diff,
DATEDIFF(year, (select min(tran_date) from transactions), (select max(tran_date) from transactions)) as year_diff

--5. Which product category does the sub_category 'DIY' belong to?

select prod_cat from prod_cat_info
where prod_subcat = 'DIY'


--Data Analysis

--1. Which channel is most frequently used for transactions?

select top 1 Store_type from Transactions
group by Store_type
order by count(store_type) desc

--2. What is the count of Male and Female customers in the database?

select Gender, count(Gender) count_of_gender from Customer
group by Gender
having Gender in ('M','F')

--3. From which city do we have the maximum number of customers and how many??

select top 1 city_code, count(city_code) as number_of_customers from Customer
group by city_code
order by count(city_code) desc

--4. How many sub_categories are there under the books category??

select prod_cat, count(prod_subcat) total_no_of_sub_categories from prod_cat_info
where prod_cat = 'Books'
group by prod_cat

--5. What is the maximum quantity of products ever ordered?

select top 1 p.prod_cat, count(Qty) total_qty_orderd from Transactions t inner join prod_cat_info p 
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
group by p.prod_cat
order by count(Qty) desc

--6. What is the net total revenue generated in categpries Electronics and Books?

select p.prod_cat, sum(total_amt) as Revenue from Transactions t inner join prod_cat_info p
on t.prod_cat_code = p.prod_cat_code
group by p.prod_cat
having p.prod_cat in ('Electronics','Books')

--7. How many customers have >10 transactions with us, excluding returns?

select count(cust_id) as cust_with_more_than_10_tran from
(select cust_id from Transactions
where Qty > 0
group by cust_id
having count(transaction_id) > 10) a

--8. What is the combined revenue earned from the 'Electronics' and 'Clothing' categories, from 'Flagship stores'?

select sum(total_amt) Total_Revenue from Transactions t inner join prod_cat_info p on t.prod_cat_code = p.prod_cat_code
where prod_cat in('Clothing','Electronics') and Store_type = 'Flagship store'

--9.What is the total Revenue generated from 'Male' customers in 'Electronics' category? output should display total revenue by prod sub_cat?

select prod_subcat, sum(total_amt) as [Revenue from Electronics by male] from Transactions t inner join Customer c on t.cust_id = c.customer_Id inner join prod_cat_info p
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
where Gender = 'M' and prod_cat = 'Electronics'
group by prod_subcat

--10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?

select top 5 p.prod_subcat,
	(select round(
	(sum(case when total_amt > 0 then total_amt else 0 end)/(select sum(total_amt) from Transactions where total_amt > 0)*100),2)) [sales_percent],
	(select round(
	(sum(case when total_amt < 0 then total_amt else 0 end)/(select sum(total_amt) from Transactions where total_amt < 0)*100),2)) [return_percent]
from Transactions t inner join prod_cat_info p
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
group by prod_subcat
order by [sales_percent] desc

/*11. For all customers aged between 25 to 35 years find what is the net total revenue generated by 
these consumers in last 30 days of transactions from max transaction date available in the data*/

select c.customer_Id, DATEDIFF(YEAR, DOB, tran_date) as [age], (select round(sum(total_amt),2)) as total_revenue
from Transactions t inner join Customer c
on t.cust_id = c.customer_Id
where DATEDIFF(YEAR, DOB, tran_date) between 25 and 35
group by customer_Id, DOB, tran_date
having datediff(DAY, t.tran_date, (select max(tran_date) from Transactions)) <=30
order by [age]

--12. Which product category has seen the max value of returns in the last 3 months of transactions??

select top 1 p.prod_cat, sum(case when total_amt<0 then total_amt else 0 end) [total_return_vale]
from Transactions t inner join prod_cat_info p on t.prod_cat_code = p.prod_cat_code
group by p.prod_cat, tran_date
having tran_date > DATEADD(month, -3, (select max(tran_date) from Transactions))
order by [total_return_vale] asc

--13 Which store-type sells the maximum products; by value of sales amount and quantity sold??

select top 1 Store_type,
sum(Qty) [Qty_sold],
(select round(sum(total_amt),2)) [sales_amount]
from Transactions
group by Store_type
order by [sales_amount] desc, [Qty_sold] desc

--14. What are the categories for which average revenue is above the overall average??

select prod_cat, avg(total_amt) [avg_revenue_of_prod]
from Transactions t inner join prod_cat_info p on t.prod_cat_code = p.prod_cat_code 
group by prod_cat
having avg(total_amt) > (select avg(total_amt) from transactions)

--15.Find the average and total revenue by each sub category for the categories which are among top 5 categories in terms of quantity sold

select prod_cat, prod_subcat, avg(total_amt) [avg_revenue], sum(total_amt) [total_revenue] 
from Transactions t inner join prod_cat_info p
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
where p.prod_cat_code in
(select top 5 prod_cat_code from Transactions 
group by prod_cat_code
order by (select sum(case when Qty >0 then Qty else 0 end)) desc)
group by prod_cat, prod_subcat
order by prod_cat, prod_subcat

