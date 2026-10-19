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
    <meta name="description" content="Cookie Policy and session tracking transparency for SmartParking Management System.">
    <title>SmartParking | Cookie Policy</title>
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
                <span class="badge badge-info" style="font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.5px;">Privacy &amp; Transparency</span>
                <h1 style="font-size: 2rem; font-weight: 800; color: var(--color-primary); margin-top: 10px; margin-bottom: 8px;">
                    Cookie Policy
                </h1>
                <p style="color: var(--text-muted); font-size: 0.92rem; margin: 0;">
                    Information on how we utilize cookies and local browser storage on Smart Parking System.  
                    <br><strong>Last Updated:</strong> October 2026 &bull; <strong>Version:</strong> 2.4
                </p>
            </div>

            <article style="line-height: 1.7; color: var(--text-color); font-size: 0.95rem;">

                <section style="margin-bottom: 26px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        1. What Are Cookies?
                    </h2>
                    <p>
                        Cookies are small text files placed on your computer, smartphone, or tablet when you visit websites. They are widely used to make web applications function correctly, maintain your security, remember your operational preferences, and ensure seamless authentication.
                    </p>
                </section>

                <section style="margin-bottom: 26px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        2. Our Cookie &amp; Storage Philosophy: Strict Data Minimization
                    </h2>
                    <p>
                        Smart Parking System adheres to strict <strong>privacy-by-design</strong> principles under India's Digital Personal Data Protection (DPDP) Act, 2023. We do <strong>not</strong> sell your data, do <strong>not</strong> participate in behavioral cross-site ad tracking networks, and do <strong>not</strong> install intrusive third-party spyware or profiling beacons.
                    </p>
                </section>

                <section style="margin-bottom: 26px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        3. Detailed Inventory of Cookies &amp; Storage
                    </h2>
                    <p style="margin-bottom: 14px;">
                        The following table outlines all cookies and local browser storage mechanisms utilized by this application:
                    </p>
                    <div style="overflow-x: auto;">
                        <table class="table" style="width: 100%; font-size: 0.88rem; border-collapse: collapse; margin-bottom: 12px;">
                            <thead>
                                <tr style="background: rgba(255,255,255,0.03); text-align: left; border-bottom: 1.5px solid var(--border-color);">
                                    <th style="padding: 10px 12px;">Identifier</th>
                                    <th style="padding: 10px 12px;">Storage Type</th>
                                    <th style="padding: 10px 12px;">Category</th>
                                    <th style="padding: 10px 12px;">Purpose</th>
                                    <th style="padding: 10px 12px;">Duration</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr style="border-bottom: 1px solid var(--border-color);">
                                    <td style="padding: 10px 12px; font-family: monospace; font-weight: 700; color: var(--color-accent);">JSESSIONID</td>
                                    <td style="padding: 10px 12px;">HTTP Cookie</td>
                                    <td style="padding: 10px 12px;"><span class="badge badge-success">Strictly Necessary</span></td>
                                    <td style="padding: 10px 12px;">Maintains user session authentication across parking slot selection, reservation, and profile views. Essential for security and login state.</td>
                                    <td style="padding: 10px 12px;">Session (Deleted upon closing browser)</td>
                                </tr>
                                <tr style="border-bottom: 1px solid var(--border-color);">
                                    <td style="padding: 10px 12px; font-family: monospace; font-weight: 700; color: var(--color-accent);">sps_cookie_consent</td>
                                    <td style="padding: 10px 12px;">HTML5 LocalStorage</td>
                                    <td style="padding: 10px 12px;"><span class="badge badge-info">Functional / Preference</span></td>
                                    <td style="padding: 10px 12px;">Stores your cookie preference selection so that the consent banner does not re-appear on subsequent visits.</td>
                                    <td style="padding: 10px 12px;">180 Days</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </section>

                <section style="margin-bottom: 26px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        4. Third-Party Analytics &amp; Advertising
                    </h2>
                    <div class="alert alert-info" style="border-left: 4px solid var(--color-accent); padding: 12px 16px; margin: 12px 0;">
                        <strong>Third-Party Tracking Audit Status: ZERO (0) TRACKERS</strong><br>
                        We do not load Google Analytics, Meta Pixel, Hotjar, marketing tag managers, or cross-site tracking scripts. Your parking search history, license plate entries, and geolocation coordinates are never broadcast to ad brokers.
                    </div>
                </section>

                <section style="margin-bottom: 26px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        5. How to Control or Revoke Cookie Consent
                    </h2>
                    <p style="margin-bottom: 10px;">
                        You have complete autonomy over cookie storage:
                    </p>
                    <ul style="padding-left: 20px; margin-bottom: 16px;">
                        <li>
                            <strong>In-App Controls:</strong> You may adjust or revoke your cookie choices at any time by clicking the button below:
                            <div style="margin: 12px 0;">
                                <button type="button" class="btn btn-secondary btn-sm cookie-settings-btn" style="cursor: pointer;">
                                    ⚙ Open Cookie Consent Settings
                                </button>
                            </div>
                        </li>
                        <li>
                            <strong>Browser Settings:</strong> You can configure your browser to block all cookies or alert you when a cookie is placed:
                            <ul style="margin-top: 6px; padding-left: 20px;">
                                <li><strong>Google Chrome:</strong> Settings &rarr; Privacy and security &rarr; Third-party cookies</li>
                                <li><strong>Mozilla Firefox:</strong> Settings &rarr; Privacy &amp; Security &rarr; Enhanced Tracking Protection</li>
                                <li><strong>Microsoft Edge:</strong> Settings &rarr; Cookies and site permissions &rarr; Manage cookies</li>
                                <li><strong>Apple Safari:</strong> Preferences &rarr; Privacy &rarr; Prevent cross-site tracking / Block cookies</li>
                            </ul>
                        </li>
                    </ul>
                    <p style="color: var(--text-muted); font-size: 0.88rem;">
                        <em>Note: Disabling the strictly necessary <code>JSESSIONID</code> cookie will disable authentication, preventing you from reserving parking slots or accessing your booking history.</em>
                    </p>
                </section>

                <section style="margin-bottom: 20px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        6. Contact &amp; Grievance
                    </h2>
                    <p>
                        For technical or legal questions regarding our cookie practices, please contact our Data Protection Officer:
                    </p>
                    <div style="background: rgba(255, 255, 255, 0.04); border: 1px solid var(--border-color); border-radius: 8px; padding: 14px 18px; margin-top: 10px; font-size: 0.9rem;">
                        <strong>Data Protection &amp; Grievance Desk:</strong><br>
                        <strong>Email:</strong> <a href="mailto:grievance@smartparkingsystem.in" style="color: var(--color-accent); font-weight: 700;">grievance@smartparkingsystem.in</a><br>
                        <strong>Entity:</strong> Smart Parking Solutions India Private Limited<br>
                        <strong>Address:</strong> Level 4, Prestige Tech Park, Bengaluru, Karnataka 560103
                    </div>
                </section>

            </article>

            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
                <a href="<%= request.getContextPath() %>/zones" class="btn btn-secondary btn-sm">&larr; Back to Parking Zones</a>
                <div style="display: flex; gap: 12px;">
                    <a href="<%= request.getContextPath() %>/privacy.jsp" class="btn btn-secondary btn-sm">Privacy Policy</a>
                    <a href="<%= request.getContextPath() %>/terms.jsp" class="btn btn-secondary btn-sm">Terms &amp; Conditions</a>
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
