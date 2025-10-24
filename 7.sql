WITH city_revenue AS (
    SELECT r.pickup_city,
           r.driver_id,
           SUM(r.fare) AS total_revenue
    FROM rides r
    WHERE r.request_time BETWEEN '2021-06-01' AND '2024-12-31'
    GROUP BY r.pickup_city, r.driver_id
)
SELECT cr.pickup_city, cr.driver_id, d.name AS driver_name, cr.total_revenue
FROM (
    SELECT pickup_city, driver_id, total_revenue,
           ROW_NUMBER() OVER(PARTITION BY pickup_city ORDER BY total_revenue DESC) AS rn
    FROM city_revenue
) cr
JOIN drivers d ON cr.driver_id = d.driver_id
WHERE rn <= 3
ORDER BY cr.pickup_city, total_revenue DESC
LIMIT 3;