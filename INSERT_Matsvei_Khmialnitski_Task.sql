INSERT INTO film (
    title, 
    description, 
    release_year, 
    language_id, 
    rental_duration, 
    rental_rate, 
    length, 
    replacement_cost, 
    rating, 
    special_features, 
    last_update
) VALUES (
    'The Matrix', 
    'A computer hacker learns about the true nature of reality and his role in the war against its controllers.', 
    1999, 
    1, 
    14, 
    4.99, 
    136, 
    19.99, 
    'R', 
    '{"Trailers","Commentaries","Deleted Scenes","Behind the Scenes"}', 
    now()
);



-- Insert actors into the actor table
INSERT INTO actor (first_name, last_name, last_update) VALUES
('Keanu', 'Reeves', NOW()),
('Laurence', 'Fishburne', NOW()),
('Carrie-Anne', 'Moss', NOW());

--get the film id 1001
SELECT film_id FROM film WHERE title = 'The Matrix';

--get the actor id 201, 202, 203
SELECT actor_id FROM actor WHERE last_name IN ('Reeves', 'Fishburne', 'Moss');


-- Insert records into the film_actor table
INSERT INTO film_actor (actor_id, film_id, last_update) VALUES
(201, 1001, NOW()),
(202, 1001, NOW()),
(203, 1001, NOW());


-- Get the film_id for The Matrix 1001
SELECT film_id FROM film WHERE title = 'The Matrix';

INSERT INTO inventory (film_id, store_id, last_update) VALUES
(1001, 1, NOW());


-- update
-- Update the rental duration and rental rate for "The Matrix"
UPDATE film
SET rental_duration = 21,
    rental_rate = 9.99
WHERE title = 'The Matrix';



--
-- Find a customer with at least 10 rental and 10 payment records
SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(r.rental_id) >= 10 AND COUNT(p.payment_id) >= 10
LIMIT 1;


-- Update the personal data of the identified customer
UPDATE customer
SET first_name = 'YourFirstName',
    last_name = 'YourLastName',
    email = 'your.email@example.com',
    address_id = (SELECT address_id FROM address LIMIT 1)  -- Use an existing address
WHERE customer_id = 101;  -- Replace 101 with the actual customer ID obtained from Step 1


-- Find a customer with at least 10 rental and 10 payment records
WITH target_customer AS (
    SELECT c.customer_id
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(r.rental_id) >= 10 AND COUNT(p.payment_id) >= 10
    LIMIT 1
)

-- Update the personal data of the identified customer
UPDATE customer
SET first_name = 'Matsvei',
    last_name = 'khmialnitski',
    email = 'matsvei@esde.com',
    address_id = (SELECT address_id FROM address LIMIT 1),  -- Use an existing address
    create_date = CURRENT_DATE
WHERE customer_id = (SELECT customer_id FROM target_customer);

-- Change the customer's create_date value to current_date.
UPDATE customer
SET create_date = current_date
WHERE first_name = 'Matsvei' AND last_name = 'khmialnitski';