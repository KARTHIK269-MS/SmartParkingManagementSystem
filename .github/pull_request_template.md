## Description
Please include a summary of the change and which issue is fixed or feature implemented.

Fixes #(issue)

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Performance optimization or security hardening
- [ ] Documentation update

## Verification & Testing Performed
Please describe the tests that you ran to verify your changes:
- [ ] Core Unit Tests (`MiniProjectUnitTest`)
- [ ] System Integration Tests (`TestSystem`)
- [ ] Bay Availability & Sync Tests (`BayAvailabilitySyncTest`)
- [ ] Admin Reports & Export Tests (`AdminReportsTest`)
- [ ] ANPR Gate Workflow Tests (`ANPRGateWorkflowTest`)
- [ ] Booking Lifecycle Audit Tests (`BookingLifecycleAuditTest`)

## Security Checklist
- [ ] No hardcoded passwords, tokens, or credentials are added.
- [ ] Local configurations (`db.properties`, `config/application.properties`) remain ignored.
- [ ] SQL inputs use parameterized prepared statements (`PreparedStatement`).
- [ ] User-facing HTML and CSV exports apply escaping to prevent injection.
