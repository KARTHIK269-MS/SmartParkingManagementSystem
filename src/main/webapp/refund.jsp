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
    <meta name="description" content="Cancellation and refund policies for pre-booked bays, 15-minute grace period cancellations, and simulated ledger credits.">
    <title>SmartParking | Refund Policy</title>
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
                <span class="badge badge-success" style="font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.5px;">Consumer Transparency</span>
                <h1 style="font-size: 2rem; font-weight: 800; color: var(--color-primary); margin-top: 10px; margin-bottom: 8px;">
                    Cancellation &amp; Refund Policy
                </h1>
                <p style="color: var(--text-muted); font-size: 0.92rem; margin: 0;">
                    Adhering to the Consumer Protection Act, 2019 and Consumer Protection (E-Commerce) Rules, 2020.  
                    <br><strong>Last Updated:</strong> October 2026 &bull; <strong>Version:</strong> 2.4
                </p>
            </div>

            <article style="line-height: 1.7; color: var(--text-color); font-size: 0.95rem;">

                <section style="margin-bottom: 26px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        1. Overview &amp; Fair Trading Commitment
                    </h2>
                    <p>
                        At Smart Parking System (operated by Smart Parking Solutions India Pvt. Ltd.), we strive to deliver transparent, predictable, and fair parking reservation experiences. This policy outlines when and how you may cancel reservations and claim eligible refunds for digital parking bay reservations.
                    </p>
                </section>

                <section style="margin-bottom: 26px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        2. Driver Cancellation Rules &amp; Refund Tiers
                    </h2>
                    <p style="margin-bottom: 12px;">
                        Drivers may cancel reservations directly from the <a href="<%= request.getContextPath() %>/booking?action=myBookings" style="color: var(--color-accent); text-decoration: underline;">My Bookings</a> dashboard. Refund eligibility is determined by the timing of the cancellation relative to the scheduled slot start time:
                    </p>

                    <div style="overflow-x: auto;">
                        <table class="table" style="width: 100%; font-size: 0.88rem; border-collapse: collapse; margin-bottom: 14px;">
                            <thead>
                                <tr style="background: rgba(255,255,255,0.03); text-align: left; border-bottom: 1.5px solid var(--border-color);">
                                    <th style="padding: 10px 12px;">Cancellation Window</th>
                                    <th style="padding: 10px 12px;">Refund Percentage</th>
                                    <th style="padding: 10px 12px;">Deductions / Notes</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr style="border-bottom: 1px solid var(--border-color);">
                                    <td style="padding: 10px 12px; font-weight: 600;">More than 60 minutes before start time</td>
                                    <td style="padding: 10px 12px; color: var(--color-accent); font-weight: 700;">100% Full Refund</td>
                                    <td style="padding: 10px 12px;">Zero cancellation fee. Entire prepaid amount is refunded to original source.</td>
                                </tr>
                                <tr style="border-bottom: 1px solid var(--border-color);">
                                    <td style="padding: 10px 12px; font-weight: 600;">Between 15 to 60 minutes before start time</td>
                                    <td style="padding: 10px 12px; font-weight: 700;">85% Partial Refund</td>
                                    <td style="padding: 10px 12px;">15% reservation holding fee retained to offset demand allocation costs.</td>
                                </tr>
                                <tr style="border-bottom: 1px solid var(--border-color);">
                                    <td style="padding: 10px 12px; font-weight: 600;">Less than 15 minutes before start time</td>
                                    <td style="padding: 10px 12px; font-weight: 700;">50% Partial Refund</td>
                                    <td style="padding: 10px 12px;">50% holding fee retained due to short-notice bay immobilization.</td>
                                </tr>
                                <tr style="border-bottom: 1px solid var(--border-color);">
                                    <td style="padding: 10px 12px; font-weight: 600;">Post slot commencement / Active Session</td>
                                    <td style="padding: 10px 12px; color: #ef4444; font-weight: 700;">No Refund (0%)</td>
                                    <td style="padding: 10px 12px;">Once a session has commenced, bay is fully reserved and non-refundable.</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </section>

                <section style="margin-bottom: 26px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        3. The 15–20 Minute Arrival Grace Period &amp; Auto-Cancellation
                    </h2>
                    <div class="alert alert-warning" style="border-left: 4px solid #f59e0b; padding: 14px 18px; margin: 12px 0;">
                        <strong>Important Notice regarding Arrival Timing:</strong>
                        <ul style="margin-top: 8px; margin-bottom: 4px; padding-left: 20px;">
                            <li>A floating grace period of <strong>15 to 20 minutes</strong> from your selected reservation start time is granted to accommodate traffic delays.</li>
                            <li>If your vehicle does not trigger entry check-in via automated ANPR cameras or barrier scanning within this grace period, the reservation is <strong>automatically canceled</strong> to prevent bay blocking.</li>
                            <li>In the event of an automated grace period timeout cancellation, you will receive a <strong>50% refund</strong> to your payment account, and the slot is immediately released to the public queue.</li>
                        </ul>
                    </div>
                </section>

                <section style="margin-bottom: 26px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        4. Facility Unavailability &amp; Service Failure Guarantee
                    </h2>
                    <p>
                        In the rare circumstance that you arrive within the scheduled time and grace period but your allocated bay is inaccessible due to:
                    </p>
                    <ul style="padding-left: 20px; margin: 8px 0;">
                        <li>Unauthorized vehicle occupying your reserved slot;</li>
                        <li>Automated mechanical barrier malfunction or power outage;</li>
                        <li>Emergency facility maintenance or closure;</li>
                    </ul>
                    <p>
                        You are entitled to an **immediate alternative upgrade slot** at no extra fee. If an equivalent bay is unavailable, you will receive an **immediate 100% full refund** plus a 20% discount coupon applied toward your subsequent booking.
                    </p>
                </section>

                <section style="margin-bottom: 26px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        5. Refund Processing Timelines &amp; Methods
                    </h2>
                    <p>
                        All refunds are credited directly back to the payment instrument utilized during initial booking:
                    </p>
                    <ul style="padding-left: 20px; margin: 8px 0;">
                        <li><strong>UPI (Google Pay, PhonePe, Paytm, BHIM):</strong> 24 to 48 hours.</li>
                        <li><strong>Credit / Debit Cards (Visa, Mastercard, RuPay):</strong> 5 to 7 working bank business days.</li>
                        <li><strong>Net Banking:</strong> 3 to 5 working bank business days.</li>
                    </ul>
                    <p style="color: var(--text-muted); font-size: 0.88rem; margin-top: 6px;">
                        <em>Processing turnaround times are governed by Reserve Bank of India (RBI) payment settlement mandates and the customer's acquiring bank.</em>
                    </p>
                </section>

                <section style="margin-bottom: 20px;">
                    <h2 style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary); margin-bottom: 8px;">
                        6. Dispute Escalation &amp; Support Contacts
                    </h2>
                    <p>
                        If your refund has not reflected within 7 business days, or if you believe an erroneous deduction occurred, please raise an inquiry with your booking transaction ID:
                    </p>
                    <div style="background: rgba(255, 255, 255, 0.04); border: 1px solid var(--border-color); border-radius: 8px; padding: 14px 18px; margin-top: 10px; font-size: 0.9rem;">
                        <strong>Billing Support &amp; Dispute Resolution Desk:</strong><br>
                        <strong>Email:</strong> <a href="mailto:billing@smartparkingsystem.in" style="color: var(--color-accent); font-weight: 700;">billing@smartparkingsystem.in</a><br>
                        <strong>Phone:</strong> <a href="tel:+918049001234" style="color: var(--color-accent); font-weight: 700;">+91 80 4900 1234</a> (Toll-Free, 24x7 Support)<br>
                        <strong>Turnaround:</strong> Dispute tickets are acknowledged in under 4 hours and finalized within 48 hours.
                    </div>
                </section>

            </article>

            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
                <a href="<%= request.getContextPath() %>/zones" class="btn btn-secondary btn-sm">&larr; Back to Parking Zones</a>
                <div style="display: flex; gap: 12px;">
                    <a href="<%= request.getContextPath() %>/privacy.jsp" class="btn btn-secondary btn-sm">Privacy Policy</a>
                    <a href="<%= request.getContextPath() %>/terms.jsp" class="btn btn-secondary btn-sm">Terms &amp; Conditions</a>
                    <a href="<%= request.getContextPath() %>/cookies.jsp" class="btn btn-secondary btn-sm">Cookie Policy</a>
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
