WITH staff_revenue AS (
    SELECT
        s.staff_id,
        s.first_name || ' ' || s.last_name AS staff_name,
        st.store_id,
        SUM(p.amount) AS total_revenue,
        RANK() OVER (PARTITION BY st.store_id ORDER BY SUM(p.amount) DESC) AS revenue_rank
    FROM
        staff s
    JOIN
        store st ON s.store_id = st.store_id
    JOIN
        payment p ON s.staff_id = p.staff_id
    JOIN
        rental r ON p.rental_id = r.rental_id
    WHERE
        EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY
        s.staff_id,
        st.store_id
)
SELECT
    store_id,
    staff_name,
    total_revenue
FROM
    staff_revenue
WHERE
    revenue_rank = 1;


SELECT
    f.title AS movie_title,
    COUNT(r.rental_id) AS rental_count,
    AVG(EXTRACT(YEAR FROM age(c.create_date))) AS average_account_age
FROM
    film f
JOIN
    inventory i ON f.film_id = i.film_id
JOIN
    rental r ON i.inventory_id = r.inventory_id
JOIN
    customer c ON r.customer_id = c.customer_id
GROUP BY
    f.title
ORDER BY
    rental_count DESC
LIMIT 5;




SELECT
    a.actor_id,
    a.first_name || ' ' || a.last_name AS actor_name,
    MAX(f.release_year) AS last_movie_year,
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS inactivity_years
FROM
    actor a
JOIN
    film_actor fa ON a.actor_id = fa.actor_id
JOIN
    film f ON fa.film_id = f.film_id
GROUP BY
    a.actor_id
ORDER BY
    inactivity_years DESC;
