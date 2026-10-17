-- =========================================================
-- CAR RENTAL SYSTEM  |  MySQL 8.0
-- FILE 1 : DATABASE (run once with Execute All = Ctrl+Shift+Enter)
-- Re-running this file wipes and rebuilds everything (fresh sample data)
-- =========================================================

DROP DATABASE IF EXISTS car_rental;
CREATE DATABASE car_rental;
USE car_rental;

-- =========================================================
-- 1. TABLES  (PK, FK, UNIQUE, NOT NULL, CHECK, DEFAULT, ENUM)
-- =========================================================

CREATE TABLE Admins (
    admin_id    INT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,                 -- stored as SHA2 hash
    manager_id  INT NULL,                              -- self reference (hierarchy)
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (manager_id) REFERENCES Admins(admin_id) ON DELETE SET NULL
);

CREATE TABLE Users (
    user_id     INT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,
    phone       VARCHAR(15) UNIQUE,
    city        VARCHAR(50),
    license_no  VARCHAR(20) NOT NULL UNIQUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_phone CHECK (CHAR_LENGTH(phone) = 10)
);

CREATE TABLE CarTypes (
    type_id      INT PRIMARY KEY AUTO_INCREMENT,
    type_name    VARCHAR(50) NOT NULL UNIQUE,
    description  VARCHAR(255)
);

CREATE TABLE Cars (
    car_id       INT PRIMARY KEY AUTO_INCREMENT,
    type_id      INT NOT NULL,
    brand        VARCHAR(50) NOT NULL,
    model        VARCHAR(50) NOT NULL,
    model_year   YEAR,
    reg_number   VARCHAR(20) NOT NULL UNIQUE,
    daily_rate   DECIMAL(10,2) NOT NULL,
    status       ENUM('Available','Rented','Maintenance') NOT NULL DEFAULT 'Available',
    CONSTRAINT chk_rate CHECK (daily_rate > 0),
    CONSTRAINT fk_car_type FOREIGN KEY (type_id) REFERENCES CarTypes(type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Bookings (
    booking_id    INT PRIMARY KEY AUTO_INCREMENT,
    user_id       INT NOT NULL,
    car_id        INT NOT NULL,
    start_date    DATE NOT NULL,
    end_date      DATE NOT NULL,
    total_amount  DECIMAL(10,2),
    status        ENUM('Pending','Confirmed','Completed','Cancelled') NOT NULL DEFAULT 'Pending',
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_dates CHECK (end_date >= start_date),
    CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_booking_car  FOREIGN KEY (car_id)  REFERENCES Cars(car_id)   ON DELETE RESTRICT
);

CREATE TABLE Payments (
    payment_id    INT PRIMARY KEY AUTO_INCREMENT,
    booking_id    INT NOT NULL,
    amount        DECIMAL(10,2) NOT NULL,
    payment_date  DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_mode  ENUM('Cash','Card','UPI','NetBanking') NOT NULL,
    CONSTRAINT chk_amount CHECK (amount > 0),
    CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
        ON DELETE CASCADE
);

CREATE TABLE Reviews (
    review_id    INT PRIMARY KEY AUTO_INCREMENT,
    user_id      INT NOT NULL,
    car_id       INT NOT NULL,
    rating       TINYINT NOT NULL,
    comment      VARCHAR(500),
    review_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT uq_user_car UNIQUE (user_id, car_id),    -- composite unique: one review per user per car
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (car_id)  REFERENCES Cars(car_id)   ON DELETE CASCADE
);

CREATE TABLE Maintenance (
    maint_id      INT PRIMARY KEY AUTO_INCREMENT,
    car_id        INT NOT NULL,
    service_date  DATE NOT NULL,
    cost          DECIMAL(10,2) NOT NULL,
    description   VARCHAR(255),
    FOREIGN KEY (car_id) REFERENCES Cars(car_id) ON DELETE CASCADE
);

CREATE TABLE BookingAudit (                              -- filled automatically by triggers
    audit_id     INT PRIMARY KEY AUTO_INCREMENT,
    booking_id   INT NOT NULL,
    action       VARCHAR(30) NOT NULL,
    old_status   VARCHAR(20),
    new_status   VARCHAR(20),
    changed_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 2. INDEXES
-- =========================================================

CREATE INDEX idx_cars_status      ON Cars(status);
CREATE INDEX idx_bookings_dates   ON Bookings(start_date, end_date);
CREATE INDEX idx_payments_date    ON Payments(payment_date);

-- =========================================================
-- 3. BASE DATA (no triggers needed yet)
-- =========================================================

INSERT INTO Admins (name, email, password, manager_id) VALUES
('Suresh Rao',  'suresh@carrental.com', SHA2('admin1',256), NULL),
('Meera Nair',  'meera@carrental.com',  SHA2('admin2',256), 1),
('Kiran Shah',  'kiran@carrental.com',  SHA2('admin3',256), 1),
('Pooja Iyer',  'pooja@carrental.com',  SHA2('admin4',256), 2);

INSERT INTO Users (name, email, password, phone, city, license_no) VALUES
('Rahul Sharma',    'rahul@mail.com',   SHA2('pass1',256), '9876543210', 'Pune',   'MH12-2020-001'),
('Priya Patil',     'priya@mail.com',   SHA2('pass2',256), '9876501234', 'Mumbai', 'MH01-2019-045'),
('Amit Verma',      'amit@mail.com',    SHA2('pass3',256), '9123456780', 'Nashik', 'MH15-2021-077'),
('Sneha Kulkarni',  'sneha@mail.com',   SHA2('pass4',256), '9988001122', 'Pune',   'MH12-2018-310'),
('Vikram Singh',    'vikram@mail.com',  SHA2('pass5',256), '9822334455', 'Nagpur', 'MH31-2017-142'),
('Anjali Deshmukh', 'anjali@mail.com',  SHA2('pass6',256), '9765432100', 'Mumbai', 'MH02-2022-208'),
('Rohan Joshi',     'rohan@mail.com',   SHA2('pass7',256), '9011223344', 'Pune',   'MH12-2023-415'),
('Neha Gupta',      'neha@mail.com',    SHA2('pass8',256), '9090909090', 'Thane',  'MH04-2020-066');

INSERT INTO CarTypes (type_name, description) VALUES
('Hatchback',   'Compact city cars'),
('Sedan',       'Comfortable family cars'),
('SUV',         'Spacious and powerful'),
('Luxury',      'Premium cars for special occasions'),
('Convertible', 'Open-top cars (no cars added yet)');

INSERT INTO Cars (type_id, brand, model, model_year, reg_number, daily_rate, status) VALUES
(1, 'Maruti',   'Swift',      2022, 'MH12AB1001', 1500.00, 'Available'),
(2, 'Honda',    'City',       2021, 'MH12CD2002', 2200.00, 'Available'),
(3, 'Hyundai',  'Creta',      2023, 'MH14EF3003', 3000.00, 'Available'),
(3, 'Mahindra', 'XUV700',     2023, 'MH14GH4004', 3800.00, 'Available'),
(1, 'Tata',     'Tiago',      2022, 'MH12IJ5005', 1300.00, 'Available'),
(2, 'Hyundai',  'Verna',      2022, 'MH12KL6006', 2100.00, 'Rented'),
(4, 'BMW',      '3 Series',   2023, 'MH12MN7007', 7500.00, 'Available'),
(1, 'Hyundai',  'i20',        2021, 'MH14OP8008', 1600.00, 'Maintenance'),
(3, 'Toyota',   'Fortuner',   2022, 'MH12QR9009', 5000.00, 'Available'),
(2, 'Skoda',    'Slavia',     2023, 'MH14ST1010', 2400.00, 'Available');

-- =========================================================
-- 4. TRIGGERS
-- =========================================================

DELIMITER //

-- Trigger 1: validate a new booking and auto-calculate the total amount
CREATE TRIGGER trg_booking_before_insert
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
    DECLARE v_clash  INT DEFAULT 0;
    DECLARE v_rate   DECIMAL(10,2);
    DECLARE v_status VARCHAR(20);

    SELECT daily_rate, status INTO v_rate, v_status
    FROM Cars WHERE car_id = NEW.car_id;

    IF v_status = 'Maintenance' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car is under maintenance';
    END IF;

    IF COALESCE(NEW.status, 'Pending') IN ('Pending','Confirmed') THEN
        SELECT COUNT(*) INTO v_clash
        FROM Bookings
        WHERE car_id = NEW.car_id
          AND status IN ('Pending','Confirmed')
          AND NEW.start_date <= end_date
          AND NEW.end_date   >= start_date;

        IF v_clash > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car is already booked for these dates';
        END IF;
    END IF;

    SET NEW.total_amount = (DATEDIFF(NEW.end_date, NEW.start_date) + 1) * v_rate;
END//

-- Trigger 2: a payment confirms a pending booking
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON Payments
FOR EACH ROW
BEGIN
    UPDATE Bookings
    SET status = 'Confirmed'
    WHERE booking_id = NEW.booking_id AND status = 'Pending';
END//

-- Trigger 3: audit every status change
CREATE TRIGGER trg_booking_after_update
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO BookingAudit (booking_id, action, old_status, new_status)
        VALUES (NEW.booking_id, 'STATUS CHANGE', OLD.status, NEW.status);
    END IF;
END//

-- Trigger 4: audit every deleted booking
CREATE TRIGGER trg_booking_after_delete
AFTER DELETE ON Bookings
FOR EACH ROW
BEGIN
    INSERT INTO BookingAudit (booking_id, action, old_status, new_status)
    VALUES (OLD.booking_id, 'DELETED', OLD.status, NULL);
END//

DELIMITER ;

-- =========================================================
-- 5. TRANSACTION DATA (inserted through the triggers)
--    total_amount is calculated automatically by trg_booking_before_insert
-- =========================================================

INSERT INTO Bookings (user_id, car_id, start_date, end_date, status) VALUES
(1, 1, '2026-07-01', '2026-07-03', 'Completed'),   -- booking 1
(2, 2, '2026-07-10', '2026-07-12', 'Completed'),   -- booking 2
(3, 3, '2026-08-01', '2026-08-05', 'Completed'),   -- booking 3
(1, 4, '2026-08-10', '2026-08-12', 'Completed'),   -- booking 4
(4, 1, '2026-08-15', '2026-08-16', 'Completed'),   -- booking 5
(5, 7, '2026-09-01', '2026-09-02', 'Completed'),   -- booking 6
(2, 3, '2026-09-10', '2026-09-14', 'Completed'),   -- booking 7
(6, 9, '2026-09-20', '2026-09-22', 'Cancelled'),   -- booking 8
(4, 5, '2026-10-01', '2026-10-04', 'Completed'),   -- booking 9
(1, 6, '2026-10-14', '2026-10-18', 'Confirmed'),   -- booking 10 (active now)
(3, 2, '2026-10-20', '2026-10-23', 'Pending'),     -- booking 11 (no payment yet)
(5, 4, '2026-10-25', '2026-10-27', 'Pending'),     -- booking 12 (no payment yet)
(6, 9, '2026-11-01', '2026-11-03', 'Confirmed');   -- booking 13

INSERT INTO Payments (booking_id, amount, payment_date, payment_mode) VALUES
(1,   4500.00, '2026-06-30 18:30:00', 'UPI'),
(2,   6600.00, '2026-07-09 12:00:00', 'Card'),
(3,  15000.00, '2026-07-31 09:15:00', 'NetBanking'),
(4,  11400.00, '2026-08-09 16:45:00', 'Card'),
(5,   3000.00, '2026-08-14 11:20:00', 'Cash'),
(6,  15000.00, '2026-08-31 20:10:00', 'UPI'),
(7,  15000.00, '2026-09-09 14:05:00', 'Card'),
(9,   5200.00, '2026-09-30 10:40:00', 'Cash'),
(10,  5000.00, '2026-10-13 15:30:00', 'UPI'),
(13,  5000.00, '2026-10-10 13:00:00', 'Card');

INSERT INTO Reviews (user_id, car_id, rating, comment) VALUES
(1, 1, 5, 'Smooth drive, great mileage'),
(2, 2, 4, 'Comfortable for family trips'),
(3, 3, 4, 'Spacious and powerful'),
(1, 4, 5, 'Best SUV ever'),
(4, 1, 3, 'Average AC cooling'),
(5, 7, 5, 'Luxury experience'),
(2, 3, 5, 'Loved the ride'),
(4, 5, 4, 'Good city car');

INSERT INTO Maintenance (car_id, service_date, cost, description) VALUES
(8, '2026-10-05', 3500.00, 'Brake pad replacement'),
(8, '2026-10-12', 1200.00, 'Oil change'),
(3, '2026-07-25', 2500.00, 'Regular service'),
(7, '2026-08-20', 6000.00, 'Engine check');

-- =========================================================
-- 6. STORED FUNCTIONS
-- =========================================================

DELIMITER //

CREATE FUNCTION fn_rental_days(p_start DATE, p_end DATE)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN DATEDIFF(p_end, p_start) + 1;
END//

CREATE FUNCTION fn_is_car_free(p_car INT, p_start DATE, p_end DATE)
RETURNS TINYINT(1)
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM Bookings
    WHERE car_id = p_car
      AND status IN ('Pending','Confirmed')
      AND p_start <= end_date
      AND p_end   >= start_date;
    RETURN v_count = 0;
END//

CREATE FUNCTION fn_customer_tier(p_user INT)
RETURNS VARCHAR(10)
READS SQL DATA
BEGIN
    DECLARE v_n INT;
    SELECT COUNT(*) INTO v_n FROM Bookings
    WHERE user_id = p_user AND status <> 'Cancelled';
    RETURN CASE
        WHEN v_n >= 3 THEN 'Gold'
        WHEN v_n >= 2 THEN 'Silver'
        WHEN v_n >= 1 THEN 'Bronze'
        ELSE 'New'
    END;
END//

-- =========================================================
-- 7. STORED PROCEDURES (incl. transaction, exception handler, cursor)
-- =========================================================

CREATE PROCEDURE sp_complete_booking(IN p_booking_id INT)
BEGIN
    UPDATE Bookings SET status = 'Completed' WHERE booking_id = p_booking_id;
    UPDATE Cars SET status = 'Available'
    WHERE car_id = (SELECT car_id FROM Bookings WHERE booking_id = p_booking_id);
END//

CREATE PROCEDURE sp_book_car(
    IN  p_user  INT,
    IN  p_car   INT,
    IN  p_start DATE,
    IN  p_end   DATE,
    OUT p_msg   VARCHAR(100))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_msg = 'Booking FAILED: car not available for these dates';
    END;

    START TRANSACTION;
    INSERT INTO Bookings (user_id, car_id, start_date, end_date)
    VALUES (p_user, p_car, p_start, p_end);
    COMMIT;
    SET p_msg = 'Booking SUCCESSFUL';
END//

CREATE PROCEDURE sp_monthly_report(IN p_year INT)
BEGIN
    SELECT MONTHNAME(payment_date) AS month_name,
           COUNT(*)                AS payments,
           SUM(amount)             AS revenue
    FROM Payments
    WHERE YEAR(payment_date) = p_year
    GROUP BY MONTH(payment_date), MONTHNAME(payment_date)
    ORDER BY MONTH(payment_date);
END//

CREATE PROCEDURE sp_total_paid_cursor(OUT p_total DECIMAL(12,2))
BEGIN
    DECLARE v_amount DECIMAL(10,2);
    DECLARE v_done   INT DEFAULT 0;
    DECLARE cur CURSOR FOR SELECT amount FROM Payments;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    SET p_total = 0;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_amount;
        IF v_done = 1 THEN
            LEAVE read_loop;
        END IF;
        SET p_total = p_total + v_amount;
    END LOOP;
    CLOSE cur;
END//

DELIMITER ;

-- =========================================================
-- 8. VIEWS
-- =========================================================

CREATE VIEW vw_booking_details AS
SELECT b.booking_id,
       u.name AS customer,
       CONCAT(c.brand, ' ', c.model) AS car,
       c.reg_number,
       b.start_date, b.end_date, b.total_amount, b.status
FROM Bookings b
JOIN Users u ON b.user_id = u.user_id
JOIN Cars  c ON b.car_id  = c.car_id;

CREATE VIEW vw_car_ratings AS
SELECT c.car_id, c.brand, c.model,
       ROUND(AVG(r.rating), 1) AS avg_rating,
       COUNT(r.review_id)      AS total_reviews
FROM Cars c
LEFT JOIN Reviews r ON c.car_id = r.car_id
GROUP BY c.car_id, c.brand, c.model;

CREATE VIEW vw_user_spending AS
SELECT u.user_id, u.name,
       COUNT(DISTINCT b.booking_id)  AS total_bookings,
       COALESCE(SUM(p.amount), 0)    AS total_paid
FROM Users u
LEFT JOIN Bookings b ON u.user_id = b.user_id
LEFT JOIN Payments p ON b.booking_id = p.booking_id
GROUP BY u.user_id, u.name;

CREATE VIEW vw_available_cars AS
SELECT c.car_id, c.brand, c.model, t.type_name, c.daily_rate
FROM Cars c
JOIN CarTypes t ON c.type_id = t.type_id
WHERE c.status = 'Available';

-- =========================================================
-- DONE. Quick check:
-- =========================================================
SELECT 'Database created successfully' AS result;
-- =========================================================
-- CAR RENTAL SYSTEM  |  FILE 2 : DEMO QUERIES
-- Run car_rental_db.sql FIRST (Execute All).
--
-- HOW TO USE:
--   * Click inside ONE statement and press Ctrl+Enter (runs only that statement).
--   * For multi-line blocks (transactions), select the block and press Ctrl+Shift+Enter.
--   * Do NOT use the magnifier (Explain) button.
--   * Take a screenshot of the Result Grid after each step.
--   * Go in order. Later parts depend on earlier ones.
-- =========================================================

USE car_rental;

-- =========================================================
-- PART 1 : DATABASE STRUCTURE
-- =========================================================

-- 1.1 Show all tables and views
SHOW FULL TABLES;

-- 1.2 Table structure (columns, data types, keys)
DESCRIBE Users;
DESCRIBE Cars;
DESCRIBE Bookings;
DESCRIBE Payments;

-- 1.3 Full definition of a table (shows PK, FK, CHECK, indexes)
SHOW CREATE TABLE Bookings;

-- 1.4 Data in every table
SELECT * FROM Admins;
SELECT * FROM Users;
SELECT * FROM CarTypes;
SELECT * FROM Cars;
SELECT * FROM Bookings;
SELECT * FROM Payments;
SELECT * FROM Reviews;
SELECT * FROM Maintenance;

-- 1.5 Row count of every table
SELECT 'Admins' AS table_name, COUNT(*) AS total_rows FROM Admins
UNION ALL SELECT 'Users',       COUNT(*) FROM Users
UNION ALL SELECT 'CarTypes',    COUNT(*) FROM CarTypes
UNION ALL SELECT 'Cars',        COUNT(*) FROM Cars
UNION ALL SELECT 'Bookings',    COUNT(*) FROM Bookings
UNION ALL SELECT 'Payments',    COUNT(*) FROM Payments
UNION ALL SELECT 'Reviews',     COUNT(*) FROM Reviews
UNION ALL SELECT 'Maintenance', COUNT(*) FROM Maintenance;

-- =========================================================
-- PART 2 : DDL  (CREATE, ALTER, RENAME, TRUNCATE, DROP)
-- =========================================================

-- 2.1 CREATE TABLE
CREATE TABLE Coupons (
    coupon_id         INT PRIMARY KEY AUTO_INCREMENT,
    code              VARCHAR(20) NOT NULL UNIQUE,
    discount_percent  INT NOT NULL,
    note              VARCHAR(100)
);
DESCRIBE Coupons;

-- 2.2 ALTER TABLE (add, modify, rename column, add constraint, drop column)
ALTER TABLE Coupons ADD COLUMN expiry_date DATE;
ALTER TABLE Coupons MODIFY COLUMN code VARCHAR(30) NOT NULL;
ALTER TABLE Coupons RENAME COLUMN note TO description;
ALTER TABLE Coupons ADD CONSTRAINT chk_discount CHECK (discount_percent BETWEEN 1 AND 90);
DESCRIBE Coupons;
ALTER TABLE Coupons DROP COLUMN expiry_date;
DESCRIBE Coupons;

-- 2.3 INSERT multiple rows, then view
INSERT INTO Coupons (code, discount_percent, description) VALUES
('WELCOME10', 10, 'First booking offer'),
('FEST20',    20, 'Festival offer'),
('WEEKEND15', 15, 'Weekend special');
SELECT * FROM Coupons;

-- 2.4 TRUNCATE (removes all rows, keeps structure)
TRUNCATE TABLE Coupons;
SELECT COUNT(*) AS rows_after_truncate FROM Coupons;

-- 2.5 RENAME TABLE, copy table (CREATE ... AS SELECT), DROP TABLE
RENAME TABLE Coupons TO Offers;
CREATE TABLE Cars_Backup AS SELECT * FROM Cars;
SELECT * FROM Cars_Backup;
DROP TABLE Cars_Backup;
DROP TABLE Offers;
SHOW TABLES;

-- =========================================================
-- PART 3 : CONSTRAINTS (each of these is EXPECTED to give an error)
-- Take a screenshot of the Output panel error message
-- =========================================================

-- 3.1 UNIQUE violation (duplicate email)  -> Error 1062
INSERT INTO Users (name, email, password, phone, city, license_no)
VALUES ('Test User', 'rahul@mail.com', 'x', '9000000001', 'Pune', 'LIC-TEST-1');

-- 3.2 NOT NULL violation  -> Error 1048
INSERT INTO Users (name, email, password, license_no)
VALUES (NULL, 'test@mail.com', 'x', 'LIC-TEST-2');

-- 3.3 CHECK violation: negative price  -> Error 3819
INSERT INTO Cars (type_id, brand, model, reg_number, daily_rate)
VALUES (1, 'Test', 'Car', 'MH00XX0000', -500);

-- 3.4 CHECK violation: invalid phone length  -> Error 3819 (chk_phone)
INSERT INTO Users (name, email, password, phone, license_no)
VALUES ('Test User', 'test2@mail.com', 'x', '12345', 'LIC-TEST-3');

-- 3.5 CHECK violation: end date before start date  -> Error 3819 (chk_dates)
INSERT INTO Bookings (user_id, car_id, start_date, end_date)
VALUES (1, 10, '2026-12-05', '2026-12-01');

-- 3.6 FOREIGN KEY violation: user does not exist  -> Error 1452
INSERT INTO Bookings (user_id, car_id, start_date, end_date)
VALUES (99, 1, '2026-12-01', '2026-12-03');

-- 3.7 ENUM violation: invalid status  -> Error 1265
INSERT INTO Cars (type_id, brand, model, reg_number, daily_rate, status)
VALUES (1, 'Test', 'Car', 'MH00YY1111', 1000, 'Broken');

-- 3.8 Composite UNIQUE violation: same user reviewing same car twice  -> Error 1062
INSERT INTO Reviews (user_id, car_id, rating, comment) VALUES (1, 1, 4, 'Second review');

-- 3.9 ON DELETE RESTRICT: cannot delete a user who has bookings  -> Error 1451
DELETE FROM Users WHERE user_id = 1;

-- 3.10 DEFAULT constraint: status is not given, so it becomes 'Available'
INSERT INTO Cars (type_id, brand, model, reg_number, daily_rate)
VALUES (1, 'Renault', 'Kwid', 'MH12UV1111', 1100);
SELECT car_id, model, status FROM Cars WHERE reg_number = 'MH12UV1111';
DELETE FROM Cars WHERE reg_number = 'MH12UV1111';

-- =========================================================
-- PART 4 : DML  (INSERT, UPDATE, DELETE)
-- =========================================================

-- 4.1 INSERT a new customer (password hashed with SHA2)
INSERT INTO Users (name, email, password, phone, city, license_no)
VALUES ('Karan Mehta', 'karan@mail.com', SHA2('pass9',256), '9988776655', 'Pune', 'MH12-2024-099');
SELECT user_id, name, city, phone FROM Users WHERE email = 'karan@mail.com';

-- 4.2 UPDATE customer details
UPDATE Users SET city = 'Mumbai', phone = '9988776600' WHERE email = 'karan@mail.com';
SELECT user_id, name, city, phone FROM Users WHERE email = 'karan@mail.com';

-- 4.3 UPDATE with an expression (raise a rate by 100, then restore it)
UPDATE Cars SET daily_rate = daily_rate + 100 WHERE car_id = 1;
SELECT car_id, model, daily_rate FROM Cars WHERE car_id = 1;
UPDATE Cars SET daily_rate = daily_rate - 100 WHERE car_id = 1;
SELECT car_id, model, daily_rate FROM Cars WHERE car_id = 1;

-- 4.4 DELETE the customer
DELETE FROM Users WHERE email = 'karan@mail.com';
SELECT COUNT(*) AS karan_rows FROM Users WHERE email = 'karan@mail.com';

-- =========================================================
-- PART 5 : SELECT CLAUSES
-- =========================================================

-- 5.1 Specific columns with alias and calculation
SELECT brand AS Brand, model AS Model, daily_rate AS Daily_Rate, daily_rate * 7 AS Weekly_Rate FROM Cars;

-- 5.2 WHERE with AND
SELECT * FROM Cars WHERE status = 'Available' AND daily_rate < 3000;

-- 5.3 IN / OR
SELECT * FROM Cars WHERE brand IN ('Hyundai', 'Maruti');

-- 5.4 BETWEEN on dates
SELECT * FROM Bookings WHERE start_date BETWEEN '2026-08-01' AND '2026-09-30';

-- 5.5 LIKE (pattern matching)
SELECT * FROM Users WHERE name LIKE 'P%';
SELECT * FROM Users WHERE email LIKE '%a%l.com';

-- 5.6 REGEXP
SELECT * FROM Cars WHERE reg_number REGEXP '^MH12';

-- 5.7 IS NULL
SELECT * FROM Admins WHERE manager_id IS NULL;

-- 5.8 DISTINCT
SELECT DISTINCT city FROM Users;

-- 5.9 ORDER BY and LIMIT (top 3 costliest cars)
SELECT brand, model, daily_rate FROM Cars ORDER BY daily_rate DESC LIMIT 3;

-- 5.10 Currently active rentals (date logic)
SELECT * FROM Bookings
WHERE CURDATE() BETWEEN start_date AND end_date AND status = 'Confirmed';

-- =========================================================
-- PART 6 : BUILT-IN FUNCTIONS
-- =========================================================

-- 6.1 String functions
SELECT CONCAT(brand, ' ', model) AS car_name,
       UPPER(brand)              AS brand_upper,
       LENGTH(model)             AS model_length,
       SUBSTRING(reg_number, 1, 4) AS rto_code,
       TRIM('   Car Rental   ')  AS trimmed_text
FROM Cars;

SELECT name, email, LEFT(email, LOCATE('@', email) - 1) AS username FROM Users;

-- 6.2 Numeric functions
SELECT model, daily_rate,
       ROUND(daily_rate * 1.18, 0) AS rate_with_gst,
       CEIL(daily_rate / 1000)     AS ceil_value,
       FLOOR(daily_rate / 1000)    AS floor_value,
       MOD(car_id, 2)              AS odd_or_even,
       ABS(-500)                   AS abs_value
FROM Cars;

-- 6.3 Date functions
SELECT booking_id, start_date,
       DATE_FORMAT(start_date, '%d-%b-%Y') AS formatted_date,
       DAYNAME(start_date)                 AS day_name,
       MONTHNAME(start_date)               AS month_name,
       DATEDIFF(end_date, start_date) + 1  AS rental_days,
       DATE_ADD(end_date, INTERVAL 7 DAY)  AS plus_7_days
FROM Bookings;

SELECT CURDATE() AS today, NOW() AS right_now, YEAR(NOW()) AS this_year,
       DATEDIFF('2026-12-31', CURDATE()) AS days_left_in_year;

-- 6.4 CASE, IF, IFNULL, COALESCE
SELECT car_id, brand, model, daily_rate,
       CASE WHEN daily_rate < 2000 THEN 'Budget'
            WHEN daily_rate < 4000 THEN 'Standard'
            ELSE 'Premium' END AS price_category
FROM Cars;

SELECT name, IF(city = 'Pune', 'Local', 'Outstation') AS customer_type FROM Users;
SELECT name, IFNULL(manager_id, 'No manager') AS manager FROM Admins;

-- 6.5 Aggregate functions
SELECT COUNT(*) AS total_cars, AVG(daily_rate) AS avg_rate,
       MIN(daily_rate) AS cheapest, MAX(daily_rate) AS costliest, SUM(daily_rate) AS total_rate
FROM Cars;

-- 6.6 GROUP_CONCAT and password hashing
SELECT type_id, GROUP_CONCAT(model SEPARATOR ', ') AS models FROM Cars GROUP BY type_id;
SELECT name, password AS hashed_password FROM Users LIMIT 3;

-- =========================================================
-- PART 7 : GROUP BY, HAVING, ROLLUP
-- =========================================================

-- 7.1 Cars and average price per type
SELECT type_id, COUNT(*) AS total_cars, ROUND(AVG(daily_rate), 2) AS avg_rate
FROM Cars GROUP BY type_id;

-- 7.2 Revenue per payment mode
SELECT payment_mode, COUNT(*) AS payments, SUM(amount) AS revenue
FROM Payments GROUP BY payment_mode ORDER BY revenue DESC;

-- 7.3 Monthly revenue
SELECT DATE_FORMAT(payment_date, '%Y-%m') AS month, SUM(amount) AS revenue
FROM Payments GROUP BY month ORDER BY month;

-- 7.4 HAVING: customers with 2 or more bookings
SELECT user_id, COUNT(*) AS total_bookings
FROM Bookings GROUP BY user_id HAVING COUNT(*) >= 2;

-- 7.5 HAVING: cars with average rating of 4 or more
SELECT car_id, ROUND(AVG(rating), 1) AS avg_rating, COUNT(*) AS reviews
FROM Reviews GROUP BY car_id HAVING AVG(rating) >= 4;

-- 7.6 WITH ROLLUP (grand total row)
SELECT payment_mode, SUM(amount) AS revenue
FROM Payments GROUP BY payment_mode WITH ROLLUP;

-- =========================================================
-- PART 8 : JOINS
-- =========================================================

-- 8.1 INNER JOIN
SELECT b.booking_id, u.name AS customer, c.brand, c.model, b.total_amount
FROM Bookings b
INNER JOIN Users u ON b.user_id = u.user_id
INNER JOIN Cars  c ON b.car_id  = c.car_id;

-- 8.2 Four-table join
SELECT b.booking_id, u.name AS customer, t.type_name, c.model, b.start_date, b.end_date, b.total_amount, b.status
FROM Bookings b
JOIN Users    u ON b.user_id = u.user_id
JOIN Cars     c ON b.car_id  = c.car_id
JOIN CarTypes t ON c.type_id = t.type_id
ORDER BY b.booking_id;

-- 8.3 LEFT JOIN: all users, with or without bookings
SELECT u.user_id, u.name, b.booking_id
FROM Users u LEFT JOIN Bookings b ON u.user_id = b.user_id
ORDER BY u.user_id;

-- 8.3b Users who never booked
SELECT u.user_id, u.name
FROM Users u LEFT JOIN Bookings b ON u.user_id = b.user_id
WHERE b.booking_id IS NULL;

-- 8.4 RIGHT JOIN: cars never booked
SELECT c.car_id, c.brand, c.model, b.booking_id
FROM Bookings b RIGHT JOIN Cars c ON b.car_id = c.car_id
WHERE b.booking_id IS NULL;

-- 8.5 FULL OUTER JOIN (emulated with UNION): car types with and without cars
SELECT t.type_name, c.brand, c.model
FROM CarTypes t LEFT JOIN Cars c ON t.type_id = c.type_id
UNION
SELECT t.type_name, c.brand, c.model
FROM CarTypes t RIGHT JOIN Cars c ON t.type_id = c.type_id;

-- 8.6 SELF JOIN: employee and manager
SELECT e.name AS employee, IFNULL(m.name, 'No manager') AS manager
FROM Admins e LEFT JOIN Admins m ON e.manager_id = m.admin_id;

-- 8.6b SELF JOIN: pairs of cars of the same type
SELECT a.model AS car_1, b.model AS car_2, t.type_name
FROM Cars a
JOIN Cars b     ON a.type_id = b.type_id AND a.car_id < b.car_id
JOIN CarTypes t ON a.type_id = t.type_id
ORDER BY t.type_name;

-- 8.7 CROSS JOIN: every user with every car type
SELECT u.name, t.type_name FROM Users u CROSS JOIN CarTypes t LIMIT 10;

-- 8.8 NATURAL JOIN (joins on the common column type_id)
SELECT brand, model, type_name FROM Cars NATURAL JOIN CarTypes;

-- 8.9 JOIN ... USING
SELECT c.brand, c.model, t.type_name FROM Cars c JOIN CarTypes t USING (type_id);

-- =========================================================
-- PART 9 : SUBQUERIES
-- =========================================================

-- 9.1 Scalar subquery: cars costlier than the average
SELECT brand, model, daily_rate FROM Cars
WHERE daily_rate > (SELECT AVG(daily_rate) FROM Cars);

-- 9.2 IN: customers who have booked an SUV
SELECT name FROM Users
WHERE user_id IN (SELECT b.user_id FROM Bookings b
                  JOIN Cars c ON b.car_id = c.car_id WHERE c.type_id = 3);

-- 9.3 NOT IN: cars never booked
SELECT car_id, brand, model FROM Cars
WHERE car_id NOT IN (SELECT car_id FROM Bookings);

-- 9.4 EXISTS and NOT EXISTS
SELECT name FROM Users u
WHERE EXISTS (SELECT 1 FROM Reviews r WHERE r.user_id = u.user_id);

SELECT name FROM Users u
WHERE NOT EXISTS (SELECT 1 FROM Bookings b WHERE b.user_id = u.user_id);

-- 9.5 Correlated subquery: cars priced above the average of their own type
SELECT c1.brand, c1.model, c1.type_id, c1.daily_rate
FROM Cars c1
WHERE c1.daily_rate > (SELECT AVG(c2.daily_rate) FROM Cars c2 WHERE c2.type_id = c1.type_id);

-- 9.6 ALL / ANY
SELECT brand, model, daily_rate FROM Cars
WHERE daily_rate > ALL (SELECT daily_rate FROM Cars WHERE type_id = 1);

SELECT brand, model, daily_rate FROM Cars
WHERE daily_rate > ANY (SELECT daily_rate FROM Cars WHERE type_id = 3);

-- 9.7 Derived table (subquery in FROM)
SELECT t.type_name, d.avg_rate
FROM (SELECT type_id, ROUND(AVG(daily_rate), 2) AS avg_rate FROM Cars GROUP BY type_id) d
JOIN CarTypes t ON t.type_id = d.type_id;

-- 9.8 Subquery in SELECT list
SELECT c.brand, c.model,
       (SELECT COUNT(*) FROM Bookings b WHERE b.car_id = c.car_id) AS times_booked
FROM Cars c ORDER BY times_booked DESC;

-- 9.9 Nested subquery: customer who paid the most
SELECT name FROM Users WHERE user_id = (
    SELECT b.user_id FROM Bookings b
    JOIN Payments p ON b.booking_id = p.booking_id
    GROUP BY b.user_id ORDER BY SUM(p.amount) DESC LIMIT 1);

-- =========================================================
-- PART 10 : SET OPERATIONS
-- INTERSECT and EXCEPT need MySQL 8.0.31 or newer. Check: SELECT VERSION();
-- =========================================================

-- 10.1 UNION: customers who booked OR reviewed (duplicates removed)
SELECT name FROM Users WHERE user_id IN (SELECT user_id FROM Bookings)
UNION
SELECT name FROM Users WHERE user_id IN (SELECT user_id FROM Reviews);

-- 10.2 UNION ALL (duplicates kept, compare with 10.1)
SELECT user_id FROM Bookings
UNION ALL
SELECT user_id FROM Reviews;

-- 10.3 INTERSECT: customers who booked AND reviewed
SELECT user_id FROM Bookings
INTERSECT
SELECT user_id FROM Reviews;
-- Older MySQL alternative:
-- SELECT DISTINCT user_id FROM Bookings WHERE user_id IN (SELECT user_id FROM Reviews);

-- 10.4 EXCEPT: customers who booked but NEVER reviewed
SELECT user_id FROM Bookings
EXCEPT
SELECT user_id FROM Reviews;
-- Older MySQL alternative:
-- SELECT DISTINCT user_id FROM Bookings WHERE user_id NOT IN (SELECT user_id FROM Reviews);

-- =========================================================
-- PART 11 : WINDOW FUNCTIONS AND CTE
-- =========================================================

-- 11.1 RANK within each car type
SELECT t.type_name, c.model, c.daily_rate,
       RANK() OVER (PARTITION BY c.type_id ORDER BY c.daily_rate DESC) AS price_rank
FROM Cars c JOIN CarTypes t ON c.type_id = t.type_id;

-- 11.2 Rank customers by total paid
SELECT name, total_paid,
       RANK()       OVER (ORDER BY total_paid DESC) AS rnk,
       ROW_NUMBER() OVER (ORDER BY total_paid DESC) AS row_no,
       DENSE_RANK() OVER (ORDER BY total_paid DESC) AS dense_rnk
FROM vw_user_spending;

-- 11.3 Running total of payments
SELECT payment_id, payment_date, amount,
       SUM(amount) OVER (ORDER BY payment_date) AS running_total
FROM Payments;

-- 11.4 LAG: compare with previous payment
SELECT payment_id, payment_date, amount,
       LAG(amount) OVER (ORDER BY payment_date) AS previous_amount
FROM Payments;

-- 11.5 CTE (WITH clause): revenue per car from completed bookings
WITH car_revenue AS (
    SELECT car_id, SUM(total_amount) AS revenue
    FROM Bookings WHERE status = 'Completed' GROUP BY car_id
)
SELECT c.brand, c.model, cr.revenue
FROM car_revenue cr JOIN Cars c ON cr.car_id = c.car_id
ORDER BY cr.revenue DESC;

-- 11.6 Recursive CTE: admin hierarchy
WITH RECURSIVE admin_tree AS (
    SELECT admin_id, name, manager_id, 1 AS level, CAST(name AS CHAR(200)) AS path
    FROM Admins WHERE manager_id IS NULL
    UNION ALL
    SELECT a.admin_id, a.name, a.manager_id, t.level + 1, CONCAT(t.path, ' > ', a.name)
    FROM Admins a JOIN admin_tree t ON a.manager_id = t.admin_id
)
SELECT * FROM admin_tree;

-- =========================================================
-- PART 12 : VIEWS
-- =========================================================

-- 12.1 List views
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- 12.2 Use the views
SELECT * FROM vw_booking_details;
SELECT * FROM vw_car_ratings;
SELECT * FROM vw_user_spending;
SELECT * FROM vw_available_cars;

-- 12.3 Filter a view like a table
SELECT * FROM vw_booking_details WHERE status = 'Pending';

-- 12.4 Create, use and drop a view
CREATE VIEW vw_suv_cars AS
SELECT car_id, brand, model, daily_rate FROM Cars WHERE type_id = 3;
SELECT * FROM vw_suv_cars;
DROP VIEW vw_suv_cars;

-- =========================================================
-- PART 13 : INDEXES
-- =========================================================

-- 13.1 Existing indexes
SHOW INDEX FROM Cars;
SHOW INDEX FROM Bookings;

-- 13.2 EXPLAIN: indexed column (type = const) vs non-indexed column (type = ALL)
EXPLAIN SELECT * FROM Users WHERE email = 'rahul@mail.com';
EXPLAIN SELECT * FROM Users WHERE city = 'Pune';

-- 13.3 Create an index on city, then view it
CREATE INDEX idx_users_city ON Users(city);
SHOW INDEX FROM Users;

-- 13.4 Drop the index
DROP INDEX idx_users_city ON Users;

-- =========================================================
-- PART 14 : STORED FUNCTIONS, PROCEDURES, CURSOR
-- =========================================================

-- 14.1 Function: rental days
SELECT fn_rental_days('2026-11-01', '2026-11-05') AS days;
SELECT booking_id, start_date, end_date,
       fn_rental_days(start_date, end_date) AS days, total_amount
FROM Bookings;

-- 14.2 Function: is a car free? (1 = free, 0 = booked)
SELECT fn_is_car_free(1, '2026-12-01', '2026-12-05') AS car1_free,
       fn_is_car_free(6, '2026-10-15', '2026-10-16') AS car6_free;

-- 14.3 Function: customer tier
SELECT name, fn_customer_tier(user_id) AS tier FROM Users;

-- 14.4 Procedure with parameter: monthly report
CALL sp_monthly_report(2026);

-- 14.5 Procedure with transaction and error handling: book a car
CALL sp_book_car(3, 10, '2026-12-01', '2026-12-04', @msg);
SELECT @msg AS result;

-- 14.6 Same booking again: handler catches the trigger error and rolls back
CALL sp_book_car(2, 10, '2026-12-02', '2026-12-03', @msg);
SELECT @msg AS result;

-- 14.7 Procedure: complete a booking (car becomes Available again)
SELECT car_id, status FROM Cars WHERE car_id = 6;
CALL sp_complete_booking(10);
SELECT booking_id, status FROM Bookings WHERE booking_id = 10;
SELECT car_id, status FROM Cars WHERE car_id = 6;

-- 14.8 Cursor: total payments collected, compared with SUM()
CALL sp_total_paid_cursor(@total);
SELECT @total AS total_by_cursor, (SELECT SUM(amount) FROM Payments) AS total_by_sum;

-- 14.9 List stored routines
SHOW PROCEDURE STATUS WHERE Db = 'car_rental';
SHOW FUNCTION STATUS WHERE Db = 'car_rental';

-- =========================================================
-- PART 15 : TRIGGERS
-- =========================================================

-- 15.1 List triggers
SHOW TRIGGERS FROM car_rental;

-- 15.2 Overlapping booking is blocked  -> Error: Car is already booked for these dates
INSERT INTO Bookings (user_id, car_id, start_date, end_date)
VALUES (2, 4, '2026-10-26', '2026-10-28');

-- 15.3 Car under maintenance is blocked  -> Error: Car is under maintenance
INSERT INTO Bookings (user_id, car_id, start_date, end_date)
VALUES (2, 8, '2026-11-20', '2026-11-22');

-- 15.4 total_amount is calculated automatically (3 days x 1300 = 3900)
INSERT INTO Bookings (user_id, car_id, start_date, end_date)
VALUES (7, 5, '2026-11-10', '2026-11-12');
SET @new_booking = LAST_INSERT_ID();
SELECT booking_id, car_id, start_date, end_date, total_amount, status
FROM Bookings WHERE booking_id = @new_booking;

-- 15.5 Payment trigger: Pending -> Confirmed automatically
SELECT booking_id, status FROM Bookings WHERE booking_id = 11;
INSERT INTO Payments (booking_id, amount, payment_mode) VALUES (11, 8800, 'UPI');
SELECT booking_id, status FROM Bookings WHERE booking_id = 11;

-- 15.6 Audit triggers: delete the booking from 15.4 and view the audit log
DELETE FROM Bookings WHERE booking_id = @new_booking;
SELECT * FROM BookingAudit ORDER BY audit_id;

-- =========================================================
-- PART 16 : TRANSACTIONS (TCL: START TRANSACTION, COMMIT, ROLLBACK, SAVEPOINT)
-- Select each block fully and press Ctrl+Shift+Enter
-- =========================================================

-- 16.1 ROLLBACK: undo a 10% price hike on SUVs
START TRANSACTION;
UPDATE Cars SET daily_rate = daily_rate * 1.10 WHERE type_id = 3;
SELECT car_id, model, daily_rate AS rate_inside_transaction FROM Cars WHERE type_id = 3;
ROLLBACK;
SELECT car_id, model, daily_rate AS rate_after_rollback FROM Cars WHERE type_id = 3;

-- 16.2 COMMIT: make a change permanent (then restore it)
START TRANSACTION;
UPDATE Cars SET status = 'Maintenance' WHERE car_id = 5;
COMMIT;
SELECT car_id, model, status FROM Cars WHERE car_id = 5;
UPDATE Cars SET status = 'Available' WHERE car_id = 5;

-- 16.3 SAVEPOINT: keep the review, undo the accidental delete
START TRANSACTION;
INSERT INTO Reviews (user_id, car_id, rating, comment) VALUES (7, 2, 4, 'Nice car');
SAVEPOINT after_review;
DELETE FROM Payments WHERE booking_id = 1;
SELECT COUNT(*) AS payments_after_wrong_delete FROM Payments;
ROLLBACK TO SAVEPOINT after_review;
COMMIT;
SELECT COUNT(*) AS payments_restored FROM Payments;
SELECT * FROM Reviews WHERE user_id = 7;
DELETE FROM Reviews WHERE user_id = 7 AND car_id = 2;

-- 16.4 ON DELETE CASCADE: deleting a booking deletes its payment (then undo)
START TRANSACTION;
DELETE FROM Bookings WHERE booking_id = 1;
SELECT * FROM Payments WHERE booking_id = 1;
ROLLBACK;
SELECT * FROM Payments WHERE booking_id = 1;

-- =========================================================
-- PART 17 : DCL (GRANT, REVOKE)  -- run as root user
-- =========================================================

-- 17.1 Create a staff user, grant and revoke privileges
CREATE USER 'rental_staff'@'localhost' IDENTIFIED BY 'Staff@123';
GRANT SELECT, INSERT ON car_rental.Bookings TO 'rental_staff'@'localhost';
GRANT SELECT ON car_rental.Cars TO 'rental_staff'@'localhost';
SHOW GRANTS FOR 'rental_staff'@'localhost';
REVOKE INSERT ON car_rental.Bookings FROM 'rental_staff'@'localhost';
SHOW GRANTS FOR 'rental_staff'@'localhost';
DROP USER 'rental_staff'@'localhost';

-- =========================================================
-- PART 18 : PROJECT SUMMARY (final screenshot)
-- =========================================================

SELECT (SELECT COUNT(*) FROM Users)           AS total_users,
       (SELECT COUNT(*) FROM Cars)            AS total_cars,
       (SELECT COUNT(*) FROM Bookings)        AS total_bookings,
       (SELECT SUM(amount) FROM Payments)     AS total_revenue,
       (SELECT COUNT(*) FROM BookingAudit)    AS audit_entries;