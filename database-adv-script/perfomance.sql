SELECT
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    u.first_name,
    u.last_name,
    u.email,
    p.name AS property_name,
    p.location,
    pay.amount AS payment_amount,
    pay.payment_method
FROM
    Booking AS b
JOIN
    "User" AS u
ON
    b.user_id = u.user_id
JOIN
    Property AS p
ON
    b.property_id = p.property_id
JOIN
    Payment AS pay
ON
    b.booking_id = pay.booking_id
WHERE
    b.status = 'confirmed'
    AND p.location = 'Lagos, Nigeria'
ORDER BY
    b.start_date DESC;

SELECT
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    u.first_name,
    u.last_name,
    u.email,
    p.name AS property_name,
    p.location,
    pay.amount AS payment_amount,
    pay.payment_method
FROM
    Booking AS b
JOIN
    "User" AS u
ON
    b.user_id = u.user_id
JOIN
    Property AS p
ON
    b.property_id = p.property_id
JOIN
    Payment AS pay
ON
    b.booking_id = pay.booking_id
WHERE
    b.status = 'confirmed'
    AND p.location = 'Lagos, Nigeria'
ORDER BY
    b.start_date DESC;
