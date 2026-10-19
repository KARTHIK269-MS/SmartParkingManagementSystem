# Contributing to Smart Parking Management System

Thank you for your interest in contributing to the **Smart Parking Management System**! We welcome bug reports, documentation enhancements, feature proposals, and code contributions.

---

## 1. Code of Conduct

All contributors are expected to maintain a welcoming, respectful, and harassment-free environment for everyone. Please be constructive, professional, and collaborative.

---

## 2. Getting Started

1. **Fork the Repository** on GitHub.
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/<your-username>/SmartParkingManagementSystem.git
   cd SmartParkingManagementSystem
   ```
3. **Configure your development database**:
   - Follow the [Local Setup Guide](docs/setup-guide.md).
   - Never commit your active database configuration (`config/application.properties` or `db.properties`).
4. **Create a topic branch**:
   ```bash
   git checkout -b feature/my-new-feature
   ```

---

## 3. Development Guidelines

- **Java Standard**: Write clean, modern Java 17 code.
- **Architectural Integrity**: Maintain the 3-tier MVC separation (JSP Presentation -> Servlet Controller -> DAO Data Access).
- **Security First**:
  - Always use `PreparedStatement` with parameterized queries to prevent SQL injection.
  - Sanitize user inputs and escape dynamic attributes using `HtmlEscaper`.
  - Apply formula-injection defenses (`'` prefix) on dynamic CSV export values.
- **Automated Verification**:
  - Run the test suite before submitting:
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\run_tests.ps1
    ```
  - Ensure all existing and new tests pass without regressions.

---

## 4. Submitting a Pull Request (PR)

1. Commit your changes with clear, descriptive commit messages:
   ```bash
   git commit -m "feat(billing): add support for automated GST invoice tax breakdown"
   ```
2. Push your topic branch to your GitHub fork:
   ```bash
   git push origin feature/my-new-feature
   ```
3. Open a Pull Request against the `main` branch of the upstream repository.
4. Fill in the provided [Pull Request Template](.github/pull_request_template.md).
