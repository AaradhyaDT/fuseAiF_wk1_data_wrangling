-- ============================================================
-- SQL Assignment — Classic Models Database
-- Fuse AI Fellowship 2026 | Week 1
-- Aaradhya Dev Tamrakar
-- Submitted: May 4, 2026
-- ============================================================

USE classicmodels;

-- ------------------------------------------------------------
-- Q1. Show all the customers whose creditLimit is greater than 20000
-- ------------------------------------------------------------
SELECT customerName, creditLimit
FROM customers
WHERE creditLimit > 20000
ORDER BY creditLimit DESC;


-- ------------------------------------------------------------
-- Q2. Show the employees who report to VP Sales.
-- ------------------------------------------------------------
SELECT employeeNumber, firstName, lastName, jobTitle
FROM employees
WHERE reportsTo = (
    SELECT employeeNumber FROM employees WHERE jobTitle = 'VP Sales'
);


-- ------------------------------------------------------------
-- Q3. Find all the customers who have set their state while filling
--     the forms and Lives in USA and credit limit is between 100000 and 200000.
-- ------------------------------------------------------------
SELECT customerNumber, customerName, state, country, creditLimit
FROM customers
WHERE country = 'USA'
  AND creditLimit BETWEEN 100000 AND 200000
  AND state IS NOT NULL;


-- ------------------------------------------------------------
-- Q4. Find all the employees who report to Sales Managers of all types.
-- ------------------------------------------------------------
SELECT employeeNumber, firstName, lastName, jobTitle, reportsTo
FROM employees
WHERE reportsTo IN (
    SELECT employeeNumber FROM employees WHERE jobTitle LIKE '%Sale% %Manage%'
);


-- ------------------------------------------------------------
-- Q5. Find the average credit limit of customers of each country.
-- ------------------------------------------------------------
SELECT country, AVG(creditLimit) AS avg_credit
FROM customers
GROUP BY country
ORDER BY avg_credit DESC;


-- ------------------------------------------------------------
-- Q6. Find the total no. of orders for each date and customer.
--     Show only dates with total number of orders greater than 10
--     for date and customer.
-- ------------------------------------------------------------
SELECT COUNT(o.orderNumber) AS order_count, o.orderDate, o.customerNumber, c.customerName
FROM orders o
LEFT JOIN customers c ON o.customerNumber = c.customerNumber
GROUP BY o.orderDate, o.customerNumber
HAVING COUNT(o.orderNumber) > 10;

-- Note: Empty result — max orders per (date, customer) in this dataset is 2.
-- Query logic is correct; the threshold of 10 simply exceeds what the data contains.


-- ------------------------------------------------------------
-- Q7. Find the name of the supervisor, job title of supervisor and
--     total no. of supervisee using subquery. (Without using Join operation)
-- ------------------------------------------------------------
SELECT
    firstName,
    lastName,
    jobTitle,
    (SELECT COUNT(*) FROM employees e2 WHERE e2.reportsTo = e1.employeeNumber) AS supervisee_count
FROM employees e1
HAVING supervisee_count > 0;


-- ------------------------------------------------------------
-- Q8. Find the name of the supervisor, job title of supervisor and
--     total no. of supervisee using subquery. (With using Join operation)
-- ------------------------------------------------------------
SELECT e2.firstName, e2.lastName, e2.jobTitle, COUNT(e1.employeeNumber) AS supervisee_count
FROM employees e2
JOIN employees e1 ON e2.employeeNumber = e1.reportsTo
GROUP BY e2.employeeNumber;


-- ------------------------------------------------------------
-- Q9. Find all customers with a credit limit greater than average
--     credit limit using WITH Clause.
-- ------------------------------------------------------------
WITH cte_name AS (
    SELECT AVG(creditLimit) AS avg_credit FROM customers
)
SELECT customerNumber, customerName, creditLimit
FROM customers, cte_name
WHERE creditLimit > avg_credit;


-- ------------------------------------------------------------
-- Q10. Find the rank of customer. [Customer with highest credit limit
--      have 1 rank and Customer with lowest credit limit have highest rank].
--      Then, find the customer with the third highest credit limit.
-- ------------------------------------------------------------
WITH ranked AS (
    SELECT customerName, creditLimit, RANK() OVER (ORDER BY creditLimit DESC) AS rnk
    FROM customers
)
SELECT * FROM ranked WHERE rnk = 3;


-- ------------------------------------------------------------
-- Q11. Generate a report that shows total no. of employees working
--      in each office.
-- ------------------------------------------------------------
SELECT o.city, o.country, COUNT(e.employeeNumber) AS total_employees
FROM offices o
LEFT JOIN employees e ON o.officeCode = e.officeCode
GROUP BY o.officeCode;


-- ------------------------------------------------------------
-- Q12. Generate a report that shows total no. of customers visited
--      each office.
-- ------------------------------------------------------------
SELECT o.city, o.country, COUNT(c.customerNumber) AS total_customers
FROM offices o
LEFT JOIN employees e ON o.officeCode = e.officeCode
LEFT JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
GROUP BY o.officeCode;


-- ------------------------------------------------------------
-- Q13. Generate a report that shows total payment received by each office
--      using payment tables and essential tables. The report should show
--      the office name, state and country, along with total payments made.
-- ------------------------------------------------------------
SELECT o.city, o.state, o.country, SUM(p.amount) AS total_payments
FROM offices o
LEFT JOIN employees e ON o.officeCode = e.officeCode
LEFT JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
LEFT JOIN payments p ON c.customerNumber = p.customerNumber
GROUP BY o.officeCode;


-- ------------------------------------------------------------
-- Q14. Generate a report that shows total sales(in amount) by each office
--      using order details table and other essential tables.
-- ------------------------------------------------------------
SELECT o.city, o.state, o.country, SUM(od.quantityOrdered * od.priceEach) AS total_sales
FROM offices o
LEFT JOIN employees e ON o.officeCode = e.officeCode
LEFT JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
LEFT JOIN orders or2 ON c.customerNumber = or2.customerNumber
LEFT JOIN orderdetails od ON or2.orderNumber = od.orderNumber
GROUP BY o.officeCode;


-- ------------------------------------------------------------
-- Q15. Generate a report that shows total payment pending for each office.
-- ------------------------------------------------------------
SELECT o.city, o.state, o.country,
       SUM(COALESCE(sales.total_sales, 0)) - SUM(COALESCE(pay.total_payments, 0)) AS total_pending
FROM offices o
LEFT JOIN employees e ON o.officeCode = e.officeCode
LEFT JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
LEFT JOIN (
    SELECT or2.customerNumber, SUM(od.quantityOrdered * od.priceEach) AS total_sales
    FROM orders or2
    JOIN orderdetails od ON or2.orderNumber = od.orderNumber
    GROUP BY or2.customerNumber
) sales ON c.customerNumber = sales.customerNumber
LEFT JOIN (
    SELECT customerNumber, SUM(amount) AS total_payments
    FROM payments
    GROUP BY customerNumber
) pay ON c.customerNumber = pay.customerNumber
GROUP BY o.officeCode;


-- ------------------------------------------------------------
-- Q16. Find the creditLimit of each person, proportion of creditLimit
--      of each person in each country.
--      [Proportion = creditLimit of person / sum(creditLimit of all persons in same country)]
-- ------------------------------------------------------------
SELECT c.customerNumber, c.customerName, c.country, c.creditLimit,
       c.creditLimit / SUM(c2.creditLimit) AS proportion
FROM customers c
JOIN customers c2 ON c.country = c2.country
GROUP BY c.customerNumber, c.country, c.creditLimit;


-- ------------------------------------------------------------
-- Q17. Create a view showing the customer name, complete address,
--      and their total number of orders.
-- ------------------------------------------------------------
CREATE VIEW customer_order_summary AS
SELECT c.customerName,
       CONCAT(c.addressLine1, ', ', COALESCE(c.addressLine2, ''), ', ', c.city, ', ', c.country) AS complete_address,
       COUNT(o.orderNumber) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber;

SELECT * FROM customer_order_summary LIMIT 10;


-- ------------------------------------------------------------
-- Q18. Update the country of a customer (use any one record).
-- ------------------------------------------------------------
UPDATE customers
SET country = 'Nepal'
WHERE customerNumber = 103;

SELECT customerNumber, customerName, country FROM customers WHERE customerNumber = 103;


-- ------------------------------------------------------------
-- Q19. Delete all payments below 20,000.
-- ------------------------------------------------------------
DELETE FROM payments WHERE amount < 20000;

SELECT COUNT(*) AS remaining_payments FROM payments;


-- ------------------------------------------------------------
-- Q20. Add new payments manually for an existing customer.
-- ------------------------------------------------------------
INSERT INTO payments (customerNumber, checkNumber, paymentDate, amount)
VALUES (103, 'CHK99999', '2026-05-04', 50000.00);

SELECT * FROM payments WHERE customerNumber = 103;

-- ============================================================
-- End of Assignment
-- ============================================================
