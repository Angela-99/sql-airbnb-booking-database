USE project;

CREATE VIEW GuestBookingsSummaryView AS
SELECT 
    guest.GuestID,
    guest.FullName,
    COUNT(bookings.BookingID) AS TotalBookings,
    MAX(bookings.CheckOut) AS LastCheckOut
FROM guest 
JOIN bookings ON guest.GuestID = bookings.GuestID
GROUP BY guest.GuestID, guest.FullName;

CREATE VIEW PropertyRatingsView AS
SELECT 
    properties.PropertyID,
    properties.Address,
    AVG(reviews.Rating) AS AvgRating,
    COUNT(reviews.ReviewID) AS ReviewCount
FROM reviews 
JOIN bookings ON reviews.BookingID = bookings.BookingID
JOIN properties ON bookings.PropertyID = properties.PropertyID
GROUP BY properties.PropertyID, properties.Address;

USE project;
CREATE VIEW HostPropertyCountView AS
SELECT 
    host.HostID,
    host.FullName,
    COUNT(properties.PropertyID) AS PropertyCount
FROM host
JOIN properties ON host.HostID = properties.HostID
GROUP BY host.HostID, host.FullName;

USE project;
CREATE VIEW ActiveBookingsView AS
SELECT 
    bookings.BookingID,
    guest.FullName AS GuestName,
    properties.Address,
    properties.Price,
    bookings.CheckIn,
    bookings.CheckOut,
    bookings.BookingStatus
FROM bookings 
JOIN guest ON bookings.GuestID = guest.GuestID
JOIN properties ON bookings.PropertyID = properties.PropertyID
WHERE bookings.BookingStatus IN ('Confirmed', 'Completed');

USE project;
CREATE VIEW RevenuePerHostView AS
SELECT 
    host.HostID,
    host.FullName,
    SUM(payments.Amount) AS TotalRevenue
FROM host 
JOIN properties ON host.HostID = properties.HostID
JOIN bookings ON bookings.PropertyID = properties.PropertyID
JOIN payments ON bookings.BookingID = payments.BookingID
WHERE payments.PaymentStatus = 'Completed'
GROUP BY host.HostID, host.FullName;

	