<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%
    User currentUser = (User) session.getAttribute("driverUser");
    if (currentUser == null) currentUser = (User) session.getAttribute("adminUser");
    if (currentUser == null) currentUser = (User) session.getAttribute("user");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Terms and Conditions of service, bay reservation rules, and parking facility usage policies.">
    <title>SmartParking | Terms and Conditions</title>
    <link rel="icon" type="image/svg+xml" href="<%= request.getContextPath() %>/resources/images/favicon.svg">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <script>
        const contextPath = "<%= request.getContextPath() %>";
    </script>
</head>
<body>

    <!-- Navigation Bar -->
    <nav class="navbar" aria-label="Main Navigation">
        <a href="<%= request.getContextPath() %>/zones" class="navbar-brand">
            <div class="brand-icon" aria-hidden="true">P</div>
            <span>SmartParking<span class="brand-tag">SYSTEM</span></span>
        </a>
        <ul class="nav-links">
            <li><a href="<%= request.getContextPath() %>/zones" class="nav-link">Parking Zones</a></li>
            <% if (currentUser != null) { %>
                <li><a href="<%= request.getContextPath() %>/booking?action=myBookings" class="nav-link">My Bookings</a></li>
            <% } %>
            <li><a href="<%= request.getContextPath() %>/terms.jsp" class="nav-link active">Terms</a></li>
            <li><a href="<%= request.getContextPath() %>/privacy.jsp" class="nav-link">Privacy</a></li>
        </ul>
        <div class="nav-actions">
            <% if (currentUser != null) { %>
                <div class="user-badge">
                    <div class="user-avatar"><%= currentUser.getName().substring(0, 1).toUpperCase() %></div>
                    <span><%= currentUser.getName() %></span>
                </div>
                <a href="<%= request.getContextPath() %>/login?action=logout" class="btn btn-secondary btn-sm">Sign Out</a>
            <% } else { %>
                <a href="<%= request.getContextPath() %>/login" class="btn btn-secondary btn-sm">Sign In</a>
                <a href="<%= request.getContextPath() %>/register" class="btn btn-primary btn-sm">Register</a>
            <% } %>
        </div>
    </nav>

    <!-- Main Content Container -->
    <main class="container" style="max-width: 900px; padding-top: 30px; padding-bottom: 60px;">
        <div class="card" style="padding: 40px 36px;">
            <div style="border-bottom: 1.5px solid var(--border-color); padding-bottom: 20px; margin-bottom: 28px;">
                <span class="badge badge-warning" style="font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.5px;">User Agreement</span>
                <h1 style="font-size: 2rem; font-weight: 800; color: var(--color-primary); margin-top: 10px; margin-bottom: 8px;">
                    Terms of Service &amp; Parking Facility Rules
                </h1>
                <p style="color: var(--text-muted); font-size: 0.92rem; margin: 0;">
                    Please read these terms carefully before reserving or parking in our facilities.
                    <br><strong>Last Updated:</strong> October 2026 &bull; <strong>Version:</strong> 2.4
                </p>
            </div>

            <article style="line-height: 1.7; color: var(--text-main); font-size: 0.95rem;">
                
                <!-- Section 1 -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        1. Acceptance of Terms &amp; Scope of Service
                    </h2>
                    <p>
                        These Terms and Conditions constitute a legally binding agreement between you (the "Driver" or "User") and <strong>Smart Parking Solutions India Private Limited</strong> ("Operator", "Company", "we", "us"). By registering an account, reserving a bay, or accessing any affiliated parking facility, you acknowledge and agree to comply with these terms.
                    </p>
                </section>

                <!-- Section 2: Limitation of Liability -->
                <section style="margin-bottom: 28px; background: #fffbeb; border: 2px solid #f59e0b; border-radius: var(--border-radius-md); padding: 22px 24px;">
                    <h2 style="font-size: 1.25rem; font-weight: 800; color: #92400e; margin-bottom: 10px; display: flex; align-items: center; gap: 8px;">
                        <span>⚠️</span> 2. Crucial Disclaimer: "Park at Your Own Risk" &amp; Limitation of Liability
                    </h2>
                    <p style="color: #78350f; font-size: 0.92rem; margin-bottom: 12px; font-weight: 600;">
                        THE PARKING PERMIT CONSTITUTES A REVOCABLE LICENSE TO OCCUPY A DESIGNATED SPACE ONLY. IT DOES NOT CONSTITUTE A CONTRACT OF BAILMENT, CUSTODY, OR SAFEKEEPING.
                    </p>
                    <ul style="color: #78350f; font-size: 0.88rem; padding-left: 20px; line-height: 1.6; margin: 0;">
                        <li><strong>Vehicle Damage:</strong> The Operator, its directors, employees, property owners, and affiliates bear NO liability whatsoever for any collision, dent, scratch, fire, mechanical breakdown, or damage caused to your vehicle while parked or maneuvering inside the facility.</li>
                        <li><strong>Theft of Valuables:</strong> You are solely responsible for removing all personal property, electronic devices, cash, jewelry, and luggage from your vehicle. The Operator is not liable for theft, burglary, or loss of any articles left inside parked vehicles.</li>
                        <li><strong>Third-Party Actions:</strong> We are not responsible for criminal or negligent acts of third parties, trespassers, or other drivers in the parking complex.</li>
                        <li><strong>Lock &amp; Secure Duty:</strong> Drivers are strictly obligated to properly park within bay markings, set the parking handbrake, turn off the engine, and securely lock all vehicle windows and doors before leaving the bay.</li>
                    </ul>
                </section>

                <!-- Section 3: 15-20 Min Grace Arrival -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        3. Scheduled Reservation &amp; 15–20 Minute Arrival Grace Period
                    </h2>
                    <p>
                        To prevent parking slot hoarding and maintain fair urban availability:
                    </p>
                    <ul style="padding-left: 20px;">
                        <li><strong>Exclusive Bay Hold:</strong> When you reserve a slot, the system locks the bay exclusively for your designated Vehicle Registration Number (VRN).</li>
                        <li><strong>15–20 Minute Grace Period:</strong> You are granted a <strong>15–20 minute grace window</strong> from your scheduled arrival time to reach the facility gate and verify entry.</li>
                        <li><strong>Automated Non-Arrival Cancellation:</strong> If your vehicle does not check in at the facility within 15–20 minutes past the scheduled arrival time, the reservation will be <strong>automatically cancelled</strong> and the slot released back to the general public.</li>
                    </ul>
                </section>

                <!-- Section 4: Tariffs & Overstays -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        4. Tariffs, Overstay Penalties &amp; Vehicle Removal
                    </h2>
                    <p>
                        Parking fees are calculated on an hourly basis in accordance with posted facility rates:
                    </p>
                    <ul style="padding-left: 20px;">
                        <li><strong>Live Metering:</strong> Live parking duration starts upon verified entrance and concludes when you scan out and complete the payment on exit.</li>
                        <li><strong>Overstay Past 24 Hours:</strong> Any vehicle remaining parked for more than 24 hours without an active reservation or prior written communication with facility management will be deemed <em>unauthorized/abandoned</em>.</li>
                        <li><strong>Wheel Clamping &amp; Towing:</strong> The Operator reserves the right to clamp wheels or tow unauthorized vehicles to a municipal impound lot at the vehicle owner's sole risk and expense.</li>
                    </ul>
                </section>

                <!-- Section 5: Facility Conduct -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        5. Facility Code of Conduct &amp; Prohibited Activities
                    </h2>
                    <p>
                        While inside any facility, users agree NOT to:
                    </p>
                    <ul style="padding-left: 20px;">
                        <li>Exceed the posted internal speed limit of <strong>10 km/h</strong>.</li>
                        <li>Park across designated white lines, in disabled bays without valid permit, or block emergency egress routes.</li>
                        <li>Store hazardous chemicals, flammable fuels, explosives, or illegal contraband in the vehicle.</li>
                        <li>Carry out commercial vehicle washing, oil changes, or mechanical maintenance inside parking bays.</li>
                    </ul>
                </section>

                <!-- Section 6: Governing Law -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        6. Governing Law &amp; Dispute Resolution
                    </h2>
                    <p>
                        These Terms and Conditions shall be governed by and construed in accordance with the laws of <strong>India</strong>. Any disputes, claims, or legal proceedings arising out of or related to these terms shall be subject to the exclusive jurisdiction of the competent courts in <strong>Bengaluru, Karnataka, India</strong>.
                    </p>
                </section>

            </article>

            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
                <a href="<%= request.getContextPath() %>/zones" class="btn btn-secondary btn-sm">&larr; Back to Parking Zones</a>
                <div style="display: flex; gap: 12px;">
                    <a href="<%= request.getContextPath() %>/privacy.jsp" class="btn btn-secondary btn-sm">Privacy Policy (DPDP)</a>
                    <a href="<%= request.getContextPath() %>/cookies.jsp" class="btn btn-secondary btn-sm">Cookie Policy</a>
                    <a href="<%= request.getContextPath() %>/refund.jsp" class="btn btn-secondary btn-sm">Refund Policy</a>
                </div>
            </div>
        </div>
    </main>

        <!-- Standardized Academic Footer -->
    <footer class="footer" role="contentinfo">
        <div class="footer-container">
            <div>
                <div class="footer-brand">SmartParking</div>
                <div class="footer-sub">Smart Parking Management System • Academic Mini Project</div>
                <div class="footer-sub" style="margin-top: 4px;">Developed with Java 17, JSP, Servlets, JDBC & MySQL</div>
            </div>
            <div style="text-align: right;">
                <div class="footer-links" style="margin-bottom: 6px; justify-content: flex-end;">
                    <a href="<%= request.getContextPath() %>/privacy.jsp">Privacy Policy</a>
                    <a href="<%= request.getContextPath() %>/terms.jsp">Terms &amp; Conditions</a>
                    <a href="<%= request.getContextPath() %>/cookies.jsp">Cookie Policy</a>
                    <a href="<%= request.getContextPath() %>/refund.jsp">Refund Policy</a>
                </div>
                <div class="footer-sub">&copy; 2026 SmartParking. For Academic Demonstration.</div>
            </div>
        </div>
    </footer>

    <script src="<%= request.getContextPath() %>/resources/js/cookieConsent.js"></script>
</body>
</html>
