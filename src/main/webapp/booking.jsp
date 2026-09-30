<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Zone" %>
<%@ page import="com.parkingsystem.model.Slot" %>
<%
    User currentUser = (User) session.getAttribute("user");
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
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reserve Bay <%= slot.getSlotId() %> | Smart Parking</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <style>
        .arrival-preset-btn {
            padding: 9px 12px;
            font-size: 0.82rem;
            font-weight: 600;
            border: 1.5px solid var(--border-color);
            background: #ffffff;
            color: var(--text-main);
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
        }
        .arrival-preset-btn:hover {
            border-color: var(--color-primary);
            background: #f8fafc;
        }
        .arrival-preset-btn.active {
            background: var(--color-primary) !important;
            color: #ffffff !important;
            border-color: var(--color-primary) !important;
            box-shadow: 0 2px 6px rgba(15, 23, 42, 0.15);
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
            <li><a href="<%= request.getContextPath() %>/zones" class="nav-link">Zones</a></li>
            <li><a href="<%= request.getContextPath() %>/booking?action=myBookings" class="nav-link">My Bookings</a></li>
        </ul>
        <div class="nav-actions">
            <div class="user-badge">
                <div class="user-avatar"><%= currentUser.getName().substring(0, 1).toUpperCase() %></div>
                <span><%= currentUser.getName() %></span>
            </div>
            <a href="<%= request.getContextPath() %>/login?action=logout" class="btn btn-secondary btn-sm">Sign Out</a>
        </div>
    </nav>

    <!-- Main Container -->
    <main class="container" style="max-width: 680px;">
        <div class="card" style="padding: 36px 32px;">
            <!-- 4-Step Animated Parking Journey Stepper -->
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
                    <div class="step-label">3. Arrive & Scan</div>
                </div>
                <div class="step-item">
                    <div class="step-bubble">4</div>
                    <div class="step-label">4. Live Meter & Pay</div>
                </div>
            </div>

            <div style="margin-bottom: 24px;">
                <a href="<%= request.getContextPath() %>/zones?action=slots&zone=<%= zone.getZoneId() %>" 
                   style="color: var(--text-muted); font-size: 0.85rem; font-weight: 600; display: inline-flex; align-items: center; gap: 4px; margin-bottom: 8px;">
                    &larr; Back to Bay Selection
                </a>
                <h2 style="font-size: 1.6rem; font-weight: 800; color: var(--color-primary);">Reserve Parking Bay <%= slot.getSlotId() %></h2>
                <p style="color: var(--text-muted); font-size: 0.9rem; margin-top: 4px;">Schedule your arrival time. Your bay will be held exclusively for you.</p>
            </div>

            <!-- Booking Summary Banner -->
            <div style="background: var(--bg-card-alt); border-radius: var(--border-radius-md); padding: 18px 20px; display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 24px; border: 1px solid var(--border-color);">
                <div>
                    <span style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; font-weight: 700;">Parking Bay</span>
                    <div style="font-size: 1.35rem; font-weight: 800; color: var(--color-accent);"><%= slot.getSlotId() %></div>
                    <span style="font-size: 0.75rem; color: var(--text-muted);">Floor Level <%= slot.getFloor() %></span>
                </div>
                <div>
                    <span style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; font-weight: 700;">Zone Facility</span>
                    <div style="font-size: 1.1rem; font-weight: 700; color: var(--color-primary);"><%= zone.getName() %></div>
                    <span style="font-size: 0.75rem; color: var(--text-muted);"><%= slot.getType() %> Bay</span>
                </div>
                <div>
                    <span style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; font-weight: 700;">Hourly Tariff</span>
                    <% if (zone.isRushHour()) { %>
                        <div style="font-size: 1.35rem; font-weight: 800; color: #dc2626;">
                            ₹ 50.00
                        </div>
                        <div style="font-size: 0.72rem; color: #991b1b; font-weight: 700;">
                            ⚡ Rush Hours Active (Base: ₹40)
                        </div>
                    <% } else if (zone.isOffPeak()) { %>
                        <div style="font-size: 1.35rem; font-weight: 800; color: #059669;">
                            ₹ 30.00
                        </div>
                        <div style="font-size: 0.72rem; color: #166534; font-weight: 700;">
                            🏷️ No Rush Saver Active (Base: ₹40)
                        </div>
                    <% } else { %>
                        <div style="font-size: 1.35rem; font-weight: 800; color: var(--color-primary);">₹ 40.00</div>
                        <span style="font-size: 0.75rem; color: var(--text-muted);">per hour (Normal Tariff)</span>
                    <% } %>
                </div>
            </div>

            <% if (zone.isRushHour()) { %>
                <div style="background: #fef2f2; border: 1.5px solid #fecaca; border-radius: var(--border-radius-md); padding: 14px 18px; margin-bottom: 20px; display: flex; align-items: center; gap: 10px;">
                    <span style="font-size: 1.4rem;">⚡</span>
                    <div>
                        <strong style="color: #991b1b; font-size: 0.92rem;">Dynamic Rush Hours Tariff Applied (₹50/hr)</strong>
                        <div style="color: #b91c1c; font-size: 0.82rem; margin-top: 2px;">
                            Due to high live occupancy and fast booking demand in Zone <%= zone.getZoneId() %>, the rate is dynamically adjusted to ₹50.00/hr.
                        </div>
                    </div>
                </div>
            <% } else if (zone.isOffPeak()) { %>
                <div style="background: #f0fdf4; border: 1.5px solid #bbf7d0; border-radius: var(--border-radius-md); padding: 14px 18px; margin-bottom: 20px; display: flex; align-items: center; gap: 10px;">
                    <span style="font-size: 1.4rem;">🏷️</span>
                    <div>
                        <strong style="color: #166534; font-size: 0.92rem;">No Rush Hours Saver Tariff Applied (₹30/hr)</strong>
                        <div style="color: #15803d; font-size: 0.82rem; margin-top: 2px;">
                            Low demand and plenty of open bays in Zone <%= zone.getZoneId() %>! Enjoy our off-peak discounted rate of ₹30.00/hr.
                        </div>
                    </div>
                </div>
            <% } %>

            <!-- Booking Reservation Form -->
            <form id="bookingForm" action="<%= request.getContextPath() %>/booking" method="POST" onsubmit="return validateReservationSchedule(event)">
                <input type="hidden" name="action" value="reserveSlot">
                <input type="hidden" name="slotId" value="<%= slot.getSlotId() %>">
                <input type="hidden" name="zoneId" value="<%= zone.getZoneId() %>">

                <!-- Scheduled Date & Arrival Time Selection -->
                <div class="form-group" style="margin-bottom: 22px; background: var(--bg-card-alt); border: 1px solid var(--border-color); border-radius: var(--border-radius-md); padding: 18px 20px;">
                    <label class="form-label" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                        <span style="font-size: 1rem; font-weight: 800; color: var(--color-primary); display: flex; align-items: center; gap: 6px;">
                            📅 Select Reservation Date & Arrival Time
                        </span>
                        <span style="font-size: 0.78rem; color: var(--color-accent); font-weight: 700;">Exclusive Bay Hold</span>
                    </label>

                    <!-- Quick Preset Shortcuts -->
                    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 16px;">
                        <button type="button" class="btn btn-secondary arrival-preset-btn active" id="btnPreset15m" onclick="applyQuickSchedule('15m')">
                            ⚡ In 15 Mins
                        </button>
                        <button type="button" class="btn btn-secondary arrival-preset-btn" id="btnPreset30m" onclick="applyQuickSchedule('30m')">
                            ⏱️ In 30 Mins
                        </button>
                        <button type="button" class="btn btn-secondary arrival-preset-btn" id="btnPreset1h" onclick="applyQuickSchedule('1h')">
                            🕐 In 1 Hour
                        </button>
                        <button type="button" class="btn btn-secondary arrival-preset-btn" id="btnPresetTomorrow" onclick="applyQuickSchedule('tomorrow')">
                            🌅 Tomorrow Morning
                        </button>
                    </div>

                    <!-- Paired Date & Time Inputs -->
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                        <div>
                            <label for="bookingDate" style="font-size: 0.85rem; font-weight: 700; color: var(--text-main); display: block; margin-bottom: 6px;">
                                📅 Parking Date:
                            </label>
                            <input type="date" id="bookingDate" name="bookingDate" class="form-control" required min="<%= todayDateStr %>" onchange="onCustomDateTimeChange()">
                            <small style="color: var(--text-muted); font-size: 0.76rem; margin-top: 4px; display: block;">Select today or any upcoming date.</small>
                        </div>
                        <div>
                            <label for="bookingTime" style="font-size: 0.85rem; font-weight: 700; color: var(--text-main); display: block; margin-bottom: 6px;">
                                ⏰ Scheduled Arrival Time:
                            </label>
                            <input type="time" id="bookingTime" name="bookingTime" class="form-control" required onchange="onCustomDateTimeChange()">
                            <small style="color: var(--text-muted); font-size: 0.76rem; margin-top: 4px; display: block;">Arrival time in 12hr / 24hr format.</small>
                        </div>
                    </div>

                    <!-- Live Schedule & Grace Preview Badge -->
                    <div style="margin-top: 16px; background: #ffffff; border: 1.5px dashed #cbd5e1; border-radius: var(--border-radius-sm); padding: 14px 18px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
                        <div>
                            <span style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; font-weight: 700; display: flex; align-items: center; gap: 4px;">
                                📅 Confirmed Arrival Schedule:
                            </span>
                            <div id="scheduledTimePreview" style="font-weight: 900; color: var(--color-primary); font-size: 1.05rem; margin-top: 2px;">
                                Calculating...
                            </div>
                        </div>
                        <div style="text-align: right;">
                            <span style="font-size: 0.75rem; color: #b45309; text-transform: uppercase; font-weight: 700; display: flex; align-items: center; gap: 4px; justify-content: flex-end;">
                                ⏱️ 15-Min Grace Cutoff:
                            </span>
                            <div id="graceCutoffPreview" style="font-weight: 900; color: #dc2626; font-size: 1.05rem; margin-top: 2px;">
                                Calculating...
                            </div>
                        </div>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="vehicleNumber">Vehicle Registration Number (VRN)</label>
                    
                    <!-- Indian HSRP Graphic Plate Preview -->
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
                        Sensor camera checks your plate upon bay arrival to confirm occupancy
                    </small>
                </div>

                <div style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: var(--border-radius-md); padding: 14px 18px; margin-bottom: 24px; display: flex; align-items: center; gap: 12px;">
                    <span style="font-size: 1.4rem;">📡</span>
                    <div style="font-size: 0.85rem; color: #166534; line-height: 1.4;">
                        <strong>Automatic Sensor Metering on Arrival:</strong> When you arrive at the zone, scanning your number plate switches the bay status to <strong>OCCUPIED</strong> and starts the live parking meter from <strong>0hr 0min 0sec</strong>.
                    </div>
                </div>

                <button type="submit" class="btn btn-primary btn-block" style="font-size: 1.05rem; padding: 16px; display: flex; align-items: center; justify-content: center; gap: 8px;">
                    <span>⏱️</span> Confirm & Reserve Bay <%= slot.getSlotId() %> &rarr;
                </button>
            </form>
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

    <script src="<%= request.getContextPath() %>/resources/js/validation.js"></script>
    <script>
        function pad2(num) {
            return String(num).padStart(2, '0');
        }

        function formatTime12(date) {
            let hours = date.getHours();
            let minutes = date.getMinutes();
            const ampm = hours >= 12 ? 'PM' : 'AM';
            hours = hours % 12;
            hours = hours ? hours : 12;
            const strMinutes = minutes < 10 ? '0' + minutes : minutes;
            return hours + ':' + strMinutes + ' ' + ampm;
        }

        function formatDatePretty(date) {
            return date.toLocaleDateString('en-US', {
                weekday: 'short',
                month: 'short',
                day: 'numeric'
            });
        }

        function updatePreviews(targetDate) {
            const schedPreview = document.getElementById('scheduledTimePreview');
            const cutoffPreview = document.getElementById('graceCutoffPreview');
            if (schedPreview) {
                schedPreview.textContent = formatDatePretty(targetDate) + ' at ' + formatTime12(targetDate);
            }
            if (cutoffPreview) {
                // 15-minute grace period cutoff
                const cutoffDate = new Date(targetDate.getTime() + (15 * 60 * 1000));
                cutoffPreview.textContent = formatTime12(cutoffDate);
            }
        }

        function applyQuickSchedule(opt) {
            // Update active preset button highlight
            document.querySelectorAll('.arrival-preset-btn').forEach(btn => btn.classList.remove('active'));
            const btnId = opt === '15m' ? 'btnPreset15m' :
                          opt === '30m' ? 'btnPreset30m' :
                          opt === '1h'  ? 'btnPreset1h' :
                          opt === 'tomorrow' ? 'btnPresetTomorrow' : null;
            if (btnId) {
                const btn = document.getElementById(btnId);
                if (btn) btn.classList.add('active');
            }

            let targetDate = new Date();
            if (opt === '15m') {
                targetDate = new Date(Date.now() + (15 * 60 * 1000));
            } else if (opt === '30m') {
                targetDate = new Date(Date.now() + (30 * 60 * 1000));
            } else if (opt === '1h') {
                targetDate = new Date(Date.now() + (60 * 60 * 1000));
            } else if (opt === 'tomorrow') {
                targetDate.setDate(targetDate.getDate() + 1);
                targetDate.setHours(9, 0, 0, 0); // 9:00 AM next day
            }

            const dateInput = document.getElementById('bookingDate');
            const timeInput = document.getElementById('bookingTime');

            if (dateInput) {
                dateInput.value = targetDate.getFullYear() + '-' +
                                  pad2(targetDate.getMonth() + 1) + '-' +
                                  pad2(targetDate.getDate());
            }
            if (timeInput) {
                timeInput.value = pad2(targetDate.getHours()) + ':' + pad2(targetDate.getMinutes());
            }

            updatePreviews(targetDate);
        }

        function onCustomDateTimeChange() {
            // Remove active highlight from quick presets when user manually alters date/time
            document.querySelectorAll('.arrival-preset-btn').forEach(btn => btn.classList.remove('active'));

            const dateVal = document.getElementById('bookingDate')?.value;
            const timeVal = document.getElementById('bookingTime')?.value;

            if (dateVal && timeVal) {
                const partsD = dateVal.split('-');
                const partsT = timeVal.split(':');
                const targetDate = new Date(
                    parseInt(partsD[0], 10),
                    parseInt(partsD[1], 10) - 1,
                    parseInt(partsD[2], 10),
                    parseInt(partsT[0], 10),
                    parseInt(partsT[1], 10),
                    0
                );
                updatePreviews(targetDate);
            }
        }

        function validateReservationSchedule(event) {
            const dateVal = document.getElementById('bookingDate')?.value;
            const timeVal = document.getElementById('bookingTime')?.value;

            if (!dateVal || !timeVal) {
                alert('Please select both a reservation date and an arrival time.');
                if (event) event.preventDefault();
                return false;
            }

            const partsD = dateVal.split('-');
            const partsT = timeVal.split(':');
            const targetDate = new Date(
                parseInt(partsD[0], 10),
                parseInt(partsD[1], 10) - 1,
                parseInt(partsD[2], 10),
                parseInt(partsT[0], 10),
                parseInt(partsT[1], 10),
                0
            );

            // Allow up to 2 minutes clock skew for current-time selections
            if (targetDate.getTime() < Date.now() - (2 * 60 * 1000)) {
                alert('The selected arrival date and time is in the past. Please choose a future arrival time.');
                if (event) event.preventDefault();
                return false;
            }

            return true;
        }

        document.addEventListener('DOMContentLoaded', function() {
            applyQuickSchedule('15m');
        });
    </script>
</body>
</html>
