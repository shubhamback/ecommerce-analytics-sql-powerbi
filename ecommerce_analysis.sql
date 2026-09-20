69ooooooo9i8-- ============================================================
-- E-COMMERCE ANALYTICS SQL PROJECT
-- Dataset: Olist Brazilian E-Commerce (Kaggle)
-- Database: PostgreSQL
-- ============================================================

-- ============================================================
-- SECTION 1: DATABASE SCHEMA
-- ============================================================

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght NUMERIC,
    product_description_lenght NUMERIC,
    product_photos_qty NUMERIC,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INTEGER,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INTEGER,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC,
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat NUMERIC,
    geolocation_lng NUMERIC,
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5)
);


-- ============================================================
-- SECTION 2: PERFORMANCE INDEXES
-- ============================================================
-- Added to speed up JOINs between orders and order_items on
-- customer_id / order_id. Improved avg-order-value query
-- execution time from 864ms to 742ms (~14% faster).

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);


-- ============================================================
-- SECTION 3: BUSINESS ANALYSIS QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- Query 1: Monthly Revenue Trend
-- Business Question: Kaunse mahine me sabse zyada revenue aaya,
-- aur growth trend kya hai?
-- ------------------------------------------------------------
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price)::numeric, 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY month;


-- ------------------------------------------------------------
-- Query 2: Top 10 Products by Revenue
-- Business Question: Kaunse products/categories sabse zyada
-- revenue generate kar rahe hain?
-- ------------------------------------------------------------
SELECT 
    p.product_id,
    pt.product_category_name_english AS category,
    ROUND(SUM(oi.price)::numeric, 2) AS total_revenue,
    COUNT(oi.order_id) AS times_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pt 
    ON p.product_category_name = pt.product_category_name
GROUP BY p.product_id, pt.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- Query 3: Average Order Value by State
-- Business Question: Kaunse states ke customers zyada spend
-- karte hain, taaki regional marketing target ho sake?
-- ------------------------------------------------------------
SELECT 
    c.customer_state,
    ROUND(AVG(order_total)::numeric, 2) AS avg_order_value,
    COUNT(*) AS total_orders
FROM (
    SELECT o.order_id, o.customer_id, SUM(oi.price) AS order_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
) sub
JOIN customers c ON sub.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_order_value DESC;


-- ------------------------------------------------------------
-- Query 4: RFM Customer Segmentation
-- Business Question: Customers ko kaise segment karein
-- (Champions, Loyal, At Risk, Lost) taaki targeted marketing
-- ho sake?
-- ------------------------------------------------------------
WITH customer_rfm AS (
    SELECT 
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT 
        customer_unique_id,
        last_order_date,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY last_order_date DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
    FROM customer_rfm
)
SELECT 
    customer_unique_id,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score + frequency_score + monetary_score) AS total_rfm_score,
    CASE 
        WHEN (recency_score + frequency_score + monetary_score) >= 12 THEN 'Champions'
        WHEN (recency_score + frequency_score + monetary_score) >= 9 THEN 'Loyal Customers'
        WHEN (recency_score + frequency_score + monetary_score) >= 6 THEN 'At Risk'
        ELSE 'Lost Customers'
    END AS customer_segment
FROM rfm_scores
ORDER BY total_rfm_score DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Query 5: Cohort Retention Analysis
-- Business Question: Customers apne first purchase ke baad
-- kitne % return karke dobara order karte hain?
-- ------------------------------------------------------------
WITH first_purchase AS (
    SELECT 
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_orders AS (
    SELECT 
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
)
SELECT 
    fp.cohort_month,
    EXTRACT(MONTH FROM AGE(co.order_month, fp.cohort_month)) AS months_since_first_purchase,
    COUNT(DISTINCT co.customer_unique_id) AS active_customers
FROM first_purchase fp
JOIN customer_orders co ON fp.customer_unique_id = co.customer_unique_id
GROUP BY fp.cohort_month, months_since_first_purchase
ORDER BY fp.cohort_month, months_since_first_purchase;


-- ------------------------------------------------------------
-- Query 6: Customer Lifetime Value (CLV)
-- Business Question: Kaunse repeat customers sabse zyada
-- lifetime value la rahe hain, jinhe VIP treatment milna chahiye?
-- ------------------------------------------------------------
SELECT 
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price)::numeric, 2) AS total_spent,
    ROUND((SUM(oi.price) / COUNT(DISTINCT o.order_id))::numeric, 2) AS avg_order_value,
    MIN(o.order_purchase_timestamp) AS first_purchase,
    MAX(o.order_purchase_timestamp) AS last_purchase
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY total_spent DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Query 7: Delivery Delay Impact on Review Score
-- Business Question: Kya late delivery customer satisfaction
-- (review score) ko affect karti hai?
-- Result: On-time avg rating = 4.29 | Late avg rating = 2.57
-- ------------------------------------------------------------
SELECT 
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late Delivery'
        ELSE 'On Time Delivery'
    END AS delivery_status,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_review_score,
    COUNT(*) AS total_orders
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;


-- ============================================================
-- SECTION 4: OPTIMIZATION PROOF (Before / After)
-- ============================================================
-- Run this with EXPLAIN ANALYZE before and after creating the
-- indexes in Section 2 to reproduce the performance comparison:
-- Before indexes: Execution Time ~ 864 ms
-- After indexes:  Execution Time ~ 742 ms  (~14% faster)

EXPLAIN ANALYZE
SELECT 
    c.customer_state,
    ROUND(AVG(order_total)::numeric, 2) AS avg_order_value,
    COUNT(*) AS total_orders
FROM (
    SELECT o.order_id, o.customer_id, SUM(oi.price) AS order_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
) sub
JOIN customers c ON sub.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_order_value DESC;
