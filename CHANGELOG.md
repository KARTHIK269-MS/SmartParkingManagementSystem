# Changelog

All notable changes to the **Smart Parking Management System** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-10-15

### Added
- **Multi-Facility Corridor Architecture**: Support for 12 parking facilities across 3 metropolitan tech hubs (Bengaluru, Hyderabad, Chennai) with 150 monitored bays.
- **ANPR Gate Access & Automated Barrier Engine**: Complete number-plate validation pipeline supporting live camera feeds and high-fidelity web simulation.
- **3-Tier Dynamic Demand Pricing**: Automated tariff adjustment engine scaling operating rates by 1.25x upon crossing the 80% occupancy threshold.
- **Smart Occupancy Prediction**: 24-hour predictive demand curves using historical telemetry snapshots (`occupancy_snapshots`) and exponential moving averages.
- **Audited Financial Reporting**: Dynamic date-range filtering for Occupancy, Bookings, and Settled Revenue reports.
- **Export Engine**:
  - RFC 4180 compliant CSV exports with active spreadsheet formula injection defenses (`=`, `+`, `-`, `@`).
  - Professional multi-page OpenPDF vector generation with clean empty states, executive summary KPIs, and tabular transaction breakdowns.
- **Interactive Supervisory Bay Grid**: Visual floor map with real-time status indicators (Available, Reserved, Occupied, EV, Accessible) and emergency admin overrides.
- **Automated Verification Suites**: 6 automated test suites covering 190+ test assertions for concurrency locks, gate lifecycles, and financial parity.

### Security
- Replaced hardcoded database credentials in `DBConnection` with dynamic multi-source resolution (Environment Variables, System Properties, `db.properties`, `config/application.properties`).
- Implemented salted BCrypt password hashing (`PasswordHasher`) with 10 salt rounds.
- Hardened all SQL queries using parameterized prepared statements (`PreparedStatement`).
- Added cryptographic CSRF token validation (`CsrfUtil`) across administrative operations.
- Separated Driver and Administrator HTTP session boundaries.
