WITH driver_stats_bonus AS (
    SELECT r.driver_id,
           COUNT(*) AS rides_completed,
           AVG(d.rating) AS avg_rating,
           SUM(CASE WHEN r.status = 'cancelled' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100 AS cancellation_rate
    FROM rides r
    JOIN drivers d ON r.driver_id = d.driver_id
    GROUP BY r.driver_id, d.rating
)
SELECT ds.driver_id, d.name, rides_completed, ROUND(avg_rating,2) AS avg_rating,
       ROUND(cancellation_rate,2) AS cancellation_rate_percent
FROM driver_stats_bonus ds
JOIN drivers d ON ds.driver_id = d.driver_id
WHERE rides_completed >= 30
  AND avg_rating >= 4.5
  AND cancellation_rate < 5
ORDER BY rides_completed DESC
LIMIT 10;