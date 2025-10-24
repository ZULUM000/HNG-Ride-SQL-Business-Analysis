SELECT pickup_city,
       ROUND(100.0 * SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*),2) AS cancellation_rate_percent
FROM rides
GROUP BY pickup_city
ORDER BY cancellation_rate_percent DESC
LIMIT 10;