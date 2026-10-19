# Smart Parking Management System — Automated Testing & Verification Guide

This guide details the test architecture, test suites, execution procedures, and concurrency verification for the Smart Parking Management System.

---

## 1. Test Architecture Overview

The system includes 6 comprehensive automated test suites covering unit logic, integration workflows, database transactions, concurrency locks, report exports, and gate lifecycles.

```
src/test/java/com/parkingsystem/
├── MiniProjectUnitTest.java        # Core logic, BCrypt hashing, auth, cancellation, data isolation
├── TestSystem.java                 # End-to-end integration: 150 bays, booking, IoT pulse, dynamic tariffs
├── BayAvailabilitySyncTest.java    # Bay status synchronization across Driver & Admin views
├── AdminReportsTest.java           # Date filtering, 24-hr ranges, CSV/PDF export, formula injection defense
├── ANPRGateWorkflowTest.java       # Number-plate verification, gate movements, duplicate scan rejection
└── BookingLifecycleAuditTest.java  # Booking, timer deferred start, occupancy lock, checkout billing
```

---

## 2. Test Execution

### Running All Test Suites with Automated Runner

Execute the automated test script in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
```

The runner:
1. Compiles test sources with dependencies against Java 17.
2. Executes each suite sequentially against the local test database.
3. Performs automated test-slot isolation and rollback cleanup.
4. Outputs detailed per-scenario PASS/FAIL logs and summaries.

---

## 3. Test Suites Breakdown

### 3.1. Mini-Project Core Unit Tests (`MiniProjectUnitTest`)
- **Scenarios**:
  - User registration with BCrypt hashing and salt rounds verification.
  - Authentication success and invalid credential rejection.
  - 15-minute advance reservation grace period timing.
  - Concurrency: Double-booking prevention via `SELECT ... FOR UPDATE` locking.
  - Booking cancellation and immediate bay release.
  - Cross-user data isolation and ownership enforcement.
  - Active booking protection against manual administrative overwrite.
  - Gate activity ledger insertion and revenue isolation.

### 3.2. End-to-End System Integration (`TestSystem`)
- **Scenarios**:
  - Full 150-bay facility capacity verification across all 12 zones.
  - Scheduled booking creation -> confirmation -> payment finalization.
  - 5-star feedback rating submission and persistence.
  - Simulated IoT sensor pulse vehicle arrival/departure transitions.
  - 3-tier dynamic demand pricing (Normal ₹40, Surge ₹50, Off-peak ₹30).
  - Analytics 24-hour occupancy curve and payment channel distribution.
  - ANPR plate scan check-in and timer actuation.
  - 30-minute grace auto-cancellation and notification generation.

### 3.3. Bay Availability & Session Sync Suite (`BayAvailabilitySyncTest`)
- **Scenarios**:
  - State parity between Driver and Admin views in real-time.
  - Persistence across newly instantiated DAOs (DB as single source of truth).
  - Zone availability arithmetic consistency (`available_slots + occupied_slots = total_slots`).
  - Safe handling of concurrent booking attempts on the same physical bay.

### 3.4. Admin Reports & Export Suite (`AdminReportsTest`)
- **Scenarios**:
  - Real-time Bay Occupancy accounting across all 12 facilities.
  - Driver Bookings Ledger date-range filtering.
  - Settled Revenue & Financials accounting (excluding unpaid/pending transactions).
  - Boundary validation: Empty dates, single-day ranges, format validation, start > end rejection.
  - End-of-day completeness (`23:59:59.999` boundary coverage).
  - RFC 4180 CSV escaping and spreadsheet formula injection mitigation (`=`, `+`, `-`, `@`).
  - OpenPDF vector generation: Empty states and populated multi-page outputs.

### 3.5. ANPR & Gate Access Workflow Suite (`ANPRGateWorkflowTest`)
- **Scenarios**:
  - Valid plate with matching reservation -> Entry authorized, session started, bay marked OCCUPIED.
  - Unknown plate -> Rejected with descriptive message (`Entry rejected: Unknown number plate`).
  - Cancelled reservation -> Rejected at gate.
  - Expired arrival window -> Rejected and bay released.
  - Mismatched plate for bay -> Rejected with redirect error.
  - Duplicate scan after vehicle already parked -> Rejected (`Duplicate entry attempt`).
  - Concurrent arrival scans -> Exactly 1 succeeds, 1 safely rejected.
  - Exit scan -> Parking charge calculated, payment finalized, bay released.

### 3.6. Booking & Parking-Session Lifecycle Audit (`BookingLifecycleAuditTest`)
- **Rules Verified**:
  1. Advance reservation locks bay as `RESERVED` but **does not start the timer**.
  2. Timer starts **strictly upon ANPR check-in** when vehicle physically enters.
  3. While parked, bay remains exclusively `OCCUPIED` and unavailable to any other driver.
  4. Exit records actual exit time and calculates exact charge using billing rules.
  5. Bay is released back to `AVAILABLE` **only after departure and payment completion**.
  6. Strict chronological integrity: `booking_time <= entry_time <= exit_time`.

---

## 4. Test Isolation & Safety Standards

- **Zero Data Loss**: Test suites operate using designated isolated test slots (e.g., `B4`, `B12`) and test accounts (`TST_DRV`, `TST_DRV1`).
- **Automated Tear-down**: All test records, reservations, and transactions generated during test runs are cleaned up automatically in `finally` blocks.
- **Production Safety**: Existing customer accounts (`ADM001`, `U001` - `U012`) and facility capacities remain intact and unmodified.
