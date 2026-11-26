-- Data quality checks. Run after 01_restore_database.sql (read-only).
-- The data is synthetic, so these checks show where the generated data does not
-- line up, and which constraints the schema does and does not enforce.
USE project;

-- Bookings pointing at a guest that does not exist
SELECT COUNT(*) AS bookings_with_missing_guest
FROM bookings b LEFT JOIN guest g ON g.GuestID = b.GuestID
WHERE g.GuestID IS NULL;

-- Bookings pointing at a property that does not exist
SELECT COUNT(*) AS bookings_with_missing_property
FROM bookings b LEFT JOIN properties p ON p.PropertyID = b.PropertyID
WHERE p.PropertyID IS NULL;

-- Payments pointing at a booking that does not exist
SELECT COUNT(*) AS payments_with_missing_booking
FROM payments pay LEFT JOIN bookings b ON b.BookingID = pay.BookingID
WHERE b.BookingID IS NULL;

-- How many bookings have any payment, and payments per booking
SELECT COUNT(DISTINCT BookingID) AS bookings_with_payment,
       COUNT(*)                  AS payments,
       ROUND(COUNT(*) / COUNT(DISTINCT BookingID), 1) AS payments_per_booking
FROM payments;

-- Check-out not after check-in
SELECT COUNT(*) AS bad_date_ranges FROM bookings WHERE CheckOut <= CheckIn;

-- Duplicate property types
SELECT PropertyType, COUNT(*) AS copies FROM propertytype GROUP BY PropertyType HAVING COUNT(*) > 1;

-- Which foreign keys exist
SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'project' AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;
