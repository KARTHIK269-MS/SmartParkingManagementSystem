<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Booking" %>
<%@ page import="com.parkingsystem.model.Notification" %>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login?msg=auth_required");
        return;
    }
    List<Booking> bookings = (List<Booking>) request.getAttribute("bookings");
    Booking activeBooking = (Booking) request.getAttribute("activeBooking");
    List<Notification> notifications = (List<Notification>) request.getAttribute("notifications");
    Integer unreadCount = (Integer) request.getAttribute("unreadCount");
    if (unreadCount == null) unreadCount = 0;

    String confirmed = request.getParameter("confirmed");
    String paid = request.getParameter("paid");
    String parked = request.getParameter("parked");
    String reserved = request.getParameter("reserved");
    String cancelled = request.getParameter("cancelled");
    String feedbackSuccess = request.getParameter("feedbackSuccess");
    String overtimeChecked = request.getParameter("overtimeChecked");
    String bookingIdParam = request.getParameter("bookingId");
    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Parking Sessions & Permits | Smart Parking System</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <style>
        .ticket-modal {
            display: none;
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(11, 25, 44, 0.7);
            backdrop-filter: blur(4px);
            z-index: 2000;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .ticket-card {
            background: #ffffff;
            border-radius: var(--border-radius-lg);
            width: 100%;
            max-width: 440px;
            overflow: hidden;
            box-shadow: var(--shadow-xl);
            position: relative;
        }

        /* Floating 15-Minute Grace Policy Toast Notification */
        .floating-policy-notification {
            position: fixed;
            bottom: 28px;
            right: 28px;
            max-width: 450px;
            width: calc(100vw - 40px);
            background: linear-gradient(135deg, #fffdf5 0%, #fef3c7 100%);
            border: 2px solid #f59e0b;
            border-radius: 16px;
            box-shadow: 0 20px 45px -10px rgba(180, 83, 9, 0.4), 0 4px 16px rgba(0, 0, 0, 0.08);
            padding: 20px 22px;
            z-index: 99999;
            animation: floatingPolicySlideIn 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
            font-family: inherit;
        }
        @keyframes floatingPolicySlideIn {
            0% {
                opacity: 0;
                transform: translateY(40px) scale(0.95);
            }
            100% {
                opacity: 1;
                transform: translateY(0) scale(1);
            }
        }
        @keyframes floatingPolicySlideOut {
            0% {
                opacity: 1;
                transform: translateY(0) scale(1);
            }
            100% {
                opacity: 0;
                transform: translateY(30px) scale(0.95);
            }
        }
        .floating-policy-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 12px;
        }
        .floating-policy-title-wrap {
            display: flex;
            align-items: flex-start;
            gap: 12px;
        }
        .floating-policy-icon {
            font-size: 1.8rem;
            line-height: 1;
            background: #ffffff;
            border: 1.5px solid #fcd34d;
            border-radius: 50%;
            width: 44px;
            height: 44px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 4px 10px rgba(245, 158, 11, 0.2);
            flex-shrink: 0;
        }
        .floating-policy-title {
            font-weight: 800;
            color: #92400e;
            font-size: 0.98rem;
            line-height: 1.3;
        }
        .floating-policy-close {
            background: transparent;
            border: none;
            color: #b45309;
            font-size: 1.4rem;
            line-height: 1;
            cursor: pointer;
            padding: 2px 6px;
            border-radius: 6px;
            transition: all 0.2s;
        }
        .floating-policy-close:hover {
            background: rgba(180, 83, 9, 0.15);
            color: #78350f;
        }
        .floating-policy-body p {
            color: #78350f;
            font-size: 0.86rem;
            line-height: 1.5;
            margin: 0 0 10px 0;
        }
        .floating-policy-warning {
            background: #ffffff;
            border: 1px solid #fde68a;
            border-radius: 8px;
            padding: 8px 12px;
            font-size: 0.82rem;
            color: #b45309;
            font-weight: 700;
            line-height: 1.4;
            display: flex;
            align-items: flex-start;
            gap: 8px;
            margin-bottom: 14px;
        }
        .floating-policy-footer {
            display: flex;
            justify-content: flex-end;
            align-items: center;
            gap: 10px;
        }
    </style>
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
            <li><a href="<%= request.getContextPath() %>/booking?action=myBookings" class="nav-link active">My Bookings</a></li>
        </ul>
        <div class="nav-actions">
            <!-- Notification Bell -->
            <div class="notif-bell-wrapper" id="notifBellWrapper">
                <button type="button" class="notif-bell-btn" id="notifBellBtn" title="Notifications" onclick="toggleNotifDropdown(event)">
                    🔔
                    <span class="notif-badge" id="notifBadge" style="<%= (unreadCount > 0) ? "" : "display: none;" %>"><%= unreadCount %></span>
                </button>
                <div class="notif-dropdown" id="notifDropdown">
                    <div class="notif-dropdown-header">
                        <strong>Notifications</strong>
                        <button type="button" class="notif-mark-all" onclick="markAllNotifsRead(event)">Mark all as read</button>
                    </div>
                    <div class="notif-list" id="notifList">
                        <% if (notifications != null && !notifications.isEmpty()) { %>
                            <% for (Notification n : notifications) { %>
                                <div class="notif-item <%= !n.isRead() ? "unread" : "" %> <%= "CANCELLATION".equalsIgnoreCase(n.getType()) ? "cancellation" : "" %>" onclick="markNotifRead(<%= n.getNotificationId() %>, this)">
                                    <div class="notif-icon"><%= "CANCELLATION".equalsIgnoreCase(n.getType()) ? "⚠️" : "🔔" %></div>
                                    <div class="notif-content">
                                        <div class="notif-title"><%= n.getTitle() %></div>
                                        <div class="notif-msg"><%= n.getMessage() %></div>
                                        <div class="notif-time"><%= new SimpleDateFormat("dd MMM, hh:mm a").format(n.getCreatedAt()) %></div>
                                    </div>
                                </div>
                            <% } %>
                        <% } else { %>
                            <div class="notif-empty">No notifications yet</div>
                        <% } %>
                    </div>
                </div>
            </div>

            <div class="user-badge">
                <div class="user-avatar"><%= currentUser.getName().substring(0, 1).toUpperCase() %></div>
                <span><%= currentUser.getName() %></span>
            </div>
            <a href="<%= request.getContextPath() %>/login?action=logout" class="btn btn-secondary btn-sm">Sign Out</a>
        </div>
    </nav>

    <!-- Main Container -->
    <main class="container">
        <% if ("true".equals(reserved)) { %>
            <div class="alert alert-success" style="background:#fffbeb; border:1.5px solid #f59e0b; color:#92400e;">
                <span>⏱️</span>
                <div>
                    <strong>Bay Reserved Successfully! Reference #<%= bookingIdParam %>.</strong> Your parking bay is locked exclusively for your scheduled arrival. You have a <strong>15-minute grace window</strong> to arrive at the zone and scan your number plate. If the vehicle does not arrive within 15 minutes past scheduled time, the reservation will be auto-cancelled and a notification sent.
                </div>
            </div>
        <% } %>
        <% if ("true".equals(overtimeChecked)) { %>
            <div class="alert alert-warning" style="background: #fffbeb; border: 1.5px solid #f59e0b; color: #92400e;">
                <span>⚡</span>
                <div>
                    <strong>Overtime Sweep Completed:</strong> Scanned for reservations exceeding the 15-minute grace period. Expired slots have been released and users notified.
                </div>
            </div>
        <% } %>
        <% if ("true".equals(parked)) { %>
            <div class="alert alert-success">
                <span>📡</span>
                <div>
                    <strong>Vehicle Parked & Sensor Active!</strong> Bay allocated. The IoT sensor has scanned your plate and your live parking timer is running from <strong>0hr 0min 0sec</strong>. Total bill will be calculated when you leave the bay.
                </div>
            </div>
        <% } else if ("true".equals(paid)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>
                    <strong>Payment Completed Successfully!</strong> Reference #<%= bookingIdParam %>. Parking bay released back to public availability in IoT sensor network. Your digital exit pass is ready below.
                </div>
            </div>
        <% } else if ("true".equals(confirmed)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>
                    <strong>Booking Confirmed Successfully!</strong> Reference #<%= bookingIdParam %>. Your bay is secured.
                </div>
            </div>
        <% } else if ("true".equals(cancelled)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>Your reservation was cancelled and the parking bay was released back to public availability.</div>
            </div>
        <% } else if ("true".equals(feedbackSuccess)) { %>
            <div class="alert alert-success">
                <span>⭐</span>
                <div>Thank you for your rating and feedback! Your review helps improve urban mobility.</div>
            </div>
        <% } %>

        <!-- Unread Overtime Cancellation Warning Notification Banner -->
        <% if (notifications != null) {
            for (Notification n : notifications) {
                if (!n.isRead() && "CANCELLATION".equalsIgnoreCase(n.getType())) { %>
                    <div class="alert alert-danger" style="background: #fef2f2; border: 1.5px solid #ef4444; color: #991b1b; padding: 16px 20px; border-radius: var(--border-radius-md); margin-bottom: 24px; display: flex; align-items: flex-start; gap: 14px; box-shadow: 0 4px 12px rgba(239, 68, 68, 0.15);">
                        <span style="font-size: 1.8rem; line-height: 1;">⚠️</span>
                        <div style="flex: 1;">
                            <div style="font-weight: 800; font-size: 1.02rem; color: #7f1d1d;"><%= n.getTitle() %></div>
                            <div style="font-size: 0.9rem; margin-top: 4px; color: #991b1b; line-height: 1.4;"><%= n.getMessage() %></div>
                            <div style="font-size: 0.76rem; color: #b91c1c; margin-top: 6px;">Notification: <%= new SimpleDateFormat("dd MMM yyyy, hh:mm a").format(n.getCreatedAt()) %></div>
                        </div>
                        <button type="button" class="btn btn-secondary btn-sm" onclick="markNotifRead(<%= n.getNotificationId() %>, this.parentElement)" style="border-color: #fca5a5; color: #991b1b; font-weight: 700;">Dismiss &times;</button>
                    </div>
        <%      }
            }
        } %>

        <!-- Reserved Booking Card (Awaiting Arrival & ANPR Plate Scan) -->
        <% if (activeBooking != null && activeBooking.isReserved()) { 
            long schedMillis = (activeBooking.getScheduledArrivalTime() != null) ? activeBooking.getScheduledArrivalTime().getTime() : System.currentTimeMillis();
            long graceCutoffMillis = schedMillis + (15 * 60 * 1000L);
            java.util.Date graceCutoffDate = new java.util.Date(graceCutoffMillis);
        %>
            <div class="card" style="border: 2px solid #f59e0b; background: #fffbeb; padding: 28px; margin-bottom: 30px; box-shadow: 0 10px 25px -5px rgba(245, 158, 11, 0.2);">
                <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; border-bottom: 1px solid #fde68a; padding-bottom: 18px; margin-bottom: 20px;">
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <span class="pulse-dot" style="background: #f59e0b; width: 12px; height: 12px;"></span>
                        <span style="font-weight: 800; color: #92400e; letter-spacing: 0.5px; font-size: 0.95rem; text-transform: uppercase;">
                            BAY RESERVED • AWAITING VEHICLE ARRIVAL & PLATE SCAN
                        </span>
                    </div>
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <button type="button" onclick="showFloatingGracePolicy()" class="btn btn-sm btn-secondary" style="border-color: #f59e0b; color: #92400e; background: #ffffff; font-size: 0.78rem; font-weight: 700; padding: 4px 10px; border-radius: 6px; cursor: pointer;">
                            ⏱️ 15m Policy Notice
                        </button>
                        <div style="font-size: 0.85rem; color: #b45309; font-weight: 700;">
                            Reservation Ref #<%= activeBooking.getBookingId() %>
                        </div>
                    </div>
                </div>

                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 18px; align-items: center;">
                    <div>
                        <div style="font-size: 0.75rem; color: #92400e; text-transform: uppercase; font-weight: 700;">Allocated Bay</div>
                        <div style="font-size: 1.55rem; font-weight: 900; color: #b45309;"><%= activeBooking.getSlotId() %></div>
                        <div style="font-size: 0.82rem; color: #78350f;">Zone <%= activeBooking.getZoneId() %> • Held Exclusively</div>
                    </div>

                    <div>
                        <div style="font-size: 0.75rem; color: #92400e; text-transform: uppercase; font-weight: 700;">Authorized Vehicle VRN</div>
                        <div style="font-family: monospace; font-size: 1.15rem; font-weight: 800; background: #ffffff; display: inline-block; padding: 4px 10px; border-radius: 6px; border: 1px solid #fcd34d; color: #0f172a; margin-top: 2px;">
                            <%= activeBooking.getVehicleNumber() %>
                        </div>
                        <div style="font-size: 0.78rem; color: #78350f; margin-top: 4px;">
                            Tariff: ₹ <%= String.format("%.2f", activeBooking.getHourlyRate()) %>/hr
                        </div>
                    </div>

                    <div>
                        <div style="font-size: 0.75rem; color: #92400e; text-transform: uppercase; font-weight: 700;">Scheduled Arrival Time</div>
                        <div style="font-size: 1.2rem; font-weight: 800; color: #92400e;">
                            <%= activeBooking.getScheduledArrivalTime() != null ? sdf.format(activeBooking.getScheduledArrivalTime()) : "Pending" %>
                        </div>
                        <div style="font-size: 0.78rem; color: #b45309; margin-top: 2px;">
                            Cutoff (+15m grace): <%= sdf.format(graceCutoffDate) %>
                        </div>
                    </div>

                    <div>
                        <div style="font-size: 0.75rem; color: #dc2626; text-transform: uppercase; font-weight: 800;">Grace Period Remaining</div>
                        <div id="reservationGraceCountdown" data-cutoff="<%= graceCutoffMillis %>" style="font-family: monospace; font-size: 1.55rem; font-weight: 900; color: #dc2626; letter-spacing: 1px;">
                            --:--
                        </div>
                        <div style="font-size: 0.75rem; color: #991b1b; font-weight: 600;">
                            Auto-cancels if not scanned in
                        </div>
                    </div>
                </div>

                <!-- Number Plate Scanner Check-In Action Section -->
                <div style="margin-top: 24px; padding: 18px 20px; background: #ffffff; border-radius: var(--border-radius-md); border: 1.5px solid #fde68a; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
                    <div style="flex: 1; min-width: 260px;">
                        <div style="font-weight: 800; color: #1e3a8a; font-size: 0.95rem; display: flex; align-items: center; gap: 6px;">
                            <span>📷</span> Arrived at Zone? Scan Vehicle Number Plate to Occupy Bay
                        </div>
                        <div style="font-size: 0.82rem; color: var(--text-muted); margin-top: 4px;">
                            Simulates the bay's ultrasonic sensor reading your plate. Bay switches to <strong>OCCUPIED</strong> and live timer starts from <strong>0hr 0min 0sec</strong>.
                        </div>
                    </div>

                    <form action="<%= request.getContextPath() %>/booking" method="POST" style="margin: 0; display: flex; gap: 8px; align-items: center; flex-wrap: wrap;">
                        <input type="hidden" name="action" value="scanPlateCheckIn">
                        <input type="hidden" name="slotId" value="<%= activeBooking.getSlotId() %>">
                        <input type="text" name="vehicleNumber" value="<%= activeBooking.getVehicleNumber() %>" class="form-control" style="width: 140px; font-family: monospace; font-weight: 800; text-transform: uppercase;" required>
                        <button type="submit" class="btn btn-primary" style="background: #059669; border: none; font-weight: 800; padding: 12px 20px; display: flex; align-items: center; gap: 8px; box-shadow: 0 4px 12px rgba(5, 150, 105, 0.3);">
                            <span>🚗</span> Scan Plate &amp; Check-In &rarr;
                        </button>
                        <a href="<%= request.getContextPath() %>/anpr.jsp" class="btn btn-secondary" style="font-weight: 700; padding: 12px 16px; display: flex; align-items: center; gap: 6px; border-color: #3b82f6; color: #1d4ed8;" title="Open Real-Time ANPR Camera Gate Terminal">
                            <span>📷</span> Open Camera Terminal &rarr;
                        </a>
                    </form>
                </div>

                <!-- Sub Actions: Cancel or Simulate Overtime -->
                <div style="margin-top: 16px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
                    <form action="<%= request.getContextPath() %>/booking" method="POST" style="margin: 0;" onsubmit="return confirm('Cancel reservation for Bay <%= activeBooking.getSlotId() %>? The bay will be released immediately.');">
                        <input type="hidden" name="action" value="cancelReservation">
                        <input type="hidden" name="bookingId" value="<%= activeBooking.getBookingId() %>">
                        <button type="submit" class="btn btn-secondary btn-sm" style="color: #dc2626; border-color: #fca5a5;">
                            &times; Cancel My Reservation
                        </button>
                    </form>

                    <form action="<%= request.getContextPath() %>/booking" method="POST" style="margin: 0;">
                        <input type="hidden" name="action" value="simulateOvertime">
                        <button type="submit" class="btn btn-secondary btn-sm" title="Simulate 15 minutes passing without vehicle arrival to trigger auto-cancellation & notification">
                            ⚡ Fast-Forward: Test 15m Overtime Auto-Cancel
                        </button>
                    </form>
                </div>
            </div>
        <% } %>

        <!-- Active Parking Session Card (Sensor Live Timer) -->
        <% if (activeBooking != null && (activeBooking.isActive() || activeBooking.isPaymentPending())) { %>
            <div class="card" style="border: 2px solid <%= activeBooking.isPaymentPending() ? "#f59e0b" : "#10b981" %>; background: <%= activeBooking.isPaymentPending() ? "#fffbeb" : "#f0fdf4" %>; padding: 28px; margin-bottom: 30px; box-shadow: 0 10px 25px -5px rgba(16, 185, 129, 0.15);">
                <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; border-bottom: 1px solid <%= activeBooking.isPaymentPending() ? "#fde68a" : "#bbf7d0" %>; padding-bottom: 18px; margin-bottom: 20px;">
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <span class="pulse-dot" style="background: <%= activeBooking.isPaymentPending() ? "#d97706" : "#059669" %>; width: 12px; height: 12px;"></span>
                        <span style="font-weight: 800; color: <%= activeBooking.isPaymentPending() ? "#92400e" : "#065f46" %>; letter-spacing: 0.5px; font-size: 0.95rem; text-transform: uppercase;">
                            <%= activeBooking.isPaymentPending() ? "VEHICLE SCANNED OUT • PAYMENT PENDING" : "LIVE IOT SENSOR ACTIVE • VEHICLE PARKED" %>
                        </span>
                    </div>
                    <div style="font-size: 0.85rem; color: <%= activeBooking.isPaymentPending() ? "#b45309" : "#047857" %>; font-weight: 700;">
                        Session Ref #<%= activeBooking.getBookingId() %>
                    </div>
                </div>

                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 18px; align-items: center;">
                    <div>
                        <div style="font-size: 0.75rem; color: #047857; text-transform: uppercase; font-weight: 700;">Bay & Zone</div>
                        <div style="font-size: 1.45rem; font-weight: 900; color: #065f46;"><%= activeBooking.getSlotId() %></div>
                        <div style="font-size: 0.82rem; color: #047857;">Zone <%= activeBooking.getZoneId() %> • Level 1</div>
                    </div>

                    <div>
                        <div style="font-size: 0.75rem; color: #047857; text-transform: uppercase; font-weight: 700;">Vehicle Registration</div>
                        <div style="font-family: monospace; font-size: 1.15rem; font-weight: 800; background: #ffffff; display: inline-block; padding: 4px 10px; border-radius: 6px; border: 1px solid #86efac; color: #0f172a; margin-top: 2px;">
                            <%= activeBooking.getVehicleNumber() %>
                        </div>
                        <div style="font-size: 0.78rem; color: #047857; margin-top: 4px;">
                            Parked: <%= activeBooking.getEntryTime() != null ? sdf.format(activeBooking.getEntryTime()) : "Recent" %>
                        </div>
                    </div>

                    <div>
                        <%
                            long initElapsedSec = activeBooking.getElapsedSeconds();
                            long initH = initElapsedSec / 3600;
                            long initM = (initElapsedSec % 3600) / 60;
                            long initS = initElapsedSec % 60;
                            String initDigitalClock = String.format("%02d:%02d:%02d", initH, initM, initS);
                        %>
                        <div style="font-size: 0.75rem; color: #047857; text-transform: uppercase; font-weight: 700;">Live Parked Duration</div>
                        <div id="liveStopwatch" class="hud-digits" style="font-family: monospace; font-size: 1.75rem; font-weight: 900; color: #0369a1; letter-spacing: 1.5px; text-shadow: 0 0 12px rgba(6, 182, 212, 0.4);">
                            <%= initDigitalClock %>
                        </div>
                        <div id="liveFormattedTime" style="font-size: 0.82rem; color: #0284c7; font-weight: 700;">
                            <%= activeBooking.getFormattedElapsed() %>
                        </div>
                    </div>

                    <div>
                        <div style="font-size: 0.75rem; color: #047857; text-transform: uppercase; font-weight: 700;">
                            <%= activeBooking.isPaymentPending() ? "Total Final Bill" : "Current Accrued Bill" %>
                        </div>
                        <div id="liveAccruedBill" style="font-size: 1.7rem; font-weight: 900; color: #065f46;">
                            ₹ <%= String.format("%.2f", activeBooking.isPaymentPending() ? activeBooking.getTotalAmount() : activeBooking.getLiveEstimatedAmount(activeBooking.getHourlyRate())) %>
                        </div>
                        <div id="liveTariffText" style="font-size: 0.78rem; color: #047857; display: flex; align-items: center; gap: 4px;">
                            Tariff: ₹ <%= String.format("%.2f", activeBooking.getHourlyRate()) %>/hr
                        </div>
                    </div>
                </div>

                <div style="margin-top: 24px; padding-top: 18px; border-top: 1px solid <%= activeBooking.isPaymentPending() ? "#fde68a" : "#bbf7d0" %>; display: flex; justify-content: flex-end; gap: 12px; align-items: center; flex-wrap: wrap;">
                    <% if (activeBooking.isActive()) { %>
                        <div style="font-size: 0.85rem; color: #047857; margin-right: auto; display: flex; align-items: center; gap: 6px;">
                            <span>📡</span> <strong>Sensor Meter Active:</strong> Timing started from 0hr 0min 0sec. Total bill is computed upon vehicle exit.
                        </div>
                        <form action="<%= request.getContextPath() %>/booking" method="POST" style="margin: 0;"
                              onsubmit="return confirm('Vehicle departure: Scan out vehicle and calculate final parking bill?');">
                            <input type="hidden" name="action" value="leaveAndPay">
                            <input type="hidden" name="bookingId" value="<%= activeBooking.getBookingId() %>">
                            <button type="submit" class="btn btn-warning" style="background: #f59e0b; color: #0f172a; font-weight: 800; padding: 12px 24px; font-size: 1rem; border: none; box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3); display: flex; align-items: center; gap: 8px;">
                                <span>🚗</span> Vehicle Leaving &rarr; Scan Out & Pay Bill
                            </button>
                        </form>
                    <% } else if (activeBooking.isPaymentPending()) { %>
                        <div style="font-size: 0.85rem; color: #b45309; font-weight: 700; margin-right: auto;">
                            ⚠️ Vehicle scanned out. Pay total calculated bill to release bay and get exit pass.
                        </div>
                        <a href="<%= request.getContextPath() %>/booking?action=payment&bookingId=<%= activeBooking.getBookingId() %>" 
                           class="btn btn-primary" style="font-weight: 800; padding: 12px 24px; font-size: 1rem;">
                            💳 Pay Accrued Bill (₹ <%= String.format("%.2f", activeBooking.getTotalAmount()) %>) &rarr;
                        </a>
                    <% } %>
                </div>
            </div>
        <% } %>

        <div class="section-header">
            <div>
                <h2 class="section-title">Parking History & Permits</h2>
                <p class="section-subtitle">Track your parking sessions, view digital e-tickets, and submit ratings</p>
            </div>
            <div>
                <a href="<%= request.getContextPath() %>/zones" class="btn btn-primary btn-sm">
                    + Park in Another Bay
                </a>
            </div>
        </div>

        <% if (bookings == null || bookings.isEmpty()) { %>
            <div class="card" style="text-align: center; padding: 60px 20px;">
                <div style="font-size: 3rem; margin-bottom: 12px;">🚗</div>
                <h3 style="font-size: 1.3rem; font-weight: 700; color: var(--color-primary);">No Reservations Found</h3>
                <p style="color: var(--text-muted); margin-top: 6px; margin-bottom: 24px;">You haven't parked in any bays yet.</p>
                <a href="<%= request.getContextPath() %>/zones" class="btn btn-primary">Find Available Parking Bays &rarr;</a>
            </div>
        <% } else { %>
            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-responsive">
                    <table class="custom-table">
                        <thead>
                            <tr>
                                <th>Ref #</th>
                                <th>Bay & Zone</th>
                                <th>Vehicle Plate</th>
                                <th>Entry Time</th>
                                <th>Exit Time</th>
                                <th>Duration</th>
                                <th>Total Bill</th>
                                <th>Status</th>
                                <th style="text-align: right;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Booking b : bookings) { 
                                String statusBadge = "badge-secondary";
                                if (b.isConfirmed() || b.isCompleted()) statusBadge = "badge-success";
                                else if (b.isActive()) statusBadge = "badge-success";
                                else if (b.isCancelled()) statusBadge = "badge-danger";
                                else if (b.isPending() || b.isPaymentPending()) statusBadge = "badge-warning";
                            %>
                                <tr>
                                    <td><strong>#<%= b.getBookingId() %></strong></td>
                                    <td>
                                        <span style="font-weight: 800; color: var(--color-primary); font-size: 1.05rem;">
                                            <%= b.getSlotId() %>
                                        </span>
                                        <span style="color: var(--text-muted); font-size: 0.8rem; display: block;">
                                            Zone <%= b.getZoneId() != null ? b.getZoneId() : "A" %>
                                        </span>
                                    </td>
                                    <td>
                                        <span style="font-family: monospace; font-weight: 700; background: var(--bg-card-alt); padding: 2px 6px; border-radius: 4px; border: 1px solid var(--border-color);">
                                            <%= b.getVehicleNumber() %>
                                        </span>
                                    </td>
                                    <td>
                                        <%= b.getEntryTime() != null ? sdf.format(b.getEntryTime()) : (b.getScheduledArrivalTime() != null ? ("<span style='color:#b45309;font-weight:600;'>Sched: " + sdf.format(b.getScheduledArrivalTime()) + "</span>") : (b.getBookingTime() != null ? sdf.format(b.getBookingTime()) : "Recent")) %>
                                    </td>
                                    <td>
                                        <%= b.getExitTime() != null ? sdf.format(b.getExitTime()) : (b.isActive() ? "<span style='color:#059669; font-weight:700;'>Currently Parked</span>" : (b.isReserved() ? "<span style='color:#b45309;'>Awaiting Arrival</span>" : "-")) %>
                                    </td>
                                    <td>
                                        <% if (b.isActive()) { %>
                                            <span style="color: #059669; font-weight: 700;">Live Timer</span>
                                        <% } else if (b.isReserved()) { %>
                                            <span style="color: #b45309; font-weight: 600;">15m Grace</span>
                                        <% } else { %>
                                            <%= b.getDurationHours() > 0 ? b.getDurationHours() + " Hours" : "1 Hour" %>
                                        <% } %>
                                    </td>
                                    <td>
                                        <% if (b.isActive()) { %>
                                            <span style="color: #047857; font-weight: 700;">Billed on exit</span>
                                        <% } else if (b.isReserved()) { %>
                                            <span style="color: #b45309; font-weight: 600;">₹ <%= String.format("%.2f", b.getHourlyRate()) %>/hr</span>
                                        <% } else { %>
                                            <strong>₹ <%= String.format("%.2f", b.getTotalAmount()) %></strong>
                                        <% } %>
                                    </td>
                                    <td>
                                        <% if (b.isActive()) { %>
                                            <span class="badge badge-success" style="background:#059669; color:#fff; display:inline-flex; align-items:center; gap:5px;">
                                                <span class="pulse-dot" style="width:6px; height:6px; background:#fff;"></span> Parked (Live)
                                            </span>
                                        <% } else if (b.isReserved()) { %>
                                            <span class="badge badge-warning" style="background:#f59e0b; color:#fff;">⏱️ Reserved</span>
                                        <% } else if (b.isPaymentPending()) { %>
                                            <span class="badge badge-warning">Bill Ready</span>
                                        <% } else if (b.isCancelled()) { %>
                                            <span class="badge badge-danger">Cancelled</span>
                                            <% if (b.getCancellationReason() != null && !b.getCancellationReason().trim().isEmpty()) { %>
                                                <div style="font-size: 0.72rem; color: #dc2626; margin-top: 3px; max-width: 150px; line-height: 1.2;">
                                                    <%= b.getCancellationReason() %>
                                                </div>
                                            <% } %>
                                        <% } else { %>
                                            <span class="badge <%= statusBadge %>"><%= b.getStatus() %></span>
                                        <% } %>
                                    </td>
                                    <td style="text-align: right;">
                                        <div style="display: inline-flex; gap: 8px; justify-content: flex-end;">
                                            <% if (b.isActive()) { %>
                                                <form action="<%= request.getContextPath() %>/booking" method="POST" style="display: inline;" 
                                                      onsubmit="return confirm('Vehicle departure: Scan out vehicle and calculate final parking bill?');">
                                                    <input type="hidden" name="action" value="leaveAndPay">
                                                    <input type="hidden" name="bookingId" value="<%= b.getBookingId() %>">
                                                    <button type="submit" class="btn btn-warning btn-sm" style="background:#f59e0b; color:#0f172a; font-weight:700; border:none;">
                                                        Scan Out & Pay
                                                    </button>
                                                </form>
                                            <% } else if (b.isReserved()) { %>
                                                <form action="<%= request.getContextPath() %>/booking" method="POST" style="display: inline;">
                                                    <input type="hidden" name="action" value="scanPlateCheckIn">
                                                    <input type="hidden" name="slotId" value="<%= b.getSlotId() %>">
                                                    <input type="hidden" name="vehicleNumber" value="<%= b.getVehicleNumber() %>">
                                                    <button type="submit" class="btn btn-sm" style="background:#059669; color:#fff; font-weight:700; border:none;" title="Scan plate upon bay arrival">
                                                        🚗 Scan In
                                                    </button>
                                                </form>
                                                <form action="<%= request.getContextPath() %>/booking" method="POST" style="display: inline;" 
                                                      onsubmit="return confirm('Cancel reservation for bay <%= b.getSlotId() %>?');">
                                                    <input type="hidden" name="action" value="cancelReservation">
                                                    <input type="hidden" name="bookingId" value="<%= b.getBookingId() %>">
                                                    <button type="submit" class="btn btn-secondary btn-sm" style="color:#dc2626; border-color:#fca5a5;">
                                                        Cancel
                                                    </button>
                                                </form>
                                            <% } else if (b.isPaymentPending() || b.isPending()) { %>
                                                <a href="<%= request.getContextPath() %>/booking?action=payment&bookingId=<%= b.getBookingId() %>" 
                                                   class="btn btn-primary btn-sm">
                                                    Pay Bill
                                                </a>
                                            <% } else if (b.isCompleted() || b.isConfirmed()) { %>
                                                <button class="btn btn-dark btn-sm" 
                                                        onclick="openTicketModal('<%= b.getBookingId() %>', '<%= b.getSlotId() %>', '<%= b.getZoneId() %>', '<%= b.getVehicleNumber() %>', '<%= b.getDurationHours() > 0 ? b.getDurationHours() : 1 %>', '<%= String.format("%.2f", b.getTotalAmount()) %>', '<%= b.getEntryTime() != null ? sdf.format(b.getEntryTime()) : (b.getBookingTime() != null ? sdf.format(b.getBookingTime()) : "") %>', '<%= b.getPaymentId() != null ? b.getPaymentId() : "TXN_MOCK" %>')">
                                                    Pass & Receipt
                                                </button>

                                                <% if (!b.isFeedbackGiven()) { %>
                                                    <a href="<%= request.getContextPath() %>/booking?action=feedback&bookingId=<%= b.getBookingId() %>" 
                                                       class="btn btn-secondary btn-sm" style="color: #d97706;">
                                                        ★ Rate
                                                    </a>
                                                <% } %>
                                            <% } else { %>
                                                <span style="color: var(--text-muted); font-size: 0.8rem;">Cancelled</span>
                                            <% } %>
                                        </div>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        <% } %>
    </main>

    <!-- Floating 15-Minute Grace Arrival Policy Notification (Shown After Booking) -->
    <% if ("true".equals(reserved) || (activeBooking != null && activeBooking.isReserved())) { %>
    <div id="floatingGracePolicyNotification" class="floating-policy-notification" role="alert" aria-live="assertive">
        <div class="floating-policy-header">
            <div class="floating-policy-title-wrap">
                <div class="floating-policy-icon">⏱️</div>
                <div>
                    <div class="floating-policy-title">15-Minute Grace Arrival &amp; Auto-Cancellation Policy</div>
                    <div style="font-size: 0.75rem; color: #b45309; font-weight: 700; margin-top: 2px;">
                        <%= (activeBooking != null) ? "Bay " + activeBooking.getSlotId() + " Reserved Exclusively" : "Parking Bay Reserved" %>
                    </div>
                </div>
            </div>
            <button type="button" class="floating-policy-close" onclick="dismissFloatingGracePolicy()" title="Dismiss">&times;</button>
        </div>
        <div class="floating-policy-body">
            <p>
                When you reserve this bay, it is locked exclusively for your vehicle. You have up to <strong>15 minutes</strong> after your scheduled arrival time to reach the zone and scan your number plate.
            </p>
            <div class="floating-policy-warning">
                <span style="font-size: 1.1rem; line-height: 1;">⚠️</span>
                <span>If vehicle does not arrive within 15 minutes, reservation will be auto-cancelled to free the bay, and a notification will be sent.</span>
            </div>
        </div>
        <div class="floating-policy-footer">
            <button type="button" onclick="dismissFloatingGracePolicy()" class="btn btn-sm" style="background: #b45309; color: #ffffff; border: none; font-weight: 700; border-radius: 8px; padding: 7px 16px; font-size: 0.82rem; cursor: pointer; display: flex; align-items: center; gap: 6px; box-shadow: 0 2px 6px rgba(180, 83, 9, 0.25);">
                <span>✓</span> Got It / Understood
            </button>
        </div>
    </div>
    <% } %>

    <!-- Digital E-Ticket Pass Modal -->
    <div id="ticketModal" class="ticket-modal">
        <div class="ticket-card printable-ticket">
            <!-- Ticket Header -->
            <div style="background: var(--color-primary); color: #ffffff; padding: 20px; text-align: center;">
                <div class="brand-icon" style="margin: 0 auto 8px; width: 32px; height: 32px; font-size: 1rem;">P</div>
                <h3 style="font-size: 1.15rem; font-weight: 800; letter-spacing: -0.5px;">SMART PARKING PASS</h3>
                <div style="font-size: 0.75rem; color: var(--color-accent); text-transform: uppercase; letter-spacing: 1px;">Digital Contactless Permit & Receipt</div>
            </div>

            <!-- Ticket Body -->
            <div style="padding: 24px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; border-bottom: 1px dashed var(--border-color); padding-bottom: 12px;">
                    <div>
                        <span style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase;">Permit Reference</span>
                        <div style="font-size: 1.1rem; font-weight: 800;" id="modalTicketRef">--</div>
                    </div>
                    <div style="text-align: right;">
                        <span style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase;">Allocated Bay</span>
                        <div style="font-size: 1.5rem; font-weight: 900; color: var(--color-accent);" id="modalTicketBay">--</div>
                    </div>
                </div>

                <div style="margin-bottom: 12px; font-size: 0.88rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Vehicle VRN:</span>
                    <strong style="font-family: monospace;" id="modalTicketVRN">--</strong>
                </div>

                <div style="margin-bottom: 12px; font-size: 0.88rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Parking Zone:</span>
                    <strong id="modalTicketZone">--</strong>
                </div>

                <div style="margin-bottom: 12px; font-size: 0.88rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Parked Duration:</span>
                    <span id="modalTicketDuration">--</span>
                </div>

                <div style="margin-bottom: 12px; font-size: 0.88rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Check-in Time:</span>
                    <span id="modalTicketTime">--</span>
                </div>

                <div style="margin-bottom: 16px; font-size: 0.88rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Transaction Ref:</span>
                    <span style="font-family: monospace; font-size: 0.75rem;" id="modalTicketTxn">--</span>
                </div>

                <!-- Barcode Simulation Graphic -->
                <div style="text-align: center; margin-top: 18px; padding-top: 14px; border-top: 1px dashed var(--border-color);">
                    <div style="display: flex; justify-content: center; gap: 3px; height: 38px; align-items: flex-end; margin-bottom: 6px;">
                        <% for (int i = 0; i < 35; i++) { 
                            int w = (i % 3 == 0) ? 4 : ((i % 2 == 0) ? 2 : 1);
                        %>
                            <div style="background: #0f172a; width: <%= w %>px; height: 100%;"></div>
                        <% } %>
                    </div>
                    <div style="font-family: monospace; font-size: 0.75rem; color: var(--text-muted);" id="modalTicketBarcode">
                        *PKG-2026-987123*
                    </div>
                </div>
            </div>

            <!-- Ticket Footer Actions -->
            <div class="no-print" style="background: var(--bg-card-alt); padding: 14px 20px; display: flex; justify-content: space-between; gap: 10px;">
                <button type="button" class="btn btn-secondary btn-sm" onclick="closeTicketModal()">Close</button>
                <button type="button" class="btn btn-primary btn-sm" onclick="window.print()">Print Pass</button>
            </div>
        </div>
    </div>

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

    <% if (activeBooking != null && activeBooking.isActive()) { %>
    <script>
        (function() {
            // Base elapsed seconds calculated by the server
            let baseElapsed = <%= activeBooking.getElapsedSeconds() %>;
            const pageLoadTime = Date.now();
            let hourlyRate = <%= activeBooking.getHourlyRate() > 0 ? activeBooking.getHourlyRate() : 30.0 %>;
            const bookingId = <%= activeBooking.getBookingId() %>;
            const stopwatchEl = document.getElementById('liveStopwatch');
            const formattedEl = document.getElementById('liveFormattedTime');
            const accruedEl = document.getElementById('liveAccruedBill');
            const tariffEl = document.getElementById('liveTariffText');

            let serverOffset = 0;

            function updateStopwatch() {
                const secondsSinceLoad = Math.floor((Date.now() - pageLoadTime) / 1000);
                const totalSeconds = Math.max(0, baseElapsed + secondsSinceLoad + serverOffset);

                const hrs = Math.floor(totalSeconds / 3600);
                const mins = Math.floor((totalSeconds % 3600) / 60);
                const secs = totalSeconds % 60;

                const timeStr = String(hrs).padStart(2, '0') + ':' + 
                                String(mins).padStart(2, '0') + ':' + 
                                String(secs).padStart(2, '0');

                if (stopwatchEl) stopwatchEl.textContent = timeStr;
                if (formattedEl) formattedEl.textContent = hrs + 'hr ' + mins + 'min ' + secs + 'sec';

                // Dynamic tariff calculation: ceil(totalSeconds / 3600), minimum 1 hr
                const billableHours = Math.max(1, Math.ceil(totalSeconds / 3600));
                const total = billableHours * hourlyRate;
                if (accruedEl) accruedEl.textContent = '₹ ' + total.toFixed(2);
            }

            // Immediately start ticking every second
            updateStopwatch();
            setInterval(updateStopwatch, 1000);

            // Periodic AJAX sync with server every 10 seconds
            setInterval(async () => {
                try {
                    const res = await fetch('<%= request.getContextPath() %>/booking?action=liveTimer&bookingId=' + bookingId);
                    const data = await res.json();
                    if (data && data.found) {
                        if (data.status !== 'ACTIVE' && data.status !== 'PARKED') {
                            window.location.reload();
                        } else {
                            if (typeof data.elapsedSeconds === 'number') {
                                const currentSecondsSinceLoad = Math.floor((Date.now() - pageLoadTime) / 1000);
                                serverOffset = data.elapsedSeconds - (baseElapsed + currentSecondsSinceLoad);
                            }
                            if (typeof data.hourlyRate === 'number' && data.hourlyRate > 0) {
                                hourlyRate = data.hourlyRate;
                                if (tariffEl) {
                                    if (data.surgeActive) {
                                        tariffEl.innerHTML = 'Tariff: ₹ ' + data.hourlyRate.toFixed(2) + '/hr <span class="badge" style="background:#f59e0b;color:#0b192c;font-size:0.68rem;font-weight:800;padding:2px 6px;border-radius:10px;">⚡ 1.25x SURGE</span>';
                                    } else {
                                        tariffEl.innerHTML = 'Tariff: ₹ ' + data.hourlyRate.toFixed(2) + '/hr';
                                    }
                                }
                            }
                        }
                    }
                } catch (e) {}
            }, 10000);
        })();
    </script>
    <% } %>

    <script>
        // Reservation Grace Period Countdown Timer
        (function() {
            const graceEl = document.getElementById('reservationGraceCountdown');
            if (!graceEl) return;
            const cutoffMillis = parseInt(graceEl.getAttribute('data-cutoff'), 10);
            if (!cutoffMillis) return;

            function updateGrace() {
                const now = Date.now();
                const diffSec = Math.floor((cutoffMillis - now) / 1000);
                if (diffSec <= 0) {
                    graceEl.textContent = 'EXPIRED (00:00)';
                    graceEl.style.color = '#ef4444';
                    setTimeout(() => window.location.reload(), 2500);
                    return;
                }
                const mins = Math.floor(diffSec / 60);
                const secs = diffSec % 60;
                graceEl.textContent = String(mins).padStart(2, '0') + 'm ' + String(secs).padStart(2, '0') + 's';
            }
            updateGrace();
            setInterval(updateGrace, 1000);
        })();

        // Notification Bell dropdown & mark-read functions
        function toggleNotifDropdown(e) {
            e.stopPropagation();
            const dd = document.getElementById('notifDropdown');
            if (dd) dd.classList.toggle('show');
        }

        document.addEventListener('click', function(e) {
            const dd = document.getElementById('notifDropdown');
            const btn = document.getElementById('notifBellBtn');
            if (dd && !dd.contains(e.target) && e.target !== btn) {
                dd.classList.remove('show');
            }
        });

        async function markNotifRead(id, el) {
            try {
                await fetch('<%= request.getContextPath() %>/booking?action=markNotificationRead&id=' + id, { method: 'POST' });
                if (el) {
                    el.classList.remove('unread');
                    if (el.tagName === 'DIV' && el.classList.contains('alert')) {
                        el.style.display = 'none';
                    }
                }
                const badge = document.getElementById('notifBadge');
                if (badge) {
                    let c = parseInt(badge.textContent, 10);
                    if (!isNaN(c) && c > 1) {
                        badge.textContent = c - 1;
                    } else {
                        badge.style.display = 'none';
                    }
                }
            } catch (e) {}
        }

        async function markAllNotifsRead(e) {
            e.stopPropagation();
            try {
                await fetch('<%= request.getContextPath() %>/booking?action=markNotificationRead&id=all', { method: 'POST' });
                const unreadItems = document.querySelectorAll('.notif-item.unread');
                unreadItems.forEach(item => item.classList.remove('unread'));
                const badge = document.getElementById('notifBadge');
                if (badge) badge.style.display = 'none';
            } catch (e) {}
        }

        function openTicketModal(id, bay, zone, vrn, dur, amount, time, txn) {
            document.getElementById('modalTicketRef').textContent = '#' + id;
            document.getElementById('modalTicketBay').textContent = bay;
            document.getElementById('modalTicketZone').textContent = 'Zone ' + zone;
            document.getElementById('modalTicketVRN').textContent = vrn;
            document.getElementById('modalTicketDuration').textContent = dur + ' Hours (₹ ' + amount + ')';
            document.getElementById('modalTicketTime').textContent = time;
            document.getElementById('modalTicketTxn').textContent = txn;
            document.getElementById('modalTicketBarcode').textContent = '*PKG-' + id + '-' + vrn + '*';
            document.getElementById('ticketModal').style.display = 'flex';
        }

        function closeTicketModal() {
            document.getElementById('ticketModal').style.display = 'none';
        }

        window.onclick = function(e) {
            const modal = document.getElementById('ticketModal');
            if (e.target === modal) closeTicketModal();
        }

        function dismissFloatingGracePolicy() {
            const toast = document.getElementById('floatingGracePolicyNotification');
            if (toast) {
                toast.style.animation = 'floatingPolicySlideOut 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards';
                setTimeout(() => {
                    toast.style.display = 'none';
                }, 300);
                try { sessionStorage.setItem('gracePolicyDismissed', 'true'); } catch (e) {}
            }
        }

        function showFloatingGracePolicy() {
            const toast = document.getElementById('floatingGracePolicyNotification');
            if (toast) {
                toast.style.display = 'block';
                toast.style.animation = 'floatingPolicySlideIn 0.35s cubic-bezier(0.16, 1, 0.3, 1) forwards';
            }
        }

        document.addEventListener('DOMContentLoaded', function() {
            const isReservedParam = <%= "true".equals(reserved) ? "true" : "false" %>;
            if (!isReservedParam) {
                try {
                    if (sessionStorage.getItem('gracePolicyDismissed') === 'true') {
                        const toast = document.getElementById('floatingGracePolicyNotification');
                        if (toast) toast.style.display = 'none';
                    }
                } catch (e) {}
            } else {
                try { sessionStorage.removeItem('gracePolicyDismissed'); } catch (e) {}
            }
        });
    </script>
</body>
</html>
