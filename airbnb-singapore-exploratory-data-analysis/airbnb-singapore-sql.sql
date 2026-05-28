USE airbnb_singapore;

-- distinct listing count
SELECT listing_id, host_id
FROM listing
UNION DISTINCT
SELECT listing_id, host_id
FROM review;

-- Number of listings for each host with a rating of
-- at least 3 (grade C) and having at least 20 reviews
SELECT host_id, listing_id,
CASE
WHEN review_scores_rating BETWEEN 3 AND 4 THEN 'C'
WHEN review_scores_rating BETWEEN 4 AND 4.5 THEN 'B'
WHEN review_scores_rating > 4.5 THEN 'A'
END 
AS review_grade,
COUNT(*) OVER(PARTITION BY host_id) AS listing_count
FROM review
WHERE number_of_reviews > 20 AND review_scores_rating >= 3
ORDER BY host_id, review_grade;

-- Running total value of property grouped by neighbourhood
SELECT listing_id, property_type, neighbourhood_cleansed, price,
SUM(price) OVER(PARTITION BY neighbourhood_cleansed ORDER BY price) AS total_value
FROM listing
WHERE price IS NOT NULL;
-- same final order but without partition and running total
-- if both used, order by overrides final order
-- ORDER BY neighbourhood_cleansed, price;

-- Percentage of total value per property type
WITH total_value_property AS
(SELECT property_type, MIN(price) AS lowest_value, MAX(price) AS highest_value, 
AVG(price) AS average_value, SUM(price) as total_value_property
FROM listing
WHERE price IS NOT NULL
GROUP BY property_type)
SELECT *, total_value_property/(SELECT SUM(price) FROM listing)*100 AS total_value_percentage
FROM total_value_property
ORDER BY total_value_percentage DESC;

-- Temporary table showing the amenities for each listings
CREATE TEMPORARY TABLE temp_amenities 
SELECT listing_id, host_id, price,
REGEXP_LIKE(amenities, 'air con') AS air_conditioning,
REGEXP_LIKE(amenities, 'essentials') AS essentials,
REGEXP_LIKE(amenities, 'washer') AS washer,
REGEXP_LIKE(amenities, 'wifi') AS wifi
FROM listing
WHERE price IS NOT NULL
ORDER BY price;
SELECT * FROM temp_amenities;

-- Procedure to show listings with selected amenities, price and review scores based on user inputs 
-- DROP PROCEDURE listing_filter;
DELIMITER $$
CREATE PROCEDURE listing_filter(p_price DECIMAL(10, 2), p_review_score DECIMAL(3, 2), p_review_count INT,
p_air_con INT, p_essentials INT, p_washer INT, p_wifi INT)
BEGIN
SELECT a.listing_id, a.host_id, a.price, b.review_scores_rating
FROM temp_amenities AS a INNER JOIN review AS b
ON a.listing_id = b.listing_id
WHERE a.price <= p_price AND b.review_scores_rating >= p_review_score AND number_of_reviews >= p_review_count
AND a.air_conditioning = p_air_con AND a.essentials = p_essentials AND a.washer = p_washer AND a.wifi = p_wifi
ORDER BY a.price, b.review_scores_rating DESC;
END $$
DELIMITER ;
CALL listing_filter(100, 4.5, 20, 1, 1, 1, 1);

-- Trigger to insert new entries into other tables after inserting a new listing
DELIMITER $$
CREATE TRIGGER insert_new_entry
AFTER INSERT ON listing FOR EACH ROW
BEGIN
INSERT INTO review(listing_id, host_id) VALUES (NEW.listing_id, NEW.host_id);
INSERT INTO host(host_id) VALUES (NEW.host_id);
END $$
DELIMITER ;
-- INSERT INTO airbnb_singapore.listing VALUES
-- (234634566, 34634673, 'Pasir Ris', 'East', 'condo', 'Private room', 2, 1, 'Private', 1, 2,
-- '["Washer", "Free parking on premises", "Essentials", "Elevator", "Shampoo", "Heating",
-- "Air conditioning", "Hot water", "Wifi", "Long term stays allowed", "Kitchen", "Hangers", "Pool"]', 150);
-- select * from airbnb_singapore.listing where listing_id = 234634566;
-- select * from airbnb_singapore.host where host_id = 34634673;
-- select * from airbnb_singapore.review where listing_id = 234634566;

-- Event to update the price due to inflation every year
DELIMITER $$
CREATE EVENT price_inflation
ON SCHEDULE EVERY 1 YEAR
DO BEGIN
UPDATE listing
SET price = price * 0.018;
END $$
DELIMITER ;