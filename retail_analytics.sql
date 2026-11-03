-- Retail Inventory & Sales Analytics | MySQL 8.0+
-- Grain: one row per product line within an order.
CREATE DATABASE IF NOT EXISTS retail_analytics;
USE retail_analytics;

DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS stores;

CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    city VARCHAR(60) NOT NULL,
    region VARCHAR(30) NOT NULL
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(120) NOT NULL,
    category VARCHAR(60) NOT NULL,
    unit_cost DECIMAL(12,2) NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    is_seasonal TINYINT(1) NOT NULL DEFAULT 0,
    CHECK (unit_cost >= 0),
    CHECK (unit_price >= 0)
);

CREATE TABLE sales (
    sales_line_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    order_date DATE NOT NULL,
    product_id INT NOT NULL,
    store_id INT NOT NULL,
    quantity_sold INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    discount_pct DECIMAL(5,4) NOT NULL DEFAULT 0,
    sales_amount DECIMAL(14,2) NOT NULL,
    cost_amount DECIMAL(14,2) NOT NULL,
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT fk_sales_store FOREIGN KEY (store_id) REFERENCES stores(store_id),
    CHECK (quantity_sold > 0),
    CHECK (discount_pct >= 0 AND discount_pct <= 1)
);

CREATE TABLE inventory (
    product_id INT NOT NULL,
    store_id INT NOT NULL,
    stock_quantity INT NOT NULL,
    reorder_level INT NOT NULL,
    snapshot_date DATE NOT NULL,
    PRIMARY KEY (product_id, store_id, snapshot_date),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    CHECK (stock_quantity >= 0),
    CHECK (reorder_level >= 0)
);

-- Import CSVs after creating tables:
-- MySQL Workbench: right-click table > Table Data Import Wizard.
-- Import order: stores, products, sales, inventory.
-- For sales, sales_line_id is AUTO_INCREMENT; import remaining columns only.

-- 1. Data quality checks
SELECT COUNT(*) AS sales_lines, COUNT(DISTINCT order_id) AS orders FROM sales;
SELECT product_id, COUNT(*) AS duplicate_count
FROM products GROUP BY product_id HAVING COUNT(*) > 1;
SELECT * FROM sales WHERE quantity_sold <= 0 OR sales_amount < 0 OR cost_amount < 0;
SELECT * FROM inventory WHERE stock_quantity < 0 OR reorder_level < 0;

-- 2. Executive KPIs
SELECT
    ROUND(SUM(sales_amount),2) AS total_revenue,
    SUM(quantity_sold) AS units_sold,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales_amount-cost_amount),2) AS gross_profit,
    ROUND(100*SUM(sales_amount-cost_amount)/NULLIF(SUM(sales_amount),0),2) AS gross_margin_pct
FROM sales;

-- 3. Monthly revenue and profit
SELECT DATE_FORMAT(order_date,'%Y-%m') AS sales_month,
       ROUND(SUM(sales_amount),2) AS revenue,
       ROUND(SUM(sales_amount-cost_amount),2) AS gross_profit,
       SUM(quantity_sold) AS units_sold
FROM sales
GROUP BY DATE_FORMAT(order_date,'%Y-%m')
ORDER BY sales_month;

-- 4. Category performance
SELECT p.category, ROUND(SUM(s.sales_amount),2) AS revenue,
       SUM(s.quantity_sold) AS units_sold,
       ROUND(SUM(s.sales_amount-s.cost_amount),2) AS gross_profit
FROM sales s JOIN products p ON s.product_id=p.product_id
GROUP BY p.category ORDER BY revenue DESC;

-- 5. Top 10 products by revenue
SELECT p.product_id,p.product_name,p.category,
       SUM(s.quantity_sold) AS units_sold,
       ROUND(SUM(s.sales_amount),2) AS revenue
FROM sales s JOIN products p ON s.product_id=p.product_id
GROUP BY p.product_id,p.product_name,p.category
ORDER BY revenue DESC LIMIT 10;

-- 6. Low-stock items (at or below reorder point)
SELECT st.store_name,p.product_name,p.category,
       i.stock_quantity,i.reorder_level,
       (i.reorder_level-i.stock_quantity) AS units_below_reorder
FROM inventory i
JOIN products p ON i.product_id=p.product_id
JOIN stores st ON i.store_id=st.store_id
WHERE i.stock_quantity <= i.reorder_level
ORDER BY units_below_reorder DESC;

-- 7. Overstock: more than 8 months of cover using trailing 3-month demand
WITH demand AS (
    SELECT product_id,store_id,SUM(quantity_sold)/3.0 AS avg_monthly_units
    FROM sales
    WHERE order_date >= '2025-10-01' AND order_date < '2026-01-01'
    GROUP BY product_id,store_id
)
SELECT st.store_name,p.product_name,i.stock_quantity,
       ROUND(COALESCE(d.avg_monthly_units,0),2) AS avg_monthly_units,
       CASE WHEN COALESCE(d.avg_monthly_units,0)=0 THEN NULL
            ELSE ROUND(i.stock_quantity/d.avg_monthly_units,1) END AS months_of_cover
FROM inventory i
JOIN products p ON i.product_id=p.product_id
JOIN stores st ON i.store_id=st.store_id
LEFT JOIN demand d ON i.product_id=d.product_id AND i.store_id=d.store_id
WHERE COALESCE(d.avg_monthly_units,0)>0
  AND i.stock_quantity/d.avg_monthly_units > 8
ORDER BY months_of_cover DESC;

-- 8. Slow-moving products: lowest sales volume over the full year
SELECT p.product_id,p.product_name,p.category,
       COALESCE(SUM(s.quantity_sold),0) AS units_sold,
       COALESCE(ROUND(SUM(s.sales_amount),2),0) AS revenue
FROM products p LEFT JOIN sales s ON p.product_id=s.product_id
GROUP BY p.product_id,p.product_name,p.category
ORDER BY units_sold ASC LIMIT 15;

-- 9. Store comparison
SELECT st.store_name,st.city,
       ROUND(SUM(s.sales_amount),2) AS revenue,
       SUM(s.quantity_sold) AS units_sold,
       COUNT(DISTINCT s.order_id) AS orders,
       ROUND(SUM(s.sales_amount)/COUNT(DISTINCT s.order_id),2) AS avg_order_value
FROM sales s JOIN stores st ON s.store_id=st.store_id
GROUP BY st.store_id,st.store_name,st.city ORDER BY revenue DESC;

-- 10. Reorder recommendation: suggested quantity = 2 months of recent demand minus on-hand
WITH recent_demand AS (
    SELECT product_id,store_id,SUM(quantity_sold)/3.0 AS avg_monthly_units
    FROM sales
    WHERE order_date >= '2025-10-01' AND order_date < '2026-01-01'
    GROUP BY product_id,store_id
)
SELECT st.store_name,p.product_name,i.stock_quantity,
       ROUND(COALESCE(rd.avg_monthly_units,0),1) AS avg_monthly_units,
       GREATEST(0,CEIL(2*COALESCE(rd.avg_monthly_units,0)-i.stock_quantity)) AS suggested_reorder_qty
FROM inventory i
JOIN products p ON i.product_id=p.product_id
JOIN stores st ON i.store_id=st.store_id
LEFT JOIN recent_demand rd ON i.product_id=rd.product_id AND i.store_id=rd.store_id
WHERE i.stock_quantity <= i.reorder_level
ORDER BY suggested_reorder_qty DESC;

-- 11. Inventory value by category
SELECT p.category,
       ROUND(SUM(i.stock_quantity*p.unit_cost),2) AS inventory_cost_value,
       SUM(i.stock_quantity) AS units_on_hand
FROM inventory i JOIN products p ON i.product_id=p.product_id
GROUP BY p.category ORDER BY inventory_cost_value DESC;

-- 12. Discount effectiveness
SELECT CASE WHEN discount_pct=0 THEN 'No discount'
            WHEN discount_pct<=0.05 THEN '0-5%'
            WHEN discount_pct<=0.10 THEN '5-10%'
            ELSE '10%+' END AS discount_band,
       COUNT(*) AS sales_lines,
       ROUND(SUM(sales_amount),2) AS revenue,
       ROUND(SUM(sales_amount-cost_amount),2) AS gross_profit
FROM sales GROUP BY discount_band ORDER BY discount_band;
