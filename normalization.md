# Normalization to Third Normal Form (3NF) — ALX Airbnb Database

**Objective:** Review the schema, remove redundancies and transitive dependencies, and present a revised design that satisfies Third Normal Form (3NF). This document is written as a formal project deliverable and contains: (1) a short overview of the issues found, (2) the design changes made and why, (3) the final Postgres-compatible DDL you can copy/paste, and (4) a 3NF proof that explains why the resulting schema is in 3NF.

---

## Executive summary

The original specification is mostly well-structured, but two practical redundancies / normalization issues were identified that would violate or risk violating 3NF in certain workflows:

1. **Review table redundancy** — The original Review included both `property_id` and `user_id` while the business rule requires reviews to be associated with bookings. Storing `property_id` (or `user_id`) in Review when `booking_id` already identifies the booking (and therefore the property and guest) creates *redundant* data and a *transitive dependency* (Review → Booking → Property). To achieve 3NF we must avoid attributes that are functionally dependent on other non-key attributes of the same row.

2. **Property address fields** — `location` stored as a single VARCHAR can hide repeated address components or cause inconsistent storage. Splitting address components into a distinct `PropertyAddress` entity removes repeated groups (city, state, postal_code, coordinates), improves data cleanliness, and keeps location-specific attributes that are logically about the address separate from property metadata.

Additional clarifications and best-practice adjustments included:

* Make the relationship between `Review` and `Booking` explicit by storing only `booking_id` in `Review` and enforce a uniqueness constraint so there is at most one review per booking.
* Use a trigger-based `updated_at` maintenance for `Property.updated_at` (Postgres does not support `ON UPDATE CURRENT_TIMESTAMP`).
* Keep `total_price` in `Booking` as a stored snapshot (acceptable for audit/history and performance) but document the trade-off; ensure application logic or a database trigger maintains consistency.

Below are the completed changes and the final DDL.

---

## Schema changes applied (concise)

1. **Review table**

   * **Removed**: `property_id`, `user_id` (attributes that create redundancy).
   * **Added**: `booking_id` (FK) — the review references the booking it is written for.
   * **Constraints**: `UNIQUE(booking_id)` — ensures at most one review per booking. The reviewer and property are derived via `Booking`.

2. **PropertyAddress table**

   * **Added**: `PropertyAddress` entity to hold structured address fields: street, city, state, country, postal_code, latitude, longitude.
   * **Property** now references `PropertyAddress.address_id` rather than storing a single `location` string.

3. **Property.updated_at**

   * Implemented with a trigger to auto-set `updated_at` on UPDATE.

4. **Documented total_price handling**

   * `Booking.total_price` remains in Booking as a snapshot. It is permitted in 3NF because it is functionally dependent on the Booking primary key; document that the application or triggers must recalculate/update it on relevant changes to preserve accuracy.

5. **Indexes & constraints**

   * Ensure all primary keys are UUIDs (with `gen_random_uuid()` default). Add explicit indexes on frequently queried fields (email, host_id, property_id, booking_id).

---

## Final Postgres-compatible DDL (copy-paste ready)

> Note: This DDL follows the provided specification (UUID PKs, enums via CHECKs, timestamps). It uses the `pgcrypto` extension for `gen_random_uuid()`.

```sql
-- Enable UUID generator (Postgres)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. User
CREATE TABLE "User" (
  user_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name    VARCHAR(100) NOT NULL,
  last_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone_number  VARCHAR(30),
  role          VARCHAR(10) NOT NULL CHECK (role IN ('guest','host','admin')),
  created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 2. PropertyAddress (new)
CREATE TABLE PropertyAddress (
  address_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  street       VARCHAR(255),
  city         VARCHAR(100),
  state        VARCHAR(100),
  country      VARCHAR(100),
  postal_code  VARCHAR(20),
  latitude     DOUBLE PRECISION,
  longitude    DOUBLE PRECISION
);

-- 3. Property (now references PropertyAddress)
CREATE TABLE Property (
  property_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id       UUID NOT NULL REFERENCES "User"(user_id),
  name          VARCHAR(255) NOT NULL,
  description   TEXT NOT NULL,
  address_id    UUID REFERENCES PropertyAddress(address_id),
  pricepernight NUMERIC(10,2) NOT NULL,
  created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Trigger function to maintain updated_at on Property
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON Property
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_updated_at();

-- 4. Booking
-- total_price is stored as a snapshot (audit/history). Application logic must maintain correctness.
CREATE TABLE Booking (
  booking_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id  UUID NOT NULL REFERENCES Property(property_id),
  user_id      UUID NOT NULL REFERENCES "User"(user_id),
  start_date   DATE NOT NULL,
  end_date     DATE NOT NULL,
  total_price  NUMERIC(12,2) NOT NULL,
  status       VARCHAR(10) NOT NULL CHECK (status IN ('pending','confirmed','canceled')),
  created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CHECK (start_date < end_date)
);

-- 5. Payment
CREATE TABLE Payment (
  payment_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id     UUID NOT NULL REFERENCES Booking(booking_id),
  amount         NUMERIC(12,2) NOT NULL,
  payment_date   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('credit_card','paypal','stripe'))
);

-- 6. Review (normalized: references Booking only)
CREATE TABLE Review (
  review_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES Booking(booking_id),
  rating     INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment    TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE (booking_id)
);

-- 7. Message
CREATE TABLE Message (
  message_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id    UUID NOT NULL REFERENCES "User"(user_id),
  recipient_id UUID NOT NULL REFERENCES "User"(user_id),
  message_body TEXT NOT NULL,
  sent_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Indexes (in addition to PK indexes)
CREATE INDEX idx_user_email ON "User"(email);
CREATE INDEX idx_property_host ON Property(host_id);
CREATE INDEX idx_booking_property ON Booking(property_id);
CREATE INDEX idx_booking_user ON Booking(user_id);
CREATE INDEX idx_payment_booking ON Payment(booking_id);
CREATE INDEX idx_message_sender ON Message(sender_id);
CREATE INDEX idx_message_recipient ON Message(recipient_id);
```

---

## Rationale for each change (detailed)

### 1. Review: use `booking_id` only

* **Problem:** In the original layout the Review had `property_id` and `user_id`. Because the booking uniquely identifies both the property and the reviewer (guest), storing `property_id` and `user_id` in Review duplicates data that can be derived via `Booking`.
* **Why this violates 3NF:** If `Review` stores `property_id` while also storing `booking_id`, then `property_id` is functionally dependent on `booking_id` (a non-key attribute depends on another non-key attribute). This is a transitive dependency and violates 3NF.
* **Resolution:** Keep a single FK `booking_id`. Derive `property` and `user` via joins when needed. Add `UNIQUE(booking_id)` to enforce one review per booking.
* **Business effect:** The DB enforces that reviews belong to real bookings. App code can still present the reviewer and property easily by joining via `Booking`.

### 2. PropertyAddress entity

* **Problem:** `location` as a single VARCHAR mixes multiple address components and may lead to repeated textual variants (e.g., different spellings, formats) across records. While this does not always violate 3NF, it hides repeated groups and complicates queries by city/state.
* **Why this improves normalization:** Address components are attributes of the address entity, not intrinsic attributes of the property itself. Moving them to `PropertyAddress` keeps the `Property` table focused on property-specific attributes (name, description, pricing).
* **Resolution:** Create `PropertyAddress` and add `address_id` FK to `Property`. This eliminates repeated groups and makes city/state searchable and indexable without string parsing.

### 3. `total_price` in Booking — discussion

* **Observation:** `total_price` can be computed from `property.pricepernight` and the number of nights + fees. Storing it is a form of denormalization because it duplicates data that could be computed.
* **3NF assessment:** Storing `total_price` in `Booking` does **not** inherently violate 3NF because `total_price` is still dependent on `booking_id` (the table PK). Transitive dependency concerns would arise only if `Booking` also stored `pricepernight` (or if other non-key attributes were functionally related).
* **Practical decision:** Keep `total_price` as a snapshot in `Booking` for auditability (the price at time of booking) and performance. Enforce correctness via application logic and/or database-triggered recalculation on price changes, booking updates, or refunds. Document this as a requirement.

### 4. `updated_at` handling

* **Problem:** The spec included `updated_at: TIMESTAMP, ON UPDATE CURRENT_TIMESTAMP`. Postgres requires this to be implemented as a trigger or the value updated at the application level.
* **Resolution:** Add a trigger function `trigger_set_updated_at()` and a trigger on `Property` to set `updated_at` on each update. This keeps the timestamp reliable and centralized in the DB.

---

## 3NF proof / justification

Third Normal Form requires:

1. The relation is in Second Normal Form (2NF).
2. No non-prime attribute is transitively dependent on the primary key.

Below is a short 3NF verification for each final table.

### Table: `User(user_id, first_name, last_name, email, password_hash, phone_number, role, created_at)`

* **Key:** `user_id`
* **Non-key attributes:** first_name, last_name, email, password_hash, phone_number, role, created_at.
* **Dependencies:** each non-key attribute depends directly on `user_id`. There is no non-key attribute that depends on another non-key attribute. **Hence 3NF satisfied.**

### Table: `Property(property_id, host_id, name, description, address_id, pricepernight, created_at, updated_at)`

* **Key:** `property_id`
* **Non-key attributes:** host_id, name, description, address_id, pricepernight, created_at, updated_at.
* **Dependencies:** All non-key attributes are properties of the property identified by `property_id`. `host_id` is a FK but not a non-key attribute functionally determining other non-key attributes. No transitive dependencies exist inside the `Property` table. **Hence 3NF satisfied.**

### Table: `PropertyAddress(address_id, street, city, state, country, postal_code, latitude, longitude)`

* **Key:** `address_id`
* **Non-key attributes:** street, city, state, country, postal_code, latitude, longitude — all depend on `address_id`. **3NF satisfied.**

### Table: `Booking(booking_id, property_id, user_id, start_date, end_date, total_price, status, created_at)`

* **Key:** `booking_id`
* **Non-key attributes:** property_id, user_id, start_date, end_date, total_price, status, created_at.
* `property_id` and `user_id` are FKs but are not non-key attributes that determine other non-key attributes *within Booking*. `total_price` is stored but is functionally dependent on the booking itself (snapshot). There is no non-key attribute that depends on another non-key attribute in the Booking row. **3NF satisfied.**

### Table: `Payment(payment_id, booking_id, amount, payment_date, payment_method)`

* **Key:** `payment_id`
* All non-key attributes depend on `payment_id`. Payment references `booking_id` but there is no transitive dependency among non-key attributes. **3NF satisfied.**

### Table: `Review(review_id, booking_id, rating, comment, created_at)`

* **Key:** `review_id`
* Non-key attributes: booking_id, rating, comment, created_at.
* `booking_id` is a FK. The rating and comment depend on the review identity (`review_id`) and are not transitively dependent on another non-key attribute. The removal of `property_id` and `user_id` prevents the transitive dependency Review→Booking→Property or Review→Booking→User inside the Review table. **3NF satisfied.**

### Table: `Message(message_id, sender_id, recipient_id, message_body, sent_at)`

* **Key:** `message_id`
* Non-key attributes depend on `message_id`; the sender/recipient are FKs. There is no transitive dependency. **3NF satisfied.**

---

## Operational & deployment notes (practical requirements)

1. **Triggers / application logic**

   * `Property.updated_at` trigger implemented in DDL. Similar triggers or application code should update `Booking.total_price` on booking creation/modification if `total_price` is derived at any point.

2. **Business rules not enforced by 3NF**

   * Preventing double-booking across overlapping date ranges is a business rule that requires application checks or Postgres `EXCLUDE` constraints on date ranges. This is not directly a 3NF issue but necessary for correctness.

3. **Soft deletes**

   * Prefer `is_active` or `deleted_at` columns over hard deletes on `User` and `Property` to avoid orphaning historical records (bookings, payments).

4. **Review posting policy**

   * Enforce that a review can only be created for a booking that is in `completed` or `confirmed` status via application-level checks or transactional procedures.

5. **Indexes**

   * Keep the explicit indexes included in the DDL. Monitor query patterns and add composite indexes where necessary (for example `(property_id, start_date)` if range queries are common).
