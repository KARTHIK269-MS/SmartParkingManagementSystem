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
    <meta name="description" content="Privacy Policy and data governance compliance for SmartParking System under the Digital Personal Data Protection Act.">
    <title>SmartParking | Privacy Policy</title>
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
            <li><a href="<%= request.getContextPath() %>/terms.jsp" class="nav-link">Terms</a></li>
            <li><a href="<%= request.getContextPath() %>/privacy.jsp" class="nav-link active">Privacy</a></li>
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
                <span class="badge badge-success" style="font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.5px;">Legal &amp; Regulatory Compliance</span>
                <h1 style="font-size: 2rem; font-weight: 800; color: var(--color-primary); margin-top: 10px; margin-bottom: 8px;">
                    Privacy Policy &amp; DPDP Act Notice
                </h1>
                <p style="color: var(--text-muted); font-size: 0.92rem; margin: 0;">
                    Compliant with India's <strong>Digital Personal Data Protection (DPDP) Act, 2023</strong> and the Information Technology Act, 2000.  
                    <br><strong>Last Updated:</strong> October 2026 &bull; <strong>Version:</strong> 2.4
                </p>
            </div>

            <article style="line-height: 1.7; color: var(--text-main); font-size: 0.95rem;">
                
                <!-- Section 1 -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        1. Introduction &amp; Data Fiduciary Details
                    </h2>
                    <p>
                        This Privacy Notice is issued by <strong>Smart Parking Solutions India Private Limited</strong> ("we", "us", "our", or "Company"), acting as the <strong>Data Fiduciary</strong> under India's Digital Personal Data Protection Act, 2023 (DPDP Act). We are dedicated to maintaining the confidentiality, integrity, and security of digital personal data belonging to drivers and system users ("Data Principals").
                    </p>
                    <div style="background: var(--bg-card-alt); border-radius: var(--border-radius-sm); padding: 14px 18px; border: 1px solid var(--border-color); font-size: 0.88rem;">
                        <strong>Corporate Identity:</strong> Smart Parking Solutions India Pvt. Ltd.<br>
                        <strong>Registered Office:</strong> Level 4, Prestige Tech Park, Marathahalli-Sarjapur Ring Road, Bengaluru, Karnataka 560103, India<br>
                        <strong>CIN:</strong> U72900KA2024PTC189000 &bull; <strong>Official Contact:</strong> <a href="mailto:privacy@smartparkingsystem.in" style="color: var(--color-accent); font-weight: 600;">privacy@smartparkingsystem.in</a>
                    </div>
                </section>

                <!-- Section 2 -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        2. Categories of Personal Data Collected (Data Minimization)
                    </h2>
                    <p>
                        In adherence to the principle of <em>Data Minimization</em> mandated by the DPDP Act, we only collect personal data that is strictly necessary to provide smart parking reservations, vehicular check-in, and billing services:
                    </p>
                    <ul style="padding-left: 20px; margin-bottom: 14px;">
                        <li><strong>Identity &amp; Contact Data:</strong> Full Name, Email Address, and 10-digit Indian Mobile Phone Number (collected during registration).</li>
                        <li><strong>Vehicular Data:</strong> Vehicle Registration Number (VRN) in Indian High Security Registration Plate (HSRP) format, essential for parking bay assignment and gate barrier clearance.</li>
                        <li><strong>Transactional Data:</strong> Parking zone choice, bay identifier, entry timestamp, departure timestamp, duration parked, amount paid, and masked payment gateway transaction reference.</li>
                        <li><strong>Technical &amp; Session Data:</strong> Ephemeral IP address, browser type, and strictly necessary session identifier (<code style="background: #e2e8f0; padding: 2px 6px; border-radius: 4px;">JSESSIONID</code>) to keep you signed in securely.</li>
                    </ul>
                    <div style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: var(--border-radius-sm); padding: 12px 16px; font-size: 0.88rem; color: #166534;">
                        <strong>🛡️ No Sensitive Personal Data Collected:</strong> We do NOT collect Aadhaar numbers, biometric records, credit/debit card numbers (handled exclusively by RBI-authorized payment aggregators), or precise background GPS tracking.
                    </div>
                </section>

                <!-- Section 3 -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        3. Lawful Purpose &amp; Legal Grounds for Processing
                    </h2>
                    <p>
                        We process your digital personal data under the following legitimate and recognized grounds under the DPDP Act:
                    </p>
                    <ol style="padding-left: 20px;">
                        <li><strong>Performance of Parking Contract:</strong> To lock your chosen bay exclusively, calculate accurate tariffs, issue digital passes, and facilitate vehicle exit.</li>
                        <li><strong>Explicit Consent:</strong> Provided by you through deliberate opt-in checkboxes on account registration and bay reservation forms.</li>
                        <li><strong>Compliance with Law:</strong> Maintaining GST tax invoices, audit trails, and safety logs required by municipal parking regulations and law enforcement authorities.</li>
                    </ol>
                </section>

                <!-- Section 4 -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        4. Automated License Plate Recognition (ANPR) &amp; Sensor Telemetry
                    </h2>
                    <p>
                        Our entrance cameras and bay sensors capture vehicle license plates and ultrasonic distance data solely for parking session verification:
                    </p>
                    <ul style="padding-left: 20px;">
                        <li>Images captured at barrier gates are processed in real-time to match your reserved VRN and automatically lift the boom barrier.</li>
                        <li>Bay ultrasonic sensors detect only physical occupancy (occupied/available) and do not record passenger visuals or audio.</li>
                        <li>Optical plate scans are retained strictly for session verification and purged in accordance with our retention policy.</li>
                    </ul>
                </section>

                <!-- Section 5 -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        5. Rights of the Data Principal under DPDP Act, 2023
                    </h2>
                    <p>
                        As a Data Principal in India, you enjoy comprehensive statutory rights:
                    </p>
                    <ul style="padding-left: 20px;">
                        <li><strong>Right to Access Information:</strong> You may request a summary of the personal data we hold about you and details of processing activities.</li>
                        <li><strong>Right to Correction &amp; Erasure:</strong> You can update inaccurate profile details or request complete deletion of your account and personal history, subject to statutory tax record retention.</li>
                        <li><strong>Right of Grievance Redressal:</strong> You have the right to an expedited, transparent resolution of any privacy concerns via our Grievance Officer.</li>
                        <li><strong>Right to Nominate:</strong> You have the right to nominate an individual to exercise your data rights in the event of death or incapacity.</li>
                        <li><strong>Right to Withdraw Consent:</strong> You may withdraw consent at any time by contacting our Grievance Officer, following which personal processing for discretionary purposes will cease.</li>
                    </ul>
                </section>

                <!-- Section 6 -->
                <section style="margin-bottom: 28px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        6. Data Retention &amp; Security Measures
                    </h2>
                    <p>
                        Your personal credentials and passwords are encrypted using one-way <strong>cryptographic SHA-256 hashing</strong> with salting. All data transmissions are protected via Transport Layer Security (TLS 1.3).
                    </p>
                    <p>
                        Booking ledgers and billing records are stored for <strong>7 years</strong> solely to comply with the Indian Goods and Services Tax (GST) Act and the Companies Act, after which they are irreversibly anonymized or securely expunged.
                    </p>
                </section>

                <!-- Section 7 -->
                <section style="margin-bottom: 28px; background: var(--bg-card-alt); border: 1.5px solid var(--border-color); border-radius: var(--border-radius-md); padding: 22px 24px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 10px;">
                        7. Grievance Redressal Officer (Mandatory Statutory Notice)
                    </h2>
                    <p style="font-size: 0.9rem; margin-bottom: 12px;">
                        In accordance with Section 13 of the Digital Personal Data Protection Act, 2023, and Rule 3(2) of the Information Technology (Intermediary Guidelines and Digital Media Ethics Code) Rules, 2021, the designated Grievance Officer for Smart Parking Solutions India Pvt. Ltd. is:
                    </p>
                    <div style="font-size: 0.88rem; line-height: 1.6;">
                        <strong>Name:</strong> Mr. Rahul Sharma<br>
                        <strong>Designation:</strong> Data Protection &amp; Grievance Redressal Officer<br>
                        <strong>Company:</strong> Smart Parking Solutions India Pvt. Ltd.<br>
                        <strong>Postal Address:</strong> Level 4, Prestige Tech Park, Marathahalli-Sarjapur Ring Road, Bengaluru, Karnataka 560103, India<br>
                        <strong>Email:</strong> <a href="mailto:grievance@smartparkingsystem.in" style="color: var(--color-accent); font-weight: 700;">grievance@smartparkingsystem.in</a><br>
                        <strong>Helpline Phone:</strong> <a href="tel:+918049001234" style="color: var(--color-accent); font-weight: 700;">+91 80 4900 1234</a> (Mon–Fri, 9:30 AM to 6:00 PM IST)<br>
                        <strong>Turnaround Time:</strong> All grievances are acknowledged within 24 hours and resolved within 30 calendar days as stipulated by law.
                    </div>
                </section>

            </article>

            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
                <a href="<%= request.getContextPath() %>/zones" class="btn btn-secondary btn-sm">&larr; Back to Parking Zones</a>
                <div style="display: flex; gap: 12px;">
                    <a href="<%= request.getContextPath() %>/terms.jsp" class="btn btn-secondary btn-sm">Terms &amp; Conditions</a>
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
