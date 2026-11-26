USE project;

CREATE UNIQUE INDEX IDX_GuestEmail ON guest (Email);

CREATE INDEX IDX_PaymentStatusDate ON payments (PaymentStatus, PaymentDate);

CREATE INDEX IDX_BookingStatusDates ON bookings (BookingStatus, CheckIn, CheckOut);

CREATE INDEX IDX_ReviewRating ON reviews (BookingID, Rating);

CREATE INDEX IDX_PropertyLocation ON properties (LocationID);
