-- Active: 1790801754508@@localhost@5432@superstore


SELECT COUNT(*) FROM (
    SELECT ROW_NUMBER() OVER (
               PARTITION BY c.customer_id
               ORDER BY o.order_date DESC
           ) AS rn
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
) t
WHERE rn <= 2;


WITH customer_profits AS (
    SELECT
        c.region,
        c.customer_id,
        c.customer_name,
        SUM(o.profit) AS total_profit
    FROM customers c
    JOIN orders o
        ON o.customer_id = c.customer_id
    GROUP BY c.region, c.customer_id, c.customer_name
)
SELECT
    region,
    customer_name,
    total_profit,
    RANK() OVER (
        PARTITION BY region
        ORDER BY total_profit DESC
    ) AS profit_rank,
    DENSE_RANK() OVER (
        PARTITION BY region
        ORDER BY total_profit DESC
    ) AS profit_dense_rank
FROM customer_profits
ORDER BY region, profit_rank, customer_name;


SELECT * FROM (
    SELECT customer_name, total_sales,
           NTILE(4) OVER (ORDER BY total_sales DESC) AS quartile
    FROM (
        SELECT c.customer_name, SUM(o.sales) AS total_sales
        FROM customers c
        JOIN orders o ON o.customer_id = c.customer_id
        GROUP BY c.customer_id, c.customer_name
    ) t
) q
WHERE customer_name = 'Customer_26';


SELECT
    month,
    monthly_sales,
    LAG(monthly_sales, 1)  OVER (ORDER BY month) AS prev_month_sales,
    LEAD(monthly_sales, 1) OVER (ORDER BY month) AS next_month_sales
FROM (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS monthly_sales
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
) t
ORDER BY month;


WITH product_totals AS (
    SELECT
        p.category,
        p.product_name,
        SUM(o.sales) AS product_sales
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
    GROUP BY p.category, p.product_name
)
SELECT
    category,
    product_name,
    product_sales,
    SUM(product_sales) OVER (PARTITION BY category) AS category_total,
    ROUND(
        product_sales * 100.0 /
        SUM(product_sales) OVER (PARTITION BY category),
        2
    ) AS pct_of_category
FROM product_totals
ORDER BY category, pct_of_category DESC;