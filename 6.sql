SELECT r.rider_id, r.name, COUNT(ri.ride_id) AS total_rides
FROM riders r
JOIN rides ri ON r.rider_id = ri.rider_id
LEFT JOIN payments p ON ri.ride_id = p.ride_id
GROUP BY r.rider_id, r.name
HAVING COUNT(ri.ride_id) > 10
   AND SUM(CASE WHEN p.method = 'cash' THEN 1 ELSE 0 END) = 0;