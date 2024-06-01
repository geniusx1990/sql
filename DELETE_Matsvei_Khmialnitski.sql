--Remove a previously inserted film from the inventory and all corresponding rental records

BEGIN;

DELETE FROM rental
WHERE inventory_id IN (
    SELECT inventory_id FROM inventory WHERE film_id = (SELECT film_id FROM film WHERE title = 'The Matrix')
);

DELETE FROM inventory
WHERE film_id = (SELECT film_id FROM film WHERE title = 'The Matrix');

DELETE FROM film_actor
WHERE film_id = (SELECT film_id FROM film WHERE title = 'The Matrix');

DELETE FROM film
WHERE film_id = (SELECT film_id FROM film WHERE title = 'The Matrix');

COMMIT;


-- Remove any records related to you (as a customer) from all tables except "Customer" and "Inventory"
BEGIN;

DELETE FROM staff WHERE staff_id IN (SELECT staff_id FROM staff WHERE store_id IN (SELECT store_id FROM store WHERE manager_staff_id = (SELECT staff_id FROM staff WHERE first_name = 'Matsvei' AND last_name = 'khmialnitski')));
DELETE FROM payment WHERE rental_id IN (SELECT rental_id FROM rental WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Matsvei' AND last_name = 'khmialnitski'));

COMMIT;
