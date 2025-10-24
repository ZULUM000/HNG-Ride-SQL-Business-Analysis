SELECT r.ride_id,
       d.name AS driver_name,
       rd.name AS rider_name,
       r.pickup_city,
       r.dropoff_city,
       p.method AS payment_method,
       r.distance_km
FROM rides r
JOIN drivers d ON r.driver_id = d.driver_id
JOIN riders rd ON r.rider_id = rd.rider_id
LEFT JOIN payments p ON r.ride_id = p.ride_id
ORDER BY r.distance_km DESC
LIMIT 10;