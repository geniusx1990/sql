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