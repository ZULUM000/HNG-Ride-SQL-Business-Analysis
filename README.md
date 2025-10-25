


# HNG Ride – SQL Business Analysis (Stage 2A)

## Overview
This project was completed as part of the HNG Internship (Data Analytics Track – Stage 2A).  
It focuses on cleaning, preparing, and analyzing transactional ride data from **HNG Ride**, a mid-sized transportation company in North America.  
The goal is to assess operational performance between **June 2021 and December 2024**, derive actionable business insights, and support data-driven decision-making.

---

## Project Objectives
1. Clean and validate raw data from four CSV datasets: `drivers`, `riders`, `rides`, and `payments`.
2. Handle missing values, duplicates, inconsistent formatting, and invalid records.
3. Focus on completed rides only (where `amount > 0`).
4. Restrict analysis to rides between **June 2021 and December 2024**.
5. Write SQL queries to answer eight key business questions.
6. Present findings in a structured report with evidence of query outputs and insights.

---

## Tools and Environment
- **Database:** PostgreSQL (pgAdmin 4)
- **Visualization:** Power BI (for exploratory insights and trend dashboards)
- **Data Format:** CSV
- **Languages:** SQL
- **System Used:** HP EliteBook 1040 G6 (32GB RAM, 512GB SSD)

---

## Database Schema

### 1. Drivers
| Column Name | Data Type | Description |
|--------------|------------|-------------|
| driver_id | SERIAL PRIMARY KEY | Unique identifier for each driver |
| name | VARCHAR(100) | Driver's full name |
| signup_date | TIMESTAMP | Registration date |
| city | VARCHAR(100) | City of operation |
| rating | NUMERIC(2,1) | Average driver rating |

### 2. Riders
| Column Name | Data Type | Description |
|--------------|------------|-------------|
| rider_id | SERIAL PRIMARY KEY | Unique rider identifier |
| name | VARCHAR(100) | Rider's name |
| signup_date | TIMESTAMP | Registration date |
| city | VARCHAR(100) | City of residence |
| email | VARCHAR(150) | Contact email |

### 3. Rides
| Column Name | Data Type | Description |
|--------------|------------|-------------|
| ride_id | SERIAL PRIMARY KEY | Unique ride identifier |
| rider_id | INT | Foreign key referencing riders |
| driver_id | INT | Foreign key referencing drivers |
| request_time | TIMESTAMP | Time when ride was requested |
| pickup_time | TIMESTAMP | Time when ride began |
| dropoff_time | TIMESTAMP | Time when ride ended |
| pickup_city | VARCHAR(100) | City where ride started |
| dropoff_city | VARCHAR(100) | City where ride ended |
| distance_km | NUMERIC(10,2) | Ride distance |
| status | VARCHAR(50) | Ride status (completed/cancelled) |
| fare | NUMERIC(10,2) | Fare charged |

### 4. Payments
| Column Name | Data Type | Description |
|--------------|------------|-------------|
| payment_id | SERIAL PRIMARY KEY | Payment record ID |
| ride_id | INT | Foreign key referencing rides |
| amount | NUMERIC(10,2) | Amount paid |
| method | VARCHAR(50) | Payment method (cash/card/etc.) |
| paid_date | TIMESTAMP | Payment timestamp |

---

## Data Preparation Steps
1. **Created tables manually** with appropriate constraints.
2. **Imported data** using PostgreSQL’s `\copy` command.
3. **Converted date columns** from text to `TIMESTAMP`.
4. **Removed duplicates** using `ROW_NUMBER()` window function.
5. **Standardized text fields** (`INITCAP()` and `TRIM()` for city names).
6. **Replaced invalid fares** with the city’s mean fare.
7. **Added engineered columns:**
   - `ride_duration` = `dropoff_time - pickup_time`
   - `ride_month` and `ride_year` extracted from `request_time`
8. **Created views:**
   - `completed_rides` → only rides with `amount > 0`
   - `valid_rides` → rides within the time range `2021-06-01` to `2024-12-31`

---

## Business Analysis Queries
![WhatsApp Image 2025-10-25 at 10 35 00_c2180c83](https://github.com/user-attachments/assets/3f181ecb-e80e-45e6-9a53-8049b38e93bc)

### 1. Top 10 Longest Rides by Distance
Identifies the longest trips, including driver, rider, pickup/dropoff cities, and payment method.
```sql
SELECT r.ride_id, d.name AS driver_name, rd.name AS rider_name,
       r.pickup_city, r.dropoff_city, p.method AS payment_method, r.distance_km
FROM completed_rides r
JOIN drivers d ON r.driver_id = d.driver_id
JOIN riders rd ON r.rider_id = rd.rider_id
LEFT JOIN payments p ON r.ride_id = p.ride_id
ORDER BY r.distance_km DESC
LIMIT 10;
````

### 2. Riders Who Signed Up in 2021 and Still Took Rides in 2024

Tracks customer retention over time.

```sql
SELECT COUNT(DISTINCT r.rider_id) AS active_riders_2024
FROM riders r
JOIN completed_rides cr ON r.rider_id = cr.rider_id
WHERE EXTRACT(YEAR FROM r.signup_date) = 2021
  AND EXTRACT(YEAR FROM cr.request_time) = 2024;
```

### 3. Quarterly Revenue Comparison (2021–2024)

Compares revenue trends per quarter and calculates year-over-year growth.

```sql
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
```

### 4. Top 5 Drivers by Average Monthly Rides Since Signup

Measures consistency of active drivers.

```sql
WITH driver_stats AS (
    SELECT driver_id,
           COUNT(*) AS total_rides,
           EXTRACT(MONTH FROM age(MAX(request_time), MIN(request_time))) + 1 AS active_months
    FROM completed_rides
    GROUP BY driver_id
)
SELECT d.driver_id, d.name,
       ROUND(total_rides::NUMERIC / NULLIF(active_months,0),2) AS avg_rides_per_month
FROM driver_stats ds
JOIN drivers d ON ds.driver_id = d.driver_id
ORDER BY avg_rides_per_month DESC
LIMIT 5;
```

### 5. Cancellation Rate per City

Highlights cities with poor operational performance.

```sql
SELECT pickup_city,
       ROUND(100.0 * SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*),2) AS cancellation_rate_percent
FROM valid_rides
GROUP BY pickup_city
ORDER BY cancellation_rate_percent DESC;
```

### 6. Riders with More Than 10 Rides Who Never Paid with Cash

Analyzes user payment preferences.

```sql
SELECT r.rider_id, r.name, COUNT(cr.ride_id) AS total_rides
FROM riders r
JOIN completed_rides cr ON r.rider_id = cr.rider_id
LEFT JOIN payments p ON cr.ride_id = p.ride_id
GROUP BY r.rider_id, r.name
HAVING COUNT(cr.ride_id) > 10
   AND SUM(CASE WHEN p.method = 'cash' THEN 1 ELSE 0 END) = 0;
```

### 7. Top 3 Drivers per City by Total Revenue (June 2021–Dec 2024)

Determines the top-earning drivers in each city.

```sql
WITH city_revenue AS (
    SELECT pickup_city, driver_id, SUM(fare) AS total_revenue
    FROM valid_rides
    GROUP BY pickup_city, driver_id
)
SELECT pickup_city, driver_id, d.name AS driver_name, total_revenue
FROM (
    SELECT pickup_city, driver_id, total_revenue,
           ROW_NUMBER() OVER(PARTITION BY pickup_city ORDER BY total_revenue DESC) AS rn
    FROM city_revenue
) cr
JOIN drivers d ON cr.driver_id = d.driver_id
WHERE rn <= 3
ORDER BY pickup_city, total_revenue DESC;
```

### 8. Top 10 Drivers Qualified for Bonuses

Evaluates eligibility based on ride volume, rating, and low cancellation rate.

```sql
WITH driver_stats_bonus AS (
    SELECT r.driver_id, COUNT(*) AS rides_completed,
           AVG(d.rating) AS avg_rating,
           SUM(CASE WHEN r.status = 'cancelled' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100 AS cancellation_rate
    FROM valid_rides r
    JOIN drivers d ON r.driver_id = d.driver_id
    GROUP BY r.driver_id, d.rating
)
SELECT ds.driver_id, d.name, rides_completed,
       ROUND(avg_rating,2) AS avg_rating, ROUND(cancellation_rate,2) AS cancellation_rate_percent
FROM driver_stats_bonus ds
JOIN drivers d ON ds.driver_id = d.driver_id
WHERE rides_completed >= 30 AND avg_rating >= 4.5 AND cancellation_rate < 5
ORDER BY rides_completed DESC
LIMIT 10;
```

---

## Insights Summary

* **Revenue Growth:** Significant fluctuations across quarters, with highest YoY growth in 2023 Q4, likely driven by urban expansion and improved payment compliance.
* **Customer Retention:** 2021 signups show moderate retention, with only a small percentage still active in 2024.
* **Driver Performance:** Top drivers maintain monthly consistency above 30 rides per month.
* **Cancellations:** A few major cities show higher-than-average cancellation rates, indicating potential service issues.
* **Payment Behavior:** Most loyal riders prefer digital or card payments over cash.
* **Bonus Qualification:** Only a limited number of drivers (under 10%) meet the full bonus eligibility criteria.

---

## Folder Structure

```
HNG_Ride_Stage2A/
│
├── 1.sql
├── 2.sql
├── 3.sql
├── 4.sql
├── 5.sql
├── 6.sql
├── 7.sql
├── 8.sql
│
├── HNG_TASK2A_DOCUMENTATION.docx
├── README.md
└── PowerBI_Report.pbix
```

---

## Author

**Name:** Enoch Chukwuebuka
**Role:** Data Analyst Intern
**Track:** Data Analytics (HNG Internship)
**Tools:** PostgreSQL, Power BI, Excel, Python (for preprocessing support)

---

## License

This project is part of the HNG Internship Program and is for educational purposes only.
Unauthorized commercial use is prohibited.

```
