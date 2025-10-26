-- 1. USER TABLE

INSERT INTO "User" (first_name, last_name, email, password_hash, phone_number, role)
VALUES
('Zainab', 'Johnson', 'anurang@example.com', '$2b$12$hashalice123', '+2348012345678', 'host'),
('Timi', 'Scott', 'aanu@example.com', '$2b$12$hashbob123', '+2348023456789', 'guest'),
('Tofs', 'Zain', 'moyo@example.com', '$2b$12$hashcharlie123', '+2348034567890', 'guest'),
('Nana', 'Ojo', 'scott@example.com', '$2b$12$hashdiana123', '+2348045678901', 'host'),
('Admin', 'User', 'admin@airbnbclone.com', '$2b$12$hashadmin123', '+2348056789012', 'admin');

-- 2. PROPERTY TABLE
-- ===========================================================
-- Host: Zainab (user_id selected from above)
-- Host: Tofunmi (user_id selected from above)
-- For demonstration, we use subqueries to map host_id by email

INSERT INTO Property (host_id, name, description, location, pricepernight)
VALUES
((SELECT user_id FROM "User" WHERE email = 'ay@example.com'),
 'Seaside Apartment',
 'Beautiful two-bedroom beachfront apartment with free Wi-Fi and parking.',
 'Lagos, Nigeria',
 250.00),

 
((SELECT user_id FROM "User" WHERE email = 'scott@example.com'),
 'City View Loft',
 'Luxury loft with panoramic city views and rooftop pool access.',
 'Abuja, Nigeria',
 320.00),

((SELECT user_id FROM "User" WHERE email = 'nana@example.com'),
 'Cozy Cottage',
 'Quiet countryside cottage with private garden and fireplace.',
 'Ibadan, Nigeria',
 180.00);


-- 3. BOOKING TABLE
-- Guests: Zain and Aanu making bookings on Tofunmi & Scott's properties

INSERT INTO Booking (property_id, user_id, start_date, end_date, total_price, status)
VALUES
((SELECT property_id FROM Property WHERE name = 'Seaside Apartment'),
 (SELECT user_id FROM "User" WHERE email = 'zain@example.com'),
 '2025-11-05', '2025-11-10', 1250.00, 'confirmed'),

((SELECT property_id FROM Property WHERE name = 'City View Loft'),
 (SELECT user_id FROM "User" WHERE email = 'tofs@example.com'),
 '2025-12-01', '2025-12-04', 960.00, 'pending'),

((SELECT property_id FROM Property WHERE name = 'Cozy Cottage'),
 (SELECT user_id FROM "User" WHERE email = 'zain@example.com'),
 '2025-12-10', '2025-12-15', 900.00, 'canceled');


-- 4. PAYMENT TABLE
-- Only confirmed or completed bookings have payments

INSERT INTO Payment (booking_id, amount, payment_method)
VALUES
((SELECT booking_id FROM Booking WHERE status = 'confirmed' AND total_price = 1250.00),
 1250.00, 'credit_card');


-- 5. REVIEW TABLE
-- Only guests who completed stays can review properties

INSERT INTO Review (property_id, user_id, rating, comment)
VALUES
((SELECT property_id FROM Property WHERE name = 'Seaside Apartment'),
 (SELECT user_id FROM "User" WHERE email = 'zain@example.com'),
 5,
 'Fantastic location and amazing host! Would definitely stay again.'),

((SELECT property_id FROM Property WHERE name = 'City View Loft'),
 (SELECT user_id FROM "User" WHERE email = 'tofs@example.com'),
 4,
 'Beautiful apt with great amenities. The check-in could have been faster. Omdsss');


 -- 6. MESSAGE TABLE
-- Simulate in-app conversation between guest (Zain) and host (Nana)

INSERT INTO Message (sender_id, recipient_id, message_body)
VALUES
((SELECT user_id FROM "User" WHERE email = 'zain@example.com'),
 (SELECT user_id FROM "User" WHERE email = 'aanu@example.com'),
 'Hi Zainny, I just booked your Seaside Apartment. Can I check in early on arrival day?'),

((SELECT user_id FROM "User" WHERE email = 'aanu@example.com'),
 (SELECT user_id FROM "User" WHERE email = 'zain@example.com'),
 'Hello Zain, early check-in is possible after 11 AM. Looking forward to hosting you!'),

((SELECT user_id FROM "User" WHERE email = 'nana@example.com'),
 (SELECT user_id FROM "User" WHERE email = 'scott@example.com'),
 'Hi Nana, is the Cozy Cottage available for Christmas week?');
