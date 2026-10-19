# Security Policy

## 1. Supported Versions

Security updates and critical patches are actively provided for the following releases:

| Version | Supported          | Java Compatibility |
| ------- | ------------------ | ------------------ |
| 1.0.x   | :white_check_mark: | Java 17 LTS        |
| < 1.0   | :x:                | -                  |

---

## 2. Reporting a Vulnerability

The project team takes the security of user authentication, vehicle access, and transaction ledgers seriously.

If you discover a security vulnerability (such as an authentication bypass, SQL injection, CSRF gap, or credential leakage):

1. **Do NOT open a public GitHub issue.**
2. Send a responsible disclosure email detailing:
   - Type of vulnerability
   - Affected endpoints or source files
   - Step-by-step reproduction guide or proof-of-concept payload
   - Potential impact
3. The maintainers will acknowledge receipt within 48 hours and work with you on a coordinated fix and advisory.

---

## 3. Credential & Secret Management Policy

- **No Hardcoded Passwords**: The codebase utilizes dynamic property resolution (`DBConnection`) and environment variables (`DB_URL`, `DB_USER`, `DB_PASSWORD`).
- **Template Configuration**: Only sanitized `.example` configuration files (`config/application.example.properties`) are tracked in Git.
- **Git Hygiene**: Active `.properties`, `.env`, and private dumps are excluded by `.gitignore`.
- **Database Hashes**: All passwords stored in database tables use salted BCrypt (`PasswordHasher`) or SHA-256 for administrator access. Plaintext passwords must never be stored in persistent storage.
