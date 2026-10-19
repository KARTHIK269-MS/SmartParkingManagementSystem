# Database Setup & Schema Guide

This directory contains the database definition and seed data scripts for the **Smart Parking Management System**.

---

## Prerequisites

- **MySQL Server 8.0+**
- Administrative access to MySQL (`root` or dedicated user with `ALL PRIVILEGES` on `parking_system`)
- Character Set: `utf8mb4` (collation `utf8mb4_0900_ai_ci` or `utf8mb4_unicode_ci`)

---

## File Overview

| File | Description |
|---|---|
| `schema.sql` | Complete DDL script creating tables, constraints, indexes, and initial data. |
| `seed-data.sql` | Realistic development dataset: 12 facilities, 150 bays, test users, bookings, payments, and reviews. |

---

## Automated Database Initialization

### 1. Import Schema & Seed Data

Run the following command in terminal or PowerShell:

```bash
# Log into MySQL and run schema.sql (creates database and all tables)
mysql -u root -p < database/schema.sql
```

If you ever need to reset or refresh seed data independently:

```bash
mysql -u root -p parking_system < database/seed-data.sql
```

---

## Database Schema Structure

The application operates across 7 normalized relational tables:

```
+------------------+         +------------------+
|      users       |         |      zones       |
+------------------+         +------------------+
| user_id (PK)     |         | zone_id (PK)     |
| name             |         | name             |
| email (UNIQUE)   |         | location         |
| password (hash)  |         | hourly_rate      |
| phone_number     |         | total_slots      |
| role             |         | description      |
+--------+---------+         +--------+---------+
         |                            |
         | 1:N                        | 1:N
         v                            v
+------------------+         +------------------+
|     bookings     |-------->|      slots       |
+------------------+ N:1     +------------------+
| booking_id (PK)  |         | slot_id (PK)     |
| user_id (FK)     |         | zone_id (FK)     |
| slot_id (FK)     |         | slot_number      |
| vehicle_number   |         | floor            |
| entry_time       |         | type             |
| exit_time        |         | status           |
| status           |         +------------------+
| total_amount     |
+--------+---------+
         |
         | 1:1
         v
+------------------+         +----------------------+
|     payments     |         |  occupancy_snapshots |
+------------------+         +----------------------+
| payment_id (PK)  |         | snapshot_id (PK)     |
| booking_id (FK)  |         | zone_id              |
| amount           |         | total_bays           |
| payment_method   |         | occupied_bays        |
| transaction_id   |         | occupancy_percent    |
| status           |         | recorded_at          |
+------------------+         +----------------------+
```

### Table Descriptions:

1. **`users`**: User identity, roles (`ADMIN`, `USER`), and salted BCrypt password hashes.
2. **`zones`**: Parking facilities / clusters across metropolitan corridors with base tariffs.
3. **`slots`**: 150 individual physical parking bays with status (`AVAILABLE`, `RESERVED`, `OCCUPIED`, `MAINTENANCE`).
4. **`bookings`**: Complete driver booking & parking lifecycle with reservations, entry/exit timestamps, and charges.
5. **`payments`**: Audited electronic receipts with gateway transaction identifiers and channels (UPI, FASTag, Card, NetBanking).
6. **`feedback`**: Customer 1-to-5 star ratings and reviews.
7. **`occupancy_snapshots`**: Real-time hourly occupancy telemetry records used by the predictive demand engine.

---

## Default Seed Accounts (For Local Development Only)

> [!NOTE]
> All passwords in the database are hashed with BCrypt. Plaintext passwords are provided below strictly for testing default installations.

| Role | Email | Password | Description |
|---|---|---|---|
| **Admin** | `admin@smartparking.com` | `Admin@123` | Full administrative console access |
| **Driver** | `driver1@example.com` | `Driver@123` | Demo driver account |
| **Driver** | `driver2@example.com` | `Driver@123` | Demo driver account |

---

## Security & Credential Isolation

- **Never** commit production passwords or sensitive connection strings.
- Local credentials should be placed in `config/application.properties` or `db.properties` (both are git-ignored).
- Refer to `config/application.example.properties` for sample configuration syntax.
