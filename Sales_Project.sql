-- use sales database

use sales;


-- Find total_orders, customers, products  

select
(select count(order_id) from orders) As Total_orders,
(select count(customer_id) from customers) As Total_customers,
(select count(product_id) from products) As Total_products;


-- most frequant ordered products

SELECT 
    p.product_name,
    SUM(oi.quantity) AS total_ordered
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_ordered DESC
LIMIT 5;


-- Average ordered value.
WITH order_values AS (
    SELECT 
        o.order_id,
        SUM(p.unit_price * oi.quantity * (1 - oi.discount)) AS order_total
    FROM Orders o
    JOIN Order_Items oi ON o.order_id = oi.order_id 
    JOIN Products p ON oi.product_id = p.product_id
    GROUP BY o.order_id
)
SELECT 
    ROUND(AVG(order_total), 2) AS average_order_value
FROM order_values;


-- revenue over time(monthly/yearly).
SELECT 
    YEAR(o.order_date) AS year,
    ROUND(SUM((p.unit_price * oi.quantity) * (1 - oi.discount)), 2) AS revenue
FROM Orders o
JOIN Order_Items oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
GROUP BY YEAR(o.order_date)
ORDER BY year;


-- top 5 state by revenue.
SELECT
    c.state, 
    ROUND(SUM(p.unit_price * oi.quantity * (1 - oi.discount)), 2) AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.state
ORDER BY total_revenue DESC
LIMIT 5;


-- Gender wise spending distribution.
SELECT 
    c.gender,
    ROUND(SUM(p.unit_price * oi.quantity * (1 - oi.discount)), 2) AS total_spending
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.gender;


-- New  vs returning customers monthly.
WITH first_orders AS (
    SELECT customer_id, MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY customer_id
),
monthly_orders AS (
    SELECT 
        o.customer_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        CASE 
            WHEN o.order_date = fo.first_order_date THEN 'New'
            ELSE 'Returning'
        END AS customer_type
    FROM orders o
    JOIN first_orders fo ON o.customer_id = fo.customer_id
)
SELECT 
    order_month,
    customer_type,
    COUNT(DISTINCT customer_id) AS customer_count
FROM monthly_orders
GROUP BY order_month, customer_type
ORDER BY order_month, customer_type;


-- Top 10 cutomers by lifetime value.
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    ROUND(SUM(p.unit_price * oi.quantity * (1 - oi.discount)), 2) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY lifetime_value DESC
LIMIT 10;


-- churn prediction using the last order date.
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_order,
    CASE 
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) > 90 THEN 'Churned'
        ELSE 'Active'
    END AS churn_status
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY days_since_last_order DESC;


-- Top 10 Products by Quantity Sold
select
p.product_id,
p.product_name,
sum(oi.quantity) as total_quantity_sold
from order_items oi
join products p on oi.product_id = p.product_id
group by p.product_id, p.product_name
order by total_quantity_sold desc
limit 10;


-- Underperforming Products
SELECT
    p.product_id,
    p.product_name,
    p.category,
    COALESCE(SUM(oi.quantity), 0) AS total_quantity_sold,
    oi.quantity
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, oi.quantity
HAVING total_quantity_sold < 50 AND oi.quantity > 100
ORDER BY total_quantity_sold ASC, oi.quantity DESC;


-- Average Shipping Time
SELECT 
    ROUND(AVG(DATEDIFF(shipping_date, order_date)), 2) AS avg_shipping_time_days
FROM Orders
WHERE shippingdate IS NOT NULL;
