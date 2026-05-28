select * from airbnb_singapore.listing;
select * from airbnb_singapore.host;
select * from airbnb_singapore.review;

ALTER TABLE airbnb_singapore.host ADD PRIMARY KEY (host_id);

SHOW VARIABLES LIKE "secure_file_priv"; -- show location to store files to run 'load data infile'

CREATE TABLE airbnb_singapore.listing (
    listing_id BIGINT NOT NULL,
    host_id BIGINT NOT NULL,
    neighbourhood VARCHAR(100) NULL,
    neighbourhood_cleansed VARCHAR(100) NULL,
    property_type VARCHAR(100) NULL,
    room_type VARCHAR(100) NULL,
    accommodates INT NULL,
    bathrooms DECIMAL(3, 1) NULL, -- max 3 digits, with max 1 decimal place
    bathroom_type VARCHAR(100) NULL,
    bedrooms INT NULL,
    beds INT NULL,
    amenities TEXT NULL, -- TEXT type allows long lists of amenities
    price DECIMAL(10, 2) NULL,
    PRIMARY KEY (listing_id)
);

LOAD DATA INFILE '/listing.csv'
INTO TABLE airbnb_singapore.listing
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 LINES -- ignore headers
(
    listing_id,
    host_id,
    neighbourhood,
    neighbourhood_cleansed,
    property_type,
    room_type,
    @v_accommodates, -- Load problem column into a variable
    @v_bathrooms,
    bathroom_type,
    @v_bedrooms,
    @v_beds,
    amenities,
    @v_price
)
SET 
    accommodates = NULLIF(REGEXP_REPLACE(@v_accommodates, '[^0-9]', ''), ''), -- clear invisible characters using regex
    bathrooms    = NULLIF(REGEXP_REPLACE(@v_bathrooms, '[^0-9.]', ''), ''),
    bedrooms     = NULLIF(REGEXP_REPLACE(@v_bedrooms, '[^0-9]', ''), ''),
    beds         = NULLIF(REGEXP_REPLACE(@v_beds, '[^0-9]', ''), ''),
    price        = NULLIF(REGEXP_REPLACE(@v_price, '[^0-9.]', ''), '');

CREATE TABLE airbnb_singapore.review (
    listing_id BIGINT NOT NULL,
    host_id BIGINT NOT NULL,
    number_of_reviews int NULL,
    review_scores_rating DECIMAL(3, 2) NULL,
    review_scores_accuracy DECIMAL(3, 2) NULL,
    review_scores_cleanliness DECIMAL(3, 2) NULL,
    review_scores_checkin DECIMAL(3, 2) NULL,
    review_scores_communication DECIMAL(3, 2) NULL,
    review_scores_location DECIMAL(3, 2) NULL,
    review_scores_value DECIMAL(3, 2) NULL,
    PRIMARY KEY (listing_id)
);

LOAD DATA INFILE '/review.csv'
INTO TABLE airbnb_singapore.review
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 LINES -- ignore headers
(
    listing_id,
    host_id,
    @v_number_of_reviews,
    @v_review_scores_rating,
    @v_review_scores_accuracy,
    @v_review_scores_cleanliness,
    @v_review_scores_checkin,
    @v_review_scores_communication,
    @v_review_scores_location,
    @v_review_scores_value
)
SET 
    number_of_reviews 			= NULLIF(REGEXP_REPLACE(@v_number_of_reviews, '[^0-9.]', ''), ''),
    review_scores_rating 			= NULLIF(REGEXP_REPLACE(@v_review_scores_rating, '[^0-9.]', ''), ''),
    review_scores_accuracy 		= NULLIF(REGEXP_REPLACE(@v_review_scores_accuracy, '[^0-9.]', ''), ''),
    review_scores_cleanliness 	= NULLIF(REGEXP_REPLACE(@v_review_scores_cleanliness, '[^0-9.]', ''), ''),
    review_scores_checkin 		= NULLIF(REGEXP_REPLACE(@v_review_scores_checkin, '[^0-9.]', ''), ''),
    review_scores_communication 	= NULLIF(REGEXP_REPLACE(@v_review_scores_communication, '[^0-9.]', ''), ''),
    review_scores_location 		= NULLIF(REGEXP_REPLACE(@v_review_scores_location, '[^0-9.]', ''), ''),
    review_scores_value 			= NULLIF(REGEXP_REPLACE(@v_review_scores_value, '[^0-9.]', ''), '');