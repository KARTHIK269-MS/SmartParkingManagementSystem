<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Booking" %>
<%@ page import="com.parkingsystem.model.Notification" %>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User currentUser = (User) session.getAttribute("driverUser");
    if (currentUser == null) {
        currentUser = (User) session.getAttribute("user");
    }
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
    <meta name="description" content="View active parking sessions, scheduled arrivals, historical receipts, and booking cancellations.">
    <title>SmartParking | My Bookings</title>
    <link rel="icon" type="image/svg+xml" href="<%= request.getContextPath() %>/resources/images/favicon.svg">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <style>
        .ticket-modal {
            display: none;
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(2px);
            z-index: 2000;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .ticket-card {
            background: #ffffff;
            border-radius: var(--border-radius-md);
            width: 100%;
            max-width: 440px;
            overflow: hidden;
            box-shadow: var(--shadow-xl);
            border: 1px solid var(--border-color);
        }

        /* Floating 15-Minute Grace Policy Toast Notification */
        .floating-policy-notification {
            position: fixed;
            bottom: 24px;
            right: 24px;
            max-width: 420px;
            width: calc(100vw - 40px);
            background: #fffbeb;
            border: 1.5px solid #f59e0b;
            border-radius: var(--border-radius-md);
            box-shadow: var(--shadow-lg);
            padding: 18px 20px;
            z-index: 99999;
            font-family: inherit;
        }
        .floating-policy-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 10px;
        }
        .floating-policy-title-wrap {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .floating-policy-icon {
            font-size: 1.3rem;
            line-height: 1;
        }
        .floating-policy-title {
            font-weight: 700;
            color: #92400e;
            font-size: 0.95rem;
        }
        .floating-policy-close {
            background: transparent;
            border: none;
            color: #b45309;
            font-size: 1.3rem;
            line-height: 1;
            cursor: pointer;
            padding: 2px 6px;
            border-radius: 4px;
        }
        .floating-policy-close:hover {
            background: rgba(180, 83, 9, 0.1);
        }
        .floating-policy-body p {
            color: #78350f;
            font-size: 0.85rem;
            line-height: 1.45;
            margin: 0 0 10px 0;
        }
        .floating-policy-warning {
            background: #ffffff;
            border: 1px solid #fde68a;
            border-radius: var(--border-radius-sm);
            padding: 8px 12px;
            font-size: 0.82rem;
            color: #b45309;
            font-weight: 600;
            line-height: 1.4;
            display: flex;
            align-items: flex-start;
            gap: 8px;
            margin-bottom: 12px;
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
            <a href="<%= request.getContextPath() %>/login?action=logout&role=driver" class="btn btn-secondary btn-sm">Sign Out</a>
        </div>
    </nav>

    <!-- Main Container -->
    <main class="container">
        <% if ("true".equals(reserved)) { %>
            <div class="alert alert-warning">
                <span>⏱️</span>
                <div>
                    <strong>Bay Reserved Successfully (Booking #<%= bookingIdParam %>).</strong> Your parking bay is locked for your vehicle. You have a <strong>15–20 minute grace time</strong> to arrive and check in.
                </div>
            </div>
        <% } %>
        <% if ("true".equals(overtimeChecked)) { %>
            <div class="alert alert-warning">
                <span>ℹ️</span>
                <div>
                    <strong>Grace Period Check Completed:</strong> Scanned for unentered reservations exceeding the 15-minute grace period. Expired slots have been released.
                </div>
            </div>
        <% } %>
        <% if ("true".equals(parked)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>
                    <strong>Vehicle Checked In!</strong> Bay allocated. Vehicle arrival confirmed and parking timer is active. Final bill will be calculated upon exit.
                </div>
            </div>
        <% } else if ("true".equals(paid)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>
                    <strong>Payment Completed Successfully (Receipt #<%= bookingIdParam %>).</strong> Parking bay released. Your digital exit pass is ready below.
                </div>
            </div>
        <% } else if ("true".equals(confirmed)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>
                    <strong>Booking Confirmed (Reference #<%= bookingIdParam %>).</strong>
                </div>
            </div>
        <% } else if ("true".equals(cancelled)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>Your reservation was cancelled and the parking bay was released.</div>
            </div>
        <% } else if ("true".equals(feedbackSuccess)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>Thank you for your rating and feedback!</div>
            </div>
        <% } %>

        <!-- Unread Overtime Cancellation Warning Notification Banner -->
        <% if (notifications != null) {
            for (Notification n : notifications) {
                if (!n.isRead() && "CANCELLATION".equalsIgnoreCase(n.getType())) { %>
                    <div class="alert alert-danger" style="margin-bottom: 20px;">
                        <span>⚠️</span>
                        <div style="flex: 1;">
                            <div style="font-weight: 700;"><%= n.getTitle() %></div>
                            <div style="font-size: 0.85rem; margin-top: 2px;"><%= n.getMessage() %></div>
                        </div>
                        <button type="button" class="btn btn-secondary btn-sm" onclick="markNotifRead(<%= n.getNotificationId() %>, this.parentElement)">Dismiss</button>
                    </div>
        <%      }
            }
        } %>

        <!-- Reserved Booking Card (Awaiting Arrival) -->
        <% if (activeBooking != null && activeBooking.isReserved()) { 
            long schedMillis = (activeBooking.getScheduledArrivalTime() != null) ? activeBooking.getScheduledArrivalTime().getTime() : System.currentTimeMillis();
            long graceCutoffMillis = schedMillis + (15 * 60 * 1000L);
            java.util.Date graceCutoffDate = new java.util.Date(graceCutoffMillis);
        %>
            <div class="card" style="border: 1.5px solid #f59e0b; background: #fffbeb; padding: 24px; margin-bottom: 26px;">
                <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; border-bottom: 1px solid #fde68a; padding-bottom: 14px; margin-bottom: 18px;">
                    <div>
                        <span style="font-weight: 700; color: #92400e; font-size: 0.95rem; text-transform: uppercase;">
                            Bay Reserved • Awaiting Arrival
                        </span>
                    </div>
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <button type="button" onclick="showFloatingGracePolicy()" class="btn btn-sm btn-secondary" style="border-color: #f59e0b; color: #92400e; background: #ffffff;">
                            15m Policy
                        </button>
                        <div style="font-size: 0.85rem; color: #b45309; font-weight: 600;">
                            Booking #<%= activeBooking.getBookingId() %>
                        </div>
                    </div>
                </div>

                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 16px; align-items: center;">
                    <div>
                        <div style="font-size: 0.72rem; color: #92400e; text-transform: uppercase; font-weight: 600;">Allocated Bay</div>
                        <div style="font-size: 1.4rem; font-weight: 700; color: #b45309;"><%= activeBooking.getSlotId() %></div>
                        <div style="font-size: 0.8rem; color: #78350f;">Zone <%= activeBooking.getZoneId() %></div>
                    </div>

                    <div>
                        <div style="font-size: 0.72rem; color: #92400e; text-transform: uppercase; font-weight: 600;">Authorized Vehicle</div>
                        <div style="font-family: monospace; font-size: 1.1rem; font-weight: 700; background: #ffffff; display: inline-block; padding: 2px 8px; border-radius: 4px; border: 1px solid #fcd34d; color: #0f172a; margin-top: 2px;">
                            <%= activeBooking.getVehicleNumber() %>
                        </div>
                        <div style="font-size: 0.78rem; color: #78350f; margin-top: 2px;">
                            Tariff: ₹ <%= String.format("%.2f", activeBooking.getHourlyRate()) %>/hr
                        </div>
                    </div>

                    <div>
                        <div style="font-size: 0.72rem; color: #92400e; text-transform: uppercase; font-weight: 600;">Reservation Time</div>
                        <div style="font-size: 1.05rem; font-weight: 700; color: #92400e;">
                            <%= activeBooking.getBookingTime() != null ? sdf.format(activeBooking.getBookingTime()) : "Just now" %>
                        </div>
                        <div style="font-size: 0.78rem; color: #b45309; margin-top: 2px;">
                            Scheduled Arrival: <%= activeBooking.getScheduledArrivalTime() != null ? sdf.format(activeBooking.getScheduledArrivalTime()) : "Pending" %>
                        </div>
                    </div>

                    <div>
                        <div style="font-size: 0.72rem; color: #b45309; text-transform: uppercase; font-weight: 600;">Check-In &amp; Parking Timer</div>
                        <div style="font-size: 1.05rem; font-weight: 700; color: #b45309;">
                            Timer Not Started
                        </div>
                        <div style="font-size: 0.78rem; color: #92400e; margin-top: 2px;">
                            Starts upon ANPR check-in
                        </div>
                    </div>

                    <div>
                        <div style="font-size: 0.72rem; color: #dc2626; text-transform: uppercase; font-weight: 700;">Arrival Grace Cutoff (+15m)</div>
                        <div id="reservationGraceCountdown" data-cutoff="<%= graceCutoffMillis %>" style="font-family: monospace; font-size: 1.4rem; font-weight: 700; color: #dc2626;">
                            --:--
                        </div>
                        <div style="font-size: 0.72rem; color: #991b1b;">
                            Cutoff: <%= sdf.format(graceCutoffDate) %>
                        </div>
                    </div>
                </div>

                <!-- Number Plate Scanner Check-In Action Section -->
                <div style="margin-top: 20px; padding: 16px 18px; background: #ffffff; border-radius: var(--border-radius-sm); border: 1px solid #fde68a; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 14px;">
                    <div style="flex: 1; min-width: 240px;">
                        <div style="font-weight: 700; color: var(--color-primary); font-size: 0.92rem;">
                            Arrived at Zone? Confirm Vehicle Check-In
                        </div>
                        <div style="font-size: 0.8rem; color: var(--text-muted); margin-top: 2px;">
                            Check in your vehicle to occupy the bay and start your parking session.
                        </div>
                    </div>

                    <form action="<%= request.getContextPath() %>/booking" method="POST" style="margin: 0; display: flex; gap: 8px; align-items: center; flex-wrap: wrap;">
                        <input type="hidden" name="action" value="scanPlateCheckIn">
                        <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                        <input type="hidden" name="slotId" value="<%= activeBooking.getSlotId() %>">
                        <input type="text" name="vehicleNumber" value="<%= activeBooking.getVehicleNumber() %>" class="form-control" style="width: 130px; font-family: monospace; font-weight: 700; text-transform: uppercase;" required>
                        <button type="submit" class="btn btn-primary" style="font-weight: 600; padding: 10px 16px;">
                            Check In & Park &rarr;
                        </button>
                        <a href="<%= request.getContextPath() %>/anpr.jsp" class="btn btn-secondary" style="font-weight: 600; padding: 10px 14px;" title="Open Simulated ANPR Camera Terminal">
                            Camera Terminal &rarr;
                        </a>
                    </form>
                </div>

                <!-- Sub Actions: Cancel or Simulate Overtime -->
                <div style="margin-top: 14px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px;">
                    <form action="<%= request.getContextPath() %>/booking" method="POST" style="margin: 0;" onsubmit="return confirm('Cancel reservation for Bay <%= activeBooking.getSlotId() %>? The bay will be released immediately.');">
                        <input type="hidden" name="action" value="cancelReservation">
                        <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                        <input type="hidden" name="bookingId" value="<%= activeBooking.getBookingId() %>">
                        <button type="submit" class="btn btn-secondary btn-sm" style="color: #dc2626; border-color: #fca5a5;">
                            Cancel Reservation
                        </button>
                    </form>

                    <form action="<%= request.getContextPath() %>/booking" method="POST" style="margin: 0;">
                        <input type="hidden" name="action" value="simulateOvertime">
                        <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                        <button type="submit" class="btn btn-secondary btn-sm" title="Simulate 15 minutes passing without vehicle arrival">
                            Simulate 15m Overtime Auto-Cancel
                        </button>
                    </form>
                </div>
            </div>
        <% } %>

        <!-- Active Parking Session Card (Sensor Live Timer) -->
        <% if (activeBooking != null && (activeBooking.isActive() || activeBooking.isPaymentPending())) { %>
            <div class="card" style="border: 1.5px solid <%= activeBooking.isPaymentPending() ? "#f59e0b" : "#10b981" %>; background: <%= activeBooking.isPaymentPending() ? "#fffbeb" : "#f0fdf4" %>; padding: 24px; margin-bottom: 26px;">
                <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; border-bottom: 1px solid <%= activeBooking.isPaymentPending() ? "#fde68a" : "#bbf7d0" %>; padding-bottom: 14px; margin-bottom: 18px;">
                    <div>
                        <span style="font-weight: 700; color: <%= activeBooking.isPaymentPending() ? "#92400e" : "#065f46" %>; font-size: 0.95rem; text-transform: uppercase;">
                            <%= activeBooking.isPaymentPending() ? "Vehicle Departed • Payment Pending" : "Vehicle Parked • Active Session" %>
                        </span>
                    </div>
                    <div style="font-size: 0.85rem; color: <%= activeBooking.isPaymentPending() ? "#b45309" : "#047857" %>; font-weight: 600;">
                        Session #<%= activeBooking.getBookingId() %>
                    </div>
                </div>

                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 16px; align-items: center;">
                    <div>
                        <div style="font-size: 0.72rem; color: #047857; text-transform: uppercase; font-weight: 600;">Bay &amp; Zone</div>
                        <div style="font-size: 1.4rem; font-weight: 700; color: #065f46;"><%= activeBooking.getSlotId() %></div>
                        <div style="font-size: 0.8rem; color: #047857;">Zone <%= activeBooking.getZoneId() %> • Level 1</div>
                    </div>

                    <div>
                        <div style="font-size: 0.72rem; color: #047857; text-transform: uppercase; font-weight: 600;">Vehicle Registration</div>
                        <div style="font-family: monospace; font-size: 1.1rem; font-weight: 700; background: #ffffff; display: inline-block; padding: 2px 8px; border-radius: 4px; border: 1px solid #86efac; color: #0f172a; margin-top: 2px;">
                            <%= activeBooking.getVehicleNumber() %>
                        </div>
                        <div style="font-size: 0.78rem; color: #047857; margin-top: 2px;">
                            Actual Check-In: <strong><%= activeBooking.getEntryTime() != null ? sdf.format(activeBooking.getEntryTime()) : "Recent" %></strong>
                        </div>
                        <% if (activeBooking.getBookingTime() != null) { %>
                            <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 1px;">
                                Reserved: <%= sdf.format(activeBooking.getBookingTime()) %>
                            </div>
                        <% } %>
                    </div>

                    <div>
                        <%
                            long initElapsedSec = activeBooking.getElapsedSeconds();
                            long initH = initElapsedSec / 3600;
                            long initM = (initElapsedSec % 3600) / 60;
                            long initS = initElapsedSec % 60;
                            String initDigitalClock = String.format("%02d:%02d:%02d", initH, initM, initS);
                        %>
                        <div style="font-size: 0.72rem; color: #047857; text-transform: uppercase; font-weight: 600;">Parked Duration</div>
                        <div id="liveStopwatch" style="font-family: monospace; font-size: 1.5rem; font-weight: 700; color: #0369a1; letter-spacing: 1px;">
                            <%= initDigitalClock %>
                        </div>
                        <div id="liveFormattedTime" style="font-size: 0.8rem; color: #0284c7; font-weight: 600;">
                            <%= activeBooking.getFormattedElapsed() %>
                        </div>
                    </div>

                    <div>
                        <div style="font-size: 0.72rem; color: #047857; text-transform: uppercase; font-weight: 600;">
                            <%= activeBooking.isPaymentPending() ? "Final Bill" : "Current Accrued Bill" %>
                        </div>
                        <div id="liveAccruedBill" style="font-size: 1.5rem; font-weight: 700; color: #065f46;">
                            ₹ <%= String.format("%.2f", activeBooking.isPaymentPending() ? activeBooking.getTotalAmount() : activeBooking.getLiveEstimatedAmount(activeBooking.getHourlyRate())) %>
                        </div>
                        <div id="liveTariffText" style="font-size: 0.78rem; color: #047857;">
                            Tariff: ₹ <%= String.format("%.2f", activeBooking.getHourlyRate()) %>/hr
                        </div>
                    </div>
                </div>

                <div style="margin-top: 20px; padding-top: 14px; border-top: 1px solid <%= activeBooking.isPaymentPending() ? "#fde68a" : "#bbf7d0" %>; display: flex; justify-content: flex-end; gap: 10px; align-items: center; flex-wrap: wrap;">
                    <% if (activeBooking.isActive()) { %>
                        <div style="font-size: 0.84rem; color: #047857; margin-right: auto;">
                            Parking timer running. Bill is calculated based on elapsed time.
                        </div>
                        <form action="<%= request.getContextPath() %>/booking" method="POST" style="margin: 0;"
                              onsubmit="return confirm('Vehicle departure: Scan out vehicle and calculate final parking bill?');">
                            <input type="hidden" name="action" value="leaveAndPay">
                            <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                            <input type="hidden" name="bookingId" value="<%= activeBooking.getBookingId() %>">
                            <button type="submit" class="btn btn-warning" style="font-weight: 600; padding: 10px 18px;">
                                Scan Out &amp; Pay Bill &rarr;
                            </button>
                        </form>
                    <% } else if (activeBooking.isPaymentPending()) { %>
                        <div style="font-size: 0.84rem; color: #b45309; font-weight: 600; margin-right: auto;">
                            Vehicle departed. Please pay to release bay and view receipt pass.
                        </div>
                        <a href="<%= request.getContextPath() %>/booking?action=payment&bookingId=<%= activeBooking.getBookingId() %>" 
                           class="btn btn-primary" style="font-weight: 600; padding: 10px 18px;">
                            Pay Bill (₹ <%= String.format("%.2f", activeBooking.getTotalAmount()) %>) &rarr;
                        </a>
                    <% } %>
                </div>
            </div>
        <% } %>

        <div class="section-header">
            <div>
                <h2 class="section-title">Parking History &amp; Permits</h2>
                <p class="section-subtitle">Track your past parking sessions, download passes, and view receipts.</p>
            </div>
            <div>
                <a href="<%= request.getContextPath() %>/zones" class="btn btn-primary btn-sm">
                    + Reserve Another Bay
                </a>
            </div>
        </div>

        <% if (bookings == null || bookings.isEmpty()) { %>
            <div class="card" style="text-align: center; padding: 48px 20px;">
                <h3 style="font-size: 1.2rem; font-weight: 700; color: var(--color-primary);">No Bookings Found</h3>
                <p style="color: var(--text-muted); margin-top: 4px; margin-bottom: 20px;">You haven't reserved any parking bays yet.</p>
                <a href="<%= request.getContextPath() %>/zones" class="btn btn-primary">Find Available Parking Bays &rarr;</a>
            </div>
        <% } else { %>
            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-responsive">
                    <table class="custom-table">
                        <thead>
                            <tr>
                                <th>Ref #</th>
                                <th>Bay &amp; Zone</th>
                                <th>Vehicle Plate</th>
                                <th>Reservation Time</th>
                                <th>Actual Check-In</th>
                                <th>Actual Checkout</th>
                                <th>Total Parking Duration</th>
                                <th class="text-right">Total Bill</th>
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

                                String durationDisplay = "--";
                                if (b.getEntryTime() != null && b.getExitTime() != null) {
                                    long diffSec = Math.max(0, (b.getExitTime().getTime() - b.getEntryTime().getTime()) / 1000);
                                    long h = diffSec / 3600;
                                    long m = (diffSec % 3600) / 60;
                                    if (h > 0) {
                                        durationDisplay = h + "h " + (m > 0 ? (m < 10 ? "0" + m : m) + "m" : "");
                                    } else {
                                        durationDisplay = Math.max(1, m) + "m";
                                    }
                                } else if (b.isActive()) {
                                    durationDisplay = "Active Session";
                                } else if (b.isReserved()) {
                                    durationDisplay = "Timer Not Started";
                                } else if (b.getDurationHours() > 0) {
                                    durationDisplay = b.getDurationHours() + "h";
                                }

                                String resTimeFormatted = b.getBookingTime() != null ? sdf.format(b.getBookingTime()) : "--";
                                String checkinFormatted = b.getEntryTime() != null ? sdf.format(b.getEntryTime()) : (b.isReserved() ? "<span style='color:#b45309; font-weight:600;'>Awaiting Arrival</span>" : "--");
                                String checkoutFormatted = b.getExitTime() != null ? sdf.format(b.getExitTime()) : (b.isActive() ? "<span style='color:#059669; font-weight:600;'>Currently Parked</span>" : (b.isReserved() ? "<span style='color:var(--text-muted);'>Not Checked In</span>" : "--"));
                            %>
                                <tr>
                                    <td><strong>#<%= b.getBookingId() %></strong></td>
                                    <td>
                                        <span style="font-weight: 700; color: var(--color-primary);">
                                            <%= b.getSlotId() %>
                                        </span>
                                        <span style="color: var(--text-muted); font-size: 0.78rem; display: block;">
                                            Zone <%= b.getZoneId() != null ? b.getZoneId() : "A" %>
                                        </span>
                                    </td>
                                    <td>
                                        <span style="font-family: monospace; font-weight: 600; background: var(--bg-card-alt); padding: 2px 6px; border-radius: 4px; border: 1px solid var(--border-color);">
                                            <%= b.getVehicleNumber() %>
                                        </span>
                                    </td>
                                    <td>
                                        <div style="font-size: 0.84rem; font-weight: 600;"><%= resTimeFormatted %></div>
                                        <% if (b.getScheduledArrivalTime() != null) { %>
                                            <div style="font-size: 0.72rem; color: var(--text-muted);">Sched: <%= sdf.format(b.getScheduledArrivalTime()) %></div>
                                        <% } %>
                                    </td>
                                    <td>
                                        <div style="font-size: 0.84rem;"><%= checkinFormatted %></div>
                                    </td>
                                    <td>
                                        <div style="font-size: 0.84rem;"><%= checkoutFormatted %></div>
                                    </td>
                                    <td>
                                        <% if (b.isActive()) { %>
                                            <span style="color:#059669; font-weight: 600;">Active Session</span>
                                        <% } else if (b.isReserved()) { %>
                                            <span style="color:#b45309; font-size: 0.82rem;">Timer Not Started</span>
                                        <% } else { %>
                                            <strong><%= durationDisplay %></strong>
                                        <% } %>
                                    </td>
                                    <td class="text-right tabular-nums">
                                        <% if (b.isActive()) { %>
                                            <span style="color: #047857; font-weight: 600;">Billed on exit</span>
                                        <% } else if (b.isReserved()) { %>
                                            <span style="color: #b45309;">₹ <%= String.format(java.util.Locale.US, "%.2f", b.getHourlyRate()) %>/hr</span>
                                        <% } else { %>
                                            <strong>₹ <%= String.format(java.util.Locale.US, "%.2f", b.getTotalAmount()) %></strong>
                                        <% } %>
                                    </td>
                                    <td>
                                        <% if (b.isActive()) { %>
                                            <span class="badge badge-success">Parked</span>
                                        <% } else if (b.isReserved()) { %>
                                            <span class="badge badge-warning">Reserved</span>
                                        <% } else if (b.isPaymentPending()) { %>
                                            <span class="badge badge-warning">Bill Ready</span>
                                        <% } else if (b.isCancelled()) { %>
                                            <span class="badge badge-danger">Cancelled</span>
                                        <% } else { %>
                                            <span class="badge <%= statusBadge %>"><%= b.getStatus() %></span>
                                        <% } %>
                                    </td>
                                    <td style="text-align: right;">
                                        <div style="display: inline-flex; gap: 6px; justify-content: flex-end;">
                                            <% if (b.isActive()) { %>
                                                <form action="<%= request.getContextPath() %>/booking" method="POST" style="display: inline;" 
                                                      onsubmit="return confirm('Vehicle departure: Scan out vehicle and calculate final parking bill?');">
                                                    <input type="hidden" name="action" value="leaveAndPay">
                                                    <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                                                    <input type="hidden" name="bookingId" value="<%= b.getBookingId() %>">
                                                    <button type="submit" class="btn btn-warning btn-sm">
                                                        Scan Out &amp; Pay
                                                    </button>
                                                </form>
                                            <% } else if (b.isReserved()) { %>
                                                <form action="<%= request.getContextPath() %>/booking" method="POST" style="display: inline;">
                                                    <input type="hidden" name="action" value="scanPlateCheckIn">
                                                    <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                                                    <input type="hidden" name="slotId" value="<%= b.getSlotId() %>">
                                                    <input type="hidden" name="vehicleNumber" value="<%= b.getVehicleNumber() %>">
                                                    <button type="submit" class="btn btn-primary btn-sm" title="Scan plate upon bay arrival">
                                                        Check In
                                                    </button>
                                                </form>
                                                <form action="<%= request.getContextPath() %>/booking" method="POST" style="display: inline;" 
                                                      onsubmit="return confirm('Cancel reservation for bay <%= b.getSlotId() %>?');">
                                                    <input type="hidden" name="action" value="cancelReservation">
                                                    <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
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
                                                        onclick="openTicketModal('<%= b.getBookingId() %>', '<%= b.getSlotId() %>', '<%= b.getZoneId() %>', '<%= b.getVehicleNumber() %>', '<%= durationDisplay %>', '<%= String.format(java.util.Locale.US, "%.2f", b.getTotalAmount()) %>', '<%= b.getBookingTime() != null ? sdf.format(b.getBookingTime()) : "--" %>', '<%= b.getEntryTime() != null ? sdf.format(b.getEntryTime()) : "--" %>', '<%= b.getExitTime() != null ? sdf.format(b.getExitTime()) : "--" %>', '<%= b.getPaymentId() != null ? b.getPaymentId() : "TXN_MOCK" %>')">
                                                    Pass &amp; Receipt
                                                </button>

                                                <% if (!b.isFeedbackGiven()) { %>
                                                    <a href="<%= request.getContextPath() %>/booking?action=feedback&bookingId=<%= b.getBookingId() %>" 
                                                       class="btn btn-secondary btn-sm">
                                                        Rate
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

    <!-- Floating 15-Minute Grace Arrival Policy Notification -->
    <% if ("true".equals(reserved) || (activeBooking != null && activeBooking.isReserved())) { %>
    <div id="floatingGracePolicyNotification" class="floating-policy-notification" role="alert">
        <div class="floating-policy-header">
            <div class="floating-policy-title-wrap">
                <div class="floating-policy-icon">⏱️</div>
                <div>
                    <div class="floating-policy-title">15–20 Minute Grace Period Active</div>
                    <div style="font-size: 0.75rem; color: #b45309; font-weight: 600; margin-top: 1px;">
                        <%= (activeBooking != null) ? "Bay " + activeBooking.getSlotId() + " Reserved" : "Parking Bay Reserved" %>
                    </div>
                </div>
            </div>
            <button type="button" class="floating-policy-close" onclick="dismissFloatingGracePolicy()" title="Dismiss">&times;</button>
        </div>
        <div class="floating-policy-body">
            <p>
                You have <strong>15–20 minutes grace time</strong> to arrive and check in at your reserved parking slot.
            </p>
            <div class="floating-policy-warning">
                <span>⚠️</span>
                <span>If you do not enter within 15–20 minutes, your reservation will be automatically cancelled to release the slot for other drivers.</span>
            </div>
        </div>
        <div class="floating-policy-footer">
            <button type="button" onclick="dismissFloatingGracePolicy()" class="btn btn-sm btn-primary">
                Understood
            </button>
        </div>
    </div>
    <% } %>

    <!-- Digital E-Ticket Pass Modal -->
    <div id="ticketModal" class="ticket-modal">
        <div class="ticket-card printable-ticket">
            <!-- Ticket Header -->
            <div style="background: var(--color-primary); color: #ffffff; padding: 18px; text-align: center;">
                <div class="brand-icon" style="margin: 0 auto 6px; width: 28px; height: 28px; font-size: 0.95rem;">P</div>
                <h3 style="font-size: 1.1rem; font-weight: 700;">Parking Permit &amp; Receipt</h3>
                <div style="font-size: 0.72rem; color: var(--color-accent); text-transform: uppercase;">Smart Parking System</div>
            </div>

            <!-- Ticket Body -->
            <div style="padding: 20px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; border-bottom: 1px dashed var(--border-color); padding-bottom: 10px;">
                    <div>
                        <span style="font-size: 0.72rem; color: var(--text-muted); text-transform: uppercase;">Reference</span>
                        <div style="font-size: 1.05rem; font-weight: 700;" id="modalTicketRef">--</div>
                    </div>
                    <div style="text-align: right;">
                        <span style="font-size: 0.72rem; color: var(--text-muted); text-transform: uppercase;">Allocated Bay</span>
                        <div style="font-size: 1.35rem; font-weight: 700; color: var(--color-accent);" id="modalTicketBay">--</div>
                    </div>
                </div>

                <div style="margin-bottom: 10px; font-size: 0.85rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Vehicle VRN:</span>
                    <strong style="font-family: monospace;" id="modalTicketVRN">--</strong>
                </div>

                <div style="margin-bottom: 10px; font-size: 0.85rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Parking Zone:</span>
                    <strong id="modalTicketZone">--</strong>
                </div>

                <div style="margin-bottom: 10px; font-size: 0.85rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Reservation Time:</span>
                    <span id="modalTicketResTime">--</span>
                </div>

                <div style="margin-bottom: 10px; font-size: 0.85rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Actual Check-in:</span>
                    <span id="modalTicketCheckin">--</span>
                </div>

                <div style="margin-bottom: 10px; font-size: 0.85rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Actual Checkout:</span>
                    <span id="modalTicketCheckout">--</span>
                </div>

                <div style="margin-bottom: 10px; font-size: 0.85rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Total Parked Duration:</span>
                    <strong id="modalTicketDuration">--</strong>
                </div>

                <div style="margin-bottom: 14px; font-size: 0.85rem; display: flex; justify-content: space-between;">
                    <span style="color: var(--text-muted);">Transaction Ref:</span>
                    <span style="font-family: monospace; font-size: 0.75rem;" id="modalTicketTxn">--</span>
                </div>

                <!-- Barcode Simulation Graphic -->
                <div style="text-align: center; margin-top: 14px; padding-top: 12px; border-top: 1px dashed var(--border-color);">
                    <div style="display: flex; justify-content: center; gap: 3px; height: 32px; align-items: flex-end; margin-bottom: 4px;">
                        <% for (int i = 0; i < 35; i++) { 
                            int w = (i % 3 == 0) ? 3 : ((i % 2 == 0) ? 2 : 1);
                        %>
                            <div style="background: #0f172a; width: <%= w %>px; height: 100%;"></div>
                        <% } %>
                    </div>
                    <div style="font-family: monospace; font-size: 0.72rem; color: var(--text-muted);" id="modalTicketBarcode">
                        *PKG-DEMO*
                    </div>
                </div>
            </div>

            <!-- Ticket Footer Actions -->
            <div class="no-print" style="background: var(--bg-card-alt); padding: 12px 18px; display: flex; justify-content: space-between; gap: 10px;">
                <button type="button" class="btn btn-secondary btn-sm" onclick="closeTicketModal()">Close</button>
                <button type="button" class="btn btn-primary btn-sm" onclick="window.print()">Print Pass</button>
            </div>
        </div>
    </div>

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

    <% if (activeBooking != null && activeBooking.isActive()) { %>
    <script>
        (function() {
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

                const billableHours = Math.max(1, Math.ceil(totalSeconds / 3600));
                const total = billableHours * hourlyRate;
                if (accruedEl) accruedEl.textContent = '₹ ' + total.toFixed(2);
            }

            updateStopwatch();
            setInterval(updateStopwatch, 1000);

            // Periodic sync with server
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
                                    tariffEl.textContent = 'Tariff: ₹ ' + data.hourlyRate.toFixed(2) + '/hr';
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

        function openTicketModal(id, bay, zone, vrn, dur, amount, resTime, checkin, checkout, txn) {
            document.getElementById('modalTicketRef').textContent = '#' + id;
            document.getElementById('modalTicketBay').textContent = bay;
            document.getElementById('modalTicketZone').textContent = 'Zone ' + zone;
            document.getElementById('modalTicketVRN').textContent = vrn;
            document.getElementById('modalTicketResTime').textContent = resTime || '--';
            document.getElementById('modalTicketCheckin').textContent = checkin || '--';
            document.getElementById('modalTicketCheckout').textContent = checkout || '--';
            document.getElementById('modalTicketDuration').textContent = dur + ' (₹ ' + amount + ')';
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
                toast.style.display = 'none';
                try { sessionStorage.setItem('gracePolicyDismissed', 'true'); } catch (e) {}
            }
        }

        function showFloatingGracePolicy() {
            const toast = document.getElementById('floatingGracePolicyNotification');
            if (toast) {
                toast.style.display = 'block';
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
    <script src="<%= request.getContextPath() %>/resources/js/cookieConsent.js"></script>
</body>
</html>
