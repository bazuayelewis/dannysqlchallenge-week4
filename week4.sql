-- PART A
-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT(node_id)) total_nodes_types
FROM customer_nodes;

-- 2.What is the number of nodes per region?
SELECT region_id, COUNT(node_id) total_nodes
FROM customer_nodes
GROUP BY region_id; 

-- 3. How many customers are allocated to each region?
SELECT region_id, COUNT(DISTINCT(customer_id)) total_customers
FROM customer_nodes
GROUP BY region_id;

-- 4. How many days on average are customers reallocated to a different node?
SELECT ROUND(AVG(datediff(end_date,start_date) +1)) average_days
FROM customer_nodes
WHERE end_date < '2022-01-01';

-- 5.What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
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

-- PART B
-- 1. What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(DISTINCT(customer_id)) unique_count, SUM(txn_amount) total_amount
FROM customer_transactions
GROUP BY 1; 

-- 2. What is the average total historical deposit counts and amounts for all customers?
 SELECT txn_type, ROUND(COUNT(txn_type)/COUNT(DISTINCT(customer_id))) avg_deposits_made, ROUND(AVG(txn_amount),2) average_deposited_amount
 FROM customer_transactions
 WHERE txn_type = 'deposit';
 
 -- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
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
ORDER BY str_to_date(months,'%M') ;

-- 4. What is the closing balance for each customer at the end of the month?
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

-- 5. What is the percentage of customers who increase their closing balance by more than 5% ?
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

-- PART C 
/*
To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

Option 1: data is allocated based off the amount of money at the end of the previous month
Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
Option 3: data is updated real-time
For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

1. running customer balance column that includes the impact each transaction
2. customer balance at the end of each month
3. minimum, average and maximum values of the running balance for each customer
4. Using all of the data available - how much data would have been required for each option on a monthly basis? */

-- 1. running customer balance column that includes the impact each transaction
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

-- customer balance at the end of each month
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

-- 3.  minimum, average and maximum values of the running balance for each customer
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