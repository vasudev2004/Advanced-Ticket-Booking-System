-- =========================================
-- DATABASE CREATION
-- =========================================

CREATE DATABASE TicketBookingSystem;
USE TicketBookingSystem;

-- =========================================
-- USERS TABLE
-- =========================================

CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- =========================================
-- SHOWS TABLE
-- =========================================

CREATE TABLE Shows (
    show_id INT PRIMARY KEY AUTO_INCREMENT,
    movie_name VARCHAR(100) NOT NULL,
    show_time DATETIME NOT NULL
);

-- =========================================
-- SEATS TABLE
-- =========================================

CREATE TABLE Seats (
    seat_id INT PRIMARY KEY AUTO_INCREMENT,
    show_id INT,
    seat_number VARCHAR(10),
    status ENUM('AVAILABLE','BOOKED') DEFAULT 'AVAILABLE',
    version INT DEFAULT 1,

    FOREIGN KEY (show_id) REFERENCES Shows(show_id)
);

-- =========================================
-- BOOKINGS TABLE
-- =========================================

CREATE TABLE Bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    seat_id INT,
    booking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    booking_status ENUM('SUCCESS','FAILED'),

    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (seat_id) REFERENCES Seats(seat_id)
);

-- =========================================
-- INSERT SAMPLE DATA
-- =========================================

INSERT INTO Users(name,email)
VALUES
('Vasudev','vasu@gmail.com'),
('Rahul','rahul@gmail.com');

INSERT INTO Shows(movie_name,show_time)
VALUES
('Avengers','2026-05-20 06:00:00');

INSERT INTO Seats(show_id,seat_number)
VALUES
(1,'A1'),
(1,'A2'),
(1,'A3'),
(1,'A4');

-- =========================================
-- Q2 : ADVANCED BOOKING TRANSACTION
-- =========================================

DELIMITER $$

CREATE PROCEDURE BookSeat(
    IN p_user_id INT,
    IN p_seat_id INT
)
BEGIN

    DECLARE seatStatus VARCHAR(20);

    START TRANSACTION;

    -- LOCK SEAT
    SELECT status INTO seatStatus
    FROM Seats
    WHERE seat_id = p_seat_id
    FOR UPDATE NOWAIT;

    -- CHECK AVAILABILITY
    IF seatStatus = 'AVAILABLE' THEN

        -- UPDATE SEAT
        UPDATE Seats
        SET status = 'BOOKED'
        WHERE seat_id = p_seat_id;

        -- INSERT BOOKING
        INSERT INTO Bookings(user_id,seat_id,booking_status)
        VALUES(p_user_id,p_seat_id,'SUCCESS');

        COMMIT;

        SELECT 'BOOKING SUCCESSFUL' AS Message;

    ELSE

        ROLLBACK;

        SELECT 'SEAT ALREADY BOOKED' AS Message;

    END IF;

END$$

DELIMITER ;

-- =========================================
-- CALL PROCEDURE
-- =========================================

CALL BookSeat(1,1);

-- =========================================
-- CHECK DATA
-- =========================================

SELECT * FROM Seats;
SELECT * FROM Bookings;

-- =========================================
-- Q3 : PARALLEL BOOKING USING SKIP LOCKED
-- =========================================

START TRANSACTION;

SELECT *
FROM Seats
WHERE status='AVAILABLE'
FOR UPDATE SKIP LOCKED;

COMMIT;

-- =========================================
-- Q4 : DEADLOCK SIMULATION
-- =========================================

-- TRANSACTION 1
START TRANSACTION;

UPDATE Seats
SET status='BOOKED'
WHERE seat_id=2;

-- WAIT HERE

UPDATE Seats
SET status='BOOKED'
WHERE seat_id=3;

COMMIT;

-- =========================================
-- TRANSACTION 2
-- RUN IN ANOTHER WINDOW
-- =========================================

START TRANSACTION;

UPDATE Seats
SET status='BOOKED'
WHERE seat_id=3;

-- WAIT HERE

UPDATE Seats
SET status='BOOKED'
WHERE seat_id=2;

COMMIT;

-- =========================================
-- DEADLOCK PREVENTION
-- =========================================

-- ALWAYS LOCK ROWS IN SAME ORDER

-- Example:
-- Always lock smaller seat_id first

-- =========================================
-- Q5 : OPTIMISTIC LOCKING
-- =========================================

UPDATE Seats
SET
    status='BOOKED',
    version = version + 1
WHERE
    seat_id = 4
    AND version = 1;

-- IF 0 ROWS UPDATED
-- THEN SOMEONE ELSE MODIFIED THE ROW

-- =========================================
-- Q6 : FAILURE & ROLLBACK HANDLING
-- =========================================

START TRANSACTION;

-- LOCK SEAT
SELECT *
FROM Seats
WHERE seat_id=2
FOR UPDATE;

-- PAYMENT FAILED
ROLLBACK;

-- SEAT REMAINS AVAILABLE

SELECT * FROM Seats WHERE seat_id=2;

-- =========================================
-- Q7 : ISOLATION LEVEL ANALYSIS
-- =========================================

-- READ COMMITTED
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

SELECT * FROM Seats;

COMMIT;

-- SERIALIZABLE
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

START TRANSACTION;

SELECT * FROM Seats;

COMMIT;

-- =========================================
-- Q8 : AUTO RELEASE LOCKED SEATS
-- =========================================

CREATE TABLE SeatLocks (
    lock_id INT PRIMARY KEY AUTO_INCREMENT,
    seat_id INT,
    user_id INT,
    lock_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (seat_id) REFERENCES Seats(seat_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- REMOVE LOCKS AFTER 5 MINUTES

DELETE FROM SeatLocks
WHERE lock_time < NOW() - INTERVAL 5 MINUTE;

-- =========================================
-- WAITING QUEUE TABLE
-- =========================================

CREATE TABLE WaitingQueue (
    queue_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    show_id INT,
    request_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (show_id) REFERENCES Shows(show_id)
);

-- =========================================
-- VIEW FINAL DATA
-- =========================================

SELECT * FROM Users;
SELECT * FROM Shows;
SELECT * FROM Seats;
SELECT * FROM Bookings;
SELECT * FROM SeatLocks;
SELECT * FROM WaitingQueue;