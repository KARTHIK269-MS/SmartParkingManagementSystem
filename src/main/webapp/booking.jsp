<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Zone" %>
<%@ page import="com.parkingsystem.model.Slot" %>
<%
    User currentUser = (User) session.getAttribute("driverUser");
    if (currentUser == null) {
        currentUser = (User) session.getAttribute("user");
    }
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login?msg=auth_required");
        return;
    }
    Slot slot = (Slot) request.getAttribute("slot");
    Zone zone = (Zone) request.getAttribute("zone");
    if (slot == null || zone == null) {
        String reqSlotId = request.getParameter("slotId");
        if (reqSlotId != null && !reqSlotId.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/booking?action=book&slotId=" + reqSlotId);
            return;
        }
        response.sendRedirect(request.getContextPath() + "/zones");
        return;
    }
    String todayDateStr = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    String nowTimeStr = new java.text.SimpleDateFormat("HH:mm").format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Reserve bay <%= slot.getSlotId() %> in <%= zone.getName() %> with guaranteed 15-minute grace period.">
    <title>SmartParking | Reserve Bay <%= slot.getSlotId() %></title>
    <link rel="icon" type="image/svg+xml" href="<%= request.getContextPath() %>/resources/images/favicon.svg">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
</head>
<body>

    <!-- Navigation Bar -->
    <nav class="navbar">
        <a href="<%= request.getContextPath() %>/zones" class="navbar-brand">
            <div class="brand-icon">P</div>
            <span>SmartParking<span class="brand-tag">SYSTEM</span></span>
        </a>
        <ul class="nav-links">
            <li><a href="<%= request.getContextPath() %>/zones" class="nav-link">Parking Zones</a></li>
            <li><a href="<%= request.getContextPath() %>/booking?action=myBookings" class="nav-link">My Bookings</a></li>
        </ul>
        <div class="nav-actions">
            <div class="user-badge">
                <div class="user-avatar"><%= currentUser.getName().substring(0, 1).toUpperCase() %></div>
                <span><%= currentUser.getName() %></span>
            </div>
            <a href="<%= request.getContextPath() %>/login?action=logout&role=driver" class="btn btn-secondary btn-sm">Sign Out</a>
        </div>
    </nav>

    <!-- Main Container -->
    <main class="container" style="max-width: 680px;">
        <div class="card" style="padding: 32px 28px;">
            <!-- 4-Step Parking Journey Stepper -->
            <div class="booking-stepper">
                <div class="step-line"><div class="step-line-progress" style="width: 35%;"></div></div>
                <div class="step-item completed">
                    <div class="step-bubble">✓</div>
                    <div class="step-label">1. Bay Select</div>
                </div>
                <div class="step-item active">
                    <div class="step-bubble">2</div>
                    <div class="step-label">2. Reserve Bay</div>
                </div>
                <div class="step-item">
                    <div class="step-bubble">3</div>
                    <div class="step-label">3. Arrive &amp; Park</div>
                </div>
                <div class="step-item">
                    <div class="step-bubble">4</div>
                    <div class="step-label">4. Pay &amp; Exit</div>
                </div>
            </div>

            <div style="margin-bottom: 20px;">
                <a href="<%= request.getContextPath() %>/zones?action=slots&zone=<%= zone.getZoneId() %>" 
                   style="color: var(--text-muted); font-size: 0.85rem; font-weight: 600; display: inline-flex; align-items: center; gap: 4px; margin-bottom: 8px;">
                    &larr; Back to Bay Selection
                </a>
                <h2 style="font-size: 1.5rem; font-weight: 700; color: var(--color-primary);">Reserve Parking Bay <%= slot.getSlotId() %></h2>
                <p style="color: var(--text-muted); font-size: 0.88rem; margin-top: 4px;">Confirm your vehicle details to reserve your parking bay.</p>
            </div>

            <!-- Booking Summary Banner -->
            <div class="booking-summary-banner">
                <div>
                    <span style="font-size: 0.72rem; color: var(--text-muted); text-transform: uppercase; font-weight: 600;">Parking Bay</span>
                    <div style="font-size: 1.25rem; font-weight: 700; color: var(--color-accent);"><%= slot.getSlotId() %></div>
                    <span style="font-size: 0.75rem; color: var(--text-muted);">Floor Level <%= slot.getFloor() %></span>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: var(--text-muted); text-transform: uppercase; font-weight: 600;">Facility</span>
                    <div style="font-size: 1rem; font-weight: 700; color: var(--color-primary);"><%= zone.getName() %></div>
                    <span style="font-size: 0.75rem; color: var(--text-muted);"><%= slot.getType() %> Bay</span>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: var(--text-muted); text-transform: uppercase; font-weight: 600;">Hourly Tariff</span>
                    <div style="font-size: 1.25rem; font-weight: 700; color: var(--color-primary);">
                        ₹ <%= String.format("%.2f", zone.getEffectiveHourlyRate()) %>
                    </div>
                    <span style="font-size: 0.75rem; color: var(--text-muted);">per hour</span>
                </div>
            </div>

            <!-- Booking Reservation Form -->
            <form id="bookingForm" action="<%= request.getContextPath() %>/booking" method="POST">
                <input type="hidden" name="action" value="reserveSlot">
                <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                <input type="hidden" name="slotId" value="<%= slot.getSlotId() %>">
                <input type="hidden" name="zoneId" value="<%= zone.getZoneId() %>">

                <!-- Select Reservation Date & Arrival Time -->
                <div class="form-group" style="margin-bottom: 20px; background: var(--bg-card-alt); border: 1px solid var(--border-color); border-radius: var(--border-radius-md); padding: 16px 18px;">
                    <label class="form-label" style="margin-bottom: 10px; font-weight: 700; color: var(--color-primary);">
                        Reservation Schedule
                    </label>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 14px;">
                        <div>
                            <label for="bookingDate" style="font-size: 0.82rem; font-weight: 600; color: var(--text-main); display: block; margin-bottom: 4px;">
                                Date:
                            </label>
                            <input type="date" id="bookingDate" name="bookingDate" class="form-control" required min="<%= todayDateStr %>" value="<%= todayDateStr %>">
                        </div>
                        <div>
                            <label for="bookingTime" style="font-size: 0.82rem; font-weight: 600; color: var(--text-main); display: block; margin-bottom: 4px;">
                                Estimated Arrival Time:
                            </label>
                            <input type="time" id="bookingTime" name="bookingTime" class="form-control" required value="<%= nowTimeStr %>">
                        </div>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="vehicleNumber">Vehicle Registration Number (VRN)</label>
                    
                    <!-- Vehicle Registration Plate Preview -->
                    <div class="hsrp-plate-preview">
                        <div class="hsrp-ind-badge">
                            <div class="hsrp-chakra"></div>
                            <span class="hsrp-ind-text">IND</span>
                        </div>
                        <div class="hsrp-vrn-text" id="hsrpVrnPreview">KA 01 AB 1234</div>
                    </div>

                    <input type="text" id="vehicleNumber" name="vehicleNumber" class="form-control" 
                           placeholder="e.g. KA01AB1234" maxlength="10" value="KA01AB1234" required>
                    <small style="color: var(--text-muted); font-size: 0.78rem; margin-top: 4px; display: block;">
                        Used to match your vehicle when entering the parking bay.
                    </small>
                </div>

                <div style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: var(--border-radius-sm); padding: 14px 16px; margin-bottom: 20px; display: flex; align-items: flex-start; gap: 10px;">
                    <span style="font-size: 1.1rem; line-height: 1.2;">ℹ️</span>
                    <div style="font-size: 0.84rem; color: #166534; line-height: 1.45;">
                        <strong>15–20 Minute Grace Period:</strong> Once confirmed, this bay is reserved for your vehicle. You have a <strong>15–20 minute grace period</strong> from your scheduled arrival time to enter the slot, after which unentered reservations are automatically cancelled to keep slots available.
                    </div>
                </div>

                <div class="form-consent-group">
                    <input type="checkbox" id="bookingConsent" name="bookingConsent" required>
                    <label for="bookingConsent">
                        I acknowledge the <strong>15–20 minute arrival grace period rule</strong>, the 
                        <a href="<%= request.getContextPath() %>/refund.jsp" target="_blank">Refund Policy</a>, and accept the 
                        <a href="<%= request.getContextPath() %>/terms.jsp" target="_blank">Terms &amp; Conditions</a>.
                    </label>
                </div>

                <button type="submit" class="btn btn-primary btn-block" style="font-size: 0.95rem; padding: 12px;">
                    Confirm Bay <%= slot.getSlotId() %> Reservation &rarr;
                </button>
            </form>
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

    <script src="<%= request.getContextPath() %>/resources/js/validation.js"></script>
    <script src="<%= request.getContextPath() %>/resources/js/cookieConsent.js"></script>
</body>
</html>
