# Smart Parking Management System — Screenshots & UI Gallery

This folder documents key user interfaces and verified features across the Driver Web Portal and Facility Admin Console.

---

## 1. Driver Web Portal

- **Parking Zones Discovery (`/zones`)**: Multi-city facility browsing across Bengaluru, Hyderabad, and Chennai with live bay counters and dynamic tariff indicators.
- **Interactive Bay Map (`/slots`)**: Real-time visual floor grid displaying Available (Green), Reserved (Yellow), Occupied (Red), and Accessible/EV bays.
- **Reservation & Booking Workflow (`/booking`)**: 15-minute advance grace reservations, scheduled arrival selection, and instant booking confirmations.
- **Contactless Checkout & Payment (`/payment`)**: Dynamic billing calculation, support for UPI, FASTag, Credit/Debit Cards, and NetBanking.
- **Driver History & Live Timers (`/myBookings`)**: Live elapsed session timers, navigation directions, and downloadable digital VAT/GST receipts.

---

## 2. Facility Admin Console (`/admin?action=dashboard`)

- **Facility Overview Tab**: Real-time total capacity metrics, active vehicle counts, and sensor pulse simulation.
- **Analytics & Demand Curves Tab**: 24-hour occupancy distribution curves, city revenue breakdowns, and payment channel share via Chart.js.
- **Dynamic Pricing & Surge Tab**: 3-tier demand surge controls, automatic 1.25x tariff adjustments at 80% occupancy threshold.
- **Supervisory Bay Overrides**: Administrative overrides for emergency maintenance with active booking protection locks.
- **Smart Occupancy Prediction Tab**: Hourly predictive demand curves comparing observed live occupancy against machine-learned historical trendlines.
- **Financial Reports & Audit Ledger**: Date-range filtered reporting with one-click RFC 4180 CSV and OpenPDF export with formula-injection defenses.
- **ANPR Gate Simulator (`/anpr.jsp`)**: High-accuracy camera plate recognition emulation, automated barrier gate actuation, and gate decision logging.
