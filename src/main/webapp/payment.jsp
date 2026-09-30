<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Booking" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login?msg=auth_required");
        return;
    }
    Booking pendingBooking = (Booking) request.getAttribute("pendingBooking");
    if (pendingBooking == null) {
        response.sendRedirect(request.getContextPath() + "/zones");
        return;
    }
    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pay on Exit | Smart Parking System</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <script>
        const contextPath = "<%= request.getContextPath() %>";
    </script>
</head>
<body>

    <!-- Navigation Bar -->
    <nav class="navbar">
        <a href="<%= request.getContextPath() %>/zones" class="navbar-brand">
            <div class="brand-icon">P</div>
            <span>SmartParking<span class="brand-tag">SYSTEM</span></span>
        </a>
        <div class="nav-actions">
            <span style="font-size: 0.85rem; color: #94a3b8;">Session Ref #<%= pendingBooking.getBookingId() %></span>
        </div>
    </nav>

    <!-- Main Container -->
    <main class="container" style="max-width: 680px;">
        <div class="card" style="padding: 36px 32px;">

            <!-- 4-Step Animated Parking Journey Stepper -->
            <div class="booking-stepper">
                <div class="step-line"><div class="step-line-progress" style="width: 100%;"></div></div>
                <div class="step-item completed">
                    <div class="step-bubble">✓</div>
                    <div class="step-label">1. Bay Select</div>
                </div>
                <div class="step-item completed">
                    <div class="step-bubble">✓</div>
                    <div class="step-label">2. Check-In</div>
                </div>
                <div class="step-item completed">
                    <div class="step-bubble">✓</div>
                    <div class="step-label">3. Live Meter</div>
                </div>
                <div class="step-item active">
                    <div class="step-bubble">4</div>
                    <div class="step-label">4. Pay & Exit</div>
                </div>
            </div>

            <!-- Sensor Verified Exit Badge -->
            <div style="background: linear-gradient(135deg, #eff6ff 0%, #ecfdf5 100%); border: 1.5px solid #a7f3d0; border-radius: var(--border-radius-md); padding: 18px 20px; margin-bottom: 24px; display: flex; align-items: center; gap: 14px;">
                <div style="font-size: 2rem;">🚗</div>
                <div>
                    <div style="font-weight: 800; color: #065f46; font-size: 1.05rem; display: flex; align-items: center; gap: 8px;">
                        Vehicle Departure Scanned by Exit Sensor
                        <span class="badge badge-success" style="font-size: 0.72rem; padding: 2px 8px;">VERIFIED</span>
                    </div>
                    <div style="font-size: 0.84rem; color: #047857; margin-top: 3px;">
                        The IoT sensor recorded your departure. Final bill has been calculated based on your total parked time.
                    </div>
                </div>
            </div>

            <div style="margin-bottom: 20px;">
                <h2 style="font-size: 1.6rem; font-weight: 800; color: var(--color-primary);">Pay-on-Exit Checkout</h2>
                <p style="color: var(--text-muted); font-size: 0.9rem; margin-top: 4px;">Confirm payment to generate your exit clearance pass and release the bay</p>
            </div>

            <!-- Booking Breakdown Receipt -->
            <div style="background: var(--bg-card-alt); border-radius: var(--border-radius-md); padding: 20px; margin-bottom: 28px; border: 1px solid var(--border-color);">
                <div style="display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 0.9rem;">
                    <span style="color: var(--text-muted);">Session Reference:</span>
                    <strong>#<%= pendingBooking.getBookingId() %></strong>
                </div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 0.9rem;">
                    <span style="color: var(--text-muted);">Allocated Bay:</span>
                    <strong style="color: var(--color-accent); font-size: 1.1rem;"><%= pendingBooking.getSlotId() %></strong>
                </div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 0.9rem;">
                    <span style="color: var(--text-muted);">Vehicle VRN:</span>
                    <span style="font-family: monospace; font-weight: 700; background: #ffffff; padding: 2px 8px; border-radius: 4px; border: 1px solid #cbd5e1;">
                        <%= pendingBooking.getVehicleNumber() %>
                    </span>
                </div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 0.9rem;">
                    <span style="color: var(--text-muted);">Sensor Entry Time:</span>
                    <span><%= pendingBooking.getEntryTime() != null ? sdf.format(pendingBooking.getEntryTime()) : "Earlier today" %></span>
                </div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 0.9rem;">
                    <span style="color: var(--text-muted);">Sensor Exit Time:</span>
                    <span><%= pendingBooking.getExitTime() != null ? sdf.format(pendingBooking.getExitTime()) : "Just now" %></span>
                </div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 10px; font-size: 0.9rem;">
                    <span style="color: var(--text-muted);">Total Parked Duration:</span>
                    <strong><%= pendingBooking.getFormattedElapsed() %> (<%= pendingBooking.getDurationHours() %> hr billed)</strong>
                </div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 12px; font-size: 0.9rem;">
                    <span style="color: var(--text-muted);">Hourly Tariff Rate:</span>
                    <span>₹ <%= String.format("%.0f", pendingBooking.getHourlyRate() > 0 ? pendingBooking.getHourlyRate() : 40.0) %> / hour</span>
                </div>
                <div style="border-top: 1px dashed var(--border-color); padding-top: 14px; display: flex; justify-content: space-between; align-items: baseline;">
                    <div>
                        <span style="font-weight: 800; font-size: 1.1rem; color: var(--color-primary);">Total Amount Payable:</span>
                        <div style="font-size: 0.78rem; color: var(--text-muted);">Includes GST & parking infrastructure levy</div>
                    </div>
                    <span style="font-size: 1.75rem; font-weight: 900; color: #166534;">
                        ₹ <%= String.format("%.2f", pendingBooking.getTotalAmount()) %>
                    </span>
                </div>
            </div>

            <!-- Payment Form -->
            <form action="<%= request.getContextPath() %>/booking" method="POST">
                <input type="hidden" name="action" value="finalizePayment">
                <input type="hidden" name="bookingId" value="<%= pendingBooking.getBookingId() %>">
                <input type="hidden" name="amount" value="<%= pendingBooking.getTotalAmount() %>">

                <div class="form-group">
                    <label class="form-label">Select Payment Method (Mock Gateway)</label>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin-bottom: 16px;">
                        <label style="display: flex; align-items: center; gap: 10px; padding: 12px; border: 1.5px solid var(--border-color); border-radius: var(--border-radius-md); cursor: pointer;">
                            <input type="radio" name="paymentMethod" value="UPI" checked>
                            <div>
                                <div style="font-weight: 700; font-size: 0.92rem;">Instant UPI</div>
                                <div style="font-size: 0.75rem; color: var(--text-muted);">GPay, PhonePe, Paytm</div>
                            </div>
                        </label>
                        <label style="display: flex; align-items: center; gap: 10px; padding: 12px; border: 1.5px solid #93c5fd; background: #eff6ff; border-radius: var(--border-radius-md); cursor: pointer;">
                            <input type="radio" name="paymentMethod" value="FASTag">
                            <div>
                                <div style="font-weight: 800; font-size: 0.92rem; color: #1d4ed8;">⚡ FASTag Contactless</div>
                                <div style="font-size: 0.75rem; color: #3b82f6;">RFID Auto-Clearance</div>
                            </div>
                        </label>
                        <label style="display: flex; align-items: center; gap: 10px; padding: 12px; border: 1.5px solid var(--border-color); border-radius: var(--border-radius-md); cursor: pointer;">
                            <input type="radio" name="paymentMethod" value="CARD">
                            <div>
                                <div style="font-weight: 700; font-size: 0.92rem;">Credit / Debit Card</div>
                                <div style="font-size: 0.75rem; color: var(--text-muted);">Visa, MasterCard, RuPay</div>
                            </div>
                        </label>
                        <label style="display: flex; align-items: center; gap: 10px; padding: 12px; border: 1.5px solid var(--border-color); border-radius: var(--border-radius-md); cursor: pointer;">
                            <input type="radio" name="paymentMethod" value="NET_BANKING">
                            <div>
                                <div style="font-weight: 700; font-size: 0.92rem;">Net Banking</div>
                                <div style="font-size: 0.75rem; color: var(--text-muted);">All Indian Banks</div>
                            </div>
                        </label>
                        <label style="display: flex; align-items: center; gap: 10px; padding: 12px; border: 1.5px solid var(--border-color); border-radius: var(--border-radius-md); cursor: pointer;">
                            <input type="radio" name="paymentMethod" value="WALLET">
                            <div>
                                <div style="font-weight: 700; font-size: 0.92rem;">Mobility Wallet</div>
                                <div style="font-size: 0.75rem; color: var(--text-muted);">One-click express</div>
                            </div>
                        </label>
                    </div>
                </div>

                <!-- Dynamic Method Details -->
                <div id="methodPanelUPI" style="background: #f8fafc; border: 1px solid var(--border-color); border-radius: var(--border-radius-md); padding: 16px; margin-bottom: 24px;">
                    <label class="form-label" style="font-size: 0.85rem;">Virtual Payment Address (VPA / UPI ID)</label>
                    <input type="text" class="form-control" value="<%= currentUser.getEmail().split("@")[0] %>@oksbi" placeholder="user@upi">
                </div>

                <div id="methodPanelFASTag" style="display: none; background: #eff6ff; border: 1.5px solid #bfdbfe; border-radius: var(--border-radius-md); padding: 16px; margin-bottom: 24px;">
                    <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 8px;">
                        <span style="font-size: 1.5rem;">📡</span>
                        <div>
                            <strong style="color: #1e3a8a; font-size: 0.92rem;">NETC / NPCI FASTag RFID Auto-Debit</strong>
                            <div style="font-size: 0.78rem; color: #2563eb;">Linked with VRN: <strong><%= pendingBooking.getVehicleNumber() %></strong></div>
                        </div>
                    </div>
                    <div style="background: #ffffff; border: 1px solid #bfdbfe; border-radius: 6px; padding: 10px; font-size: 0.82rem; color: #1e293b;">
                        ✓ RFID Tag Identifier: <strong>FTG-<%= pendingBooking.getVehicleNumber() %>-NETC</strong> &bull; Exit barrier will auto-open upon confirmation.
                    </div>
                </div>

                <div id="methodPanelCard" style="display: none; background: #f8fafc; border: 1px solid var(--border-color); border-radius: var(--border-radius-md); padding: 16px; margin-bottom: 24px;">
                    <div class="form-group" style="margin-bottom: 12px;">
                        <label class="form-label" style="font-size: 0.85rem;">Card Number</label>
                        <input type="text" class="form-control" value="4532 •••• •••• 8821" placeholder="Card Number">
                    </div>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                        <div>
                            <label class="form-label" style="font-size: 0.85rem;">Expiry (MM/YY)</label>
                            <input type="text" class="form-control" value="08/29">
                        </div>
                        <div>
                            <label class="form-label" style="font-size: 0.85rem;">CVV</label>
                            <input type="password" class="form-control" value="999">
                        </div>
                    </div>
                </div>

                <div id="methodPanelNet" style="display: none; background: #f8fafc; border: 1px solid var(--border-color); border-radius: var(--border-radius-md); padding: 16px; margin-bottom: 24px;">
                    <label class="form-label" style="font-size: 0.85rem;">Select Bank</label>
                    <select class="form-control">
                        <option>State Bank of India (SBI)</option>
                        <option>HDFC Bank</option>
                        <option>ICICI Bank</option>
                        <option>Axis Bank</option>
                    </select>
                </div>

                <div id="methodPanelWallet" style="display: none; background: #f8fafc; border: 1px solid var(--border-color); border-radius: var(--border-radius-md); padding: 16px; margin-bottom: 24px;">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong>Smart Parking Prepaid Balance</strong>
                            <div style="font-size: 0.8rem; color: var(--text-muted);">Instant auto-debit on sensor entry</div>
                        </div>
                        <span class="badge badge-success">₹ 1,500.00 Available</span>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary btn-block" style="font-size: 1.05rem; padding: 14px;">
                    Confirm Mock Payment (₹ <%= String.format("%.2f", pendingBooking.getTotalAmount()) %>) &rarr;
                </button>
            </form>

            <div style="text-align: center; margin-top: 18px;">
                <a href="<%= request.getContextPath() %>/booking?action=myBookings" 
                   style="color: var(--text-muted); font-size: 0.88rem; font-weight: 600;">
                    &larr; Return to My Bookings
                </a>
            </div>
        </div>
    </main>

    <!-- Footer -->
    <footer class="footer">
        <div class="footer-container">
            <div>
                <strong>Smart Parking Management System</strong>
                <div style="font-size: 0.82rem; margin-top: 4px;">Dynamic Web Application powered by Java 17 & Apache Tomcat 9</div>
            </div>
            <div class="footer-sdg">
                <span>🌱</span> Real-Time Smart Urban Mobility
            </div>
        </div>
    </footer>

    <script src="<%= request.getContextPath() %>/resources/js/paymentTimer.js"></script>
</body>
</html>
