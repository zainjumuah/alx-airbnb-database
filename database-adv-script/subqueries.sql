-- Query to find all properties where the avg rating > 4.0 using a subquery
SELECT
    p.property_id,
    p.name AS property_name,
    p.location,
    p.pricepernight
FROM
    Property AS p
WHERE
    p.property_id IN (
        SELECT
            r.property_id
        FROM
            Review AS r
        GROUP BY
            r.property_id
        HAVING
            AVG(r.rating) > 4.0
    )
ORDER BY
    p.name ASC;

-- Correlated subquery to find users who have made more than 3 bookings (the Idans)
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    u.email
FROM
    "User" AS u
WHERE
    (
        SELECT
            COUNT(*)
        FROM
            Booking AS b
        WHERE
            b.user_id = u.user_id
    ) > 3
ORDER BY
    u.first_name ASC;
