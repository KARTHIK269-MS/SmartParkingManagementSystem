-- ==========================================================
-- Smart Parking Management System (PRJ_35)
-- Database: parking_system
-- ==========================================================

CREATE DATABASE IF NOT EXISTS parking_system;
USE parking_system;

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role VARCHAR(20) DEFAULT 'USER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ensure role column exists if table was previously created
SET @col_role = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='users' AND column_name='role');
SET @sql_role = IF(@col_role = 0, 'ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT "USER"', 'SELECT 1');
PREPARE stmt FROM @sql_role;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure created_at column exists
SET @col_created = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='users' AND column_name='created_at');
SET @sql_created = IF(@col_created = 0, 'ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP', 'SELECT 1');
PREPARE stmt FROM @sql_created;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. ZONES TABLE
CREATE TABLE IF NOT EXISTS zones (
    zone_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(150) NOT NULL,
    hourly_rate DECIMAL(10,2) NOT NULL,
    total_slots INT NOT NULL DEFAULT 20,
    description VARCHAR(255)
);

-- 3. SLOTS TABLE
CREATE TABLE IF NOT EXISTS slots (
    slot_id VARCHAR(10) PRIMARY KEY,
    zone_id VARCHAR(10) NOT NULL,
    slot_number INT NOT NULL,
    floor INT NOT NULL DEFAULT 1,
    type VARCHAR(20) DEFAULT 'STANDARD',
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE'
);

-- Compatibility check: rename or map 'zone' to 'zone_id' if exists
SET @col_zone = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='slots' AND column_name='zone');
SET @sql_zone = IF(@col_zone > 0, 'ALTER TABLE slots CHANGE COLUMN zone zone_id VARCHAR(10) NOT NULL', 'SELECT 1');
PREPARE stmt FROM @sql_zone;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_floor = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='slots' AND column_name='floor');
SET @sql_floor = IF(@col_floor = 0, 'ALTER TABLE slots ADD COLUMN floor INT NOT NULL DEFAULT 1', 'SELECT 1');
PREPARE stmt FROM @sql_floor;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_slot_num = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='slots' AND column_name='slot_number');
SET @sql_slot_num = IF(@col_slot_num = 0, 'ALTER TABLE slots ADD COLUMN slot_number INT NOT NULL DEFAULT 1', 'SELECT 1');
PREPARE stmt FROM @sql_slot_num;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_type = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='slots' AND column_name='type');
SET @sql_type = IF(@col_type = 0, 'ALTER TABLE slots ADD COLUMN type VARCHAR(20) DEFAULT "STANDARD"', 'SELECT 1');
PREPARE stmt FROM @sql_type;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. BOOKINGS TABLE
CREATE TABLE IF NOT EXISTS bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20) NOT NULL,
    slot_id VARCHAR(10) NOT NULL,
    vehicle_number VARCHAR(20) NOT NULL DEFAULT 'KA01AB1234',
    duration_hours INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    booking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    payment_id VARCHAR(50) NULL
);

-- Ensure vehicle_number exists
SET @col_veh = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='bookings' AND column_name='vehicle_number');
SET @sql_veh = IF(@col_veh = 0, 'ALTER TABLE bookings ADD COLUMN vehicle_number VARCHAR(20) NOT NULL DEFAULT "KA01AB1234"', 'SELECT 1');
PREPARE stmt FROM @sql_veh;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure booking_time exists
SET @col_btime = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='bookings' AND column_name='booking_time');
SET @sql_btime = IF(@col_btime = 0, 'ALTER TABLE bookings ADD COLUMN booking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP', 'SELECT 1');
PREPARE stmt FROM @sql_btime;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure expires_at exists
SET @col_exp = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='bookings' AND column_name='expires_at');
SET @sql_exp = IF(@col_exp = 0, 'ALTER TABLE bookings ADD COLUMN expires_at TIMESTAMP NULL', 'SELECT 1');
PREPARE stmt FROM @sql_exp;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure payment_id exists
SET @col_pid = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='bookings' AND column_name='payment_id');
SET @sql_pid = IF(@col_pid = 0, 'ALTER TABLE bookings ADD COLUMN payment_id VARCHAR(50) NULL', 'SELECT 1');
PREPARE stmt FROM @sql_pid;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure entry_time exists (Sensor Scan-In)
SET @col_entry = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='bookings' AND column_name='entry_time');
SET @sql_entry = IF(@col_entry = 0, 'ALTER TABLE bookings ADD COLUMN entry_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP', 'SELECT 1');
PREPARE stmt FROM @sql_entry;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure exit_time exists (Sensor Scan-Out)
SET @col_exit = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='bookings' AND column_name='exit_time');
SET @sql_exit = IF(@col_exit = 0, 'ALTER TABLE bookings ADD COLUMN exit_time TIMESTAMP NULL', 'SELECT 1');
PREPARE stmt FROM @sql_exit;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure scheduled_arrival_time exists
SET @col_sat = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='bookings' AND column_name='scheduled_arrival_time');
SET @sql_sat = IF(@col_sat = 0, 'ALTER TABLE bookings ADD COLUMN scheduled_arrival_time TIMESTAMP NULL', 'SELECT 1');
PREPARE stmt FROM @sql_sat;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ensure cancellation_reason exists
SET @col_cr = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='bookings' AND column_name='cancellation_reason');
SET @sql_cr = IF(@col_cr = 0, 'ALTER TABLE bookings ADD COLUMN cancellation_reason VARCHAR(255) NULL', 'SELECT 1');
PREPARE stmt FROM @sql_cr;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 5. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(20) NOT NULL,
    booking_id INT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(30) DEFAULT 'WARNING',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. PAYMENTS TABLE
CREATE TABLE IF NOT EXISTS payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'SUCCESS',
    payment_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. FEEDBACK TABLE
CREATE TABLE IF NOT EXISTS feedback (
    feedback_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    user_id VARCHAR(20) NOT NULL DEFAULT 'U001',
    rating INT NOT NULL,
    comment VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET @col_fuser = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='feedback' AND column_name='user_id');
SET @sql_fuser = IF(@col_fuser = 0, 'ALTER TABLE feedback ADD COLUMN user_id VARCHAR(20) NOT NULL DEFAULT "U001"', 'SELECT 1');
PREPARE stmt FROM @sql_fuser;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col_fcreated = (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='parking_system' AND table_name='feedback' AND column_name='created_at');
SET @sql_fcreated = IF(@col_fcreated = 0, 'ALTER TABLE feedback ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP', 'SELECT 1');
PREPARE stmt FROM @sql_fcreated;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 7. OCCUPANCY SNAPSHOTS TABLE (Smart Occupancy Prediction & Telemetry)
CREATE TABLE IF NOT EXISTS occupancy_snapshots (
    snapshot_id INT NOT NULL AUTO_INCREMENT,
    zone_id VARCHAR(10) NOT NULL,
    total_bays INT NOT NULL,
    occupied_bays INT NOT NULL,
    occupancy_percent DECIMAL(5,2) NOT NULL,
    recorded_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (snapshot_id),
    KEY idx_zone_recorded (zone_id, recorded_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ==========================================================
-- SEED DATA
-- ==========================================================

-- Seed Realistic Accounts (Admin + 12 Active Drivers)
-- Password for drivers: Driver@123 (BCrypt hash)
-- Admin: admin@smartparking.com / Admin@123

INSERT INTO users (user_id, name, email, password, phone_number, role)
VALUES 
('ADM001', 'System Administrator', 'admin@smartparking.com', 'e86f78a8a3caf0b60d8e74e5942aa6d86dc150cd3c03338aef25b7d2d7e3acc7', '9000000000', 'ADMIN'),
('U001', 'Arun Kumar', 'driver1@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000001', 'USER'),
('U002', 'Priya Sharma', 'driver2@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000002', 'USER'),
('U003', 'Vikram Mehta', 'driver3@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000003', 'USER'),
('U004', 'Neha Patel', 'driver4@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000004', 'USER'),
('U005', 'Rohit Verma', 'driver5@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000005', 'USER'),
('U006', 'Ananya Deshmukh', 'driver6@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000006', 'USER'),
('U007', 'Kavita Reddy', 'driver7@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000007', 'USER'),
('U008', 'Manish Joshi', 'driver8@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000008', 'USER'),
('U009', 'Suresh Nair', 'driver9@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000009', 'USER'),
('U010', 'Deepa Iyer', 'driver10@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000010', 'USER'),
('U011', 'Rahul Sen', 'driver11@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000011', 'USER'),
('U012', 'Pooja Choudhary', 'driver12@example.com', '$2a$10$s4wfExZHwiFKC62f50CTGuwsziXgu3jck95tB.RfJNDZAWvvUBBoq', '9000000012', 'USER')
ON DUPLICATE KEY UPDATE name=VALUES(name), email=VALUES(email), password=VALUES(password), phone_number=VALUES(phone_number), role=VALUES(role);

-- Seed Zones (12 Active Facilities Across 3 Major Tech Corridors - Total Capacity: 150 Bays)
INSERT INTO zones (zone_id, name, location, hourly_rate, total_slots, description)
VALUES
('B', 'Zone B - Bengaluru (Electronic City IT Hub)', 'Hosur Main Road, Electronic City Phase 1, Bengaluru, Karnataka', 40.00, 20, 'Multi-level parking near Electronic City IT Hub.'),
('BLR-2', 'Zone BLR-2 - Bengaluru (Whitefield Tech Park)', 'ITPL Main Road, Whitefield, Bengaluru, Karnataka', 35.0, 10, 'Covered facility near ITPB and Whitefield metro station.'),
('BLR-3', 'Zone BLR-3 - Bengaluru (MG Road & Brigade Central)', 'MG Road, Ashok Nagar, Bengaluru, Karnataka', 40.0, 10, 'Central parking facility near MG Road and Brigade Road.'),
('BLR-4', 'Zone BLR-4 - Bengaluru (Kempegowda Airport Gateway)', 'Devanahalli, Airport Expressway, Bengaluru', 30.0, 10, 'Transit parking near Kempegowda Airport expressway.'),
('D', 'Zone D - Hyderabad (HITEC City Cyber Towers)', 'HITEC City Main Road, Madhapur, Hyderabad, Telangana', 40.00, 20, 'Multi-storey parking serving HITEC City and Cyber Towers.'),
('HYD-2', 'Zone HYD-2 - Hyderabad (Gachibowli Financial District)', 'ISB Road, Nanakramguda, Gachibowli, Hyderabad', 30.0, 10, 'Multi-level parking near Gachibowli financial district.'),
('HYD-3', 'Zone HYD-3 - Hyderabad (Banjara Hills & Jubilee Hills)', 'Road No. 36, Jubilee Hills, Hyderabad, Telangana', 35.0, 10, 'Upscale commercial valet-ready parking facility in Hyderabad.'),
('HYD-4', 'Zone HYD-4 - Hyderabad (RGIA Airport Terminal Hub)', 'Airport Approach Road, Shamshabad, Hyderabad', 25.0, 10, 'Transit parking near Rajiv Gandhi International Airport.'),
('E', 'Zone E - Chennai (OMR IT Expressway)', 'Old Mahabalipuram Road, Taramani, Chennai, Tamil Nadu', 40.00, 20, 'Covered parking bays along Old Mahabalipuram Road (OMR).'),
('CHN-2', 'Zone CHN-2 - Chennai (Anna Salai & T. Nagar)', 'Mount Road, Anna Salai, T. Nagar, Chennai, Tamil Nadu', 30.0, 10, 'Multi-level facility serving Anna Salai and T. Nagar.'),
('CHN-3', 'Zone CHN-3 - Chennai (Guindy Industrial & Tech Hub)', 'GST Road, Kathipara Junction, Guindy, Chennai', 25.0, 10, 'Transit facility connected to Guindy metro and Kathipara junction.'),
('CHN-4', 'Zone CHN-4 - Chennai (Chennai Central Railway Gateway)', 'EVR Periyar Salai, Park Town, Chennai, Tamil Nadu', 20.0, 10, 'Transit parking serving Chennai Central railway station.')
ON DUPLICATE KEY UPDATE 
name=VALUES(name), location=VALUES(location), hourly_rate=VALUES(hourly_rate), total_slots=VALUES(total_slots), description=VALUES(description);

-- ==========================================================
-- SEED SLOTS (Total: 150 Bays)
-- ==========================================================

-- 1. Bengaluru - Zone B (B1 to B20 - 20 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES
('B1', 'B', 1, 1, 'EV', 'AVAILABLE'),
('B2', 'B', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('B3', 'B', 3, 1, 'STANDARD', 'AVAILABLE'),
('B4', 'B', 4, 1, 'STANDARD', 'AVAILABLE'),
('B5', 'B', 5, 1, 'STANDARD', 'AVAILABLE'),
('B6', 'B', 6, 1, 'STANDARD', 'AVAILABLE'),
('B7', 'B', 7, 1, 'STANDARD', 'AVAILABLE'),
('B8', 'B', 8, 1, 'STANDARD', 'AVAILABLE'),
('B9', 'B', 9, 1, 'STANDARD', 'AVAILABLE'),
('B10', 'B', 10, 1, 'STANDARD', 'AVAILABLE'),
('B11', 'B', 11, 2, 'STANDARD', 'AVAILABLE'),
('B12', 'B', 12, 2, 'STANDARD', 'AVAILABLE'),
('B13', 'B', 13, 2, 'STANDARD', 'AVAILABLE'),
('B14', 'B', 14, 2, 'STANDARD', 'AVAILABLE'),
('B15', 'B', 15, 2, 'STANDARD', 'AVAILABLE'),
('B16', 'B', 16, 2, 'STANDARD', 'AVAILABLE'),
('B17', 'B', 17, 2, 'STANDARD', 'AVAILABLE'),
('B18', 'B', 18, 2, 'STANDARD', 'AVAILABLE'),
('B19', 'B', 19, 2, 'STANDARD', 'AVAILABLE'),
('B20', 'B', 20, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 2. Bengaluru - Zone BLR-2 (BLR-2-1 to BLR-2-10 - 10 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES 
('BLR-2-1', 'BLR-2', 1, 1, 'EV', 'AVAILABLE'),
('BLR-2-2', 'BLR-2', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-2-3', 'BLR-2', 3, 1, 'STANDARD', 'AVAILABLE'),
('BLR-2-4', 'BLR-2', 4, 1, 'STANDARD', 'AVAILABLE'),
('BLR-2-5', 'BLR-2', 5, 1, 'STANDARD', 'AVAILABLE'),
('BLR-2-6', 'BLR-2', 6, 2, 'EV', 'AVAILABLE'),
('BLR-2-7', 'BLR-2', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-2-8', 'BLR-2', 8, 2, 'STANDARD', 'AVAILABLE'),
('BLR-2-9', 'BLR-2', 9, 2, 'STANDARD', 'AVAILABLE'),
('BLR-2-10', 'BLR-2', 10, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 3. Bengaluru - Zone BLR-3 (BLR-3-1 to BLR-3-10 - 10 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES 
('BLR-3-1', 'BLR-3', 1, 1, 'EV', 'AVAILABLE'),
('BLR-3-2', 'BLR-3', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-3-3', 'BLR-3', 3, 1, 'STANDARD', 'AVAILABLE'),
('BLR-3-4', 'BLR-3', 4, 1, 'STANDARD', 'AVAILABLE'),
('BLR-3-5', 'BLR-3', 5, 1, 'STANDARD', 'AVAILABLE'),
('BLR-3-6', 'BLR-3', 6, 2, 'EV', 'AVAILABLE'),
('BLR-3-7', 'BLR-3', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-3-8', 'BLR-3', 8, 2, 'STANDARD', 'AVAILABLE'),
('BLR-3-9', 'BLR-3', 9, 2, 'STANDARD', 'AVAILABLE'),
('BLR-3-10', 'BLR-3', 10, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 4. Bengaluru - Zone BLR-4 (BLR-4-1 to BLR-4-10 - 10 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES 
('BLR-4-1', 'BLR-4', 1, 1, 'EV', 'AVAILABLE'),
('BLR-4-2', 'BLR-4', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-4-3', 'BLR-4', 3, 1, 'STANDARD', 'AVAILABLE'),
('BLR-4-4', 'BLR-4', 4, 1, 'STANDARD', 'AVAILABLE'),
('BLR-4-5', 'BLR-4', 5, 1, 'STANDARD', 'AVAILABLE'),
('BLR-4-6', 'BLR-4', 6, 2, 'EV', 'AVAILABLE'),
('BLR-4-7', 'BLR-4', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-4-8', 'BLR-4', 8, 2, 'STANDARD', 'AVAILABLE'),
('BLR-4-9', 'BLR-4', 9, 2, 'STANDARD', 'AVAILABLE'),
('BLR-4-10', 'BLR-4', 10, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 5. Hyderabad - Zone D (D1 to D20 - 20 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES
('D1', 'D', 1, 1, 'EV', 'AVAILABLE'),
('D2', 'D', 2, 1, 'EV', 'AVAILABLE'),
('D3', 'D', 3, 1, 'ACCESSIBLE', 'AVAILABLE'),
('D4', 'D', 4, 1, 'STANDARD', 'AVAILABLE'),
('D5', 'D', 5, 1, 'STANDARD', 'AVAILABLE'),
('D6', 'D', 6, 1, 'STANDARD', 'AVAILABLE'),
('D7', 'D', 7, 1, 'STANDARD', 'AVAILABLE'),
('D8', 'D', 8, 1, 'STANDARD', 'AVAILABLE'),
('D9', 'D', 9, 1, 'STANDARD', 'AVAILABLE'),
('D10', 'D', 10, 1, 'STANDARD', 'AVAILABLE'),
('D11', 'D', 11, 2, 'EV', 'AVAILABLE'),
('D12', 'D', 12, 2, 'EV', 'AVAILABLE'),
('D13', 'D', 13, 2, 'ACCESSIBLE', 'AVAILABLE'),
('D14', 'D', 14, 2, 'STANDARD', 'AVAILABLE'),
('D15', 'D', 15, 2, 'STANDARD', 'AVAILABLE'),
('D16', 'D', 16, 2, 'STANDARD', 'AVAILABLE'),
('D17', 'D', 17, 2, 'STANDARD', 'AVAILABLE'),
('D18', 'D', 18, 2, 'STANDARD', 'AVAILABLE'),
('D19', 'D', 19, 2, 'STANDARD', 'AVAILABLE'),
('D20', 'D', 20, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 6. Hyderabad - Zone HYD-2 (HYD-2-1 to HYD-2-10 - 10 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES 
('HYD-2-1', 'HYD-2', 1, 1, 'EV', 'AVAILABLE'),
('HYD-2-2', 'HYD-2', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-2-3', 'HYD-2', 3, 1, 'STANDARD', 'AVAILABLE'),
('HYD-2-4', 'HYD-2', 4, 1, 'STANDARD', 'AVAILABLE'),
('HYD-2-5', 'HYD-2', 5, 1, 'STANDARD', 'AVAILABLE'),
('HYD-2-6', 'HYD-2', 6, 2, 'EV', 'AVAILABLE'),
('HYD-2-7', 'HYD-2', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-2-8', 'HYD-2', 8, 2, 'STANDARD', 'AVAILABLE'),
('HYD-2-9', 'HYD-2', 9, 2, 'STANDARD', 'AVAILABLE'),
('HYD-2-10', 'HYD-2', 10, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 7. Hyderabad - Zone HYD-3 (HYD-3-1 to HYD-3-10 - 10 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES 
('HYD-3-1', 'HYD-3', 1, 1, 'EV', 'AVAILABLE'),
('HYD-3-2', 'HYD-3', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-3-3', 'HYD-3', 3, 1, 'STANDARD', 'AVAILABLE'),
('HYD-3-4', 'HYD-3', 4, 1, 'STANDARD', 'AVAILABLE'),
('HYD-3-5', 'HYD-3', 5, 1, 'STANDARD', 'AVAILABLE'),
('HYD-3-6', 'HYD-3', 6, 2, 'EV', 'AVAILABLE'),
('HYD-3-7', 'HYD-3', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-3-8', 'HYD-3', 8, 2, 'STANDARD', 'AVAILABLE'),
('HYD-3-9', 'HYD-3', 9, 2, 'STANDARD', 'AVAILABLE'),
('HYD-3-10', 'HYD-3', 10, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 8. Hyderabad - Zone HYD-4 (HYD-4-1 to HYD-4-10 - 10 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES 
('HYD-4-1', 'HYD-4', 1, 1, 'EV', 'AVAILABLE'),
('HYD-4-2', 'HYD-4', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-4-3', 'HYD-4', 3, 1, 'STANDARD', 'AVAILABLE'),
('HYD-4-4', 'HYD-4', 4, 1, 'STANDARD', 'AVAILABLE'),
('HYD-4-5', 'HYD-4', 5, 1, 'STANDARD', 'AVAILABLE'),
('HYD-4-6', 'HYD-4', 6, 2, 'EV', 'AVAILABLE'),
('HYD-4-7', 'HYD-4', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-4-8', 'HYD-4', 8, 2, 'STANDARD', 'AVAILABLE'),
('HYD-4-9', 'HYD-4', 9, 2, 'STANDARD', 'AVAILABLE'),
('HYD-4-10', 'HYD-4', 10, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 9. Chennai - Zone E (E1 to E20 - 20 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES
('E1', 'E', 1, 1, 'EV', 'AVAILABLE'),
('E2', 'E', 2, 1, 'EV', 'AVAILABLE'),
('E3', 'E', 3, 1, 'ACCESSIBLE', 'AVAILABLE'),
('E4', 'E', 4, 1, 'STANDARD', 'AVAILABLE'),
('E5', 'E', 5, 1, 'STANDARD', 'AVAILABLE'),
('E6', 'E', 6, 1, 'STANDARD', 'AVAILABLE'),
('E7', 'E', 7, 1, 'STANDARD', 'AVAILABLE'),
('E8', 'E', 8, 1, 'STANDARD', 'AVAILABLE'),
('E9', 'E', 9, 1, 'STANDARD', 'AVAILABLE'),
('E10', 'E', 10, 1, 'STANDARD', 'AVAILABLE'),
('E11', 'E', 11, 2, 'EV', 'AVAILABLE'),
('E12', 'E', 12, 2, 'EV', 'AVAILABLE'),
('E13', 'E', 13, 2, 'ACCESSIBLE', 'AVAILABLE'),
('E14', 'E', 14, 2, 'STANDARD', 'AVAILABLE'),
('E15', 'E', 15, 2, 'STANDARD', 'AVAILABLE'),
('E16', 'E', 16, 2, 'STANDARD', 'AVAILABLE'),
('E17', 'E', 17, 2, 'STANDARD', 'AVAILABLE'),
('E18', 'E', 18, 2, 'STANDARD', 'AVAILABLE'),
('E19', 'E', 19, 2, 'STANDARD', 'AVAILABLE'),
('E20', 'E', 20, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 10. Chennai - Zone CHN-2 (CHN-2-1 to CHN-2-10 - 10 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES 
('CHN-2-1', 'CHN-2', 1, 1, 'EV', 'AVAILABLE'),
('CHN-2-2', 'CHN-2', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-2-3', 'CHN-2', 3, 1, 'STANDARD', 'AVAILABLE'),
('CHN-2-4', 'CHN-2', 4, 1, 'STANDARD', 'AVAILABLE'),
('CHN-2-5', 'CHN-2', 5, 1, 'STANDARD', 'AVAILABLE'),
('CHN-2-6', 'CHN-2', 6, 2, 'EV', 'AVAILABLE'),
('CHN-2-7', 'CHN-2', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-2-8', 'CHN-2', 8, 2, 'STANDARD', 'AVAILABLE'),
('CHN-2-9', 'CHN-2', 9, 2, 'STANDARD', 'AVAILABLE'),
('CHN-2-10', 'CHN-2', 10, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 11. Chennai - Zone CHN-3 (CHN-3-1 to CHN-3-10 - 10 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES 
('CHN-3-1', 'CHN-3', 1, 1, 'EV', 'AVAILABLE'),
('CHN-3-2', 'CHN-3', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-3-3', 'CHN-3', 3, 1, 'STANDARD', 'AVAILABLE'),
('CHN-3-4', 'CHN-3', 4, 1, 'STANDARD', 'AVAILABLE'),
('CHN-3-5', 'CHN-3', 5, 1, 'STANDARD', 'AVAILABLE'),
('CHN-3-6', 'CHN-3', 6, 2, 'EV', 'AVAILABLE'),
('CHN-3-7', 'CHN-3', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-3-8', 'CHN-3', 8, 2, 'STANDARD', 'AVAILABLE'),
('CHN-3-9', 'CHN-3', 9, 2, 'STANDARD', 'AVAILABLE'),
('CHN-3-10', 'CHN-3', 10, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- 12. Chennai - Zone CHN-4 (CHN-4-1 to CHN-4-10 - 10 Bays)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES 
('CHN-4-1', 'CHN-4', 1, 1, 'EV', 'AVAILABLE'),
('CHN-4-2', 'CHN-4', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-4-3', 'CHN-4', 3, 1, 'STANDARD', 'AVAILABLE'),
('CHN-4-4', 'CHN-4', 4, 1, 'STANDARD', 'AVAILABLE'),
('CHN-4-5', 'CHN-4', 5, 1, 'STANDARD', 'AVAILABLE'),
('CHN-4-6', 'CHN-4', 6, 2, 'EV', 'AVAILABLE'),
('CHN-4-7', 'CHN-4', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-4-8', 'CHN-4', 8, 2, 'STANDARD', 'AVAILABLE'),
('CHN-4-9', 'CHN-4', 9, 2, 'STANDARD', 'AVAILABLE'),
('CHN-4-10', 'CHN-4', 10, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- Enforce Total Capacity = 150 Bays (Cleanup any obsolete zones/slots)
DELETE FROM slots WHERE zone_id NOT IN ('B','BLR-2','BLR-3','BLR-4','D','HYD-2','HYD-3','HYD-4','E','CHN-2','CHN-3','CHN-4');
DELETE FROM zones WHERE zone_id NOT IN ('B','BLR-2','BLR-3','BLR-4','D','HYD-2','HYD-3','HYD-4','E','CHN-2','CHN-3','CHN-4');

-- Initial Bay Status Setup: 25 Occupied (BOOKED), 125 Available
UPDATE slots SET status = 'AVAILABLE';
UPDATE slots SET status = 'BOOKED' WHERE slot_id IN (
    'B8', 'B12', 'B16',
    'BLR-2-2', 'BLR-2-6',
    'BLR-3-3', 'BLR-3-7',
    'BLR-4-3',
    'D2', 'D8', 'D14', 'D19',
    'HYD-2-1', 'HYD-2-5',
    'HYD-3-2', 'HYD-3-7',
    'HYD-4-4',
    'E3', 'E9', 'E15',
    'CHN-2-2', 'CHN-2-6',
    'CHN-3-3',
    'CHN-4-4', 'CHN-4-8'
);

-- Seed Realistic Bookings Ledger (35 Audited Records Across Metros)
INSERT INTO bookings (booking_id, user_id, slot_id, vehicle_number, duration_hours, total_amount, status, booking_time, entry_time, exit_time, cancellation_reason, payment_id) VALUES
(101, 'U001', 'B5', 'KA01MJ4521', 2, 80.00, 'COMPLETED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 46 HOUR, NULL, 'TXN_20261006_101'),
(102, 'U002', 'B6', 'KA03NB8812', 3, 120.00, 'COMPLETED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 45 HOUR, NULL, 'TXN_20261006_102'),
(103, 'U003', 'BLR-2-1', 'KA05PQ9034', 1, 35.00, 'COMPLETED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 47 HOUR, NULL, 'TXN_20261006_103'),
(104, 'U004', 'BLR-3-2', 'KA04MK6721', 2, 80.00, 'COMPLETED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 46 HOUR, NULL, 'TXN_20261006_104'),
(105, 'U005', 'D1', 'TS09FA3412', 4, 160.00, 'COMPLETED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 44 HOUR, NULL, 'TXN_20261006_105'),
(106, 'U006', 'D3', 'TS07EC7789', 2, 80.00, 'COMPLETED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 46 HOUR, NULL, 'TXN_20261006_106'),
(107, 'U007', 'HYD-2-2', 'TS08GH5678', 3, 90.00, 'COMPLETED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 45 HOUR, NULL, 'TXN_20261006_107'),
(108, 'U008', 'E1', 'TN09BZ1234', 2, 80.00, 'COMPLETED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 46 HOUR, NULL, 'TXN_20261006_108'),
(109, 'U009', 'E2', 'TN07DX9876', 1, 40.00, 'COMPLETED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 47 HOUR, NULL, 'TXN_20261006_109'),
(110, 'U010', 'CHN-2-1', 'TN10ER4567', 2, 60.00, 'COMPLETED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 46 HOUR, NULL, 'TXN_20261006_110'),
(111, 'U001', 'B7', 'KA01MJ4521', 3, 120.00, 'COMPLETED', NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 21 HOUR, NULL, 'TXN_20261007_111'),
(112, 'U002', 'BLR-2-3', 'KA03NB8812', 2, 70.00, 'COMPLETED', NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 22 HOUR, NULL, 'TXN_20261007_112'),
(113, 'U003', 'BLR-4-1', 'KA05PQ9034', 4, 120.00, 'COMPLETED', NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 20 HOUR, NULL, 'TXN_20261007_113'),
(114, 'U004', 'D5', 'KA04MK6721', 2, 80.00, 'COMPLETED', NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 22 HOUR, NULL, 'TXN_20261007_114'),
(115, 'U005', 'HYD-3-1', 'TS09FA3412', 2, 70.00, 'COMPLETED', NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 22 HOUR, NULL, 'TXN_20261007_115'),
(116, 'U006', 'HYD-4-1', 'TS07EC7789', 3, 75.00, 'COMPLETED', NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 21 HOUR, NULL, 'TXN_20261007_116'),
(117, 'U007', 'E4', 'TS08GH5678', 2, 80.00, 'COMPLETED', NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 22 HOUR, NULL, 'TXN_20261007_117'),
(118, 'U008', 'CHN-3-1', 'TN09BZ1234', 2, 50.00, 'COMPLETED', NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 22 HOUR, NULL, 'TXN_20261007_118'),
(119, 'U011', 'CHN-4-2', 'TN14CL8901', 3, 60.00, 'COMPLETED', NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 21 HOUR, NULL, 'TXN_20261007_119'),
(120, 'U012', 'B9', 'KA02TR9912', 2, 80.00, 'COMPLETED', NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 22 HOUR, NULL, 'TXN_20261007_120'),
(121, 'U001', 'B8', 'KA01MJ4521', 2, 80.00, 'CONFIRMED', NOW() - INTERVAL 1 HOUR, NOW() - INTERVAL 1 HOUR, NULL, NULL, 'TXN_20261008_121'),
(122, 'U003', 'BLR-2-2', 'KA05PQ9034', 2, 70.00, 'CONFIRMED', NOW() - INTERVAL 45 MINUTE, NOW() - INTERVAL 45 MINUTE, NULL, NULL, 'TXN_20261008_122'),
(123, 'U005', 'D2', 'TS09FA3412', 3, 120.00, 'CONFIRMED', NOW() - INTERVAL 30 MINUTE, NOW() - INTERVAL 30 MINUTE, NULL, NULL, 'TXN_20261008_123'),
(124, 'U007', 'E3', 'TS08GH5678', 2, 80.00, 'CONFIRMED', NOW() - INTERVAL 20 MINUTE, NOW() - INTERVAL 20 MINUTE, NULL, NULL, 'TXN_20261008_124'),
(125, 'U009', 'CHN-2-2', 'TN10JK4321', 1, 30.00, 'CONFIRMED', NOW() - INTERVAL 10 MINUTE, NOW() - INTERVAL 10 MINUTE, NULL, NULL, 'TXN_20261008_125'),
(126, 'U002', 'B12', 'KA03NB8812', 2, 80.00, 'RESERVED', NOW() - INTERVAL 5 MINUTE, NULL, NULL, NULL, NULL),
(127, 'U004', 'BLR-3-3', 'KA04MK6721', 2, 80.00, 'RESERVED', NOW() - INTERVAL 8 MINUTE, NULL, NULL, NULL, NULL),
(128, 'U006', 'D8', 'TS07EC7789', 1, 40.00, 'RESERVED', NOW() - INTERVAL 3 MINUTE, NULL, NULL, NULL, NULL),
(129, 'U008', 'E9', 'TN09BZ1234', 2, 80.00, 'RESERVED', NOW() - INTERVAL 6 MINUTE, NULL, NULL, NULL, NULL),
(130, 'U010', 'CHN-4-4', 'TN10ER4567', 2, 40.00, 'RESERVED', NOW() - INTERVAL 2 MINUTE, NULL, NULL, NULL, NULL),
(131, 'U001', 'B10', 'KA01MJ4521', 1, 40.00, 'CANCELLED', NOW() - INTERVAL 3 DAY, NULL, NULL, 'Cancelled by user prior to arrival', NULL),
(132, 'U003', 'BLR-2-4', 'KA05PQ9034', 2, 70.00, 'CANCELLED', NOW() - INTERVAL 3 DAY, NULL, NULL, 'Schedule changed by driver', NULL),
(133, 'U005', 'D4', 'TS09FA3412', 1, 40.00, 'CANCELLED', NOW() - INTERVAL 2 DAY, NULL, NULL, 'Auto-cancelled: 15-minute grace elapsed', NULL),
(134, 'U007', 'E5', 'TS08GH5678', 2, 80.00, 'CANCELLED', NOW() - INTERVAL 1 DAY, NULL, NULL, 'Driver changed destination', NULL),
(135, 'U011', 'CHN-3-2', 'TN14CL8901', 1, 25.00, 'CANCELLED', NOW() - INTERVAL 5 HOUR, NULL, NULL, 'User cancelled reservation', NULL)
ON DUPLICATE KEY UPDATE status=VALUES(status), total_amount=VALUES(total_amount);

-- Seed Payments Table (25 Audited Electronic Receipts)
INSERT INTO payments (booking_id, amount, payment_method, transaction_id, status, payment_time) VALUES
(101, 80.00, 'UPI', 'TXN_20261006_101', 'SUCCESS', NOW() - INTERVAL 46 HOUR),
(102, 120.00, 'FASTag', 'TXN_20261006_102', 'SUCCESS', NOW() - INTERVAL 45 HOUR),
(103, 35.00, 'CARD', 'TXN_20261006_103', 'SUCCESS', NOW() - INTERVAL 47 HOUR),
(104, 80.00, 'UPI', 'TXN_20261006_104', 'SUCCESS', NOW() - INTERVAL 46 HOUR),
(105, 160.00, 'NETBANKING', 'TXN_20261006_105', 'SUCCESS', NOW() - INTERVAL 44 HOUR),
(106, 80.00, 'UPI', 'TXN_20261006_106', 'SUCCESS', NOW() - INTERVAL 46 HOUR),
(107, 90.00, 'FASTag', 'TXN_20261006_107', 'SUCCESS', NOW() - INTERVAL 45 HOUR),
(108, 80.00, 'CARD', 'TXN_20261006_108', 'SUCCESS', NOW() - INTERVAL 46 HOUR),
(109, 40.00, 'UPI', 'TXN_20261006_109', 'SUCCESS', NOW() - INTERVAL 47 HOUR),
(110, 60.00, 'UPI', 'TXN_20261006_110', 'SUCCESS', NOW() - INTERVAL 46 HOUR),
(111, 120.00, 'FASTag', 'TXN_20261007_111', 'SUCCESS', NOW() - INTERVAL 21 HOUR),
(112, 70.00, 'UPI', 'TXN_20261007_112', 'SUCCESS', NOW() - INTERVAL 22 HOUR),
(113, 120.00, 'CARD', 'TXN_20261007_113', 'SUCCESS', NOW() - INTERVAL 20 HOUR),
(114, 80.00, 'UPI', 'TXN_20261007_114', 'SUCCESS', NOW() - INTERVAL 22 HOUR),
(115, 70.00, 'FASTag', 'TXN_20261007_115', 'SUCCESS', NOW() - INTERVAL 22 HOUR),
(116, 75.00, 'UPI', 'TXN_20261007_116', 'SUCCESS', NOW() - INTERVAL 21 HOUR),
(117, 80.00, 'UPI', 'TXN_20261007_117', 'SUCCESS', NOW() - INTERVAL 22 HOUR),
(118, 50.00, 'CARD', 'TXN_20261007_118', 'SUCCESS', NOW() - INTERVAL 22 HOUR),
(119, 60.00, 'FASTag', 'TXN_20261007_119', 'SUCCESS', NOW() - INTERVAL 21 HOUR),
(120, 80.00, 'UPI', 'TXN_20261007_120', 'SUCCESS', NOW() - INTERVAL 22 HOUR),
(121, 80.00, 'UPI', 'TXN_20261008_121', 'SUCCESS', NOW() - INTERVAL 1 HOUR),
(122, 70.00, 'FASTag', 'TXN_20261008_122', 'SUCCESS', NOW() - INTERVAL 45 MINUTE),
(123, 120.00, 'UPI', 'TXN_20261008_123', 'SUCCESS', NOW() - INTERVAL 30 MINUTE),
(124, 80.00, 'CARD', 'TXN_20261008_124', 'SUCCESS', NOW() - INTERVAL 20 MINUTE),
(125, 30.00, 'UPI', 'TXN_20261008_125', 'SUCCESS', NOW() - INTERVAL 10 MINUTE)
ON DUPLICATE KEY UPDATE status=VALUES(status);

-- Seed Feedback Reviews (10 Natural User Ratings & Comments)
INSERT INTO feedback (feedback_id, booking_id, user_id, rating, comment, created_at) VALUES
(301, 101, 'U001', 5, 'Smooth entry and clear bay signage. Parking sensor detected vehicle immediately.', NOW() - INTERVAL 45 HOUR),
(302, 102, 'U002', 5, 'Very convenient near Electronic City. Contactless FASTag payment worked without delay.', NOW() - INTERVAL 44 HOUR),
(303, 103, 'U003', 4, 'Good covered parking, clean facility. Markings inside the bay are clearly visible.', NOW() - INTERVAL 46 HOUR),
(304, 104, 'U004', 4, 'Easy reservation and barrier gate opened smoothly on plate scan.', NOW() - INTERVAL 45 HOUR),
(305, 105, 'U005', 5, 'Saved 20 minutes finding parking during morning office rush hour in HITEC City.', NOW() - INTERVAL 43 HOUR),
(306, 106, 'U006', 3, 'Facility was well maintained, but exit ramp was slightly busy around 6 PM.', NOW() - INTERVAL 45 HOUR),
(307, 107, 'U007', 5, 'Clean parking spot, EV charging point in adjacent bay was also operational.', NOW() - INTERVAL 44 HOUR),
(308, 108, 'U008', 4, 'Clear navigation signs along OMR and quick automated payment on exit.', NOW() - INTERVAL 45 HOUR),
(309, 111, 'U001', 5, 'Reliable automated parking. The 15-minute grace period gave enough buffer time.', NOW() - INTERVAL 20 HOUR),
(310, 112, 'U002', 4, 'Decent parking spot in Whitefield, will book again for client meetings.', NOW() - INTERVAL 21 HOUR)
ON DUPLICATE KEY UPDATE rating=VALUES(rating), comment=VALUES(comment);

