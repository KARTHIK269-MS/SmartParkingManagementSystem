# Smart Parking Management System

[![Java 17](https://img.shields.io/badge/Java-17-orange.svg)](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html)
[![Servlet 4.0](https://img.shields.io/badge/Servlet-4.0-blue.svg)](https://javaee.github.io/servlet-spec/)
[![Apache Tomcat 9](https://img.shields.io/badge/Tomcat-9.0-yellow.svg)](https://tomcat.apache.org/download-90.cgi)
[![MySQL 8.0](https://img.shields.io/badge/MySQL-8.0-blue.svg)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-Pending_Choice-lightgrey.svg)](#-license)
[![Tests Passing](https://img.shields.io/badge/Tests-190%2B%20Passed-brightgreen.svg)](docs/testing-guide.md)

An enterprise-grade, IoT-enabled Smart Parking Management System designed for multi-facility urban corridors. Built with **Java 17, JSP, Servlets, JDBC, MySQL 8, and Apache Tomcat 9**, following strict **Model-View-Controller (MVC)** design patterns.

The platform provides an end-to-end parking lifecycle: advance bay reservations, automated number-plate recognition (ANPR) barrier gate authorization, live sensor-driven occupancy synchronization, 3-tier dynamic demand pricing, contactless digital checkout, predictive occupancy modeling, and executive financial auditing with RFC 4180 CSV and OpenPDF export capabilities.

---

## 📌 Table of Contents

- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Technology Stack](#-technology-stack)
- [Repository Directory Structure](#-repository-directory-structure)
- [Prerequisites & Setup](#-prerequisites--setup)
- [Safe Credential Configuration](#-safe-credential-configuration)
- [Build, Package & Deployment](#-build-package--deployment)
- [Default System Accounts](#-default-system-accounts)
- [ANPR & Automated Gate Access](#-anpr--automated-gate-access)
- [Smart Occupancy Prediction & Dynamic Pricing](#-smart-occupancy-prediction--dynamic-pricing)
- [Audited Reports & Data Export](#-audited-reports--data-export)
- [Automated Verification & Test Suites](#-automated-verification--test-suites)
- [Security & Reliability Hardening](#-security--reliability-hardening)
- [Hardware Prototype & Simulation Boundary](#-hardware-prototype--simulation-boundary)
- [Viva Voce & Interview Q&A](#-viva-voce--interview-qa)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌟 Key Features

### 🚗 Driver Web Portal
- **Metropolitan Facility Discovery (`/zones`)**: Real-time browsing across 12 facilities in Bengaluru, Hyderabad, and Chennai with live bay status counters.
- **Interactive Supervisory Bay Grid (`/slots`)**: Visual floor layout displaying Accessible, EV, Standard, and Executive bays with live state coloring.
- **Advance Reservation with Grace Period (`/booking`)**: 15-minute scheduled arrival buffer preventing idle holding while guaranteeing slot availability.
- **Contactless Checkout & Dynamic Billing (`/payment`)**: Dynamic tariff computation supporting UPI, FASTag, Credit/Debit Cards, and NetBanking.
- **Driver History & Live Parking Sessions (`/myBookings`)**: Live elapsed session timers, navigation directions, and downloadable digital VAT/GST receipts.

### 🏢 Facility Admin Console
- **Executive Operations Dashboard (`/admin?action=dashboard`)**: Real-time monitoring across 150 bays with active vehicle counts and sensor telemetry pulse triggers.
- **Supervisory Bay Overrides**: Administrative overrides for emergency maintenance with active reservation protection locks.
- **3-Tier Dynamic Demand Pricing**: Automated tariff adjustment engine scaling operating rates by 1.25x upon crossing the 80% occupancy threshold.
- **Smart Occupancy Prediction Engine**: Hourly demand curves comparing observed physical bay counts against machine-learned historical trendlines.
- **Financial Audit & Ledger Reports**: Date-range filtered reporting for Bay Occupancy, Driver Bookings, and Settled Revenue.
- **Security-Hardened Data Export**: One-click RFC 4180 CSV exports (with spreadsheet formula injection mitigation) and multi-page OpenPDF vector reports.
- **ANPR Gate Access Controller (`/anpr.jsp`)**: High-accuracy camera plate recognition emulation, automated barrier gate actuation, and gate decision logging.

---

## 🏛️ System Architecture

The application strictly enforces a 3-tier Model-View-Controller (MVC) architectural separation:

```
+-----------------------------------------------------------------------------------+
|                                PRESENTATION TIER                                  |
|   Driver Web Portal (JSP, CSS3, Fetch API)  |  Facility Admin Console (JSP, Tabs) |
+----------------------------------------+------------------------------------------+
                                         | HTTP / REST API
                                         v
+-----------------------------------------------------------------------------------+
|                                APPLICATION CONTROLLER TIER                        |
|   ZoneServlet | BookingServlet | AdminServlet | IoTSensorServlet | LoginServlet   |
|                       ReservationCleanupService (Background Daemon)               |
+----------------------------------------+------------------------------------------+
                                         | Service Invocation
                                         v
+-----------------------------------------------------------------------------------+
|                                DOMAIN & DATA ACCESS TIER                          |
|   BookingDAO | SlotDAO | UserDAO | ZoneDAO | PaymentDAO | ReportDAO | PredictionDAO   |
|   Utilities: DBConnection, PasswordHasher (BCrypt), CsvExportUtil, PdfExportUtil  |
+----------------------------------------+------------------------------------------+
                                         | JDBC / PreparedStatements
                                         v
+-----------------------------------------------------------------------------------+
|                                PERSISTENCE TIER                                   |
|                     MySQL 8.0 Database Engine (parking_system)                     |
+-----------------------------------------------------------------------------------+
```

### Complete Booking & Parking Lifecycle State Machine:
```
[AVAILABLE] ──(Advance Reserve)──► [RESERVED] ──(ANPR Gate Check-in)──► [OCCUPIED]
     ▲                                   │                                    │
     │                           (Grace Expiry / Cancel)              (Vehicle Depart)
     │                                   │                                    ▼
     └───────────────────────────────────┴────────── [PAYMENT_PENDING] ──(Payment)──► [COMPLETED]
```

---

## 💻 Technology Stack

| Component | Technology | Version | Description |
|---|---|---|---|
| **Language** | Java (JDK) | 17 LTS | Core backend application logic |
| **Servlet Specification** | Java Servlet API | 4.0.1 | Controller mappings and request dispatching |
| **View Template Engine** | JavaServer Pages (JSP) | 2.3.3 | Dynamic server-side page rendering |
| **Database Engine** | MySQL Server | 8.0.x | Relational storage with InnoDB engine |
| **Database Driver** | MySQL Connector/J | 8.3.0 / 9.x | JDBC persistence and connection pooling |
| **Application Server** | Apache Tomcat | 9.0.x | Servlet container and HTTP listener |
| **Security & Hashing** | Pure Java BCrypt | 10 Salt Rounds | One-way cryptographic password storage |
| **PDF Generation** | OpenPDF (LibrePDF) | 1.3.30 | Vector PDF generation for financial audits |
| **Data Analytics** | Chart.js | 4.x (CDN) | Client-side responsive interactive charts |
| **Computer Vision (ANPR)** | OpenCV & Tesseract | Python 3.10+ | Prototype number plate extraction pipeline |
| **Microcontroller Firmware** | C++ (Arduino IDE) | ESP32 | Ultrasonic & geomagnetic sensor firmware |

---

## 📂 Repository Directory Structure

```
smart-parking-system/
├── README.md                           # Master project documentation
├── .gitignore                          # Comprehensive Git ignore rules
├── pom.xml                             # Maven build descriptor (Java 17 + WAR)
├── build.ps1                           # Automated standalone compiler & packager
├── run_tests.ps1                       # Automated 6-suite test runner
├── CONTRIBUTING.md                     # Community contribution guidelines
├── SECURITY.md                         # Responsible vulnerability disclosure policy
├── CHANGELOG.md                        # Version release history
├── config/
│   └── application.example.properties  # Sanitized configuration template
├── database/
│   ├── schema.sql                      # Complete DDL tables and schema
│   ├── seed-data.sql                   # Realistic 150-bay development seed dataset
│   └── README.md                       # MySQL installation & setup instructions
├── docs/
│   ├── architecture.md                 # In-depth architectural design
│   ├── setup-guide.md                  # Step-by-step local workstation installation
│   ├── testing-guide.md                # Test execution and concurrency guarantees
│   └── screenshots/                    # UI walkthrough & feature gallery
├── anpr_service/
│   ├── anpr_pipeline.py                # Python OpenCV & OCR number plate pipeline
│   └── requirements.txt                # Python dependencies
├── iot_firmware/
│   ├── HARDWARE_WIRING_GUIDE.md        # ESP32 & Raspberry Pi pinout schematics
│   ├── esp32/esp32_smart_parking.ino   # Arduino firmware for smart bay node
│   └── raspberry_pi/                   # Gate barrier servo & camera controller
└── src/
    ├── main/
    │   ├── java/com/parkingsystem/
    │   │   ├── dao/                    # BookingDAO, SlotDAO, UserDAO, ReportDAO, PredictionDAO...
    │   │   ├── model/                  # Booking, Slot, Zone, Payment, GateActivityEvent...
    │   │   ├── servlet/                # AdminServlet, BookingServlet, IoTSensorServlet...
    │   │   └── util/                   # DBConnection, PasswordHasher, CsvExportUtil, PdfExportUtil...
    │   └── webapp/
    │       ├── WEB-INF/
    │       │   ├── web.xml             # Servlet mappings, session timeouts, error pages
    │       │   └── lib/                # Bundled MySQL connector & OpenPDF libraries
    │       ├── admin/
    │       │   └── dashboard.jsp       # Facility Admin Console
    │       ├── resources/              # CSS, JS, SVG assets, and imagery
    │       ├── anpr.jsp                # ANPR gate scanner & barrier simulation
    │       ├── booking.jsp             # Slot reservation page
    │       ├── myBookings.jsp          # Driver booking history & live timers
    │       ├── payment.jsp             # Contactless payment portal
    │       ├── slots.jsp               # Interactive bay map
    │       └── zones.jsp               # Corridor facility browser
    └── test/java/com/parkingsystem/
        ├── MiniProjectUnitTest.java    # Core logic unit tests
        ├── TestSystem.java             # System integration tests
        ├── BayAvailabilitySyncTest.java# Real-time state parity tests
        ├── AdminReportsTest.java       # Reports & export audit tests
        ├── ANPRGateWorkflowTest.java   # Number-plate gate verification tests
        └── BookingLifecycleAuditTest.java # Lifecycle & duration distinction tests
```

---

## ⚙️ Prerequisites & Setup

### Requirements:
- **Java Development Kit (JDK)**: 17 LTS (Eclipse Temurin or Oracle JDK)
- **Servlet Container**: Apache Tomcat 9.0.x
- **Database Server**: MySQL Server 8.0.x
- **Operating System**: Windows, macOS, or Linux

### Step 1: Clone Repository
```bash
git clone https://github.com/KARTHIK269-MS/SmartParkingManagementSystem.git
cd SmartParkingManagementSystem
```

### Step 2: Database Initialization
Import the schema and initial dataset into MySQL:
```bash
mysql -u root -p < database/schema.sql
```
*(For detailed database documentation, see [database/README.md](database/README.md).)*

---

## 🔒 Safe Credential Configuration

To safeguard passwords and prevent accidental credential exposure to public repositories, the application uses dynamic multi-source resolution (`DBConnection`):

1. Copy the configuration template:
   ```bash
   cp config/application.example.properties config/application.properties
   ```
   *(Or copy to `db.properties` in the project root)*

2. Edit `config/application.properties` with your local MySQL password:
   ```properties
   db.url=jdbc:mysql://localhost:3306/parking_system?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata
   db.user=root
   db.password=your_actual_password_here
   ```

3. **Protection Guarantee**:
   Both `config/application.properties` and `db.properties` are explicitly ignored in `.gitignore`. They will **never** be committed to Git.

Alternatively, you can provide credentials via environment variables:
```bash
export DB_URL="jdbc:mysql://localhost:3306/parking_system"
export DB_USER="root"
export DB_PASSWORD="your_actual_password_here"
```

---

## 🚀 Build, Package & Deployment

### Build with PowerShell (Windows):
```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```
This compiles all Java 17 sources, synchronizes properties, and packages the application archive to `target/smart-parking-system.war`.

### Build with Apache Maven (Cross-Platform):
```bash
mvn clean package
```

### Deploy to Apache Tomcat 9:
1. Copy `target/smart-parking-system.war` to your Tomcat `webapps/` folder:
   ```bash
   cp target/smart-parking-system.war /path/to/tomcat/webapps/
   ```
2. Start Tomcat (`bin/startup.sh` or `bin/startup.bat`).
3. Open your browser:
   - **Driver Booking Portal**: `http://localhost:8080/smart-parking-system/zones`
   - **Facility Admin Console**: `http://localhost:8080/smart-parking-system/admin?action=dashboard`
   - **ANPR Simulation Gate**: `http://localhost:8080/smart-parking-system/anpr.jsp`

---

## 🔑 Default System Accounts

> [!NOTE]
> All credentials below are seeded with BCrypt password hashes for local testing and demonstration.

| Role | Email | Password | Access Scope |
|---|---|---|---|
| **Facility Administrator** | `admin@smartparking.com` | `Admin@123` | Full administrative console, analytics, reports, overrides |
| **Verified Driver** | `driver1@example.com` | `Driver@123` | Driver portal, bay reservations, live sessions |
| **Verified Driver** | `driver2@example.com` | `Driver@123` | Driver portal, checkout payments, feedback |

---

## 📷 ANPR & Automated Gate Access

The system enforces automated entry gate authorization based on vehicle registration numbers:
1. **Verification**: When a vehicle approaches, the gate camera scans its plate and queries `/api/iot-sensor`.
2. **Authorization**: The engine validates that an active reservation exists for the specific bay and scheduled arrival window.
3. **Session Start**: The gate opens, session transitions to `ACTIVE`, bay status switches to `OCCUPIED`, and the session duration timer begins.
4. **Rejection Safeguards**: Unknown plates, cancelled reservations, expired grace periods, wrong facilities, or repeated entry scans are automatically rejected with descriptive gate ledger audit entries.

---

## 📈 Smart Occupancy Prediction & Dynamic Pricing

- **3-Tier Dynamic Demand Pricing**:
  - **Normal (0% - 79%)**: Baseline tariff (e.g., ₹40/hr).
  - **High Surge (80% - 99%)**: Automated 1.25x surge tariff to manage high peak-hour demand.
  - **Critical (100%)**: Facility full; reservations paused until departure events occur.
- **Smart Occupancy Prediction Engine**:
  - Collects hourly occupancy snapshots in the `occupancy_snapshots` table.
  - Calculates moving average demand curves across 24-hour cycles to forecast peak congestion times in the Admin Analytics console.

---

## 📊 Audited Reports & Data Export

The Admin Console provides comprehensive financial auditing with custom date-range filtering:
- **Real-Time Bay Occupancy Report**: Live snapshot vs historical records with explicit distinction.
- **Driver Bookings Ledger**: Filtered list of driver reservations, vehicle numbers, durations, and statuses.
- **Settled Revenue & Financials**: Genuine settled payment records, average ticket metrics, and top payment channels.
- **Export Capabilities**:
  - **RFC 4180 CSV**: Clean tabular output with active spreadsheet formula injection mitigation (`=`, `+`, `-`, `@` prefix defense).
  - **OpenPDF Multi-Page PDF**: Professional vector document formatting with executive KPI summaries, clean empty states, and auto-wrapped table columns.

---

## 🧪 Automated Verification & Test Suites

The project includes 6 comprehensive automated test suites covering 190+ assertions:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
```

| Test Suite | File | Focus Area | Result |
|---|---|---|---|
| **Core Unit Tests** | `MiniProjectUnitTest.java` | BCrypt hashing, auth, cancellation, data isolation | **13 / 13 PASSED** |
| **System Integration** | `TestSystem.java` | 150 bays, booking flow, IoT pulse, dynamic tariffs | **20 / 20 PASSED** |
| **Session Parity** | `BayAvailabilitySyncTest.java` | Real-time state parity across Driver & Admin views | **9 / 9 PASSED** |
| **Financial Exports** | `AdminReportsTest.java` | Date filters, CSV escaping, formula defense, OpenPDF | **93 / 93 PASSED** |
| **ANPR Gate Engine** | `ANPRGateWorkflowTest.java` | Plate validation, gate ledger, duplicate scan rejection | **23 / 23 PASSED** |
| **Lifecycle Audit** | `BookingLifecycleAuditTest.java` | Deferred timer, occupancy lock, checkout billing | **33 / 33 PASSED** |
| **TOTAL** | — | **Full End-to-End System Audit** | **191 / 191 (100%)** |

---

## 🛡️ Security & Reliability Hardening

1. **Password Hashing with BCrypt**: Passwords stored as one-way salt-hashed strings (`$2a$10$...`) using pure Java BCrypt with 10 salt rounds.
2. **SQL Injection Defense**: 100% of queries use parameterized `PreparedStatement` interfaces.
3. **Double-Booking Prevention**: Slot reservations utilize transactional row-level database locking (`SELECT ... FOR UPDATE`).
4. **CSRF Protection**: State-changing forms enforce unique per-session CSRF tokens verified on the server.
5. **Server-Side Price Recalculation**: Payment amounts are calculated independently on the server to prevent client-side price tampering.
6. **Cross-User Data Isolation**: Servlets verify that bookings belong strictly to the authenticated user's session before permitting view, cancel, or payment actions.

---

## ⚙️ Hardware Prototype & Simulation Boundary

To maintain academic transparency and reproducibility:
- **Physical Integration (Available)**: The repository includes complete firmware (`iot_firmware/esp32/`) and camera pipeline scripts (`anpr_service/anpr_pipeline.py`) for deploying to physical ESP32 microcontrollers and Raspberry Pi camera rigs.
- **Simulation Boundary (Default)**: For environments without physical microcontrollers attached, the application provides built-in software simulation via `anpr.jsp` and administrative sensor pulse triggers (`IoTSensorServlet`). All business logic, timers, database transactions, and gate ledgers execute identically in both modes.

---

## 🎓 Viva Voce & Interview Q&A

<details>
<summary><b>Click to expand 10 Essential Viva Questions & Answers</b></summary>

1. **Q: How does the MVC pattern function in this project?**
   > *A:* Model represents entity POJOs and JDBC DAOs. View comprises dynamic JSP pages styled with CSS. Controller includes Java Servlets that authenticate requests, manage transactions, and dispatch responses.

2. **Q: How is double-booking prevented when multiple drivers select the same bay concurrently?**
   > *A:* We utilize database row-level locking via `SELECT ... FOR UPDATE` inside a database transaction (`lockAndReserveSlot`). The second transaction detects that the bay status is no longer `AVAILABLE` and throws a custom `SlotUnavailableException`.

3. **Q: When does the parking session timer actually start?**
   > *A:* Advance reservation locks the bay as `RESERVED` but **does not start the timer**. The timer begins **strictly upon physical check-in** when the ANPR gate verifies the vehicle registration number and marks the bay `OCCUPIED`.

4. **Q: How are passwords protected in storage?**
   > *A:* Passwords are never stored in plaintext. They are hashed using BCrypt with 10 salt rounds before database insertion. Verification is handled securely via `BCrypt.checkpw`.

5. **Q: How does the dynamic demand pricing algorithm work?**
   > *A:* When a zone's occupancy reaches or exceeds the 80% capacity threshold, the system automatically applies a 1.25x surge multiplier to the base hourly rate, re-balancing metropolitan corridor traffic.

6. **Q: How does the system defend against CSV formula injection during financial report exports?**
   > *A:* The `CsvExportUtil` inspects all cell values. If a field begins with executable spreadsheet formula triggers (`=`, `+`, `-`, `@`), it prepends a single quote (`'`), ensuring spreadsheet programs treat the value strictly as text.

7. **Q: What happens if a driver reserves a bay but fails to arrive?**
   > *A:* The `ReservationCleanupService` background thread monitors reservations. If a vehicle does not arrive within the 15-minute grace period, the reservation is auto-cancelled, a notification is generated, and the bay is released back to `AVAILABLE`.

8. **Q: How are Admin and Driver sessions kept independent?**
   > *A:* The application uses separate session attributes (`adminUser` vs `driverUser`) and role-based checks (`currentUser.isAdmin()`), ensuring administrative actions and driver reservations cannot conflict.

9. **Q: How do you protect against SQL Injection?**
   > *A:* All database interactions across all DAOs use parameterized `PreparedStatement` interfaces instead of string concatenation.

10. **Q: Where are database credentials stored, and why are they absent from Git history?**
    > *A:* Credentials are kept in a local `config/application.properties` or `db.properties` file. Only sanitized template files (`application.example.properties`) are tracked in Git, ensuring zero leakage of local credentials.

</details>

---

## 🤝 Contributing

Contributions, bug reports, and enhancements are welcome! Please review our [Contributing Guidelines](CONTRIBUTING.md) and [Pull Request Template](.github/pull_request_template.md).

---

## 📄 License

This project is prepared for open-source publication. The exact open-source license will be configured according to maintainer preference (e.g., MIT, Apache 2.0, or GPLv3).
