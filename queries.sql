-- customers_count.csv
-- Общее количество покупателей
SELECT
    COUNT(DISTINCT customers.customer_id) AS customers_count
FROM customers;

-- top_10_total_income.csv
-- Топ-10 продавцов по общей выручке
SELECT
    CONCAT(TRIM(employees.first_name), ' ', TRIM(employees.last_name)) AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
JOIN employees
    ON sales.sales_person_id = employees.employee_id
JOIN products
    ON sales.product_id = products.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;

-- lowest_average_income.csv
-- Продавцы с самой низкой средней выручкой
WITH employee_avg AS (
    SELECT
        CONCAT(TRIM(employees.first_name), ' ', TRIM(employees.last_name)) AS seller,
        FLOOR(AVG(products.price * sales.quantity)) AS average_income
    FROM sales
    JOIN employees
        ON sales.sales_person_id = employees.employee_id
    JOIN products
        ON sales.product_id = products.product_id
    GROUP BY seller
),
overall AS (
    SELECT AVG(employee_avg.average_income) AS avg_all
    FROM employee_avg
)

SELECT
    employee_avg.seller,
    employee_avg.average_income
FROM employee_avg
CROSS JOIN overall
WHERE employee_avg.average_income < overall.avg_all
ORDER BY employee_avg.average_income ASC;

-- day_of_the_week_income.csv
-- Выручка по дням недели (по продавцам)
SELECT
    CONCAT(TRIM(employees.first_name), ' ', TRIM(employees.last_name)) AS seller,
    TRIM(LOWER(TO_CHAR(sales.sale_date, 'Day'))) AS day_of_week,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
JOIN employees
    ON sales.sales_person_id = employees.employee_id
JOIN products
    ON sales.product_id = products.product_id
GROUP BY
    seller,
    day_of_week,
    EXTRACT(ISODOW FROM sales.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM sales.sale_date),
    seller;

-- age_groups.csv
-- Количество покупателей по возрастным группам
SELECT
    age_category,
    COUNT(*) AS age_count
FROM (
    SELECT
        CASE
            WHEN customers.age BETWEEN 16 AND 25 THEN '16-25'
            WHEN customers.age BETWEEN 26 AND 40 THEN '26-40'
            WHEN customers.age > 40 THEN '40+'
        END AS age_category
    FROM customers
) AS grouped
GROUP BY age_category
ORDER BY
    CASE
        WHEN age_category = '16-25' THEN 1
        WHEN age_category = '26-40' THEN 2
        WHEN age_category = '40+' THEN 3
    END;

-- customers_by_month.csv
-- Кол-во уникальных клиентов и выручка по месяцам
SELECT
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
JOIN products
    ON sales.product_id = products.product_id
GROUP BY selling_month
ORDER BY selling_month;

-- special_offer.csv
-- Покупатели, чья первая покупка пришлась на акцию (цена = 0)
WITH first_purchase AS (
    SELECT
        sales.customer_id,
        MIN(sales.sale_date) AS first_date
    FROM sales
    GROUP BY sales.customer_id
),
promo_customers AS (
    SELECT DISTINCT
        first_purchase.customer_id,
        first_purchase.first_date
    FROM first_purchase
    JOIN sales
        ON sales.customer_id = first_purchase.customer_id
        AND sales.sale_date = first_purchase.first_date
    JOIN products
        ON sales.product_id = products.product_id
    WHERE products.price = 0
)

SELECT
    CONCAT(customers.first_name, ' ', customers.last_name) AS customer,
    promo_customers.first_date AS sale_date,
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller
FROM promo_customers
JOIN customers
    ON promo_customers.customer_id = customers.customer_id
JOIN sales
    ON sales.customer_id = promo_customers.customer_id
    AND sales.sale_date = promo_customers.first_date
JOIN employees
    ON sales.sales_person_id = employees.employee_id
ORDER BY promo_customers.customer_id;
