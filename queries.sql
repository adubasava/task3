-- Количество фильмов в каждой категории, по убыванию
SELECT 
  c.name AS category, 
  COUNT(f.film_id) AS film_count
FROM category c
JOIN 
  film_category fc 
  ON c.category_id = fc.category_id
JOIN 
  film f 
  ON fc.film_id = f.film_id
GROUP BY c.category_id
ORDER BY film_count DESC;


-- 10 актеров, чьи фильмы больше всего арендовали, по убыванию
SELECT 
  CONCAT(a.first_name, ' ', a.last_name) as actor, 
  COUNT(r.rental_id) AS rental_count
FROM actor a
JOIN 
  film_actor fa 
  ON a.actor_id = fa.actor_id
JOIN 
  inventory i 
  ON fa.film_id = i.film_id
JOIN 
  rental r 
  ON i.inventory_id = r.inventory_id
GROUP BY a.actor_id
ORDER BY rental_count DESC
LIMIT 10;


-- Категория фильмов, на которую потратили больше всего денег
SELECT 
  c.name AS category_name, 
  SUM(p.amount) AS total_spent
FROM category c
JOIN 
  film_category fc 
  ON c.category_id = fc.category_id
JOIN 
  film f 
  ON fc.film_id = f.film_id
JOIN 
  inventory i 
  ON f.film_id = i.film_id
JOIN 
  rental r 
  ON i.inventory_id = r.inventory_id
JOIN 
  payment p 
  ON r.rental_id = p.rental_id
GROUP BY c.name
ORDER BY total_spent DESC
LIMIT 1;


-- Названия фильмов, которых нет в inventory
SELECT DISTINCT f.title
FROM film f
LEFT JOIN 
  inventory i 
  ON f.film_id = i.film_id
WHERE 
  i.film_id IS NULL;


-- Топ 3 актеров, которые больше всего появлялись в фильмах в категории Children. Если у нескольких актеров одинаковое количество фильмов, вывести всех
WITH ChildrenFilms AS (
  SELECT 
    CONCAT(a.first_name, ' ', a.last_name) AS actor, 
    COUNT(f.film_id) AS film_count
  FROM actor a
  JOIN 
    film_actor fa 
    ON a.actor_id = fa.actor_id
  JOIN 
    film f 
    ON fa.film_id = f.film_id
  JOIN 
    film_category fc 
    ON f.film_id = fc.film_id
  JOIN 
    category c 
    ON c.category_id = fc.category_id
  WHERE c.name = 'Children'
  GROUP BY a.actor_id
)

SELECT 
  actor, 
  film_count
FROM ChildrenFilms
WHERE 
  film_count >= (
    SELECT DISTINCT film_count 
    FROM ChildrenFilms 
    ORDER BY film_count DESC 
    LIMIT 1 
    OFFSET 2
)
ORDER BY 
  film_count DESC, 
  actor;


-- Города с количеством активных и неактивных клиентов; по количеству неактивных клиентов по убыванию
SELECT 
  c.city, 
  SUM(CASE WHEN cust.active = 1 THEN 1 ELSE 0 END) AS active_customers, 
  SUM(CASE WHEN cust.active = 0 THEN 1 ELSE 0 END) AS inactive_customers
FROM city c
JOIN 
  address a 
  ON a.city_id = c.city_id
JOIN 
  customer cust 
  ON cust.address_id = a.address_id
GROUP BY c.city
ORDER BY inactive_customers DESC;

-- Категория фильмов, у которой самое большое количество часов суммарной аренды в городах, которые начинаются на букву "а". То же самое для городов, в которых есть символ "-"
WITH RentalHours AS (
  SELECT 
    c.city, 
    cat.name AS category, 
    ROUND(SUM(EXTRACT(EPOCH FROM AGE(r.return_date, r.rental_date)) / 3600), 2) AS total_hours
  FROM rental r
  JOIN 
    inventory i 
    ON r.inventory_id = i.inventory_id
  JOIN 
    film f 
    ON i.film_id = f.film_id
  JOIN 
    film_category fc 
    ON f.film_id = fc.film_id
  JOIN 
    category cat 
    ON fc.category_id = cat.category_id
  JOIN 
    customer cust 
    ON r.customer_id = cust.customer_id
  JOIN 
    address addr 
    ON cust.address_id = addr.address_id
  JOIN 
    city c 
    ON addr.city_id = c.city_id
  GROUP BY c.city, cat.name
),
CityA AS (
  SELECT 
    category, 
    SUM(total_hours) AS total_hours
  FROM RentalHours
  WHERE city LIKE 'a%'
  GROUP BY category
  ORDER BY total_hours DESC
  LIMIT 1
),
CityDash AS (
  SELECT 
    category, 
    SUM(total_hours) AS total_hours
  FROM RentalHours
  WHERE city LIKE '%-%'
  GROUP BY category
  ORDER BY total_hours DESC
  LIMIT 1
)

SELECT 
  'Cities starting with A' AS city_type, 
  category, 
  total_hours
FROM CityA
UNION ALL
SELECT 'Cities with - dash' AS city_type, 
  category, 
  total_hours
FROM CityDash;