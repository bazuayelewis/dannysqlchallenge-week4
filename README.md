# dannysqlchallenge-week4
Data Bank Case Study #4

![4](https://user-images.githubusercontent.com/107050974/188099339-63d94ce9-253e-4bc0-a7f9-a0a01f6918d9.png)

## Introduction!

There is a new innovation in the financial industry called Neo-Banks: new aged digital only banks without physical branches.

Danny thought that there should be some sort of intersection between these new age banks, cryptocurrency and the data world…so he decides to launch a new initiative - Data Bank!

Data Bank runs just like any other digital bank - but it isn’t only for banking activities, they also have the world’s most secure distributed data storage platform!

Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. There are a few interesting caveats that go with this business model, and this is where the Data Bank team need your help!

The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!

## Entity Relationship Diagrams
![case-study-4-erd](https://user-images.githubusercontent.com/107050974/188096366-0c0cb3fa-f662-4773-a6f0-81263a99ab7b.png)


Click [HERE](https://8weeksqlchallenge.com/case-study-4/) to access the case study and the relevant schema

# Case Study Questions
The following case study questions include some general data exploration analysis for the nodes and transactions before diving right into the core business questions and finishes with a challenging final request!

## PART A
1. How many unique nodes are there on the Data Bank system?

*I used the **DISTINCT** function to return only unique nodes together with the **COUNT** function to find out how many they were*
```sql
  SELECT COUNT(DISTINCT(node_id)) total_nodes_types
  FROM customer_nodes;
```
![1](https://user-images.githubusercontent.com/107050974/188103944-1fbe23fb-a837-4450-9cf5-255c222d2801.png)

**There are 5 node types**

2. What is the number of nodes per region?

*I used the **GROUP BY** function to categorize nodes into the regions they fall in then I used the **COUNT** function on the **node_id** column to know how many nodes in each region*
```sql
SELECT region_id, COUNT(node_id) total_nodes
FROM customer_nodes
GROUP BY region_id; 
```
![2](https://user-images.githubusercontent.com/107050974/188104040-76c06183-b735-4b15-9df3-0781c12438cf.png)

**Regions with region_id 1,2,3,4,5 consists of 770,735,714,665,616 nodes respectively**

3. How many customers are allocated to each region?

*Here I used the **DISTINCT** function before counting to avoid duplicate values of customers per region*
```sql
SELECT region_id, COUNT(DISTINCT(customer_id)) total_customers
FROM customer_nodes
GROUP BY region_id;
```
![3](https://user-images.githubusercontent.com/107050974/188104074-a78b0f69-9b96-4234-ae0f-8e1083857e42.png)

**Regions with region_id 1,2,3,4,5 consists of 110,105,102,95,88 customers respectively**

4. How many days on average are customers reallocated to a different node?

*The query below runs on the assumption that a reallocation occurs after an end date. So a customer_id can be reallocated to the same node_id.*
```sql
SELECT ROUND(AVG(datediff(end_date,start_date) +1)) average_days
FROM customer_nodes
WHERE end_date < '2022-01-01';
```
![4](https://user-images.githubusercontent.com/107050974/188104099-9a6072a0-d803-42cc-a5db-a2f1eb293b2d.png)

**The average days for reallocation is 16 days**

5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

*For this query I started by creating a CTE called 'distributions' which consisted of a subquery called 'reallocation' that calculated the amount of days spent in a particular node before it switches to a random node. With the outer query using the **NTILE** function to split the results into groups of 2,5 and 20 using the results gotten from the inner query that generated the amount of days spent in a node before reallocation, to generate columns that would be used to calculate for the median,80th percentile and 95th percentile respectively of reallocation days for each region.*

*Then I created another CTE called 'percentile' to return possible values of the n-percentiles I was searching for, when the range of numbers are even,two middle numbers need to be sumed up and divided by 2 to get the nth-percentile otherwise if odd it would pick the middle number.*

*Lastly I used **CASE** statements to set conditions to return a value of the median(50th percentile),80th percentile and 95th percentile for each region.*
```sql
WITH distributions AS (
        SELECT region_id, days, customer_id, 
        NTILE(2) over (PARTITION BY region_id ORDER BY days) as median, NTILE(5) over (PARTITION BY region_id ORDER BY days) as eightieth_per,
         NTILE(20) over (PARTITION BY region_id ORDER BY days) as ninetieth_per
		FROM (
			SELECT (datediff(end_date,start_date) +1) days, region_id, customer_id
			FROM customer_nodes
			WHERE end_date < '2022-01-01' ORDER BY 2,1
			) reallocation
            ),
percentile AS (
		SELECT region_id,median,eightieth_per,ninetieth_per,
		MAX(CASE WHEN median=1 THEN days END) max_median,
		MIN(CASE WHEN median=2 THEN days END) min_median,
        MAX(CASE WHEN eightieth_per=4 THEN days END) max_eightieth_per,
        MIN(CASE WHEN eightieth_per=5 THEN days END) min_eightieth_per,
        MAX(CASE WHEN ninetieth_per=19 THEN days END) max_ninetieth_per,
        MIN(CASE WHEN ninetieth_per=20 THEN days END) min_ninetieth_per
        FROM distributions
        GROUP BY region_id
        )
SELECT region_id,
CASE COUNT(median) % 2 WHEN 1 THEN  max_median ELSE (max_median+min_median)/2 END true_median,
CASE COUNT(eightieth_per) % 2 WHEN 1 THEN max_eightieth_per ELSE ((max_eightieth_per+min_eightieth_per)/2) END true_eightieth_per,
CASE COUNT(ninetieth_per) % 2 WHEN 1 THEN max_ninetieth_per ELSE (max_ninetieth_per+min_ninetieth_per)/2 END true_ninetieth_per
FROM percentile
GROUP BY 1
ORDER BY 1;
```
![5](https://user-images.githubusercontent.com/107050974/188104130-fa450ca4-68e6-4fda-9db7-38fa87cd7c4c.png)


## PART B
1. What is the unique count and total amount for each transaction type?

*I used the **GROUP BY** function to categorize values into each transaction(txn) type then used **DISTINCT** function for customers per txn_type to avoid duplicates. I also calculated the total amount transacted for each category using the **SUM** function*
```sql
SELECT txn_type, COUNT(DISTINCT(customer_id)) unique_count, SUM(txn_amount) total_amount
FROM customer_transactions
GROUP BY 1;
```
![1](https://user-images.githubusercontent.com/107050974/188124645-a4c41135-2111-4a91-8f97-61004ae5fe6d.png)

- **A *deposit* transaction was perfomed by 500 customers and the total amount sumed up to 1,359,168.**
- **A *purchase* transaction was performed by 448 customers and the total amount sumed up to 806,537.**
- **A *withdrawal* transaction was performed by 439 customers and the total amount sumed up to 793,003.**

2. What is the average total historical deposit counts and amounts for all customers?

*Here I filtered the dataset using the **WHERE** clause to return customers who only depoisted. Then I calculated the average by counting the amounts of deposit transactions made and divided it by the amount of customers that performed them, and rounded up to the nearest positive integer using **ROUND** function. I also used the **AVG** function to calculate the mean deposited amount and used **ROUND** function to round the numbers to the nearest two decimal places.*
```sql
 SELECT txn_type, ROUND(COUNT(txn_type)/COUNT(DISTINCT(customer_id))) avg_deposits_made, ROUND(AVG(txn_amount),2) average_deposited_amount
 FROM customer_transactions
 WHERE txn_type = 'deposit';
```
![2](https://user-images.githubusercontent.com/107050974/188128264-6b7d30d8-63dc-4dcf-8b92-754b84c89b02.png)

**Average deposits made by all customers is 5 and the average deposited amount is 508.86**

3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

*I created a CTE 'deposit_transactions' to store all transaction type that were deposits using the **WHERE** clause and created new columns 'months' to return the name of the month each transaction occured using the **MONTHNAME** function and 'txn' to return the number of transactions that occured. I used the GROUP BY function to categorize every customer 'txn' on a monthly basis*

*For my second CTE 'other_transactions' I repeated similar steps but this time I changed the **WHERE** clause to return other 'txn' types that are not deposits.*

*Then I used a subquery to filter customers that made more than one deposits using the **WHERE** clause on the 'deposits_transaction' table then used the **UNION** function to join it to the 'expense_transaction' table that has been filtered to return customers who have at least one txn i.e txn is not empty. I used the outer query which consisted of a **GROUP BY** function and the **DISTINCT** function to return the number of unique customers per month. I added an **ORDER BY** function to arrange my results but since we are dealing with months I added a **STR_TO_DATE** function with the neccessary format to arrange my results properly.* 
```sql
WITH deposit_transactions AS (
	SELECT *, monthname(txn_date) as months, COUNT(customer_id) txn
	FROM customer_transactions
	WHERE txn_type='deposit'
	GROUP BY 2,6
    ),
other_transactions AS(
	SELECT *, monthname(txn_date) as months, COUNT(customer_id) txn
	FROM customer_transactions
	WHERE txn_type!='deposit'
	GROUP BY 2,6
    )
SELECT months, COUNT(DISTINCT(customer_id)) total_customers
	FROM(	
		SELECT customer_id, months, txn_type, txn
		FROM deposit_transactions 
        WHERE txn>1
		UNION
		SELECT customer_id, months, txn_type, txn
		FROM other_transactions
        WHERE txn IS NOT NULL
		) AS total_customers
GROUP BY months
ORDER BY str_to_date(months,'%M');
```
![3](https://user-images.githubusercontent.com/107050974/188206578-26c081a3-2f8f-45ed-8696-600791f0c931.png)

**Total customers that had more than 1 deposit and at least one purchase or withdrawal**   
* January - **353** customers 
* February - **422** customers
* March - **429** customers
* April - **257** customers 

4. What is the closing balance for each customer at the end of the month?

*For the first two CTEs check PART B Q3 for documentation.
I used a subquey to perform a full outer join to return all records from the 'deposist_transactions' table and the 'expense_transactions' tables. For both tables, I specified that if the 'txn_amount' is greater than zero then it should return the sum of the 'txn_amount' that a customer transacted for that month if not it should return zero. This was done to avoid NULL values in our dataset.*

*For the closing balance, I subtracted the total expenses from total deposits. I used the **GROUP BY** function to show the monthly closing balance for each customer*

*NOTE:  
I did not use running closing balance as the question did not specify. The closing balance in this solution is for each month with no reference to the previous month's balance.*
```sql
WITH deposit_transactions AS (
	SELECT id, customer_id, monthname(txn_date) as months, SUM(txn_amount) deposits, txn_date
	FROM customer_transactions
	WHERE txn_type='deposit'
	GROUP BY 1,2
    ),
expenses_transactions AS(
	SELECT id,customer_id, monthname(txn_date) as months, SUM(txn_amount) expenses, txn_date
	FROM customer_transactions
	WHERE txn_type!='deposit'
	GROUP BY 1,2 
    )
SELECT customer_id, months, (SUM(deposits)-SUM(expenses)) closing_balance
FROM(	
		SELECT d.id, d.customer_id, d.months, IF(deposits>0, deposits,0) deposits, IF(e.expenses>0, e.expenses,0) expenses,d.txn_date
		FROM deposit_transactions d  
		LEFT JOIN expenses_transactions e ON d.id=e.id
		UNION
		SELECT e.id, e.customer_id, e.months, IF(d.deposits>0, d.deposits,0) deposits, IF(expenses>0, expenses,0) expenses,e.txn_date
		FROM expenses_transactions e
		LEFT JOIN deposit_transactions d ON e.id=d.id
			) AS total_customers 
GROUP BY 1,2
ORDER BY 1,txn_date;
```
![4](https://user-images.githubusercontent.com/107050974/188208950-9f54bcdc-99bf-4210-81e3-aec182ba525d.png)

**NOTE: The image only shows the first 7 customer's closing balance per month**

5. What is the percentage of customers who increase their closing balance by more than 5%?
*For the 'deposit_transactions', 'expenses_transactions' and 'total_transactions' CTEs check PART B Q 3&4 for documentation
In the 'initial_txn' CTE I used the **WHERE** clause to filter only transactions done in January and calculated the closing balance for each customer. For the 'final_txn' CTE I calculated the running closing balance for each customer.*

*Then I joined the 'initial_txn' and 'final_txn' tables and used the **WHERE** clause to set a condition to return customers who have made a 5% increase from their initial closing balance in January. I joined the qualified customers to the total customers to get the percent of customers who met the condition.*
```sql
WITH deposit_transactions AS (
	SELECT id, customer_id, monthname(txn_date) as months, SUM(txn_amount) deposits, txn_date 
	FROM customer_transactions
	WHERE txn_type='deposit'
	GROUP BY 1,2
    ),
expenses_transactions AS(
	SELECT id,customer_id, monthname(txn_date) as months, SUM(txn_amount) expenses, txn_date
	FROM customer_transactions
	WHERE txn_type!='deposit'
	GROUP BY 1,2 
    ),
total_transactions AS(
SELECT d.id, d.customer_id, d.months, IF(deposits>0, deposits,0) deposits, IF(e.expenses>0, e.expenses,0) expenses,d.txn_date
						FROM deposit_transactions d  
						LEFT JOIN expenses_transactions e ON d.id=e.id
						UNION
						SELECT e.id, e.customer_id, e.months, IF(d.deposits>0, d.deposits,0) deposits, IF(expenses>0, expenses,0) expenses,e.txn_date
						FROM expenses_transactions e
						LEFT JOIN deposit_transactions d ON e.id=d.id
),
all_customers AS( SELECT DISTINCT(customer_id) total_customers FROM customer_transactions),
initial_txn AS (
		SELECT id,customer_id,months,
		SUM(SUM(deposits)-SUM(expenses)) OVER( PARTITION BY customer_id ORDER BY txn_date) initial_balance
		FROM total_transactions		 
		WHERE months='January'
        GROUP BY 2),
final_txn AS (
		SELECT id,customer_id,months,
		SUM(SUM(deposits)-SUM(expenses)) OVER( PARTITION BY customer_id ORDER BY ranks) final_balance
		FROM(		
					SELECT id, customer_id,months,txn_date,deposits, expenses,
					DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY txn_date) ranks  
					FROM total_transactions
					GROUP BY 1,2) transaction_rank
		GROUP BY 2)
 SELECT ROUND((COUNT(qualified_customers)/COUNT(total_customers)) *100) percentage_customers 
 FROM(
 	SELECT customer_id as qualified_customers
 	FROM(
				SELECT f.customer_id,initial_balance,final_balance  
				FROM final_txn f           
				JOIN initial_txn i ON f.id=i.id
				GROUP BY 1) all_txn
		WHERE final_balance>(initial_balance*0.05)+initial_balance) five_percent
 RIGHT JOIN all_customers a ON five_percent.qualified_customers = a.total_customers;
```
![5](https://user-images.githubusercontent.com/107050974/188209917-1a7e5484-1b71-499d-9921-1983a8e9581a.png)

**33% of customers increased their closing balance by more than 5%.**

**NOTE: Closing balance compared were the initial closing balance(closing balance for January) and the final closing balance**

## PART C
To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

* Option 1: data is allocated based off the amount of money at the end of the previous month
* Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
* Option 3: data is updated real-time
For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

1. running customer balance column that includes the impact each transaction

*I created a Query that returned a running balance that showed calculated the customer's balance each time a transaction was carried out.
See previous questions for steps implemented*
```sql
WITH deposit_transactions AS (
	SELECT id, customer_id,txn_type, monthname(txn_date) as months, SUM(txn_amount) deposits, txn_date,txn_amount 
	FROM customer_transactions
	WHERE txn_type='deposit'
	GROUP BY 1,2
    ),
expenses_transactions AS(
	SELECT id,customer_id,txn_type, monthname(txn_date) as months, SUM(txn_amount) expenses, txn_date,txn_amount
	FROM customer_transactions
	WHERE txn_type!='deposit'
	GROUP BY 1,2 
    ),
total_transactions AS (
SELECT d.id, d.customer_id, d.months, d.txn_type,d.txn_amount, IF(deposits>0, deposits,0) deposits, IF(e.expenses>0, e.expenses,0) expenses,d.txn_date
						FROM deposit_transactions d  
						LEFT JOIN expenses_transactions e ON d.id=e.id
						UNION
						SELECT e.id, e.customer_id, e.months, e.txn_type,e.txn_amount, IF(d.deposits>0, d.deposits,0) deposits, IF(expenses>0, expenses,0) expenses,e.txn_date
						FROM expenses_transactions e
						LEFT JOIN deposit_transactions d ON e.id=d.id
)
SELECT customer_id,months, txn_type,txn_amount,
SUM(SUM(deposits)-SUM(expenses)) OVER( PARTITION BY customer_id ORDER BY ranks) balance
FROM(		
			SELECT id, customer_id,months, txn_type,txn_date,txn_amount, deposits, expenses,
			DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY txn_date) ranks 
            FROM total_transactions
			GROUP BY 1,2) transaction_rank
GROUP BY id,1
ORDER BY 1,txn_date;
```
![1](https://user-images.githubusercontent.com/107050974/188211261-84854e4d-7a95-40b2-a456-fa16947293c3.png)

**NOTE: The image shows 4 customers and thier balance for each transaction carried out**

2. customer balance at the end of each month
* Here I calculated the running closing balance for each customer on a monthly basis and also showed the total deposits and total expenses each customer carried out per month
NOTE: This different from PART B Q4 where I calculated the closing balance for each customer every month independently without considering past transactions.*
```sql
WITH deposit_transactions AS (
	SELECT id, customer_id, monthname(txn_date) as months, SUM(txn_amount) deposits, txn_date 
	FROM customer_transactions
	WHERE txn_type='deposit'
	GROUP BY 1,2
    ),
expenses_transactions AS(
	SELECT id,customer_id, monthname(txn_date) as months, SUM(txn_amount) expenses, txn_date
	FROM customer_transactions
	WHERE txn_type!='deposit'
	GROUP BY 1,2 
    ),
total_transactions AS(
SELECT d.id, d.customer_id, d.months, IF(deposits>0, deposits,0) deposits, IF(e.expenses>0, e.expenses,0) expenses,d.txn_date
						FROM deposit_transactions d  
						LEFT JOIN expenses_transactions e ON d.id=e.id
						UNION
						SELECT e.id, e.customer_id, e.months, IF(d.deposits>0, d.deposits,0) deposits, IF(expenses>0, expenses,0) expenses,e.txn_date
						FROM expenses_transactions e
						LEFT JOIN deposit_transactions d ON e.id=d.id
)
SELECT customer_id,months,SUM(deposits) total_deposits, SUM(expenses) total_expenses,
SUM(SUM(deposits)-SUM(expenses)) OVER( PARTITION BY customer_id ORDER BY ranks) balance
FROM(		
			SELECT id, customer_id,months,txn_date,deposits, expenses,
			DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY txn_date) ranks  
			FROM total_transactions
			GROUP BY 1,2) transaction_rank
GROUP BY 1,2
ORDER BY 1;
```
![2](https://user-images.githubusercontent.com/107050974/188212055-34df1600-b984-4175-b6a3-56ce956e5997.png)

**The image shows 7 customers running closing balance for each month.**

3. minimum, average and maximum values of the running balance for each customer

*For this query I used the AVG,MIN and MAX functions to query the running balance for each customer. I also included a column to display the amount of transactions completed per customer.*
```sql
WITH deposit_transactions AS (
	SELECT id, customer_id,txn_type, monthname(txn_date) as months, SUM(txn_amount) deposits, txn_date,txn_amount 
	FROM customer_transactions
	WHERE txn_type='deposit'
	GROUP BY 1,2
    ),
expenses_transactions AS(
	SELECT id,customer_id,txn_type, monthname(txn_date) as months, SUM(txn_amount) expenses, txn_date,txn_amount
	FROM customer_transactions
	WHERE txn_type!='deposit'
	GROUP BY 1,2 
    ),
total_transactions AS (
		SELECT d.id, d.customer_id, d.months, d.txn_type,d.txn_amount, IF(deposits>0, deposits,0) deposits, IF(e.expenses>0, e.expenses,0) expenses,d.txn_date
		FROM deposit_transactions d  
		LEFT JOIN expenses_transactions e ON d.id=e.id
		UNION
		SELECT e.id, e.customer_id, e.months, e.txn_type,e.txn_amount, IF(d.deposits>0, d.deposits,0) deposits, IF(expenses>0, expenses,0) expenses,e.txn_date		      FROM expenses_transactions e
		LEFT JOIN deposit_transactions d ON e.id=d.id
			),
running_balance AS (
SELECT customer_id,months, txn_type,txn_amount,
SUM(SUM(deposits)-SUM(expenses)) OVER( PARTITION BY customer_id ORDER BY ranks) balance
FROM(		
			SELECT id, customer_id,months, txn_type,txn_date,txn_amount, deposits, expenses,
			DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY txn_date) ranks  
			FROM total_transactions
			GROUP BY 1,2) transaction_rank
GROUP BY id,1
ORDER BY 1,txn_date
)
SELECT customer_id, COUNT(txn_type) txn_completed, 
ROUND(AVG(balance),2) average_balance, MAX(balance) maximum_balance, MIN(balance) minimum_balance
FROM running_balance 
GROUP BY 1;
```
![3](https://user-images.githubusercontent.com/107050974/188214201-2a49deaf-8c0e-4b5f-b4a9-a85a852c7401.png)
