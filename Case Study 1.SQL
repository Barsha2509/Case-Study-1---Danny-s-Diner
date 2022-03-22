CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
------ 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id,SUM(price) AS "Total Amount"
FROM menu AS M
JOIN sales AS S
ON M.product_id=S.product_id
GROUP BY customer_id
ORDER BY customer_id;

------ 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(order_date)
FROM sales
GROUP BY customer_id
ORDER BY customer_id;

------ 3. What was the first item from the menu purchased by each customer?
WITH CTE_sm AS(
SELECT customer_id, product_name,order_date,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date)
FROM menu AS M
JOIN sales AS S
ON M.product_id=S.product_id
ORDER BY customer_id)
SELECT customer_id, product_name,order_date
FROM CTE_sm
WHERE row_number=1
;

------ 4. What is the most purchased item on the menu and how many times was it
------purchased by all customers?
SELECT product_name,COUNT(order_date) AS "No. of times order placed"
FROM menu AS M
JOIN sales AS S
ON M.product_id=S.product_id
GROUP by product_name
ORDER BY "No. of times order placed" DESC;

-- 5. Which item was the most popular for each customer?
WITH CTE AS(
SELECT customer_id,product_name,COUNT(order_date) AS "No. of times order placed"
FROM menu AS M
JOIN sales AS S
ON M.product_id=S.product_id
GROUP by customer_id,product_name 
ORDER BY customer_id,"No. of times order placed" DESC
),CTE_most_popular AS (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id)
	FROM CTE							 
)
SELECT customer_id, product_name, "No. of times order placed"
FROM CTE_most_popular
WHERE row_number=1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE_first AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY s.customer_id) FROM sales AS s
JOIN menu AS M
ON M.product_id=s.product_id
WHERE order_date > any(
SELECT join_date FROM members)
ORDER BY customer_id,order_date)
SELECT customer_id, product_name FROM CTE_first 
WHERE row_number=1;

-- 7. Which item was purchased just before the customer became a member?
with CTE AS(
SELECT s.customer_id, 
S.product_id, product_name,
price, order_date,ROW_NUMBER() OVER (PARTITION BY s.customer_id)
FROM menu AS M
JOIN sales AS S
ON M.product_id=S.product_id
JOIN members AS MM
ON MM.customer_id=s.customer_id
WHERE order_date < all(
	SELECT join_date FROM members
	)),
CTE_2 AS(
SELECT customer_id,product_id, product_name,order_date, price,
LAST_VALUE(order_date) OVER(PARTITION BY customer_id) 
FROM CTE ),
CTE_3 AS(
SELECT * FROM CTE_2
WHERE customer_id ='A' OR customer_id ='B' AND order_date!= '2021-01-01' AND order_date!= '2021-01-02'
	)SELECT customer_id, 
COUNT(product_id) AS "total items", 
SUM(price) AS "total amount spent"
FROM CTE_3
GROUP BY customer_id
ORDER BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
with CTE AS(
SELECT s.customer_id, 
S.product_id, product_name,
price, order_date,ROW_NUMBER() OVER (PARTITION BY s.customer_id)
FROM menu AS M
JOIN sales AS S
ON M.product_id=S.product_id
JOIN members AS MM
ON MM.customer_id=s.customer_id
WHERE order_date < all(
	SELECT join_date FROM members
	))
SELECT customer_id, 
COUNT(product_id) AS "total items", 
SUM(price) AS "total amount spent"
FROM CTE
GROUP BY customer_id
ORDER BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, 
COUNT(S.product_id) AS "total items", 
SUM(price) AS "total amount spent", product_name
FROM menu AS M
JOIN sales AS S
ON M.product_id=S.product_id
GROUP BY customer_id,product_name
ORDER BY customer_id;

----Customer_id A-(Points excluding sushi): 30+36=66*10=660
----								sushi :2*10=20
----						 Total points : 660+20=680

----Customer_id B-(Points excluding sushi): 30+24=54*10=540
----								sushi :2*20=40
----						 Total points : 660+20=580

----Customer_id C-( Total points )		  : 36=36*10=360

------ 10. In the first week after a customer joins the program (including their 
------join date) they earn 2x points on all items, not just sushi - how many points 
------do customer A and B have at the end of January?
SELECT customer_id, 
COUNT(S.product_id) AS "total items", 
SUM(price) AS "total amount spent"
FROM menu AS M
JOIN sales AS S
ON M.product_id=S.product_id
WHERE order_date BETWEEN '2020-12-31' AND '2021-01-08'
GROUP BY customer_id
ORDER BY customer_id; 
 
------Customer_id A (points)- 40*2=80
------Customer_id B (points)- 40*2=80
------Customer_id C (points)- 36*2=72

------Points for the rest of January
SELECT customer_id, product_name,
COUNT(S.product_id) AS "total items", 
SUM(price) AS "total amount spent"
FROM menu AS M
JOIN sales AS S
ON M.product_id=S.product_id
WHERE order_date BETWEEN '2021-01-08' AND '2021-02-01'
GROUP BY customer_id,product_name
ORDER BY customer_id; 
 
 ----Customer_id A-(Total points excluding sushi): 36*10=360
----								
----Customer_id B-(Points excluding sushi): 24*10=240
----								sushi :2*10=20
----						 Total points : 240+20=260

----------------------------Total points by the end of January-------------------------
------- Customer A : 80(1st week)+240=320
------- Customer B : 80(1st week)+260=340

------Bonus Questions
-------1.Join All The Things
SELECT s.customer_id, 
order_date, 
product_name,
price, 
CASE
	WHEN join_date=order_date THEN 'Y'
	WHEN join_date<order_date THEN 'Y'
	WHEN join_date!=order_date THEN 'N'
	WHEN join_date IS NULL THEN 'N'
END member
FROM menu AS M
FULL JOIN sales AS S
ON M.product_id=S.product_id
FULL JOIN members AS MM
ON MM.customer_id=s.customer_id
ORDER BY customer_id, order_date;

------2.Rank All The Things
create view v AS(
SELECT s.customer_id, 
order_date, 
product_name,
price, 
CASE
	WHEN join_date=order_date THEN 'Y'
	WHEN join_date<order_date THEN 'Y'
	WHEN join_date!=order_date THEN 'N'
	WHEN join_date IS NULL THEN 'N'
END member
FROM menu AS M
FULL JOIN sales AS S
ON M.product_id=S.product_id
FULL JOIN members AS MM
ON MM.customer_id=s.customer_id
ORDER BY customer_id, order_date
	);

WITH CTE AS(
SELECT *, 
CASE
	WHEN member='N' THEN 0
	WHEN member='Y' THEN ROW_NUMBER() OVER (PARTITION BY customer_id, member)
END Ranking
FROM v
ORDER BY customer_id, order_date)
SELECT customer_id, 
order_date, 
product_name,
price, 
member,
CASE
	WHEN ranking::VARCHAR='0' THEN 'null'
	ELSE ranking::VARCHAR
END
FROM CTE;
