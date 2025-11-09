-- ===========================================================
-- Step 1: Rename existing table for backup
-- ===========================================================
ALTER TABLE Booking RENAME TO Booking_old;

-- ===========================================================
-- Step 2: Create a new parent table for partitioning
-- ===========================================================
CREATE TABLE Booking (
    booking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL,
    user_id UUID NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(15) NOT NULL CHECK (status IN ('pending', 'confirmed', 'canceled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
PARTITION BY RANGE (start_date);

-- ===========================================================
-- Step 3: Create partitions based on date ranges
-- ===========================================================
-- Partition 1: All bookings in 2023
CREATE TABLE Booking_2023 PARTITION OF Booking
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

-- Partition 2: All bookings in 2024
CREATE TABLE Booking_2024 PARTITION OF Booking
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Partition 3: All bookings in 2025
CREATE TABLE Booking_2025 PARTITION OF Booking
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Partition 4: Future bookings (beyond 2026)
CREATE TABLE Booking_future PARTITION OF Booking
FOR VALUES FROM ('2026-01-01') TO (MAXVALUE);

-- ===========================================================
-- Step 4: Add foreign key constraints to each partition
-- ===========================================================
ALTER TABLE Booking_2023
ADD CONSTRAINT fk_booking2023_property
FOREIGN KEY (property_id) REFERENCES Property(property_id) ON DELETE CASCADE;

ALTER TABLE Booking_2024
ADD CONSTRAINT fk_booking2024_property
FOREIGN KEY (property_id) REFERENCES Property(property_id) ON DELETE CASCADE;

ALTER TABLE Booking_2025
ADD CONSTRAINT fk_booking2025_property
FOREIGN KEY (property_id) REFERENCES Property(property_id) ON DELETE CASCADE;

ALTER TABLE Booking_future
ADD CONSTRAINT fk_bookingfuture_property
FOREIGN KEY (property_id) REFERENCES Property(property_id) ON DELETE CASCADE;
