# Smart Parking Management System — Architecture Overview

## 1. System Overview

The **Smart Parking Management System** is an enterprise-grade IoT-enabled parking facility management platform designed for multi-facility urban corridors. It implements the complete vehicle parking lifecycle: advance bay reservation, automated number plate recognition (ANPR) gate access, live sensor-driven bay occupancy tracking, automated dynamic pricing, contactless billing, and executive financial auditing.

---

## 2. High-Level Architectural Diagram

```
+-----------------------------------------------------------------------------------+
|                                PRESENTATION TIER                                  |
|                                                                                   |
|  +----------------------------------+       +----------------------------------+  |
|  |       Driver Web Portal          |       |     Facility Admin Console       |  |
|  |  (JSP, Responsive CSS, Fetch API)|       |  (JSP, Modular Tabs, Chart.js)   |  |
|  +-----------------+----------------+       +-----------------+----------------+  |
+--------------------|------------------------------------------|-------------------+
                     | HTTP / Form POST / JSON AJAX             |
                     v                                          v
+-----------------------------------------------------------------------------------+
|                                APPLICATION CONTROLLER TIER                        |
|                                                                                   |
|  +------------------+  +------------------+  +------------------+  +-----------+  |
|  |   ZoneServlet    |  |  BookingServlet  |  |   AdminServlet   |  | IoTSensor |  |
|  +------------------+  +------------------+  +------------------+  |  Servlet  |  |
|  |   LoginServlet   |  | RegisterServlet  |  |  Reservation-    |  +-----------+  |
|  +------------------+  +------------------+  |  CleanupService  |                 |
|                                              +------------------+                 |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                            DOMAIN BUSINESS & DATA ACCESS TIER                     |
|                                                                                   |
|  +--------------+  +--------------+  +--------------+  +-----------------------+  |
|  |   UserDAO    |  |   ZoneDAO    |  |   SlotDAO    |  |      BookingDAO       |  |
|  +--------------+  +--------------+  +--------------+  +-----------------------+  |
|  |  PaymentDAO  |  | FeedbackDAO  |  |  ReportDAO   |  |     PredictionDAO     |  |
|  +--------------+  +--------------+  +--------------+  +-----------------------+  |
|                                                                                   |
|  Utilities & Engines:                                                             |
|  - PasswordHasher (BCrypt Salt Rounds = 10 + SHA-256 fallback)                    |
|  - CsvExportUtil (RFC 4180 Escaping + Formula Injection Mitigation)              |
|  - PdfExportUtil (OpenPDF Multi-Page Financial & Occupancy Reports)               |
|  - CsrfUtil (Cryptographic Session Token Defense)                                 |
+-----------------------------------------------------------------------------------+
                                         | JDBC
                                         v
+-----------------------------------------------------------------------------------+
|                                PERSISTENCE TIER                                   |
|                                                                                   |
|                           MySQL 8.0 Database Engine                               |
|       (parking_system: users, zones, slots, bookings, payments, feedback,        |
|                            occupancy_snapshots)                                   |
+-----------------------------------------------------------------------------------+
```

---

## 3. Core Architectural Subsystems

### 3.1. Dynamic Configuration & Connection Manager (`DBConnection`)
- **Multi-Source Credential Resolution**:
  1. JVM System Properties (`-Ddb.url`, `-Ddb.user`, `-Ddb.password`)
  2. Operating System Environment Variables (`DB_URL`, `DB_USER`, `DB_PASSWORD`)
  3. Classpath Properties (`db.properties`, `application.properties`)
  4. Local Directory Configurations (`config/application.properties`, `db.properties`)
  5. Safe Fallbacks (Empty password for local developer root setups)
- **Zero-Exposure Credential Hygiene**: All real local credential files are permanently excluded from Git tracking via `.gitignore`.

### 3.2. Automated Number Plate Recognition (ANPR) & Gate Barrier Controller
- **Workflow Pipeline**:
  1. Vehicle arrives at the barrier gate.
  2. Camera captures image or simulator transmits plate VRN to `/api/iot-sensor`.
  3. Server validates matching reservation, ensures scheduled arrival window (15-minute grace period), and verifies bay state.
  4. Upon authorization, barrier gate opens, session status transitions to `ACTIVE`, bay status switches to `OCCUPIED`, and live session timer starts.
  5. Denies entry with audited reject codes for unknown plates, expired reservations, wrong facilities, or duplicate entries.
- **Physical Integration vs Simulation**:
  - Production: MicroPython / Python camera service (`anpr_service/anpr_pipeline.py`) + ESP32 / Raspberry Pi GPIO barrier actuator (`iot_firmware/`).
  - Web UI: Live ANPR Gate Simulation console (`anpr.jsp`) for testing without hardware peripherals.

### 3.3. 3-Tier Dynamic Demand Pricing Engine
To optimize bay turnover and reduce metropolitan congestion, the system calculates parking tariffs using three automated tiers:
1. **Tier 1 (Normal Demand, 0% - 79% Occupancy)**: Standard baseline facility rate (e.g., ₹40/hr).
2. **Tier 2 (High Demand Surge, 80% - 99% Occupancy)**: 1.25x surge multiplier applied dynamically to discourage excessive bay holding during peak hours.
3. **Tier 3 (Capacity Critical, 100% Occupancy)**: Reservation requests rejected until departures occur.

### 3.4. Smart Occupancy Prediction Engine
- Utilizes telemetry logging via `occupancy_snapshots` table.
- Computes hourly demand trends across 24-hour cycles using historical exponential moving average (EMA) weighted against real-time sensor events.
- Feeds visual predictive demand curves in the Admin Analytics console.

### 3.5. Security & Isolation Controls
- **Role-Based Access Control (RBAC)**: Strict separation between `ADMIN` (administrative dashboard) and `USER` (driver booking portal).
- **Session Isolation**: Independent session attributes ensure Admin and Driver sessions never collide.
- **CSRF Token Verification**: State-changing POST operations require validated cryptographic CSRF tokens (`CsrfUtil`).
- **Formula Injection Defense**: CSV exports protect against spreadsheet execution vulnerabilities (`=`, `+`, `-`, `@` sanitization).
