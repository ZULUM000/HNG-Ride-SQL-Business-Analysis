
---

# 🚗 HNG Ride SQL Business Analysis

**Data Analytics Track – Stage 2A Task**

---

## 🧠 Project Overview

HNG Ride is a mid-sized transportation company operating in North America. Management wants to analyze ride operations from **June 2021 to December 2024** to assess performance, trends, and areas for improvement.

As a **Data Analyst**, my task was to:

* Clean and validate the messy datasets.
* Write SQL queries to answer critical business questions.
* Summarize actionable insights in a clear, concise business report.

---

## 📊 Objectives

1. Clean and prepare the dataset by addressing duplicates, inconsistent values, and invalid entries.
2. Analyze the data using SQL to extract key performance insights.
3. Present findings that can guide management’s decision-making.

---

## 🧹 Data Cleaning & Preparation

Steps taken during data preparation:

* **Removed duplicates** across tables.
* **Handled missing values** in payments, rides, and users tables.
* **Corrected inconsistent city names** (e.g., “New York City”, “NYC”, “newyork”).
* **Validated data integrity** by ensuring:

  * Positive fares and distances.
  * Valid driver ratings (between 1 and 5).
  * Logical timestamps (ride start < ride end).
* Filtered dataset to only include rides from **June 2021 – December 2024**.

---

## ❓ Business Questions & SQL Queries

### 1️⃣ Top 10 Longest Rides

Find the 10 longest rides by distance with details including driver, rider, cities, and payment method.

### 2️⃣ Rider Retention

How many riders who signed up in 2021 still took rides in 2024?

### 3️⃣ Quarterly Revenue Growth

Compare quarterly revenue between 2021–2024 and determine which quarter had the highest year-over-year (YoY) growth.

### 4️⃣ Driver Consistency

For each driver, calculate their average monthly rides since signup and find the top 5 with the highest consistency.

### 5️⃣ City Cancellation Rate

Calculate the cancellation rate per city and identify which city has the highest rate.

### 6️⃣ Non-Cash Riders

Identify riders who have completed more than 10 rides but never paid with cash.

### 7️⃣ Top 3 Drivers per City

Find the top 3 drivers in each city by total revenue earned between June 2021 and December 2024 (based on pickup city).

### 8️⃣ Bonus Qualification

List the top 10 drivers eligible for bonuses who meet all the following criteria:

* At least **30 completed rides**
* Average rating **≥ 4.5**
* Cancellation rate **< 5%**

---

## 🧾 Deliverables

### 📁 Files Included

| File    | Description                        |
| ------- | ---------------------------------- |
| `1.sql` | Query for Top 10 Longest Rides     |
| `2.sql` | Query for Rider Retention          |
| `3.sql` | Query for Quarterly Revenue Growth |
| `4.sql` | Query for Driver Consistency       |
| `5.sql` | Query for City Cancellation Rate   |
| `6.sql` | Query for Non-Cash Riders          |
| `7.sql` | Query for Top 3 Drivers per City   |
| `8.sql` | Query for Bonus Qualification      |

### 📘 Report

A structured **PDF report** titled `HNG_Ride_SQL_Business_Analysis_Report.pdf` containing:

* Overview of objectives
* Screenshots of each SQL query
* Query outputs and results
* Key business insights and recommendations

---

## 🧩 Tools & Technologies

* **Microsoft SQL Server (MSSMS)** – for executing queries and cleaning data.
* **Excel / CSV** – for initial inspection and validation.
* **PDF Export Tools** – for compiling query screenshots and insights.

---

## 💡 Key Insights (Examples)

* Significant YoY revenue growth observed in **Q3 2023**.
* **City A** recorded the **highest cancellation rate**.
* **Driver B** consistently ranked in top performance metrics (high ratings, low cancellations).
* A large share of loyal riders from 2021 remained active in 2024, showing strong retention.

---

## 🚀 How to Run

1. Import the provided CSV files into your SQL database (e.g., Microsoft SQL Server).
2. Clean and preprocess data as outlined.
3. Execute the `.sql` files sequentially (1.sql → 8.sql).
4. Review results and insights in the provided PDF report.

---

## 👤 Author

**Name:** Enoch Chukwuebuka
**Role:** Data Analyst (HNG Internship 2025)
**Tools:** SQL, MSSMS, Excel
**Contact:** [LinkedIn](#) | [GitHub](#) | [Email](#)

---

## 🏁 License

This project is open-source and part of the **HNG Internship Data Analytics Track (Stage 2A)**.
Use for learning and reference purposes only.

---

Would you like me to include **Markdown code snippets** (SQL samples for 2 or 3 of the questions) in the README so it looks even more professional on GitHub?
