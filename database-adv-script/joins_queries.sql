--  INNER JOINs
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status
FROM
    "User" AS u
INNER JOIN
    Booking AS b
ON
    u.user_id = b.user_id;


-- LEFT JOINs
SELECT
    p.property_id,
    p.name AS property_name,
    p.location,
    r.review_id,
    r.rating,
    r.comment,
    r.created_at
FROM
    Property AS p
LEFT JOIN
    Review AS r
ON
    p.property_id = r.property_id;


-- FULL OUTER JOINs
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date,
    b.status
FROM
    "User" AS u
FULL OUTER JOIN
    Booking AS b
ON
    u.user_id = b.user_id;
