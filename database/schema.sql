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

-- ==========================================================
-- SEED DATA
-- ==========================================================

-- Seed Demo Users
-- Admin: admin@smartparking.com / Admin@123 (hash: e86f78a8a3caf0b60d8e74e5942aa6d86dc150cd3c03338aef25b7d2d7e3acc7)
-- Driver: driver@smartparking.com / Driver@123 (hash: 388fc22c686505ce88b59e2a9b1deef93dc9b855580578ea704aa383d63ee1fd)

INSERT INTO users (user_id, name, email, password, phone_number, role)
VALUES 
('ADM001', 'System Administrator', 'admin@smartparking.com', 'e86f78a8a3caf0b60d8e74e5942aa6d86dc150cd3c03338aef25b7d2d7e3acc7', '9888877777', 'ADMIN')
ON DUPLICATE KEY UPDATE role='ADMIN', password='e86f78a8a3caf0b60d8e74e5942aa6d86dc150cd3c03338aef25b7d2d7e3acc7';

INSERT INTO users (user_id, name, email, password, phone_number, role)
VALUES 
('DRV001', 'John Driver', 'driver@smartparking.com', '388fc22c686505ce88b59e2a9b1deef93dc9b855580578ea704aa383d63ee1fd', '9876543210', 'USER')
ON DUPLICATE KEY UPDATE role='USER', password='388fc22c686505ce88b59e2a9b1deef93dc9b855580578ea704aa383d63ee1fd';

-- Update existing U003 if present to USER
UPDATE users SET role='USER' WHERE user_id='U003' AND (role IS NULL OR role='');

-- Seed Zones (Famous Indian Metros & Tech Corridors)
INSERT INTO zones (zone_id, name, location, hourly_rate, total_slots, description)
VALUES
('A', 'Zone A - Mumbai (BKC Financial District)', 'Bandra Kurla Complex, Mumbai, Maharashtra', 40.00, 20, 'Multi-tier covered smart parking with rapid EV charging stations in Mumbai\'s premier financial hub.'),
('B', 'Zone B - Bengaluru (Electronic City IT Hub)', 'Hosur Main Road, Electronic City Phase 1, Bengaluru, Karnataka', 40.00, 20, 'High-tech IoT sensor-guided multi-level parking facility near major IT campuses and metro skywalks.'),
('C', 'Zone C - New Delhi (Connaught Place Central)', 'Radial Road 3, Inner Circle, Connaught Place, New Delhi', 40.00, 20, 'Central underground automated smart parking facility with live bay guidance near Rajiv Chowk interchange.'),
('D', 'Zone D - Hyderabad (HITEC City Cyber Towers)', 'HITEC City Main Road, Madhapur, Hyderabad, Telangana', 40.00, 20, 'Multi-storey smart facility with RFID access gates serving Cyberabad\'s tech hub and corporate offices.'),
('E', 'Zone E - Chennai (OMR IT Expressway)', 'Old Mahabalipuram Road, Taramani, Chennai, Tamil Nadu', 40.00, 20, 'Solar-shaded and covered bays equipped with IoT occupancy sensors along the Chennai IT Expressway.'),
('F', 'Zone F - Kolkata (Park Street & Salt Lake)', 'Sector V, Salt Lake Electronics Complex, Kolkata, West Bengal', 40.00, 20, 'State-of-the-art parking facility with digital overhead space displays in Kolkata\'s primary IT and commercial zone.')
ON DUPLICATE KEY UPDATE 
name=VALUES(name), location=VALUES(location), hourly_rate=VALUES(hourly_rate), total_slots=VALUES(total_slots), description=VALUES(description);


-- Seed Slots for Zone A (A1 to A20)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES
('A1', 'A', 1, 1, 'EV', 'AVAILABLE'),
('A2', 'A', 2, 1, 'EV', 'AVAILABLE'),
('A3', 'A', 3, 1, 'ACCESSIBLE', 'AVAILABLE'),
('A4', 'A', 4, 1, 'STANDARD', 'AVAILABLE'),
('A5', 'A', 5, 1, 'STANDARD', 'AVAILABLE'),
('A6', 'A', 6, 1, 'STANDARD', 'AVAILABLE'),
('A7', 'A', 7, 1, 'STANDARD', 'AVAILABLE'),
('A8', 'A', 8, 1, 'STANDARD', 'AVAILABLE'),
('A9', 'A', 9, 1, 'STANDARD', 'AVAILABLE'),
('A10', 'A', 10, 1, 'STANDARD', 'AVAILABLE'),
('A11', 'A', 11, 2, 'STANDARD', 'AVAILABLE'),
('A12', 'A', 12, 2, 'STANDARD', 'AVAILABLE'),
('A13', 'A', 13, 2, 'STANDARD', 'AVAILABLE'),
('A14', 'A', 14, 2, 'STANDARD', 'AVAILABLE'),
('A15', 'A', 15, 2, 'STANDARD', 'AVAILABLE'),
('A16', 'A', 16, 2, 'STANDARD', 'AVAILABLE'),
('A17', 'A', 17, 2, 'STANDARD', 'AVAILABLE'),
('A18', 'A', 18, 2, 'STANDARD', 'AVAILABLE'),
('A19', 'A', 19, 2, 'STANDARD', 'AVAILABLE'),
('A20', 'A', 20, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- Seed Slots for Zone B (B1 to B20)
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

-- Seed Slots for Zone C (C1 to C20)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES
('C1', 'C', 1, 1, 'EV', 'AVAILABLE'),
('C2', 'C', 2, 1, 'EV', 'AVAILABLE'),
('C3', 'C', 3, 1, 'EV', 'AVAILABLE'),
('C4', 'C', 4, 1, 'ACCESSIBLE', 'AVAILABLE'),
('C5', 'C', 5, 1, 'STANDARD', 'AVAILABLE'),
('C6', 'C', 6, 1, 'STANDARD', 'AVAILABLE'),
('C7', 'C', 7, 1, 'STANDARD', 'AVAILABLE'),
('C8', 'C', 8, 1, 'STANDARD', 'AVAILABLE'),
('C9', 'C', 9, 1, 'STANDARD', 'AVAILABLE'),
('C10', 'C', 10, 1, 'STANDARD', 'AVAILABLE'),
('C11', 'C', 11, 2, 'STANDARD', 'AVAILABLE'),
('C12', 'C', 12, 2, 'STANDARD', 'AVAILABLE'),
('C13', 'C', 13, 2, 'STANDARD', 'AVAILABLE'),
('C14', 'C', 14, 2, 'STANDARD', 'AVAILABLE'),
('C15', 'C', 15, 2, 'STANDARD', 'AVAILABLE'),
('C16', 'C', 16, 2, 'STANDARD', 'AVAILABLE'),
('C17', 'C', 17, 2, 'STANDARD', 'AVAILABLE'),
('C18', 'C', 18, 2, 'STANDARD', 'AVAILABLE'),
('C19', 'C', 19, 2, 'STANDARD', 'AVAILABLE'),
('C20', 'C', 20, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

-- Seed Slots for Zone D - Hyderabad (D1 to D20)
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

-- Seed Slots for Zone E - Chennai (E1 to E20)
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

-- Seed Slots for Zone F - Kolkata (F1 to F20)
INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES
('F1', 'F', 1, 1, 'EV', 'AVAILABLE'),
('F2', 'F', 2, 1, 'EV', 'AVAILABLE'),
('F3', 'F', 3, 1, 'ACCESSIBLE', 'AVAILABLE'),
('F4', 'F', 4, 1, 'STANDARD', 'AVAILABLE'),
('F5', 'F', 5, 1, 'STANDARD', 'AVAILABLE'),
('F6', 'F', 6, 1, 'STANDARD', 'AVAILABLE'),
('F7', 'F', 7, 1, 'STANDARD', 'AVAILABLE'),
('F8', 'F', 8, 1, 'STANDARD', 'AVAILABLE'),
('F9', 'F', 9, 1, 'STANDARD', 'AVAILABLE'),
('F10', 'F', 10, 1, 'STANDARD', 'AVAILABLE'),
('F11', 'F', 11, 2, 'EV', 'AVAILABLE'),
('F12', 'F', 12, 2, 'EV', 'AVAILABLE'),
('F13', 'F', 13, 2, 'ACCESSIBLE', 'AVAILABLE'),
('F14', 'F', 14, 2, 'STANDARD', 'AVAILABLE'),
('F15', 'F', 15, 2, 'STANDARD', 'AVAILABLE'),
('F16', 'F', 16, 2, 'STANDARD', 'AVAILABLE'),
('F17', 'F', 17, 2, 'STANDARD', 'AVAILABLE'),
('F18', 'F', 18, 2, 'STANDARD', 'AVAILABLE'),
('F19', 'F', 19, 2, 'STANDARD', 'AVAILABLE'),
('F20', 'F', 20, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);

UPDATE zones SET name='Zone A - Mumbai (BKC Financial District)' WHERE zone_id='A';
UPDATE zones SET name='Zone B - Bengaluru (Electronic City IT Hub)' WHERE zone_id='B';
UPDATE zones SET name='Zone C - New Delhi (Connaught Place Central)' WHERE zone_id='C';
UPDATE zones SET name='Zone D - Hyderabad (HITEC City Cyber Towers)' WHERE zone_id='D';
UPDATE zones SET name='Zone E - Chennai (OMR IT Expressway)' WHERE zone_id='E';
UPDATE zones SET name='Zone F - Kolkata (Park Street & Salt Lake)' WHERE zone_id='F';
INSERT INTO zones (zone_id, name, location, hourly_rate, total_slots, description) VALUES 
('MUM-2', 'Zone MUM-2 - Mumbai (Nariman Point & Marine Drive)', 'Nariman Point, South Mumbai, Maharashtra', 60.0, 10, 'Premium automated high-rise parking overlooking Marine Drive with VIP valet access.'),
('MUM-3', 'Zone MUM-3 - Mumbai (CSMIA Airport T2 Terminal)', 'Sahar Airport Road, Andheri East, Mumbai', 55.0, 10, 'Multi-level transit parking with covered express travelator access directly into Terminal 2 departures.'),
('MUM-4', 'Zone MUM-4 - Mumbai (Lower Parel Commercial Hub)', 'Senapati Bapat Marg, Lower Parel, Mumbai', 45.0, 10, 'Smart multi-tier facility serving High Street Phoenix, Palladium, and premier corporate towers.'),
('BLR-2', 'Zone BLR-2 - Bengaluru (Whitefield Tech Park)', 'ITPL Main Road, Whitefield, Bengaluru, Karnataka', 35.0, 10, 'High-capacity IoT parking campus adjacent to International Tech Park Bangalore (ITPB) and metro station.'),
('BLR-3', 'Zone BLR-3 - Bengaluru (MG Road & Brigade Central)', 'MG Road, Ashok Nagar, Bengaluru, Karnataka', 40.0, 10, 'Automated underground central facility with contactless FASTag payment near Trinity metro junction.'),
('BLR-4', 'Zone BLR-4 - Bengaluru (Kempegowda Airport Gateway)', 'Devanahalli, Airport Expressway, Bengaluru', 30.0, 10, 'Spacious open and canopy-shaded parking for airport travelers with rapid shuttle transit connections.'),
('DEL-2', 'Zone DEL-2 - New Delhi (Aerocity & IGI Airport T3)', 'Asset Area 4, Aerocity, New Delhi, Delhi NCR', 45.0, 10, 'World-class underground parking complex situated in the Aerocity hospitality and business district.'),
('DEL-3', 'Zone DEL-3 - New Delhi (Nehru Place IT Market)', 'Outer Ring Road, Nehru Place, New Delhi', 30.0, 10, 'Multi-storey automated facility serving Asia''''s premier electronics and corporate business hub.'),
('DEL-4', 'Zone DEL-4 - New Delhi (Cyber Hub & Gurgaon Gateway)', 'DLF Cyber City, NH-48 Gateway, Delhi NCR', 40.0, 10, 'Next-generation corporate smart parking facility with automated barrier-free license plate recognition.'),
('HYD-2', 'Zone HYD-2 - Hyderabad (Gachibowli Financial District)', 'ISB Road, Nanakramguda, Gachibowli, Hyderabad', 30.0, 10, 'Multi-level smart facility adjacent to top multinational tech headquarters and the US Consulate.'),
('HYD-3', 'Zone HYD-3 - Hyderabad (Banjara Hills & Jubilee Hills)', 'Road No. 36, Jubilee Hills, Hyderabad, Telangana', 35.0, 10, 'Upscale commercial valet-ready parking facility in Hyderabad''''s prime luxury shopping and dining district.'),
('HYD-4', 'Zone HYD-4 - Hyderabad (RGIA Airport Terminal Hub)', 'Airport Approach Road, Shamshabad, Hyderabad', 25.0, 10, 'State-of-the-art parking zone with live slot occupancy guidance serving Rajiv Gandhi International Airport.'),
('CHN-2', 'Zone CHN-2 - Chennai (Anna Salai & T. Nagar)', 'Mount Road, Anna Salai, T. Nagar, Chennai, Tamil Nadu', 30.0, 10, 'Prime central shopping and commercial district multi-tier parking with digital LED directional indicators.'),
('CHN-3', 'Zone CHN-3 - Chennai (Guindy Industrial & Tech Hub)', 'GST Road, Kathipara Junction, Guindy, Chennai', 25.0, 10, 'Convenient park-and-ride facility connected to Kathipara multi-tier cloverleaf and Guindy metro station.'),
('CHN-4', 'Zone CHN-4 - Chennai (Chennai Central Railway Gateway)', 'EVR Periyar Salai, Park Town, Chennai, Tamil Nadu', 20.0, 10, 'High-turnover transit parking hub catering to intercity rail commuters and downtown commercial offices.'),
('KOL-2', 'Zone KOL-2 - Kolkata (Park Street Commercial District)', 'Park Street, Chowringhee, Central Kolkata, West Bengal', 25.0, 10, 'Central covered parking complex located in Kolkata''''s historic dining, cultural, and corporate district.'),
('KOL-3', 'Zone KOL-3 - Kolkata (New Town Tech & Eco Park)', 'Major Arterial Road, Action Area 1, New Town, Kolkata', 20.0, 10, 'Eco-friendly solar-powered parking facility with dedicated electric vehicle fast charging infrastructure.'),
('KOL-4', 'Zone KOL-4 - Kolkata (NSCBI Airport Expressway)', 'VIP Road, Dum Dum, NSCBI Airport Approach, Kolkata', 25.0, 10, 'Multi-level covered bays serving domestic and international air passengers with 24/7 CCTV surveillance.')
ON DUPLICATE KEY UPDATE name=VALUES(name), location=VALUES(location), hourly_rate=VALUES(hourly_rate), total_slots=VALUES(total_slots), description=VALUES(description);

INSERT INTO slots (slot_id, zone_id, slot_number, floor, type, status) VALUES 
('MUM-2-1', 'MUM-2', 1, 1, 'EV', 'AVAILABLE'),
('MUM-2-2', 'MUM-2', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('MUM-2-3', 'MUM-2', 3, 1, 'STANDARD', 'AVAILABLE'),
('MUM-2-4', 'MUM-2', 4, 1, 'STANDARD', 'AVAILABLE'),
('MUM-2-5', 'MUM-2', 5, 1, 'STANDARD', 'AVAILABLE'),
('MUM-2-6', 'MUM-2', 6, 2, 'EV', 'AVAILABLE'),
('MUM-2-7', 'MUM-2', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('MUM-2-8', 'MUM-2', 8, 2, 'STANDARD', 'AVAILABLE'),
('MUM-2-9', 'MUM-2', 9, 2, 'STANDARD', 'AVAILABLE'),
('MUM-2-10', 'MUM-2', 10, 2, 'STANDARD', 'AVAILABLE'),
('MUM-3-1', 'MUM-3', 1, 1, 'EV', 'AVAILABLE'),
('MUM-3-2', 'MUM-3', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('MUM-3-3', 'MUM-3', 3, 1, 'STANDARD', 'AVAILABLE'),
('MUM-3-4', 'MUM-3', 4, 1, 'STANDARD', 'AVAILABLE'),
('MUM-3-5', 'MUM-3', 5, 1, 'STANDARD', 'AVAILABLE'),
('MUM-3-6', 'MUM-3', 6, 2, 'EV', 'AVAILABLE'),
('MUM-3-7', 'MUM-3', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('MUM-3-8', 'MUM-3', 8, 2, 'STANDARD', 'AVAILABLE'),
('MUM-3-9', 'MUM-3', 9, 2, 'STANDARD', 'AVAILABLE'),
('MUM-3-10', 'MUM-3', 10, 2, 'STANDARD', 'AVAILABLE'),
('MUM-4-1', 'MUM-4', 1, 1, 'EV', 'AVAILABLE'),
('MUM-4-2', 'MUM-4', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('MUM-4-3', 'MUM-4', 3, 1, 'STANDARD', 'AVAILABLE'),
('MUM-4-4', 'MUM-4', 4, 1, 'STANDARD', 'AVAILABLE'),
('MUM-4-5', 'MUM-4', 5, 1, 'STANDARD', 'AVAILABLE'),
('MUM-4-6', 'MUM-4', 6, 2, 'EV', 'AVAILABLE'),
('MUM-4-7', 'MUM-4', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('MUM-4-8', 'MUM-4', 8, 2, 'STANDARD', 'AVAILABLE'),
('MUM-4-9', 'MUM-4', 9, 2, 'STANDARD', 'AVAILABLE'),
('MUM-4-10', 'MUM-4', 10, 2, 'STANDARD', 'AVAILABLE'),
('BLR-2-1', 'BLR-2', 1, 1, 'EV', 'AVAILABLE'),
('BLR-2-2', 'BLR-2', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-2-3', 'BLR-2', 3, 1, 'STANDARD', 'AVAILABLE'),
('BLR-2-4', 'BLR-2', 4, 1, 'STANDARD', 'AVAILABLE'),
('BLR-2-5', 'BLR-2', 5, 1, 'STANDARD', 'AVAILABLE'),
('BLR-2-6', 'BLR-2', 6, 2, 'EV', 'AVAILABLE'),
('BLR-2-7', 'BLR-2', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-2-8', 'BLR-2', 8, 2, 'STANDARD', 'AVAILABLE'),
('BLR-2-9', 'BLR-2', 9, 2, 'STANDARD', 'AVAILABLE'),
('BLR-2-10', 'BLR-2', 10, 2, 'STANDARD', 'AVAILABLE'),
('BLR-3-1', 'BLR-3', 1, 1, 'EV', 'AVAILABLE'),
('BLR-3-2', 'BLR-3', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-3-3', 'BLR-3', 3, 1, 'STANDARD', 'AVAILABLE'),
('BLR-3-4', 'BLR-3', 4, 1, 'STANDARD', 'AVAILABLE'),
('BLR-3-5', 'BLR-3', 5, 1, 'STANDARD', 'AVAILABLE'),
('BLR-3-6', 'BLR-3', 6, 2, 'EV', 'AVAILABLE'),
('BLR-3-7', 'BLR-3', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-3-8', 'BLR-3', 8, 2, 'STANDARD', 'AVAILABLE'),
('BLR-3-9', 'BLR-3', 9, 2, 'STANDARD', 'AVAILABLE'),
('BLR-3-10', 'BLR-3', 10, 2, 'STANDARD', 'AVAILABLE'),
('BLR-4-1', 'BLR-4', 1, 1, 'EV', 'AVAILABLE'),
('BLR-4-2', 'BLR-4', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-4-3', 'BLR-4', 3, 1, 'STANDARD', 'AVAILABLE'),
('BLR-4-4', 'BLR-4', 4, 1, 'STANDARD', 'AVAILABLE'),
('BLR-4-5', 'BLR-4', 5, 1, 'STANDARD', 'AVAILABLE'),
('BLR-4-6', 'BLR-4', 6, 2, 'EV', 'AVAILABLE'),
('BLR-4-7', 'BLR-4', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('BLR-4-8', 'BLR-4', 8, 2, 'STANDARD', 'AVAILABLE'),
('BLR-4-9', 'BLR-4', 9, 2, 'STANDARD', 'AVAILABLE'),
('BLR-4-10', 'BLR-4', 10, 2, 'STANDARD', 'AVAILABLE'),
('DEL-2-1', 'DEL-2', 1, 1, 'EV', 'AVAILABLE'),
('DEL-2-2', 'DEL-2', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('DEL-2-3', 'DEL-2', 3, 1, 'STANDARD', 'AVAILABLE'),
('DEL-2-4', 'DEL-2', 4, 1, 'STANDARD', 'AVAILABLE'),
('DEL-2-5', 'DEL-2', 5, 1, 'STANDARD', 'AVAILABLE'),
('DEL-2-6', 'DEL-2', 6, 2, 'EV', 'AVAILABLE'),
('DEL-2-7', 'DEL-2', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('DEL-2-8', 'DEL-2', 8, 2, 'STANDARD', 'AVAILABLE'),
('DEL-2-9', 'DEL-2', 9, 2, 'STANDARD', 'AVAILABLE'),
('DEL-2-10', 'DEL-2', 10, 2, 'STANDARD', 'AVAILABLE'),
('DEL-3-1', 'DEL-3', 1, 1, 'EV', 'AVAILABLE'),
('DEL-3-2', 'DEL-3', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('DEL-3-3', 'DEL-3', 3, 1, 'STANDARD', 'AVAILABLE'),
('DEL-3-4', 'DEL-3', 4, 1, 'STANDARD', 'AVAILABLE'),
('DEL-3-5', 'DEL-3', 5, 1, 'STANDARD', 'AVAILABLE'),
('DEL-3-6', 'DEL-3', 6, 2, 'EV', 'AVAILABLE'),
('DEL-3-7', 'DEL-3', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('DEL-3-8', 'DEL-3', 8, 2, 'STANDARD', 'AVAILABLE'),
('DEL-3-9', 'DEL-3', 9, 2, 'STANDARD', 'AVAILABLE'),
('DEL-3-10', 'DEL-3', 10, 2, 'STANDARD', 'AVAILABLE'),
('DEL-4-1', 'DEL-4', 1, 1, 'EV', 'AVAILABLE'),
('DEL-4-2', 'DEL-4', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('DEL-4-3', 'DEL-4', 3, 1, 'STANDARD', 'AVAILABLE'),
('DEL-4-4', 'DEL-4', 4, 1, 'STANDARD', 'AVAILABLE'),
('DEL-4-5', 'DEL-4', 5, 1, 'STANDARD', 'AVAILABLE'),
('DEL-4-6', 'DEL-4', 6, 2, 'EV', 'AVAILABLE'),
('DEL-4-7', 'DEL-4', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('DEL-4-8', 'DEL-4', 8, 2, 'STANDARD', 'AVAILABLE'),
('DEL-4-9', 'DEL-4', 9, 2, 'STANDARD', 'AVAILABLE'),
('DEL-4-10', 'DEL-4', 10, 2, 'STANDARD', 'AVAILABLE'),
('HYD-2-1', 'HYD-2', 1, 1, 'EV', 'AVAILABLE'),
('HYD-2-2', 'HYD-2', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-2-3', 'HYD-2', 3, 1, 'STANDARD', 'AVAILABLE'),
('HYD-2-4', 'HYD-2', 4, 1, 'STANDARD', 'AVAILABLE'),
('HYD-2-5', 'HYD-2', 5, 1, 'STANDARD', 'AVAILABLE'),
('HYD-2-6', 'HYD-2', 6, 2, 'EV', 'AVAILABLE'),
('HYD-2-7', 'HYD-2', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-2-8', 'HYD-2', 8, 2, 'STANDARD', 'AVAILABLE'),
('HYD-2-9', 'HYD-2', 9, 2, 'STANDARD', 'AVAILABLE'),
('HYD-2-10', 'HYD-2', 10, 2, 'STANDARD', 'AVAILABLE'),
('HYD-3-1', 'HYD-3', 1, 1, 'EV', 'AVAILABLE'),
('HYD-3-2', 'HYD-3', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-3-3', 'HYD-3', 3, 1, 'STANDARD', 'AVAILABLE'),
('HYD-3-4', 'HYD-3', 4, 1, 'STANDARD', 'AVAILABLE'),
('HYD-3-5', 'HYD-3', 5, 1, 'STANDARD', 'AVAILABLE'),
('HYD-3-6', 'HYD-3', 6, 2, 'EV', 'AVAILABLE'),
('HYD-3-7', 'HYD-3', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-3-8', 'HYD-3', 8, 2, 'STANDARD', 'AVAILABLE'),
('HYD-3-9', 'HYD-3', 9, 2, 'STANDARD', 'AVAILABLE'),
('HYD-3-10', 'HYD-3', 10, 2, 'STANDARD', 'AVAILABLE'),
('HYD-4-1', 'HYD-4', 1, 1, 'EV', 'AVAILABLE'),
('HYD-4-2', 'HYD-4', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-4-3', 'HYD-4', 3, 1, 'STANDARD', 'AVAILABLE'),
('HYD-4-4', 'HYD-4', 4, 1, 'STANDARD', 'AVAILABLE'),
('HYD-4-5', 'HYD-4', 5, 1, 'STANDARD', 'AVAILABLE'),
('HYD-4-6', 'HYD-4', 6, 2, 'EV', 'AVAILABLE'),
('HYD-4-7', 'HYD-4', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('HYD-4-8', 'HYD-4', 8, 2, 'STANDARD', 'AVAILABLE'),
('HYD-4-9', 'HYD-4', 9, 2, 'STANDARD', 'AVAILABLE'),
('HYD-4-10', 'HYD-4', 10, 2, 'STANDARD', 'AVAILABLE'),
('CHN-2-1', 'CHN-2', 1, 1, 'EV', 'AVAILABLE'),
('CHN-2-2', 'CHN-2', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-2-3', 'CHN-2', 3, 1, 'STANDARD', 'AVAILABLE'),
('CHN-2-4', 'CHN-2', 4, 1, 'STANDARD', 'AVAILABLE'),
('CHN-2-5', 'CHN-2', 5, 1, 'STANDARD', 'AVAILABLE'),
('CHN-2-6', 'CHN-2', 6, 2, 'EV', 'AVAILABLE'),
('CHN-2-7', 'CHN-2', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-2-8', 'CHN-2', 8, 2, 'STANDARD', 'AVAILABLE'),
('CHN-2-9', 'CHN-2', 9, 2, 'STANDARD', 'AVAILABLE'),
('CHN-2-10', 'CHN-2', 10, 2, 'STANDARD', 'AVAILABLE'),
('CHN-3-1', 'CHN-3', 1, 1, 'EV', 'AVAILABLE'),
('CHN-3-2', 'CHN-3', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-3-3', 'CHN-3', 3, 1, 'STANDARD', 'AVAILABLE'),
('CHN-3-4', 'CHN-3', 4, 1, 'STANDARD', 'AVAILABLE'),
('CHN-3-5', 'CHN-3', 5, 1, 'STANDARD', 'AVAILABLE'),
('CHN-3-6', 'CHN-3', 6, 2, 'EV', 'AVAILABLE'),
('CHN-3-7', 'CHN-3', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-3-8', 'CHN-3', 8, 2, 'STANDARD', 'AVAILABLE'),
('CHN-3-9', 'CHN-3', 9, 2, 'STANDARD', 'AVAILABLE'),
('CHN-3-10', 'CHN-3', 10, 2, 'STANDARD', 'AVAILABLE'),
('CHN-4-1', 'CHN-4', 1, 1, 'EV', 'AVAILABLE'),
('CHN-4-2', 'CHN-4', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-4-3', 'CHN-4', 3, 1, 'STANDARD', 'AVAILABLE'),
('CHN-4-4', 'CHN-4', 4, 1, 'STANDARD', 'AVAILABLE'),
('CHN-4-5', 'CHN-4', 5, 1, 'STANDARD', 'AVAILABLE'),
('CHN-4-6', 'CHN-4', 6, 2, 'EV', 'AVAILABLE'),
('CHN-4-7', 'CHN-4', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('CHN-4-8', 'CHN-4', 8, 2, 'STANDARD', 'AVAILABLE'),
('CHN-4-9', 'CHN-4', 9, 2, 'STANDARD', 'AVAILABLE'),
('CHN-4-10', 'CHN-4', 10, 2, 'STANDARD', 'AVAILABLE'),
('KOL-2-1', 'KOL-2', 1, 1, 'EV', 'AVAILABLE'),
('KOL-2-2', 'KOL-2', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('KOL-2-3', 'KOL-2', 3, 1, 'STANDARD', 'AVAILABLE'),
('KOL-2-4', 'KOL-2', 4, 1, 'STANDARD', 'AVAILABLE'),
('KOL-2-5', 'KOL-2', 5, 1, 'STANDARD', 'AVAILABLE'),
('KOL-2-6', 'KOL-2', 6, 2, 'EV', 'AVAILABLE'),
('KOL-2-7', 'KOL-2', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('KOL-2-8', 'KOL-2', 8, 2, 'STANDARD', 'AVAILABLE'),
('KOL-2-9', 'KOL-2', 9, 2, 'STANDARD', 'AVAILABLE'),
('KOL-2-10', 'KOL-2', 10, 2, 'STANDARD', 'AVAILABLE'),
('KOL-3-1', 'KOL-3', 1, 1, 'EV', 'AVAILABLE'),
('KOL-3-2', 'KOL-3', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('KOL-3-3', 'KOL-3', 3, 1, 'STANDARD', 'AVAILABLE'),
('KOL-3-4', 'KOL-3', 4, 1, 'STANDARD', 'AVAILABLE'),
('KOL-3-5', 'KOL-3', 5, 1, 'STANDARD', 'AVAILABLE'),
('KOL-3-6', 'KOL-3', 6, 2, 'EV', 'AVAILABLE'),
('KOL-3-7', 'KOL-3', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('KOL-3-8', 'KOL-3', 8, 2, 'STANDARD', 'AVAILABLE'),
('KOL-3-9', 'KOL-3', 9, 2, 'STANDARD', 'AVAILABLE'),
('KOL-3-10', 'KOL-3', 10, 2, 'STANDARD', 'AVAILABLE'),
('KOL-4-1', 'KOL-4', 1, 1, 'EV', 'AVAILABLE'),
('KOL-4-2', 'KOL-4', 2, 1, 'ACCESSIBLE', 'AVAILABLE'),
('KOL-4-3', 'KOL-4', 3, 1, 'STANDARD', 'AVAILABLE'),
('KOL-4-4', 'KOL-4', 4, 1, 'STANDARD', 'AVAILABLE'),
('KOL-4-5', 'KOL-4', 5, 1, 'STANDARD', 'AVAILABLE'),
('KOL-4-6', 'KOL-4', 6, 2, 'EV', 'AVAILABLE'),
('KOL-4-7', 'KOL-4', 7, 2, 'ACCESSIBLE', 'AVAILABLE'),
('KOL-4-8', 'KOL-4', 8, 2, 'STANDARD', 'AVAILABLE'),
('KOL-4-9', 'KOL-4', 9, 2, 'STANDARD', 'AVAILABLE'),
('KOL-4-10', 'KOL-4', 10, 2, 'STANDARD', 'AVAILABLE')
ON DUPLICATE KEY UPDATE zone_id=VALUES(zone_id), floor=VALUES(floor), type=VALUES(type);
