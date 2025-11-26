    ---------------------------------------------------------------
-- customers_count.csv
-- Общее количество покупателей
---------------------------------------------------------------
SELECT COUNT(DISTINCT customer_id) AS customers_count
FROM customers;


---------------------------------------------------------------
-- top_10_total_income.csv
-- Топ-10 продавцов по общей выручке
---------------------------------------------------------------
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
JOIN employees AS e ON e.employee_id = s.sales_person_id
JOIN products  AS p ON p.product_id = s.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;


---------------------------------------------------------------
-- lowest_average_income.csv
-- Продавцы с самой низкой средней выручкой
---------------------------------------------------------------
WITH employee_avg AS (
    SELECT
        CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
        FLOOR(AVG(p.price * s.quantity)) AS average_income
    FROM sales AS s
    JOIN employees AS e ON e.employee_id = s.sales_person_id
    JOIN products  AS p ON p.product_id = s.product_id
    GROUP BY seller
),
overall AS (
    SELECT AVG(average_income) AS avg_all
    FROM employee_avg
)
SELECT
    seller,
    average_income
FROM employee_avg
WHERE average_income < (SELECT avg_all FROM overall)
ORDER BY average_income ASC;


---------------------------------------------------------------
-- day_of_the_week_income.csv
-- Выручка по дням недели (по продавцам)
---------------------------------------------------------------
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    TRIM(LOWER(TO_CHAR(s.sale_date, 'Day'))) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
JOIN employees AS e ON e.employee_id = s.sales_person_id
JOIN products  AS p ON p.product_id = s.product_id
GROUP BY
    seller,
    day_of_week,
    EXTRACT(ISODOW FROM s.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller;


---------------------------------------------------------------
-- age_groups.csv
-- Количество покупателей по возрастным группам
---------------------------------------------------------------
SELECT
    age_category,
    COUNT(*) AS age_count
FROM (
    SELECT
        CASE
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            WHEN age > 40 THEN '40+'
        END AS age_category
    FROM customers
) AS grouped
GROUP BY age_category
ORDER BY
    CASE
        WHEN age_category = '16-25' THEN 1
        WHEN age_category = '26-40' THEN 2
        WHEN age_category = '40+'  THEN 3
    END;


---------------------------------------------------------------
-- customers_by_month.csv
-- Кол-во уникальных клиентов и выручка по месяцам
---------------------------------------------------------------
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS "date",
    COUNT(DISTINCT s.customer_id) AS "total_customers",
    ROUND(SUM(p.price * s.quantity)::numeric, 3) AS "income"
FROM sales AS s
JOIN products AS p ON p.product_id = s.product_id
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY "date";


---------------------------------------------------------------
-- special_offer.csv
-- Покупатели, чья первая покупка пришлась на акцию (есть товар с price = 0)
---------------------------------------------------------------
WITH first_purchase AS (
    -- Дата первой покупки каждого клиента
    SELECT
        customer_id,
        MIN(sale_date) AS first_date
    FROM sales
    GROUP BY customer_id
),
promo_customers AS (
    -- Клиенты, у которых в первый день был хотя бы один акционный товар (price = 0)
    SELECT DISTINCT
        fp.customer_id,
        fp.first_date
    FROM first_purchase AS fp
    JOIN sales    AS s ON s.customer_id = fp.customer_id
                      AND s.sale_date   = fp.first_date
    JOIN products AS p ON p.product_id  = s.product_id
    WHERE p.price = 0
)
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    pc.first_date                          AS sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM promo_customers AS pc
JOIN sales      AS s ON  s.customer_id   = pc.customer_id
                    AND s.sale_date     = pc.first_date
JOIN customers  AS c ON c.customer_id    = pc.customer_id
JOIN employees  AS e ON e.employee_id    = s.sales_person_id
ORDER BY pc.customer_id;


