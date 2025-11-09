-- Initial complex query to retrieve bookings with all related details
SELECT
    b.booking_id,
    b.start_date,
    b.end_date,
    b.total_price,
    b.status,
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    p.property_id,
    p.name AS property_name,
    p.location,
    pay.payment_id,
    pay.amount,
    pay.payment_method,
    pay.payment_date
FROM
    Booking AS b
JOIN
    "User" AS u
    ON b.user_id = u.user_id
JOIN
    Property AS p
    ON b.property_id = p.property_id
LEFT JOIN
    Payment AS pay
    ON pay.booking_id = b.booking_id
ORDER BY
    b.created_at DESC;
