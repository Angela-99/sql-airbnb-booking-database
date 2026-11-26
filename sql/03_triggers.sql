-- Triggers. Run after 01_restore_database.sql.
-- The log tables (review_logs, deleted_bookings) are already created by the restore script.
USE project;

DROP TRIGGER IF EXISTS trg_ReviewInsert;
DROP TRIGGER IF EXISTS trg_AvailabilityUpdate;
DROP TRIGGER IF EXISTS trg_LogDeletedBooking;

DELIMITER $$

-- Log every new review (e.g. for moderation)
CREATE TRIGGER trg_ReviewInsert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    INSERT INTO review_logs (ReviewID) VALUES (NEW.ReviewID);
END$$

-- Mark a property 'Unavailable' when a booking is created for it
CREATE TRIGGER trg_AvailabilityUpdate
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    UPDATE properties
    SET Availability = 'Unavailable'
    WHERE PropertyID = NEW.PropertyID;
END$$

-- Keep an audit record of deleted bookings
CREATE TRIGGER trg_LogDeletedBooking
BEFORE DELETE ON bookings
FOR EACH ROW
BEGIN
    INSERT INTO deleted_bookings (BookingID, GuestID)
    VALUES (OLD.BookingID, OLD.GuestID);
END$$

DELIMITER ;
