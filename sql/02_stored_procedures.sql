-- Stored procedures. Run after 01_restore_database.sql.
USE project;

DROP PROCEDURE IF EXISTS UpdateBookingStatus;
DROP PROCEDURE IF EXISTS CancelOverdueBookings;
DROP PROCEDURE IF EXISTS GetHostProperties;

DELIMITER $$

-- Change the status of one booking
CREATE PROCEDURE UpdateBookingStatus (IN bID INT, IN newStatus VARCHAR(50))
BEGIN
    UPDATE bookings
    SET BookingStatus = newStatus
    WHERE BookingID = bID;
END$$

-- Cancel bookings whose check-in date has passed but are still 'Confirmed'
CREATE PROCEDURE CancelOverdueBookings()
BEGIN
    UPDATE bookings
    SET BookingStatus = 'Cancelled'
    WHERE CheckIn < CURDATE() AND BookingStatus = 'Confirmed';
END$$

-- All properties owned by one host
CREATE PROCEDURE GetHostProperties (IN p_hostID INT)
BEGIN
    SELECT * FROM properties
    WHERE HostID = p_hostID;
END$$

DELIMITER ;
