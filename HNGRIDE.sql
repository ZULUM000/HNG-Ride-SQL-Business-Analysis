
DROP TABLE IF EXISTS payments, rides, riders, drivers CASCADE;

-- Drivers table
CREATE TABLE drivers (
    driver_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    signup_date TEXT,
    city VARCHAR(100),
    rating NUMERIC(2,1)
);

-- Riders table
CREATE TABLE riders (
    rider_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    signup_date TEXT,
    city VARCHAR(100),
    email VARCHAR(150)
);

-- Rides table
CREATE TABLE rides (
    ride_id SERIAL PRIMARY KEY,
    rider_id INT REFERENCES riders(rider_id),
    driver_id INT REFERENCES drivers(driver_id),
    request_time TEXT,
    pickup_time TEXT,
    dropoff_time TEXT,
    pickup_city VARCHAR(100),
    dropoff_city VARCHAR(100),
    distance_km NUMERIC(10,2),
    status VARCHAR(50),
    fare NUMERIC(10,2)
);

-- Payments table
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    ride_id INT REFERENCES rides(ride_id),
    amount NUMERIC(10,2),
    method VARCHAR(50),
    paid_date TEXT
);

COPY drivers(driver_id, name, city, signup_date, rating)
FROM 'C:\\HNG Rides\\drivers_raw.csv'
DELIMITER ',' CSV HEADER;

COPY riders(rider_id, name, signup_date, city, email)
FROM 'C:\\HNG Rides\\riders_raw.csv'
DELIMITER ',' CSV HEADER;

COPY rides(ride_id, rider_id, driver_id, request_time, pickup_time, dropoff_time, pickup_city, dropoff_city, distance_km, status, fare)
FROM 'C:\\HNG Rides\\rides_raw.csv'
DELIMITER ',' CSV HEADER;

COPY payments(payment_id, ride_id, amount, method, paid_date)
FROM 'C:\\HNG Rides\\payments_raw.csv'
DELIMITER ',' CSV HEADER;

ALTER TABLE drivers
ALTER COLUMN signup_date TYPE TIMESTAMP
USING TO_TIMESTAMP(signup_date, 'MM/DD/YYYY HH24:MI');

ALTER TABLE riders
ALTER COLUMN signup_date TYPE TIMESTAMP
USING TO_TIMESTAMP(signup_date, 'MM/DD/YYYY HH24:MI');

ALTER TABLE rides
ALTER COLUMN request_time TYPE TIMESTAMP
USING TO_TIMESTAMP(request_time, 'MM/DD/YYYY HH24:MI');

ALTER TABLE rides
ALTER COLUMN pickup_time TYPE TIMESTAMP
USING TO_TIMESTAMP(pickup_time, 'MM/DD/YYYY HH24:MI');

ALTER TABLE rides
ALTER COLUMN dropoff_time TYPE TIMESTAMP
USING TO_TIMESTAMP(dropoff_time, 'MM/DD/YYYY HH24:MI');

ALTER TABLE payments
ALTER COLUMN paid_date TYPE TIMESTAMP
USING TO_TIMESTAMP(paid_date, 'MM/DD/YYYY HH24:MI');

-- Remove duplicates
DELETE FROM drivers
WHERE driver_id IN (
    SELECT driver_id FROM (
        SELECT driver_id,
               ROW_NUMBER() OVER(PARTITION BY name, city, signup_date ORDER BY driver_id) AS rn
        FROM drivers
    ) t WHERE rn > 1
);

DELETE FROM riders
WHERE rider_id IN (
    SELECT rider_id FROM (
        SELECT rider_id,
               ROW_NUMBER() OVER(PARTITION BY name, city, email, signup_date ORDER BY rider_id) AS rn
        FROM riders
    ) t WHERE rn > 1
);

DELETE FROM rides
WHERE ride_id IN (
    SELECT ride_id FROM (
        SELECT ride_id,
               ROW_NUMBER() OVER(PARTITION BY rider_id, driver_id, request_time ORDER BY ride_id) AS rn
        FROM rides
    ) t WHERE rn > 1
);

DELETE FROM payments
WHERE payment_id IN (
    SELECT payment_id FROM (
        SELECT payment_id,
               ROW_NUMBER() OVER(PARTITION BY ride_id, amount, paid_date ORDER BY payment_id) AS rn
        FROM payments
    ) t WHERE rn > 1
);

-- Trim city names and capitalize
UPDATE drivers SET city = INITCAP(TRIM(city));
UPDATE riders SET city = INITCAP(TRIM(city));
UPDATE rides
SET pickup_city = INITCAP(TRIM(pickup_city)),
    dropoff_city = INITCAP(TRIM(dropoff_city));

-- Replace missing/invalid fare with city average
WITH city_mean AS (
    SELECT pickup_city, AVG(fare) AS mean_fare
    FROM rides
    WHERE fare > 0
    GROUP BY pickup_city
)
UPDATE rides r
SET fare = cm.mean_fare
FROM city_mean cm
WHERE r.pickup_city = cm.pickup_city
  AND (r.fare IS NULL OR r.fare <= 0);

ALTER TABLE rides ADD COLUMN ride_duration INTERVAL;
UPDATE rides
SET ride_duration = dropoff_time - pickup_time;

ALTER TABLE rides ADD COLUMN ride_month INT, ADD COLUMN ride_year INT;
UPDATE rides
SET ride_month = EXTRACT(MONTH FROM request_time)::INT,
    ride_year = EXTRACT(YEAR FROM request_time)::INT;

-- Valid rides within period
CREATE OR REPLACE VIEW valid_rides AS
SELECT *
FROM rides
WHERE pickup_time BETWEEN '2021-06-01' AND '2024-12-31';

-- Completed rides with valid payments
CREATE OR REPLACE VIEW completed_rides AS
SELECT r.*
FROM valid_rides r
JOIN payments p ON r.ride_id = p.ride_id
WHERE p.amount > 0;

-- 1. Top 10 longest rides
SELECT r.ride_id, d.name AS driver_name, rd.name AS rider_name,
       r.pickup_city, r.dropoff_city, p.method AS payment_method, r.distance_km
FROM completed_rides r
JOIN drivers d ON r.driver_id = d.driver_id
JOIN riders rd ON r.rider_id = rd.rider_id
LEFT JOIN payments p ON r.ride_id = p.ride_id
ORDER BY r.distance_km DESC
LIMIT 10;

-- 2. Riders from 2021 still active in 2024
SELECT COUNT(DISTINCT r.rider_id) AS active_riders_2024
FROM riders r
JOIN completed_rides cr ON r.rider_id = cr.rider_id
WHERE EXTRACT(YEAR FROM r.signup_date) = 2021
  AND EXTRACT(YEAR FROM cr.request_time) = 2024;

-- 3. Quarterly revenue comparison with YoY growth
WITH quarterly_revenue AS (
    SELECT EXTRACT(YEAR FROM p.paid_date) AS year,
           EXTRACT(QUARTER FROM p.paid_date) AS quarter,
           SUM(p.amount) AS total_revenue
    FROM payments p
    JOIN completed_rides r ON p.ride_id = r.ride_id
    GROUP BY 1, 2
),
growth AS (
    SELECT year, quarter, total_revenue,
           LAG(total_revenue) OVER (PARTITION BY quarter ORDER BY year) AS prev_year_revenue,
           ROUND(
               100 * (total_revenue - LAG(total_revenue) OVER (PARTITION BY quarter ORDER BY year))
               / NULLIF(LAG(total_revenue) OVER (PARTITION BY quarter ORDER BY year), 0), 2
           ) AS yoy_growth_percent
    FROM quarterly_revenue
)
SELECT *
FROM growth
ORDER BY year, quarter;

-- 4. Top 5 most consistent drivers
WITH driver_stats AS (
    SELECT r.driver_id,
           COUNT(*) AS total_rides,
           EXTRACT(MONTH FROM AGE(MAX(r.request_time), MIN(r.request_time))) + 1 AS active_months
    FROM completed_rides r
    GROUP BY r.driver_id
)
SELECT d.name AS driver_name,
       ROUND(total_rides::NUMERIC / NULLIF(active_months,0), 2) AS avg_rides_per_month
FROM driver_stats ds
JOIN drivers d ON ds.driver_id = d.driver_id
ORDER BY avg_rides_per_month DESC
LIMIT 5;

-- 5. City with highest cancellation rate
SELECT pickup_city,
       ROUND(100.0 * SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancellation_rate_percent
FROM valid_rides
GROUP BY pickup_city
ORDER BY cancellation_rate_percent DESC
LIMIT 10;

-- 6. Riders with >10 rides and no cash payments
SELECT r.rider_id, r.name, COUNT(cr.ride_id) AS total_rides
FROM riders r
JOIN completed_rides cr ON r.rider_id = cr.rider_id
LEFT JOIN payments p ON cr.ride_id = p.ride_id
GROUP BY r.rider_id, r.name
HAVING COUNT(cr.ride_id) > 10
   AND SUM(CASE WHEN LOWER(p.method) = 'cash' THEN 1 ELSE 0 END) = 0;

-- 7. Top 3 drivers by revenue per city
WITH city_revenue AS (
    SELECT r.pickup_city, r.driver_id, SUM(p.amount) AS total_revenue
    FROM completed_rides r
    JOIN payments p ON r.ride_id = p.ride_id
    GROUP BY r.pickup_city, r.driver_id
)
SELECT pickup_city, d.name AS driver_name, total_revenue
FROM (
    SELECT pickup_city, driver_id, total_revenue,
           ROW_NUMBER() OVER (PARTITION BY pickup_city ORDER BY total_revenue DESC) AS rn
    FROM city_revenue
) ranked
JOIN drivers d ON ranked.driver_id = d.driver_id
WHERE rn <= 3
ORDER BY pickup_city, total_revenue DESC;

-- 8. Top 10 drivers eligible for bonuses
WITH driver_bonus AS (
    SELECT r.driver_id,
           COUNT(*) AS rides_completed,
           AVG(d.rating) AS avg_rating,
           SUM(CASE WHEN r.status = 'cancelled' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100 AS cancellation_rate
    FROM valid_rides r
    JOIN drivers d ON r.driver_id = d.driver_id
    GROUP BY r.driver_id
)
SELECT d.name AS driver_name, rides_completed, ROUND(avg_rating, 2) AS avg_rating,
       ROUND(cancellation_rate, 2) AS cancellation_rate_percent
FROM driver_bonus db
JOIN drivers d ON db.driver_id = d.driver_id
WHERE rides_completed >= 30
  AND avg_rating >= 4.5
  AND cancellation_rate < 5
ORDER BY rides_completed DESC
LIMIT 10;
