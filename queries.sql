-- customers_count.csv
-- Общее количество покупателей
SELECT
    COUNT(DISTINCT c.customer_id) AS customers_count
FROM customers AS c;


-- top_10_total_income.csv
-- Топ-10 продавцов по общей выручке
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    seller
ORDER BY
    income DESC
LIMIT 10;


-- lowest_average_income.csv
-- Продавцы с самой низкой средней выручкой
WITH employee_avg AS (
    SELECT
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        FLOOR(AVG(p.price * s.quantity)) AS average_income
    FROM sales AS s
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY
        seller
),

overall AS (
    SELECT
        AVG(average_income) AS avg_all
    FROM employee_avg
)

SELECT
    ea.seller,
    ea.average_income
FROM employee_avg AS ea
CROSS JOIN overall
WHERE
    ea.average_income < overall.avg_all
ORDER BY
    ea.average_income ASC;


-- day_of_the_week_income.csv
-- Выручка по дням недели (по продавцам)
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    TRIM(LOWER(TO_CHAR(s.sale_date, 'Day'))) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON s.sales_person_id = e.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    seller,
    day_of_week,
    EXTRACT(ISODOW FROM s.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller;


-- age_groups.csv
-- Количество покупателей по возрастным группам
SELECT
    age_category,
    COUNT(*) AS age_count
FROM (
    SELECT
        CASE
            WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
            WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
            WHEN c.age > 40 THEN '40+'
        END AS age_category
    FROM customers AS c
) AS grouped
GROUP BY
    age_category
ORDER BY
    CASE
        WHEN age_category = '16-25' THEN 1
        WHEN age_category = '26-40' THEN 2
        WHEN age_category = '40+' THEN 3
    END;


-- customers_by_month.csv
-- Кол-во уникальных клиентов и выручка по месяцам
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    selling_month
ORDER BY
    selling_month;


-- special_offer.csv
-- Покупатели, чья первая покупка пришлась на акцию (цена = 0)
WITH first_purchase AS (
    SELECT
        s.customer_id,
        MIN(s.sale_date) AS first_date
    FROM sales AS s
    GROUP BY
        s.customer_id
),

promo_customers AS (
    SELECT DISTINCT
        fp.customer_id,
        fp.first_date,
        CONCAT(c.first_name, ' ', c.last_name) AS customer,
        CONCAT(e.first_name, ' ', e.last_name) AS seller
    FROM first_purchase AS fp
    INNER JOIN sales AS s
        ON fp.customer_id = s.customer_id
        AND fp.first_date = s.sale_date
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    INNER JOIN customers AS c
        ON fp.customer_id = c.customer_id
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    WHERE
        p.price = 0
)

SELECT
    pc.first_date AS sale_date,
    pc.customer,
    pc.seller
FROM promo_customers AS pc
ORDER BY
    pc.customer_id;
