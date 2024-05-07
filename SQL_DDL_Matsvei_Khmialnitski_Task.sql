-- Create the database
CREATE DATABASE MountainClimbs;

-- Connect to the newly created database
\c MountainClimbs;

-- Create the Climbers table
CREATE TABLE Climbers (
    climber_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    gender VARCHAR(6) NOT NULL CHECK (gender IN ('Male', 'Female')),
    record_ts DATE DEFAULT CURRENT_DATE
);

-- Create the Mountains table
CREATE TABLE Mountains (
    mountain_id SERIAL PRIMARY KEY,
    mountain_name VARCHAR(100) NOT NULL,
    height INT CHECK (height > 0),
    country VARCHAR(100) NOT NULL,
    area VARCHAR(100) NOT NULL,
    record_ts DATE DEFAULT CURRENT_DATE
);

-- Create the Climbs table
CREATE TABLE Climbs (
    climb_id SERIAL PRIMARY KEY,
    climber_id INT REFERENCES Climbers(climber_id),
    mountain_id INT REFERENCES Mountains(mountain_id),
    start_date DATE CHECK (start_date >= '2000-01-01'),
    end_date DATE CHECK (end_date >= start_date),
    record_ts DATE DEFAULT CURRENT_DATE
);

-- Populate the tables with sample data

-- Sample data for Climbers
INSERT INTO Climbers (first_name, last_name, address, gender) VALUES
('John', 'Doe', '123 Mountain St', 'Male'),
('Jane', 'Smith', '456 Summit Blvd', 'Female');

-- Sample data for Mountains
INSERT INTO Mountains (mountain_name, height, country, area) VALUES
('Mount Everest', 8848, 'Nepal', 'Himalayas'),
('K2', 8611, 'Pakistan', 'Karakoram');

-- Sample data for Climbs
INSERT INTO Climbs (climber_id, mountain_id, start_date, end_date) VALUES
(1, 1, '2024-05-10', '2024-05-20'),
(2, 2, '2024-06-05', '2024-06-15');

-- Ensure that the 'record_ts' value is set for existing rows
UPDATE Climbers SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE Mountains SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE Climbs SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;