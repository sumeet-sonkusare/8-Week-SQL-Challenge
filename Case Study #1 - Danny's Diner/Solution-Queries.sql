

---/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

**Query #1**

    SELECT 
    	customer_id AS Customer, SUM(price) AS Amount_Spent
    FROM sales
    JOIN menu
    ON sales.product_id = menu.product_id
    GROUP BY customer_id;

| customer | amount_spent |
| -------- | ------------ |
| B        | 74           |
| C        | 36           |
| A        | 76           |

---
**Query #2**

    SELECT 
    	customer_id AS Customer, COUNT(DISTINCT(order_date)) AS Visits
    FROM sales
    GROUP BY customer_id
    ORDER BY 2 DESC;

| customer | visits |
| -------- | ------ |
| B        | 6      |
| A        | 4      |
| C        | 2      |

---
**Query #3**

    WITH temp_table AS(                                         
    SELECT 
    	customer_id , product_name, order_date,
       RANK()OVER(PARTITION BY customer_id ORDER BY order_date)AS Rank                                 
    FROM sales
    JOIN menu
    ON sales.product_id = menu.product_id)
    SELECT
          customer_id, product_name
    FROM temp_table
    WHERE Rank = 1;

| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |
| C           | ramen        |

---
**Query #4**

    SELECT
    	product_name, COUNT(sales.product_id)
    FROM
    	sales
    JOIN
    	menu
    ON
    	sales.product_id = menu.product_id
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 1;

| product_name | count |
| ------------ | ----- |
| ramen        | 8     |

---
**Query #5**

    WITH temp_table AS (
    SELECT customer_id, product_id, COUNT(product_id) AS prod_by_cust
    FROM sales
    GROUP BY 1,2
    ORDER BY customer_id,product_id DESC)
    SELECT customer_id, product_name                                       
    FROM(     
    SELECT customer_id, product_name, RANK()OVER(PARTITION BY customer_id ORDER BY prod_by_cust DESC) AS Rank
    FROM temp_table
    JOIN menu
    ON temp_table.product_id = menu.product_id) AS ranked
    WHERE Rank =1;

| customer_id | product_name |
| ----------- | ------------ |
| A           | ramen        |
| B           | curry        |
| B           | sushi        |
| B           | ramen        |
| C           | ramen        |

---
**Query #6**

    SELECT customer_id, product_name
     FROM(
     SELECT sales.customer_id, order_date, product_id, join_date,
     RANK()OVER(PARTITION BY sales.customer_id ORDER BY order_date) AS rank
     FROM sales
     JOIN members
     ON sales.customer_id = members.customer_id
     WHERE order_date >= join_date) AS cus_join
     JOIN menu
     ON menu.product_id = cus_join.product_id
     WHERE rank =1
     ORDER BY customer_id;

| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| B           | sushi        |

---
**Query #7**

    WITH temp_table AS(
    SELECT sales.customer_id, order_date, product_id, join_date, RANK()OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC) AS Rank
    FROM sales
    JOIN members
    ON sales.customer_id = members.customer_id
    WHERE order_date < join_date)
    SELECT customer_id, product_name
    FROM temp_table
    JOIN menu
    ON temp_table.product_id = menu.product_id
    WHERE Rank = 1
    ORDER BY customer_id;

| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| A           | curry        |
| B           | sushi        |

---
**Query #8**

    SELECT sales.customer_id AS Customer, COUNT(sales.product_id) AS Total_Product, SUM(price) AS Total_Spent
    FROM sales
    JOIN menu
    ON sales.product_id = menu.product_id
    JOIN members
    ON sales.customer_id = members.customer_id
    WHERE order_date<join_date
    GROUP BY 1
    ORDER BY 1;

| customer | total_product | total_spent |
| -------- | ------------- | ----------- |
| A        | 2             | 25          |
| B        | 3             | 40          |

---
**Query #9**

    WITH temp_table AS (
    SELECT customer_id, 
    CASE
    WHEN product_name = 'sushi' THEN price*10*2
    ELSE price*10
    END AS points
    FROM sales
    JOIN menu
    ON sales.product_id = menu.product_id)
    SELECT customer_id, SUM(points)                                         FROM  temp_table
    GROUP BY 1
    ORDER BY 1;

| customer_id | sum |
| ----------- | --- |
| A           | 860 |
| B           | 940 |
| C           | 360 |

---
**Query #10**

    SELECT customer_id, SUM(points)
    FROM(
    SELECT sales.customer_id, price*10*2 AS points
    FROM sales
    JOIN menu
    ON sales.product_id = menu.product_id
    JOIN members
    ON sales.customer_id = members.customer_id
      WHERE order_date>=join_date AND order_date<'2021-02-01'
    ) AS join_before
    GROUP BY customer_id;

| customer_id | sum  |
| ----------- | ---- |
| B           | 440  |
| A           | 1020 |

---
**Query #11**

    SELECT sales.customer_id, order_date, product_name,price,
    CASE
    WHEN order_date>=join_date THEN 'Y'
    ELSE 'N'
    END AS member
    FROM sales
    JOIN menu
    ON sales.product_id = menu.product_id
    LEFT JOIN members
    ON sales.customer_id = members.customer_id
    ORDER BY customer_id, order_date;

| customer_id | order_date               | product_name | price | member |
| ----------- | ------------------------ | ------------ | ----- | ------ |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N      |

---
**Query #12**

    SELECT *, 
    CASE 
    WHEN member = 'Y' THEN RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
    ELSE NULL
    END AS ranking
    FROM (SELECT sales.customer_id, order_date, product_name,price,
    CASE
    WHEN order_date<join_date THEN 'N'
    ELSE 'Y'
    END AS member
    FROM sales
    JOIN menu
    ON sales.product_id = menu.product_id
    LEFT JOIN members
    ON sales.customer_id = members.customer_id
    ORDER BY customer_id, order_date) AS Rank_all;

| customer_id | order_date               | product_name | price | member | ranking |
| ----------- | ------------------------ | ------------ | ----- | ------ | ------- |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |         |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      | 1       |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |         |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | Y      | 1       |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | Y      | 1       |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | Y      | 3       |

