-- ==========================================================
-- SmartParking: Smart Occupancy Prediction Migration
-- Adds lightweight occupancy_snapshots table for long-term telemetry logging
-- ==========================================================

USE parking_system;

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
