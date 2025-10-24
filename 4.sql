WITH driver_months AS (
    SELECT driver_id,
           DATE_TRUNC('month', MIN(r.request_time)) AS first_ride_month,
           DATE_TRUNC('month', MAX(r.request_time)) AS last_ride_month
    FROM rides r
    GROUP BY driver_id
),
driver_stats AS (
    SELECT r.driver_id,
           COUNT(*) AS total_rides,
           EXTRACT(MONTH FROM age(MAX(r.request_time), MIN(r.request_time))) + 1 AS active_months
    FROM rides r
    GROUP BY r.driver_id
)
SELECT d.driver_id, dr.name, ROUND(total_rides::NUMERIC / NULLIF(active_months,0),2) AS avg_rides_per_month
FROM driver_stats d
JOIN drivers dr ON d.driver_id = dr.driver_id
ORDER BY avg_rides_per_month DESC
LIMIT 5;