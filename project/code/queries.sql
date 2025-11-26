-- customers_count.csv
-- Общее количество покупателей
SELECT COUNT(DISTINCT c.customer_id) AS customers_count
FROM customers AS c;


-- top_10_total_income.csv
-- Топ-10 продавцов по общей выручке
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON e.employee_id = s.sales_person_id
INNER JOIN products AS p
    ON p.product_id = s.product_id
GROUP BY seller
ORDER BY income DESC
LIMIT 10;


-- lowest_average_income.csv
-- Продавцы с самой низкой средней выручкой
SELECT
    t.seller,
    t.average_income
FROM (
    SELECT
        CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
        FLOOR(AVG(p.price * s.quantity)) AS average_income
    FROM sales AS s
    INNER JOIN employees AS e
        ON e.employee_id = s.sales_person_id
    INNER JOIN products AS p
        ON p.product_id = s.product_id
    GROUP BY seller
) AS t
WHERE t.average_income < (
    SELECT AVG(inner_t.average_income)
    FROM (
        SELECT
            FLOOR(AVG(p.price * s2.quantity)) AS average_income
        FROM sales AS s2
        INNER JOIN employees AS e2
            ON e2.employee_id = s2.sales_person_id
        INNER JOIN products AS p2
            ON p2.product_id = s2.product_id
        GROUP BY CONCAT(TRIM(e2.first_name), ' ', TRIM(e2.last_name))
    ) AS inner_t
)
ORDER BY t.average_income ASC;


-- day_of_the_week_income.csv
-- Выручка по дням недели (по продавцам)
SELECT
    CONCAT(TRIM(e.first_name), ' ', TRIM(e.last_name)) AS seller,
    TRIM(LOWER(TO_CHAR(s.sale_date, 'Day'))) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e
    ON e.employee_id = s.sales_person_id
INNER JOIN products AS p
    ON p.product_id = s.product_id
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
    grouped.age_category,
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
GROUP BY grouped.age_category
ORDER BY
    CASE
        WHEN grouped.age_category = '16-25' THEN 1
        WHEN grouped.age_category = '26-40' THEN 2
        WHEN grouped.age_category = '40+' THEN 3
    END;


-- customers_by_month.csv
-- Кол-во уникальных клиентов и выручка по месяцам
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN products AS p
    ON p.product_id = s.product_id
GROUP BY selling_month
ORDER BY selling_month;


-- special_offer.csv
-- Покупатели, чья первая покупка пришлась на акцию (есть товар с price = 0)
SELECT
    fp.first_date AS sale_date,
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM (
    SELECT
        s.customer_id,
        MIN(s.sale_date) AS first_date
    FROM sales AS s
    GROUP BY s.customer_id
) AS fp
INNER JOIN sales AS s
    ON s.customer_id = fp.customer_id
    AND s.sale_date = fp.first_date
INNER JOIN products AS p
    ON p.product_id = s.product_id
INNER JOIN customers AS c
    ON c.customer_id = fp.customer_id
INNER JOIN employees AS e
    ON e.employee_id = s.sales_person_id
WHERE p.price = 0
ORDER BY fp.customer_id;
