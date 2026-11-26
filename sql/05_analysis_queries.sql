-- Analysis queries. Run after 01_restore_database.sql (read-only).
USE project;

-- Q1. Host consistency per property, 2024 bookings:
--     bookings, cancellation rate, occupied nights, average rating and rating spread.
SELECT h.HostID, h.FullName, p.PropertyID,
       COUNT(b.BookingID)                                        AS TotalBookings,
       ROUND(AVG(b.BookingStatus = 'Cancelled'), 3)              AS CancellationRate,
       COALESCE(SUM(CASE WHEN b.BookingStatus <> 'Cancelled'
                         THEN DATEDIFF(b.CheckOut, b.CheckIn) END), 0) AS OccupiedNights,
       ROUND(AVG(r.Rating), 2)                                   AS AvgRating,
       ROUND(STDDEV_POP(r.Rating), 2)                            AS RatingStdDev
FROM host h
JOIN properties p        ON p.HostID = h.HostID
LEFT JOIN bookings b     ON b.PropertyID = p.PropertyID AND YEAR(b.CheckIn) = 2024
LEFT JOIN reviews r      ON r.BookingID = b.BookingID
GROUP BY h.HostID, h.FullName, p.PropertyID
HAVING COUNT(b.BookingID) > 0
ORDER BY CancellationRate DESC, OccupiedNights DESC
LIMIT 20;

-- Q2. Average guest sentiment per property, taken from the JSON Analysis column.
SELECT p.PropertyID, p.Address,
       COUNT(*)                                                         AS Reviews,
       ROUND(AVG(CAST(JSON_UNQUOTE(JSON_EXTRACT(r.Analysis, '$.sentiment_score')) AS DECIMAL(4,2))), 2) AS AvgSentiment
FROM properties p
JOIN bookings b ON b.PropertyID = p.PropertyID
JOIN reviews  r ON r.BookingID  = b.BookingID
GROUP BY p.PropertyID, p.Address
ORDER BY AvgSentiment DESC, Reviews DESC
LIMIT 20;

-- Q3. Underperformers vs peers: properties with at least 3 reviews whose average rating is
--     more than 0.75 below the average of properties of the same type.
WITH prop_stats AS (
    SELECT p.PropertyID, p.PropertyTypeID,
           COUNT(r.ReviewID) AS Reviews,
           AVG(r.Rating)     AS AvgRating
    FROM properties p
    JOIN bookings b ON b.PropertyID = p.PropertyID
    JOIN reviews  r ON r.BookingID  = b.BookingID
    GROUP BY p.PropertyID, p.PropertyTypeID
    HAVING COUNT(r.ReviewID) >= 3
),
peer AS (
    SELECT *, AVG(AvgRating) OVER (PARTITION BY PropertyTypeID) AS PeerAvg,
              COUNT(*)       OVER (PARTITION BY PropertyTypeID) AS PeerCount
    FROM prop_stats
)
SELECT PropertyID, PropertyTypeID, Reviews,
       ROUND(AvgRating, 2) AS AvgRating, ROUND(PeerAvg, 2) AS PeerAvg
FROM peer
WHERE PeerCount >= 5 AND AvgRating < PeerAvg - 0.75
ORDER BY AvgRating - PeerAvg
LIMIT 20;

-- Q4. Top 5 properties by average rating on Completed bookings that offer at least
--     two of the amenities 'Pool', 'Hot Tub', 'Sauna'.
SELECT p.PropertyID, p.Address,
       ROUND(AVG(r.Rating), 2)             AS AvgRating,
       COUNT(DISTINCT b.BookingID)         AS CompletedBookings,
       a.UniqueAmenities
FROM properties p
JOIN (SELECT PropertyID,
             COUNT(DISTINCT AmenityName) AS UniqueAmenities,
             COUNT(DISTINCT CASE WHEN AmenityName IN ('Pool','Hot Tub','Sauna') THEN AmenityName END) AS Premium
      FROM amenities GROUP BY PropertyID) a ON a.PropertyID = p.PropertyID AND a.Premium >= 2
JOIN bookings b ON b.PropertyID = p.PropertyID AND b.BookingStatus = 'Completed'
JOIN reviews  r ON r.BookingID  = b.BookingID
GROUP BY p.PropertyID, p.Address, a.UniqueAmenities
ORDER BY AvgRating DESC, CompletedBookings DESC
LIMIT 5;

-- Q5. Guest behaviour dataset (input for clustering in Python): one row per guest.
--     Amenity variety is computed in its own subquery so the amenities join cannot
--     multiply booking rows.
SELECT g.GuestID,
       COUNT(b.BookingID)                                  AS total_bookings,
       ROUND(AVG(DATEDIFF(b.CheckOut, b.CheckIn)), 2)      AS avg_stay_length,
       ROUND(AVG(b.BookingStatus = 'Cancelled'), 3)        AS cancellation_rate,
       COALESCE(av.amenity_variety, 0)                     AS amenity_variety
FROM guest g
JOIN bookings b ON b.GuestID = g.GuestID
LEFT JOIN (SELECT b2.GuestID, COUNT(DISTINCT a.AmenityName) AS amenity_variety
           FROM bookings b2
           JOIN amenities a ON a.PropertyID = b2.PropertyID
           GROUP BY b2.GuestID) av ON av.GuestID = g.GuestID
GROUP BY g.GuestID, av.amenity_variety;

-- Q6. Check-ins by day of week.
SELECT DAYNAME(CheckIn) AS Weekday, COUNT(*) AS CheckIns
FROM bookings
GROUP BY DAYOFWEEK(CheckIn), DAYNAME(CheckIn)
ORDER BY DAYOFWEEK(CheckIn);

-- Q7. Monthly check-ins and check-outs.
SELECT m.ym AS Month,
       SUM(m.kind = 'in')  AS CheckIns,
       SUM(m.kind = 'out') AS CheckOuts
FROM (SELECT DATE_FORMAT(CheckIn,  '%Y-%m') AS ym, 'in'  AS kind FROM bookings
      UNION ALL
      SELECT DATE_FORMAT(CheckOut, '%Y-%m'),       'out'         FROM bookings) m
GROUP BY m.ym
ORDER BY m.ym;

-- Q8. Revenue per host (completed payments) with rank.
SELECT HostID, FullName, TotalRevenue,
       RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
FROM revenueperhostview
ORDER BY RevenueRank
LIMIT 10;

-- Q9. Payments per booking and payment mix (payments are not one-to-one with bookings here).
SELECT PaymentStatus, PaymentMethod, COUNT(*) AS Payments, ROUND(SUM(Amount), 2) AS TotalAmount
FROM payments
GROUP BY PaymentStatus, PaymentMethod
ORDER BY PaymentStatus, Payments DESC;
