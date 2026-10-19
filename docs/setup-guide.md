# Smart Parking Management System — Local Setup & Deployment Guide

This guide walks you through setting up, configuring, building, and running the Smart Parking Management System on your local development machine.

---

## 1. Prerequisites

Ensure the following tools are installed on your workstation:

| Component | Minimum Version | Recommended | Notes |
|---|---|---|---|
| **Java Development Kit (JDK)** | Java 17 | Eclipse Temurin / OpenJDK 17 | Ensure `JAVA_HOME` is set on PATH |
| **Servlet Container** | Apache Tomcat 9.0 | Tomcat 9.0.80+ | Compatible with Java EE 8 / Servlet 4.0 |
| **Database Server** | MySQL Community Server 8.0 | MySQL 8.0.30+ | Default port: `3306` |
| **Build Tools** | PowerShell 5.1+ / Apache Maven 3.8+ | Maven 3.9+ | Bundled `build.ps1` compiles with JDK directly |
| **Git** | Git 2.30+ | Git 2.40+ | For version control and GitHub tracking |

---

## 2. Step 1: Clone Repository

```bash
git clone https://github.com/KARTHIK269-MS/SmartParkingManagementSystem.git
cd SmartParkingManagementSystem
```

---

## 3. Step 2: Database Setup

1. Start your local MySQL service:
   ```bash
   # Windows PowerShell
   net start MySQL80
   ```

2. Import the database schema and default tables:
   ```bash
   mysql -u root -p < database/schema.sql
   ```
   *Note: This creates the `parking_system` database with all 7 tables and sets up the 12 zones, 150 bays, and sample test accounts.*

3. Verify database tables:
   ```bash
   mysql -u root -p -e "SHOW TABLES FROM parking_system;"
   ```

---

## 4. Step 3: Application Configuration

To protect your credentials, real passwords should never be committed to Git. Configure your local database connection using one of the two methods below:

### Option A: Configuration File (Recommended)
Copy the example configuration file:
```bash
# In project root
cp config/application.example.properties config/application.properties
```
Open `config/application.properties` and enter your MySQL credentials:
```properties
db.url=jdbc:mysql://localhost:3306/parking_system?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata
db.user=root
db.password=your_actual_mysql_password
```
*(Notice: `config/application.properties` and `db.properties` are in `.gitignore` and will never be committed.)*

### Option B: Environment Variables
Alternatively, you can set system environment variables:
```powershell
$env:DB_URL = "jdbc:mysql://localhost:3306/parking_system?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata"
$env:DB_USER = "root"
$env:DB_PASSWORD = "your_actual_mysql_password"
```

---

## 5. Step 4: Build & Packaging

You can build the project using either PowerShell or Apache Maven:

### Using Automated PowerShell Build Script:
```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```
This compiles all Java 17 source files, synchronizes configuration, and generates the WAR file:
`target/smart-parking-system.war`

### Using Maven (if installed):
```bash
mvn clean package
```

---

## 6. Step 5: Deploy to Apache Tomcat 9

### Option A: Copy WAR to Tomcat Webapps
Copy `target/smart-parking-system.war` to your Apache Tomcat `webapps` folder:
```powershell
Copy-Item "target\smart-parking-system.war" "C:\Program Files\apache-tomcat-9.0.117\webapps\" -Force
```
Tomcat will automatically extract the WAR file into a running context.

### Option B: Using Eclipse / IDE Server Runtime
Import the repository into Eclipse as an **Existing Dynamic Web Project**, configure your Tomcat 9 server in the "Servers" tab, and run on server.

---

## 7. Step 6: Access the Application

Once Tomcat is running, open your web browser:

- **Driver Booking Portal**:
  `http://localhost:8080/smart-parking-system/zones`
- **Facility Admin Console**:
  `http://localhost:8080/smart-parking-system/admin?action=dashboard`
- **ANPR Live Simulation Gate**:
  `http://localhost:8080/smart-parking-system/anpr.jsp`
- **User Authentication**:
  `http://localhost:8080/smart-parking-system/login.jsp`

---

## 8. Default Credentials for Local Testing

| Role | Email | Password | Access Area |
|---|---|---|---|
| **System Administrator** | `admin@smartparking.com` | `Admin@123` | Admin Dashboard, Reports, Bay Overrides, Analytics |
| **Driver Account** | `driver1@example.com` | `Driver@123` | Driver Booking, My Bookings, Live Sessions |
| **Driver Account** | `driver2@example.com` | `Driver@123` | Driver Booking, Payments, Feedback |

---

## 9. Troubleshooting

### Problem: `DatabaseException: Access denied for user 'root'@'localhost'`
- **Fix**: Verify your password in `config/application.properties` or `db.properties`. Confirm you can log into MySQL directly with `mysql -u root -p`.

### Problem: Port 8080 already in use
- **Fix**: Check what process is occupying port 8080 using `netstat -ano | findstr :8080`. Stop conflicting applications or change the Tomcat port in `conf/server.xml` to `8081`.

### Problem: HTTP 404 on accessing `/smart-parking-system/`
- **Fix**: Ensure the extracted folder in Tomcat `webapps/` is named `smart-parking-system`. Check Tomcat's `logs/catalina.out` or `logs/localhost.*.log` for initialization errors.
