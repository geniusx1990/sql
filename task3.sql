--1. Write a query that will return for each year the most popular in rental film among films released in one year.

WITH film_rental_counts AS (
    SELECT 
        f.film_id,
        f.title,
        f.release_year,
        COUNT(r.rental_id) AS rental_count
    FROM 
        film f
    JOIN 
        inventory i ON f.film_id = i.film_id
    JOIN 
        rental r ON i.inventory_id = r.inventory_id
    GROUP BY 
        f.film_id, f.title, f.release_year
),
max_rentals_per_year AS (
    SELECT 
        release_year,
        MAX(rental_count) AS max_rental_count
    FROM 
        film_rental_counts
    GROUP BY 
        release_year
)
SELECT 
    frc.release_year,
    frc.title,
    frc.rental_count AS total_rentals
FROM 
    film_rental_counts frc
JOIN 
    max_rentals_per_year mrpy ON frc.release_year = mrpy.release_year
                             AND frc.rental_count = mrpy.max_rental_count
ORDER BY 
    frc.release_year;

--2. Write a query that will return the Top-5 actors who have appeared in Comedies more than anyone else.
SELECT
    a.actor_id,
    a.first_name,
    a.last_name,
    COUNT(*) AS comedy_count
FROM
    actor a
JOIN
    film_actor fa ON a.actor_id = fa.actor_id
JOIN
    film f ON fa.film_id = f.film_id
JOIN
    film_category fc ON f.film_id = fc.film_id
JOIN
    category c ON fc.category_id = c.category_id
WHERE
    c.name = 'Comedy'
GROUP BY
    a.actor_id, a.first_name, a.last_name
ORDER BY
    comedy_count DESC
LIMIT 5;

--3. Write a query that will return the names of actors who have not starred in “Action” films.

WITH action_actors AS (
    SELECT DISTINCT
        a.actor_id
    FROM
        actor a
    JOIN
        film_actor fa ON a.actor_id = fa.actor_id
    JOIN
        film_category fc ON fa.film_id = fc.film_id
    JOIN
        category c ON fc.category_id = c.category_id
    WHERE
        c.name = 'Action'
)

SELECT
    a.actor_id,
    a.first_name,
    a.last_name
FROM
    actor a
WHERE
    a.actor_id NOT IN (SELECT actor_id FROM action_actors)
ORDER BY
    a.first_name, a.last_name;

---4. Write a query that will return the three most popular in rental films by each genre.

SELECT
    genre,
    title AS most_popular_film,
    rental_count
FROM (
    SELECT
        c.name AS genre,
        f.title,
        COUNT(r.rental_id) AS rental_count,
        DENSE_RANK() OVER (PARTITION BY c.name ORDER BY COUNT(r.rental_id) DESC) AS rank
    FROM
        film f
    JOIN
        inventory i ON f.film_id = i.film_id
    JOIN
        rental r ON i.inventory_id = r.inventory_id
    JOIN
        film_category fc ON f.film_id = fc.film_id
    JOIN
        category c ON fc.category_id = c.category_id
    GROUP BY
        c.name, f.film_id, f.title
) AS ranked_films
WHERE
    rank <= 3
ORDER BY
    genre,
    rental_count DESC;

SELECT
    genre,
    title AS most_popular_film,
    rental_count
FROM (
    SELECT
        c.name AS genre,
        f.title,
        COUNT(r.rental_id) AS rental_count,
        ROW_NUMBER() OVER (PARTITION BY c.name ORDER BY COUNT(r.rental_id) DESC) AS row_num
    FROM
        film f
    JOIN
        inventory i ON f.film_id = i.film_id
    JOIN
        rental r ON i.inventory_id = r.inventory_id
    JOIN
        film_category fc ON f.film_id = fc.film_id
    JOIN
        category c ON fc.category_id = c.category_id
    GROUP BY
        c.name, f.title, f.film_id
) AS ranked_films
WHERE
    row_num <= 3
ORDER BY
    genre,
    rental_count DESC;


-- 5. Calculate the number of films released each year and cumulative total by the number of films. Write two query versions, one with window functions, the other without.
SELECT
    release_year,
    COUNT(film_id) AS films_released,
    SUM(COUNT(film_id)) OVER (ORDER BY release_year) AS cumulative_total
FROM
    film
GROUP BY
    release_year
ORDER BY
    release_year;

/* 6. Calculate a monthly statistics based on “rental_date” field from “Rental” table that for each month will show the percentage of “Animation” films from the total number of rentals. Write two query
versions, one with window functions, the other without.*/
 WITH monthly_rentals AS (
    SELECT
        DATE_TRUNC('month', rental_date) AS month,
        COUNT(*) AS total_rentals,
        SUM(CASE WHEN c.name = 'Animation' THEN 1 ELSE 0 END) AS animation_rentals
    FROM
        rental r
    JOIN
        inventory i ON r.inventory_id = i.inventory_id
    JOIN
        film f ON i.film_id = f.film_id
    JOIN
        film_category fc ON f.film_id = fc.film_id
    JOIN
        category c ON fc.category_id = c.category_id
    GROUP BY
        DATE_TRUNC('month', rental_date)
)
SELECT
    month,
    total_rentals,
    animation_rentals,
    ROUND((animation_rentals::decimal / total_rentals) * 100, 2) AS animation_percentage
FROM
    monthly_rentals
ORDER BY
    month;

/* 7. Write a query that will return the names of actors who have starred in “Action” films more than in
“Drama” film. */

WITH actor_genre_counts AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(CASE WHEN c.name = 'Action' THEN 1 END) AS action_count,
        COUNT(CASE WHEN c.name = 'Drama' THEN 1 END) AS drama_count
    FROM
        actor a
        JOIN film_actor fa ON a.actor_id = fa.actor_id
        JOIN film f ON fa.film_id = f.film_id
        JOIN film_category fc ON f.film_id = fc.film_id
        JOIN category c ON fc.category_id = c.category_id
    GROUP BY
        a.actor_id, a.first_name, a.last_name
)
SELECT
    first_name,
    last_name
FROM
    actor_genre_counts
WHERE
    action_count > drama_count
ORDER BY
    first_name, last_name;


--8. Write a query that will return the top-5 customers who spent the most money watching Comedies.

WITH comedy_customers AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_spent_on_comedies
    FROM
        customer c
        JOIN rental r ON c.customer_id = r.customer_id
        JOIN payment p ON r.rental_id = p.rental_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN film_category fc ON f.film_id = fc.film_id
        JOIN category cat ON fc.category_id = cat.category_id
    WHERE
        cat.name = 'Comedy'
    GROUP BY
        c.customer_id, c.first_name, c.last_name
)
SELECT
    first_name,
    last_name,
    total_spent_on_comedies
FROM
    comedy_customers
ORDER BY
    total_spent_on_comedies DESC
LIMIT 5;


--9. In the “Address” table, in the “address” field, the last word indicates the "type" of a street: Street, Lane, Way, etc. Write a query that will return all "types" of streets and the number of addresses related to this "type".

SELECT
    SUBSTRING(address FROM 
        LENGTH(address) - POSITION(' ' IN REVERSE(address)) + 2
    ) AS street_type,
    COUNT(*) AS address_count
FROM
    address
GROUP BY
    street_type
ORDER BY
    address_count DESC;

/* 10. Write a query that will return a list of movie ratings, indicate for each rating the total number of films with this rating, the top-3 categories by the number of films in this category and the number of film in this category with this rating.
The result can be like this: */

WITH category_counts AS (
    SELECT
        f.rating AS rating,
        c.name AS category,
        COUNT(*) AS category_count
    FROM
        film f
        JOIN film_category fc ON f.film_id = fc.film_id
        JOIN category c ON fc.category_id = c.category_id
    GROUP BY
        f.rating, c.name
),
ranked_categories AS (
    SELECT
        rating,
        category,
        category_count,
        ROW_NUMBER() OVER (PARTITION BY rating ORDER BY category_count DESC) AS rank
    FROM
        category_counts
)

SELECT
    ROW_NUMBER() OVER () AS id,
    rc.rating AS rating,
    (SELECT COUNT(*) FROM film WHERE rating = rc.rating) AS total,
    MAX(CASE WHEN rc.rank = 1 THEN rc.category || ': ' || rc.category_count::text ELSE NULL END) AS category1,
    MAX(CASE WHEN rc.rank = 2 THEN rc.category || ': ' || rc.category_count::text ELSE NULL END) AS category2,
    MAX(CASE WHEN rc.rank = 3 THEN rc.category || ': ' || rc.category_count::text ELSE NULL END) AS category3
FROM
    ranked_categories rc
GROUP BY
    rc.rating
ORDER BY
    total DESC;