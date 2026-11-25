CREATE SCHEMA IF NOT EXISTS gold;

CREATE TABLE IF NOT EXISTS gold.dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day INT NOT NULL,
    month INT NOT NULL,
    year INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    week INT NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    quarter INT NOT NULL
);

CREATE TABLE IF NOT EXISTS gold.dim_customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL,
    contact_name VARCHAR(50),
    address VARCHAR(50),
    city VARCHAR(20),
    postal_code VARCHAR(10),
    country VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS gold.dim_employee (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(15) NOT NULL,
    last_name VARCHAR(15) NOT NULL,
    birth_date DATE
);

CREATE TABLE IF NOT EXISTS gold.dim_shipper (
    shipper_id INT PRIMARY KEY,
    shipper_name VARCHAR(25) NOT NULL,
    phone VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS gold.dim_category (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(25) NOT NULL,
    description VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS gold.dim_supplier (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(50) NOT NULL,
    contact_name VARCHAR(50),
    address VARCHAR(50),
    city VARCHAR(20),
    postal_code VARCHAR(10),
    country VARCHAR(15),
    phone VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS gold.dim_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL,
    unit VARCHAR(25),
    price NUMERIC(10,2) NOT NULL,
    category_id INT NOT NULL REFERENCES gold.dim_category (category_id),
    supplier_id INT NOT NULL REFERENCES gold.dim_supplier (supplier_id)
);

CREATE TABLE IF NOT EXISTS gold.fact_order_detail (
    order_detail_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    customer_id INT NOT NULL REFERENCES gold.dim_customer (customer_id),
    employee_id INT NOT NULL REFERENCES gold.dim_employee (employee_id),
    shipper_id INT NOT NULL REFERENCES gold.dim_shipper (shipper_id),
    product_id INT NOT NULL REFERENCES gold.dim_product (product_id),
    date_id INT NOT NULL REFERENCES gold.dim_date (date_id)
);

CREATE INDEX IF NOT EXISTS idx_fact_order_detail_customer_id ON gold.fact_order_detail(customer_id);
CREATE INDEX IF NOT EXISTS idx_fact_order_detail_employee_id ON gold.fact_order_detail(employee_id);
CREATE INDEX IF NOT EXISTS idx_fact_order_detail_shipper_id ON gold.fact_order_detail(shipper_id);
CREATE INDEX IF NOT EXISTS idx_fact_order_detail_product_id ON gold.fact_order_detail(product_id);
CREATE INDEX IF NOT EXISTS idx_fact_order_detail_date_id ON gold.fact_order_detail(date_id);
CREATE INDEX IF NOT EXISTS idx_dim_product_category_id ON gold.dim_product(category_id);
CREATE INDEX IF NOT EXISTS idx_dim_product_supplier_id ON gold.dim_product(supplier_id);

BEGIN;

TRUNCATE gold.fact_order_detail, gold.dim_product, gold.dim_category, gold.dim_supplier,
         gold.dim_customer, gold.dim_employee, gold.dim_shipper, gold.dim_date;

INSERT INTO gold.dim_date (date_id, full_date, day, month, year, day_of_week, day_name, week, month_name, quarter)
    SELECT
        TO_CHAR(d, 'YYYYMMDD')::INT AS date_id,
        d AS full_date,
        EXTRACT(day FROM d)::INT AS day,
        EXTRACT(month FROM d)::INT AS month,
        EXTRACT(year FROM d)::INT AS year,
        EXTRACT(isodow FROM d)::INT AS day_of_week,
        TRIM(TO_CHAR(d, 'Day')) AS day_name,
        EXTRACT(week FROM d)::INT AS week,
        TRIM(TO_CHAR(d, 'Month')) AS month_name,
        EXTRACT(quarter FROM d)::INT AS quarter
    FROM GENERATE_SERIES(
        (SELECT MIN(order_date)::DATE FROM silver.stg_orders),
        (SELECT MAX(order_date)::DATE FROM silver.stg_orders),
        INTERVAL '1 day'
    ) AS gs(d);

INSERT INTO gold.dim_customer (customer_id, customer_name, contact_name, address, city, postal_code, country)
    SELECT customer_id, customer_name, contact_name, address, city, postal_code, country
    FROM silver.stg_customers
    ORDER BY customer_id;

INSERT INTO gold.dim_employee (employee_id, first_name, last_name, birth_date)
    SELECT employee_id, first_name, last_name, birth_date::DATE
    FROM silver.stg_employees
    ORDER BY employee_id;

INSERT INTO gold.dim_shipper (shipper_id, shipper_name, phone)
    SELECT shipper_id, shipper_name, phone
    FROM silver.stg_shippers
    ORDER BY shipper_id;

INSERT INTO gold.dim_category (category_id, category_name, description)
    SELECT category_id, category_name, description
    FROM silver.stg_categories
    ORDER BY category_id;

INSERT INTO gold.dim_supplier (supplier_id, supplier_name, contact_name, address, city, postal_code, country, phone)
    SELECT supplier_id, supplier_name, contact_name, address, city, postal_code, country, phone
    FROM silver.stg_suppliers
    ORDER BY supplier_id;

INSERT INTO gold.dim_product (product_id, product_name, unit, price, category_id, supplier_id)
    SELECT product_id, product_name, unit, price, category_id, supplier_id
    FROM silver.stg_products
    ORDER BY product_id;

INSERT INTO gold.fact_order_detail (order_detail_id, order_id, quantity, unit_price, total_amount,
                                    customer_id, employee_id, shipper_id, product_id, date_id)
    SELECT od.order_detail_id, od.order_id, od.quantity, p.price,
        od.quantity * p.price AS total_amount,
        o.customer_id, o.employee_id, o.shipper_id, od.product_id,
        TO_CHAR(o.order_date, 'YYYYMMDD')::INT AS date_id
    FROM silver.stg_orderdetails od
    JOIN silver.stg_orders o ON o.order_id = od.order_id
    JOIN silver.stg_products p ON p.product_id = od.product_id;

COMMIT;
