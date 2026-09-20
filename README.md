# E-Commerce Analytics: SQL + Power BI Project

## 📌 Overview
End-to-end analytics project built on real-world e-commerce transaction data. The project simulates a business analyst role at an online marketplace: designing the database schema, writing SQL queries to answer business questions, optimizing performance, and presenting the results in an interactive Power BI dashboard.

## 🗂️ Dataset
[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)
- ~100,000 orders across 9 relational tables
- Covers customers, orders, order items, products, sellers, payments, reviews, and geolocation

## 🛠️ Tech Stack
- **Database:** PostgreSQL
- **SQL techniques:** CTEs, Window Functions (NTILE, RANK), Subqueries, Multi-table JOINs, Query Optimization (EXPLAIN ANALYZE, Indexing)
- **Visualization:** Power BI (multi-page dashboard with page navigation)

## 🗄️ Database Schema
9 normalized tables connected via foreign keys (customers → orders → order_items → products/sellers, plus payments and reviews).

![ER Diagram](er_diagram.png)

## 🔍 Business Questions & Key Insights

| # | Business Question | Key Insight |
|---|---|---|
| 1 | Monthly revenue trend? | Revenue shows clear growth pattern with seasonal spikes |
| 2 | Top revenue-generating products? | `health_beauty` category leads; mix of high-price/low-volume and low-price/high-volume products |
| 3 | Which states spend more per order? | PB (Paraíba) has highest AOV (R$216.67) despite lower order volume than PA |
| 4 | How to segment customers (RFM)? | Identified Champions, Loyal, At Risk, and Lost segments for targeted marketing |
| 5 | Do customers return after first purchase? | **Retention is very weak**: most customers are one-time buyers |
| 6 | Who are the highest lifetime-value customers? | Top repeat customers contribute disproportionately, making them candidates for VIP programs |
| 7 | Does late delivery affect reviews? | **Major finding:** On-time avg rating = 4.29 vs Late delivery avg rating = 2.57 |

## ⚡ Query Optimization
Added indexes on `orders.customer_id` and `order_items.order_id` to speed up frequent JOINs.
- **Before:** 864 ms execution time
- **After:** 742 ms execution time (**~14% faster**)

*(Insert before/after EXPLAIN ANALYZE screenshots here)*

## 📊 Power BI Dashboard
Interactive 5-page dashboard built on top of the SQL analysis, with a vertical page navigator sidebar for easy switching between pages.

| Page | What it shows |
|---|---|
| **1. Sales Overview** | Revenue trend, top products, key KPIs |
| **2. Geography** | Orders and revenue by state, AOV comparison |
| **3. RFM Segmentation** | Customer segments (Champions, Loyal, At Risk, Lost) |
| **4. Retention & CLV** | Cohort retention and customer lifetime value |
| **5. Delivery & Reviews** | Impact of delivery delays on review scores |

### Screenshots
![Sales Overview](dashboard/page1_sales_overview.png)
![Geography](dashboard/page2_geography.png)
![RFM Segmentation](dashboard/page3_rfm_segmentation.png)
![Retention & CLV](dashboard/page4_retention_clv.png)
![Delivery & Reviews](dashboard/page5_delivery_reviews.png)

🎥 **Demo video:** *(add YouTube/Loom link here)*

## 📁 Files in this Repo
- `ecommerce_analysis.sql`: Full schema, indexes, and all 7 business queries with comments
- `ecommerce_dashboard.pbix`: Power BI dashboard file
- `dashboard/`: Dashboard page screenshots
- `er_diagram.png`: Database schema diagram
- `README.md`: This file

## 🚀 How to Run
1. Download the Olist dataset from Kaggle
2. Create a PostgreSQL database
3. Run the schema section of `ecommerce_analysis.sql` to create tables
4. Import each CSV into its corresponding table
5. Run the queries in the same file to reproduce the analysis
6. Open `ecommerce_dashboard.pbix` in Power BI Desktop to explore the dashboard

## 👤 Author
*(Your name, LinkedIn, GitHub links here)*
