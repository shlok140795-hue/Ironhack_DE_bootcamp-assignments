--Q1. Show the first 10 bookings.
SELECT * FROM uk_travel LIMIT 10;

//Q2. How many bookings are there in total?  Solution:30
SELECT COUNT(*) AS total_bookings FROM uk_travel;

/*Q3. List all bookings to Spain.*/
SELECT booking_id, customer_name, destination_city, destination_country, travel_start_date
FROM uk_travel
WHERE destination_country = 'Spain';

--Q4. Find all Cancelled bookings.
SELECT booking_id, customer_name, destination_city, destination_country, status
FROM uk_travel
WHERE status = 'Cancelled';

--Q5. Which bookings have no discount recorded (NULL)?
SELECT booking_id, customer_name, discount_pct
FROM bookings
WHERE discount_pct IS NULL;

--Level 2: Aggregations
--Q6. Calculate the revenue for every booking.
SELECT booking_id, customer_name,
       travellers * price_per_person_gbp * (1 - COALESCE(discount_pct,0)/100) AS revenue_gbp
FROM uk_travel;

--Q7. Total revenue by package type for non-cancelled bookings, highest first.
SELECT package_type,
       ROUND(SUM(travellers * price_per_person_gbp * (1 - COALESCE(discount_pct,0)/100)), 2) AS revenue_gbp
FROM uk_travel
WHERE status <> 'Cancelled'
GROUP BY package_type
ORDER BY revenue_gbp DESC;

--Q8. Which destination country is booked most often?
SELECT destination_country, COUNT(*) AS bookings
FROM uk_travel
GROUP BY destination_country
ORDER BY bookings DESC
LIMIT 1;

--Q9. Share of bookings by payment mode.
SELECT payment_mode,
       COUNT(*) AS bookings,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_share
FROM uk_travel
GROUP BY payment_mode
ORDER BY bookings DESC;

--Q10. Customers with more than 2 bookings.
SELECT customer_name, COUNT(*) AS bookings
FROM uk_travel
GROUP BY customer_name
HAVING COUNT(*) > 2;

--Q11. Average rating per destination country (ignore NULL ratings), with at least 2 rated trips.
SELECT destination_country,
       ROUND(AVG(rating), 2) AS avg_rating,
       COUNT(rating) AS rated_trips
FROM uk_travel
GROUP BY destination_country
HAVING COUNT(rating) >= 2
ORDER BY avg_rating DESC;

--Level 3: Intermediate / Dates and Window Functions
--Q12. Work out each trip's return date and how far in advance it was booked.
SELECT booking_id, customer_name, booking_date,
       DATEADD('day', nights, travel_start_date) AS return_date,
       DATEDIFF('day', booking_date, travel_start_date) AS lead_time_days
FROM uk_travel;

--Q13. Monthly bookings count and revenue by travel month.
SELECT DATE_TRUNC('month', travel_start_date) AS travel_month,
       COUNT(*) AS bookings,
       ROUND(SUM(travellers * price_per_person_gbp * (1 - COALESCE(discount_pct,0)/100)), 2) AS revenue_gbp
FROM uk_travel
WHERE status <> 'Cancelled'
GROUP BY travel_month
ORDER BY travel_month;

--Q14. Rank customers by total spend within each home city.
SELECT home_city, customer_name, total_spend,
       RANK() OVER (PARTITION BY home_city ORDER BY total_spend DESC) AS city_rank
FROM (
  SELECT home_city, customer_name,
         SUM(travellers * price_per_person_gbp * (1 - COALESCE(discount_pct,0)/100)) AS total_spend
  FROM uk_travel
  WHERE status <> 'Cancelled'
  GROUP BY home_city, customer_name
);

--Q15. For repeat customers, show the gap in days between consecutive bookings.
SELECT customer_name, booking_date,
       DATEDIFF('day',
         LAG(booking_date) OVER (PARTITION BY customer_id ORDER BY booking_date),
         booking_date) AS days_since_last_booking
FROM uk_travel
QUALIFY COUNT(*) OVER (PARTITION BY customer_id) > 1
ORDER BY customer_name, booking_date;

--Q16. Top 2 destinations by revenue within each package type (use QUALIFY).
SELECT package_type, destination_city,
       SUM(travellers * price_per_person_gbp) AS revenue_gbp
FROM uk_travel
WHERE status <> 'Cancelled'
GROUP BY package_type, destination_city
QUALIFY ROW_NUMBER() OVER (PARTITION BY package_type ORDER BY SUM(travellers * price_per_person_gbp) DESC) <= 2;

--Q17. Cancellation rate by package type.
SELECT package_type,
       COUNT(*) AS bookings,
       SUM(IFF(status = 'Cancelled', 1, 0)) AS cancelled,
       ROUND(100 * SUM(IFF(status = 'Cancelled', 1, 0)) / COUNT(*), 1) AS cancel_rate_pct
FROM uk_travel
GROUP BY package_type;

--Q18. Segment bookings into Budget, Mid-range and Premium using CASE.
SELECT booking_id, destination_city, price_per_person_gbp,
       CASE
         WHEN price_per_person_gbp < 400 THEN 'Budget'
         WHEN price_per_person_gbp < 900 THEN 'Mid-range'
         ELSE 'Premium'
       END AS price_band
FROM uk_travel;

--Level 4: Snowflake-Specific Features (great for live demos)
--Q19. Time Travel. Delete Cancelled bookings by mistake, then recover them.
DELETE FROM uk_travel WHERE status = 'Cancelled';
SELECT COUNT(*) FROM uk_travel;                       -- fewer rows


-- Table as it was 5 minutes ago
SELECT COUNT(*) FROM uk_travel AT(OFFSET => -60*5);


-- Restore using the query ID of the DELETE (see Query History)
INSERT INTO uk_travel
SELECT * FROM uk_travel BEFORE(STATEMENT => '01c85c2d-0000-bb7f-0001-49aa0002714e')
WHERE status = 'Cancelled';

--Q20. Zero-copy cloning. Create a dev copy instantly and change it safely.
CREATE TABLE uk_travel_dev CLONE uk_travel;
UPDATE uk_travel_dev SET status = 'Completed' WHERE status = 'Upcoming';


SELECT status, COUNT(*) FROM uk_travel GROUP BY status;      -- unchanged
SELECT status, COUNT(*) FROM uk_travel_dev GROUP BY status;  -- changed

--Q21. UNDROP.
DROP TABLE uk_travel_dev;
UNDROP TABLE uk_travel_dev;

--Q22. Semi-structured data (VARIANT). Query JSON from a booking website's event log.
CREATE OR REPLACE TABLE uk_travel_events (event VARIANT); ----variant  is to store JSON data


INSERT INTO uk_travel_events
SELECT PARSE_JSON('{"booking_id":2001,"device":"mobile","extras":[{"name":"Airport Transfer","price":35},{"name":"Travel Insurance","price":22}]}'); --PARSE_JSON() – to convert JSON text into Snowflake JSON data.


SELECT event:booking_id::INT AS booking_id,
       event:device::STRING AS device,
       f.value:name::STRING AS extra_name,
       f.value:price::NUMBER AS extra_price_gbp
FROM uk_travel_events,
     LATERAL FLATTEN(input => event:extras) f; --FLATTEN() – to convert JSON arrays into individual rows.

--Q23. Secure data sharing idea. Create a view for the marketing team that hides customer names.
CREATE OR REPLACE VIEW v_marketing_bookings AS
SELECT booking_id, home_city, destination_country, package_type,
       travel_start_date, travellers, status
FROM bookings;

--Q24. Dynamic data masking (Enterprise edition). Mask customer names for non-admin roles.
CREATE OR REPLACE MASKING POLICY mask_name AS (val STRING) RETURNS STRING ->
  CASE WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN') THEN val ELSE '*** MASKED ***' END;

ALTER TABLE bookings MODIFY COLUMN customer_name SET MASKING POLICY mask_name;

--Q25. Warehouse scaling.
ALTER WAREHOUSE travel_wh SET WAREHOUSE_SIZE = 'MEDIUM';
-- run a heavy query
ALTER WAREHOUSE travel_wh SET WAREHOUSE_SIZE = 'XSMALL';
