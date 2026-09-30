# Smart Parking Management System (PRJ_35)

**SDG Mapping:** Sustainable Development Goal 11 (Sustainable Cities and Communities)  
**Architecture:** Model-View-Controller (MVC)  
**Backend:** Java 17, Servlet 4.0, JSP, JDBC (Transactional DAO Pattern)  
**Database:** MySQL 8.0  
**Frontend:** JSP + Vanilla JavaScript (No Frameworks), Modern CSS (Smart Parking UK Aesthetic)  
**Package:** `com.parkingsystem`  
**Location:** `C:\Users\LENOVO\smart-parking-system`  

---

## 1. Project Overview

The **Smart Parking Management System** is an intelligent urban mobility web application designed to eliminate traffic congestion, optimize parking bay occupancy, and provide drivers with guaranteed, contactless parking reservations.

The system incorporates physical sensor telemetry via an **IoT Simulator background daemon thread**, which safely broadcasts vehicle arrivals and departures using ACID-compliant JDBC row locks to protect active driver reservations against race conditions.

---

## 2. Package & Directory Structure

```
smart-parking-system/
├── pom.xml                                  # Maven project configuration (war packaging)
├── .project                                 # Eclipse Dynamic Web Project configuration
├── .classpath                               # Eclipse classpath (JavaSE-17, Web App Libraries)
├── .settings/                               # Eclipse facet and compiler preferences
├── build.ps1                                # Automated compilation & WAR packaging script
├── deploy-to-tomcat.ps1                     # Tomcat 9 deployment script
├── database/
│   └── schema.sql                           # MySQL database schema & initial seed data
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── parkingsystem/
│   │   │           ├── model/               # User, Slot, Booking, Zone, Feedback, Payment
│   │   │           ├── exception/           # DatabaseException, SlotUnavailableException, etc.
│   │   │           ├── util/                # DBConnection, PasswordHasher (SHA-256), IoTSimulator, JsonUtil
│   │   │           ├── dao/                 # UserDAO, SlotDAO, BookingDAO, ZoneDAO, FeedbackDAO, PaymentDAO
│   │   │           └── servlet/             # LoginServlet, RegisterServlet, ZoneServlet, BookingServlet, AdminServlet
│   │   └── webapp/
│   │       ├── WEB-INF/
│   │       │   ├── web.xml                  # Servlet mappings & session config
│   │       │   └── lib/                     # Bundled MySQL Connector JAR (mysql-connector-j-9.7.0.jar)
│   │       ├── resources/
│   │       │   ├── css/
│   │       │   │   └── style.css            # SmartParking.com-inspired design system & animations
│   │       │   └── js/
│   │       │       ├── validation.js        # Form validation (auth, booking, VRN)
│   │       │       ├── slotStatus.js        # Periodic 5s AJAX polling for live bay availability
│   │       │       ├── paymentTimer.js      # 5-minute countdown ring timer with auto-release
│   │       │       └── admin.js             # Admin sorting, search, filtering & IoT controls
│   │       ├── index.jsp                    # Root redirect to zones
│   │       ├── login.jsp                    # Driver & Admin authentication
│   │       ├── register.jsp                 # Driver registration with validation
│   │       ├── zones.jsp                    # Zone overview with capacity & tariffs
│   │       ├── slots.jsp                    # Interactive multi-floor parking bay grid
│   │       ├── booking.jsp                  # Two-step booking with Indian HSRP VRN builder
│   │       ├── payment.jsp                  # Mock payment gateway with timer & receipt summary
│   │       ├── myBookings.jsp               # Booking ledger, e-ticket pass modal & cancellation
│   │       ├── feedback.jsp                 # Post-parking 5-star rating & review
│   │       └── admin/
│   │           └── dashboard.jsp            # Facility manager dashboard, overrides & IoT simulator
│   └── test/
│       └── java/
│           └── com/
│               └── parkingsystem/
│                   └── TestSystem.java      # End-to-End Automated Verification Test Suite
```

---

## 3. Database Setup (MySQL 8.0)

- **Database Name:** `parking_system`
- **Host:** `localhost:3306`
- **User:** `root`
- **Password:** `karthik123`

To re-apply or inspect the schema:
```powershell
Get-Content "C:\Users\LENOVO\smart-parking-system\database\schema.sql" -Raw | & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root --password=karthik123
```

---

## 4. Default Demo Accounts

| Role | Email | Password | Access Level |
|---|---|---|---|
| **Driver** | `driver@smartparking.com` | `Driver@123` | Browsing, Bay Reservation, Payments, Passes, Ratings |
| **Admin** | `admin@smartparking.com` | `Admin@123` | Supervisory Dashboard, Manual Overrides, IoT Simulator, Audit Logs |

*New driver accounts can also be created dynamically via the Register page.*

---

## 5. How to Run in Eclipse IDE

1. Open **Eclipse IDE**.
2. Select **File &rarr; Open Projects from File System...**
3. In **Import source**, click **Directory...** and select `C:\Users\LENOVO\smart-parking-system`.
4. Click **Finish**. Eclipse will recognize it as a **Dynamic Web Project 4.0** with Java 17.
5. Right-click the `smart-parking-system` project &rarr; **Run As &rarr; Run on Server** (select Apache Tomcat 9).
6. Open your browser at:
   `http://localhost:8080/smart-parking-system/`

---

## 6. How to Build & Package via Terminal

Run the automated PowerShell build script:
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\LENOVO\smart-parking-system\build.ps1"
```
This will compile all Java 17 classes and generate `target/smart-parking-system.war`.

To run the automated verification test suite:
```powershell
$cp = "C:\Program Files\apache-tomcat-9.0.117\lib\servlet-api.jar;C:\Program Files\apache-tomcat-9.0.117\lib\jsp-api.jar;C:\Users\LENOVO\smart-parking-system\src\main\webapp\WEB-INF\lib\mysql-connector-j-9.7.0.jar;C:\Users\LENOVO\smart-parking-system\build\classes"
java -cp "$cp" com.parkingsystem.TestSystem
```

---

## 7. The 7 Core Modules (Confirmed Working End-to-End)

1. **Authentication (`LoginServlet`, `RegisterServlet`)**:
   - SHA-256 password hashing via `PasswordHasher`.
   - `HttpSession`-based login state.
   - Role-based redirection (`ADMIN` &rarr; Admin Console, `USER` &rarr; Zones).

2. **Zone & Slot Browsing (`ZoneServlet`, `zones.jsp`, `slots.jsp`)**:
   - High-impact Smart Parking UK visual styling.
   - 6 parking facilities across India's top metropolitan hubs: Zone A (Mumbai - BKC Financial District), Zone B (Bengaluru - Electronic City), Zone C (New Delhi - Connaught Place), Zone D (Hyderabad - HITEC City), Zone E (Chennai - OMR), Zone F (Kolkata - Salt Lake).
   - Multi-floor bay grid (Level 1 Ground Floor & Level 2 First Floor).
   - Live 5-second polling via `slotStatus.js` consuming JSON endpoint `?action=slotStatusJson`.

3. **Two-Step Booking (`BookingServlet`, `booking.jsp`)**:
   - Indian HSRP vehicle plate builder with chrome Ashoka Chakra hologram and `IND` badge preview.
   - Dynamic total amount calculation based on parking hours and zone tariff.
   - Transactional slot reservation: atomically sets slot to `RESERVED` and sets a 5-minute session lock.

4. **Mock Payment Gateway (`payment.jsp`, `paymentTimer.js`)**:
   - 5-minute countdown clock with animated SVG progress ring.
   - Auto-expiry: if payment is not completed in 5 minutes, an AJAX signal releases the held bay back to `AVAILABLE`.
   - Mock options: Instant UPI (QR code preview), Credit/Debit Card, Net Banking, Smart Wallet.
   - Generates realistic transaction references (`TXN...`).

5. **My Bookings & Digital Passes (`myBookings.jsp`)**:
   - Permitted booking ledger with filterable tabs.
   - Printable Contactless Smart Parking Pass modal with barcode graphic and `window.print()`.
   - Cancellation with instant mock refund and automatic slot release.

6. **Feedback & Rating (`feedback.jsp`, `FeedbackDAO`)**:
   - Interactive 5-star rating widget.
   - Quick review tag pills ("Accurate Sensors", "Seamless Entry", "Clean & Well Lit").
   - Aggregated in the admin dashboard.

7. **Admin Dashboard (`AdminServlet`, `admin/dashboard.jsp`, `admin.js`)**:
   - Real-time occupancy gauges, today's revenue, and driver ratings.
   - Supervisory slot grid with **Manual Slot Status Override Modal** (`AVAILABLE`, `BOOKED`, `BLOCKED/MAINTENANCE`).
   - Searchable and sortable driver bookings table (`admin.js`).
   - **IoT Sensor Simulator Controls**: background thread toggle, manual sensor pulse trigger, and live event monitoring.

---

## 8. Viva & Interview Questions (Preparation for College Guide)

**Q1: How does the system handle concurrent booking attempts on the same parking bay?**  
**A:** The system enforces strict ACID transactional isolation in `SlotDAO` and `BookingDAO`. When a driver initiates a booking, `SELECT status FROM slots WHERE slot_id = ? FOR UPDATE` acquires an exclusive row lock. If the slot is `AVAILABLE`, it is immediately transitioned to `RESERVED`. Any concurrent transaction is blocked until the first finishes, preventing double-bookings.

**Q2: How does the IoT Simulator interact with user bookings without overwriting them?**  
**A:** Before toggling a slot status, `IoTSimulator` checks `SELECT COUNT(*) FROM bookings WHERE slot_id = ? AND status IN ('PENDING', 'CONFIRMED')`. If any active booking exists, the transaction rolls back immediately and protects the bay from simulated interference.

**Q3: How is real-time bay availability updated on the frontend without third-party frameworks?**  
**A:** `slotStatus.js` uses native JavaScript `fetch()` to poll the lightweight JSON endpoint `ZoneServlet?action=slotStatusJson&zone=...` every 5 seconds. The DOM updates CSS classes dynamically, smoothly reflecting background sensor changes without full page reloads.

**Q4: How is password security implemented?**  
**A:** Passwords are never stored in plaintext. `PasswordHasher` applies cryptographic SHA-256 hashing before storing in the MySQL `users` table, and incoming passwords during login are hashed and verified against the stored hash.
