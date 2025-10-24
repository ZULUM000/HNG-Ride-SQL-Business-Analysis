SELECT COUNT(DISTINCT r.rider_id) AS active_riders_2024
FROM riders r
JOIN rides ri ON r.rider_id = ri.rider_id
WHERE EXTRACT(YEAR FROM r.signup_date) = 2021
  AND EXTRACT(YEAR FROM ri.request_time) = 2024;