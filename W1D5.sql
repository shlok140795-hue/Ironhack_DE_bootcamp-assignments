USE week1_db;
###Lab 1: Select all orders
SELECT *
--Count(*)
FROM orders

-----Lab 2: Select specific columns with WHERE
SELECT order_id, 
customer_id, 
quantity, 
order_date
FROM orders
WHERE quantity > 2;

## Lab 3: Use IN and BETWEEN
--A. List orders placed by customer_id 1, 2, or 3.
SELECT *
FROM orders
WHERE customer_id IN (1,2,3);

B. List orders placed between '2022-07-01' and '2022-12-31' (inclusive).
SELECT *
FROM orders
WHERE order_date BETWEEN '2022-07-01' and '2023-01-01';

--List distinct cities where customers live.
SELECT DISTINCT city
FROM customers
WHERE city IS NOT NULL;

----Find the 5 most recent orders (order_date descending). Show order_id, customer_id, order_date.
SELECT order_id, customer_id, order_date
FROM orders
ORDER BY order_date DESC
LIMIT 5;

----Find products whose name contains 'USB' or 'USB-C' using LIKE. Show product_id and product_name.
SELECT product_id, product_name
FROM products
WHERE product_name LIKE '%USB%';

----Find customers whose city is NULL. Then count customers with non-null city.
SELECT customer_name
FROM customers
WHERE city IS NULL;

SELECT
count(*) AS non_null_city_count
FROM customers
WHERE city IS NOT NULL;

---Add a new order for customer_id 3 buying product_id 106 with quantity 1 on '2023-01-05' status 'pending'. Use order_id 1100.
INSERT INTO orders( customer_id, product_id, quantity, order_date, status, order_id)
 VALUES(3, 106, 1, '2023-01-05', 'pending', 1100);
 
 UPDATE orders
 SET unit_price = 7999.00
 WHERE order_id = 1100
 
SELECT *
FROM orders
WHERE order_id = 1100;

-----Change the status of order_id 1006 from 'pending' to 'delivered'. Show the row before and after the update.
 UPDATE orders
 SET status = 'delivered'
 WHERE order_id = 1006
 
SELECT order_id, status
FROM orders
WHERE order_id = 1006;

----Delete order with order_id 1004 (it was cancelled). Verify the deletion by attempting to SELECT it and by counting remaining rows.
DELETE FROM orders
WHERE order_id = 1004

SELECT order_id, status
FROM orders
WHERE order_id = 1004;


SELECT * FROM orders;
SELECT * FROM customers;
SELECT * FROM payments;
----### Problem Statement

A. Find total number of orders.
SELECT COUNT(*) FROM orders;

B. Find total quantity ordered across all orders.
SELECT SUM(quantity) AS total_quantity
FROM orders;

C. Find average unit_price across orders.
SELECT ROUND(AVG(unit_price),2) AS average_unit_price
FROM orders;

D. Find minimum and maximum unit_price recorded in orders.
SELECT MIN(unit_price) AS minimun_unit_price,
MAX(unit_price) AS maximun_unit_price
FROM orders;

----##Problem Statement

-------Find total spent per customer (sum of quantity * unit_price) and list customers who spent more than 20000. Show customer_id and total_spent.
SELECT customer_id, 
SUM(quantity * unit_price) AS total_spent_per_customer
FROM orders
GROUP BY customer_id
HAVING SUM(quantity * unit_price) > 20000

----Problem Statement

List order_id, customer_name, product_id, quantity, order_date for all delivered orders. Use INNER JOIN.
SELECT o.order_id, c.customer_name, o.product_id, o.quantity, o.order_date
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.status = "delivered";

-----Find orders that do not have an entry in payments (left join payments and filter where payment_id IS NULL). Show order_id, customer_id, order_date.
SELECT o.order_id, o.customer_id, o.order_date
FROM orders o
LEFT JOIN payments p
ON o.order_id = p.order_id
WHERE p.payment_id IS NULL

---For each product category, calculate total revenue = SUM(quantity * unit_price) and total_units_sold = SUM(quantity). 
----Show category, total_units_sold, total_revenue. Order by total_revenue DESC.
SELECT * FROM products;

SELECT pr.category,
SUM(o.quantity * pr.unit_price) AS total_revenue,
SUM(o.quantity) AS total_units_sold
FROM orders o
LEFT JOIN products pr
ON o.product_id = pr.product_id
GROUP BY pr.category
ORDER BY total_revenue DESC

'''''Create a business report showing top 5 customers by total spending (total_spent = SUM(quantity * unit_price)). For each top customer, show:

- customer_id
- customer_name
- city
- total_spent
- total_orders (number of orders)
- first_order_date
- last_order_date'''''

SELECT c.customer_id, c.customer_name, c.city, 
SUM(o.quantity * o.unit_price) AS total_spent,
COUNT(o.order_id) AS total_orders,
MIN(o.order_date) AS first_order_date,
MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.status IN ('delivered', 'returned') AND (o.order_date BETWEEN '2022-01-01' AND '2023-01-01')
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY SUM(o.quantity * o.unit_price) DESC
LIMIT 5