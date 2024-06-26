-- 1. Create a new user with the username "rentaluser" and the password "rentalpassword".
-- Give the user the ability to connect to the database but no other permissions.

DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rentaluser') THEN
       CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
    ELSE
        RAISE NOTICE 'This user already exists';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE dvdrental TO rentaluser;

--psql -U rentaluser -d dvdrental


/* 2. Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure 
this permission works correctly—write a SQL query to select all customers.
 */

-- psql -U postgres -d dvdrental

GRANT SELECT ON TABLE customer TO rentaluser;

-- \exit

--psql -U rentaluser -d dvdrental

SELECT * FROM customer;


-- 3. Create a new user group called "rental" and add "rentaluser" to the group. 

-- Create the group role 'rental' if it doesn't already exist
--psql -U postgres -d dvdrental

DO
$$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rental') THEN
            CREATE ROLE rental NOLOGIN;
        END IF;
    END
$$;

-- Add "rentaluser" to the "rental" role if not already a member
DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM pg_auth_members
                       WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'rental')
                         AND member = (SELECT oid FROM pg_roles WHERE rolname = 'rentaluser')) THEN
            GRANT rental TO rentaluser;
        END IF;
    END
$$;



/* 4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. 
Insert a new row and update one existing row in the "rental" table under that role. 
 */

GRANT INSERT, UPDATE ON TABLE rental TO rental;
GRANT USAGE ON SEQUENCE rental_rental_id_seq TO rental; 
GRANT SELECT ON TABLE rental TO rental;

SET ROLE rentaluser;


-- Insert
DO
$$
    BEGIN
        INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
        VALUES ('2024-06-20', 1, 1, '2024-06-25', 1)
        ON CONFLICT (rental_date, inventory_id, customer_id) DO NOTHING;

        IF NOT FOUND THEN
            RAISE NOTICE 'Record with rental_date %, inventory_id %, customer_id % already exists.',
                '2024-06-20', 1, 1;
        END IF;
    END
$$;


-- Update
DO
$$
    BEGIN
        IF EXISTS (SELECT 1 FROM rental WHERE rental_id = 1) THEN
            UPDATE rental SET return_date = '2024-06-23' WHERE rental_id = 1;
        ELSE
            RAISE NOTICE 'Rental with rental_id 1 does not exist.';
        END IF;
    END
$$;

-- Reset the role back
RESET ROLE;

/* 5. Revoke the "rental" group's INSERT permission for the "rental" table. 
Try to insert new rows into the "rental" table make sure this action is denied.
 */

REVOKE INSERT ON TABLE rental FROM rental;

SET ROLE rental;

INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES ('2024-06-15', 1, 1, '2024-06-16', 1)
ON CONFLICT (rental_date, inventory_id, customer_id) DO NOTHING;


/* 6. Create a personalized role for any customer already existing in the dvd_rental 
database. The name of the role name must be client_{first_name}_{last_name} 
(omit curly brackets). The customer's payment and rental history must not be empty. 
Configure that role so that the customer can only access their own data 
in the "rental" and "payment" tables. Write a query to make sure this user sees 
only their own data.
 */

 -- Find a customer with non-empty payment and rental history
SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(p.payment_id) > 0 AND COUNT(r.rental_id) > 0
LIMIT 1;

SELECT * FROM customer_info;

/* dvdrental=# select * from customer_info;
 customer_id | first_name | last_name 
-------------+------------+-----------
           2 | PATRICIA   | JOHNSON
(1 row)

 */

DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'client_PATRICIA_JOHNSON') THEN
        CREATE ROLE client_PATRICIA_JOHNSON WITH LOGIN PASSWORD 'password';
    ELSE
        RAISE NOTICE 'Role "client_PATRICIA_JOHNSON" already exists, skipping creation.';
    END IF;
END
$$;

GRANT SELECT ON TABLE rental TO client_PATRICIA_JOHNSON;
GRANT SELECT ON TABLE payment TO client_PATRICIA_JOHNSON;

ALTER TABLE rental ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS client_rental_policy ON rental;

CREATE POLICY client_rental_policy ON rental
    FOR SELECT
    USING (customer_id = 2);

ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS client_payment_policy ON payment;

CREATE POLICY client_payment_policy ON payment
    FOR SELECT
    USING (customer_id = 2);


SET ROLE client_PATRICIA_JOHNSON;

-- Test queries to see if only Patricia's data is accessible
SELECT * FROM rental;
SELECT * FROM payment;

-- Reset the role back
RESET ROLE;
