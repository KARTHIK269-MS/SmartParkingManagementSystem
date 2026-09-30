<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Zone" %>
<%@ page import="com.parkingsystem.model.Slot" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    Zone zone = (Zone) request.getAttribute("zone");
    List<Slot> slots = (List<Slot>) request.getAttribute("slots");
    if (zone == null || slots == null) {
        response.sendRedirect(request.getContextPath() + "/zones");
        return;
    }
    int availableCount = 0;
    for (Slot s : slots) {
        if (s.isAvailable()) availableCount++;
    }
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= zone.getName() %> | Bay Availability | Smart Parking</title>
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
        <ul class="nav-links">
            <li><a href="<%= request.getContextPath() %>/zones" class="nav-link">All Zones</a></li>
            <li><a href="<%= request.getContextPath() %>/zones?action=slots&zone=<%= zone.getZoneId() %>" class="nav-link active"><%= zone.getName() %></a></li>
            <% if (currentUser != null) { %>
                <li><a href="<%= request.getContextPath() %>/booking?action=myBookings" class="nav-link">My Bookings</a></li>
            <% } %>
        </ul>
        <div class="nav-actions">
            <% if (currentUser != null) { %>
                <!-- Notification Bell -->
                <div class="notif-bell-wrapper" id="notifBellWrapper">
                    <button type="button" class="notif-bell-btn" id="notifBellBtn" title="Notifications" onclick="toggleNotifDropdown(event)">
                        🔔
                        <span class="notif-badge" id="notifBadge" style="display: none;">0</span>
                    </button>
                    <div class="notif-dropdown" id="notifDropdown">
                        <div class="notif-dropdown-header">
                            <strong>Notifications</strong>
                            <button type="button" class="notif-mark-all" onclick="markAllNotifsRead(event)">Mark all as read</button>
                        </div>
                        <div class="notif-list" id="notifList">
                            <div class="notif-empty">Loading notifications...</div>
                        </div>
                    </div>
                </div>

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

    <!-- Main Container -->
    <main class="container">
        <% if ("slot_taken".equals(error)) { %>
            <div class="alert alert-danger">
                <span>⚠️</span>
                <div>The slot you selected was just reserved by another driver. Please pick an alternative available bay below.</div>
            </div>
        <% } %>
        <% if (zone.isRushHour()) { %>
            <div class="alert alert-warning" style="background: #fef2f2; border-color: #f87171; color: #991b1b; margin-bottom: 20px;">
                <span>⚡</span>
                <div>
                    <strong>Dynamic Rush Hours Active:</strong>
                    This zone is currently experiencing high demand (<strong><%= zone.getOccupancyPercentage() %>% occupancy</strong>). Tariff is dynamically adjusted from 
                    <span style="text-decoration: line-through;">₹ 40</span> to 
                    <strong>₹ 50.00/hr</strong>.
                </div>
            </div>
        <% } else if (zone.isOffPeak()) { %>
            <div class="alert alert-success" style="background: #f0fdf4; border-color: #86efac; color: #166534; margin-bottom: 20px;">
                <span>🏷️</span>
                <div>
                    <strong>No Rush Hours Active (Off-Peak Saver):</strong>
                    High bay availability in Zone <%= zone.getZoneId() %> (<strong><%= zone.getAvailableSlots() %> bays open</strong>). Tariff is discounted from 
                    <span style="text-decoration: line-through;">₹ 40</span> to 
                    <strong>₹ 30.00/hr</strong>.
                </div>
            </div>
        <% } %>

        <div class="section-header">
            <div>
                <a href="<%= request.getContextPath() %>/zones" style="color: var(--text-muted); font-size: 0.85rem; font-weight: 600; display: inline-flex; align-items: center; gap: 4px; margin-bottom: 6px;">
                    &larr; Back to Zones
                </a>
                <h2 class="section-title"><%= zone.getName() %></h2>
                <p class="section-subtitle">
                    📍 <%= zone.getLocation() %> &bull; Tariff: 
                    <% if (zone.isRushHour()) { %>
                        <span style="text-decoration: line-through; color: var(--text-muted);">₹ 40</span>
                        <strong style="color: #dc2626;">₹ 50.00/hr</strong>
                        <span class="badge" style="background: #ef4444; color: #ffffff; font-size: 0.7rem; font-weight: 800; padding: 2px 7px; border-radius: 10px;">⚡ RUSH HOUR (₹50)</span>
                    <% } else if (zone.isOffPeak()) { %>
                        <span style="text-decoration: line-through; color: var(--text-muted);">₹ 40</span>
                        <strong style="color: #059669;">₹ 30.00/hr</strong>
                        <span class="badge" style="background: #10b981; color: #ffffff; font-size: 0.7rem; font-weight: 800; padding: 2px 7px; border-radius: 10px;">🏷️ NO RUSH (₹30)</span>
                    <% } else { %>
                        <strong style="color: var(--color-primary);">₹ 40.00/hr</strong>
                        <span class="badge" style="background: #3b82f6; color: #ffffff; font-size: 0.7rem; font-weight: 800; padding: 2px 7px; border-radius: 10px;">⚖️ NORMAL (₹40)</span>
                    <% } %>
                </p>
            </div>
            <div style="text-align: right;">
                <div style="font-size: 1.8rem; font-weight: 800; color: var(--color-status-available);" id="liveAvailableCount">
                    <%= availableCount %>
                </div>
                <div style="font-size: 0.78rem; color: var(--text-muted); font-weight: 600; text-transform: uppercase;">
                    Bays Available Now
                </div>
            </div>
        </div>

        <!-- Legend -->
        <div class="slot-legend">
            <div class="legend-item">
                <div class="legend-box available"></div>
                <span>Available (Click to Select)</span>
            </div>
            <div class="legend-item">
                <div class="legend-box booked"></div>
                <span>Occupied (Sensor Active)</span>
            </div>
            <div class="legend-item">
                <div class="legend-box reserved"></div>
                <span>Reserved (Pending)</span>
            </div>
            <div class="legend-item">
                <div class="legend-box" style="background: #06b6d4; box-shadow: 0 0 8px rgba(6, 182, 212, 0.7);"></div>
                <span>⚡ EV Fast Charging Bay</span>
            </div>
            <div class="legend-item">
                <div class="legend-box blocked"></div>
                <span>Maintenance</span>
            </div>
        </div>

        <!-- Floor Filter Tabs -->
        <div class="floor-tabs">
            <button class="floor-tab-btn active" data-floor="1">Level 1 (Ground Floor)</button>
            <button class="floor-tab-btn" data-floor="2">Level 2 (First Floor)</button>
        </div>

        <!-- Interactive Parking Grid -->
        <div class="parking-grid" id="parkingGrid" data-zone-id="<%= zone.getZoneId() %>" data-hourly-rate="<%= zone.getHourlyRate() %>">
            <% for (Slot s : slots) { 
                String statusLower = s.getStatus().toLowerCase();
                boolean isEv = "EV".equalsIgnoreCase(s.getType()) || s.getSlotId().endsWith("1") || s.getSlotId().endsWith("5");
                String evClass = isEv ? "ev-slot" : "";
            %>
                <div class="slot-box <%= statusLower %> <%= evClass %>" 
                     data-slot-id="<%= s.getSlotId() %>" 
                     data-floor="<%= s.getFloor() %>"
                     data-status="<%= s.getStatus() %>">
                    <div class="slot-sensor-dome" title="IoT Ultrasonic Sensor Status"></div>
                    <div class="slot-type-badge"><%= isEv ? "⚡ EV BAY" : s.getType() %></div>
                    <% if ("BOOKED".equalsIgnoreCase(s.getStatus())) { %>
                        <div class="slot-vehicle-icon" title="Vehicle Detected in Bay">🚗</div>
                    <% } else if ("RESERVED".equalsIgnoreCase(s.getStatus())) { %>
                        <div class="slot-vehicle-icon" title="Holding for Driver">⏱️</div>
                    <% } else { %>
                        <div class="slot-vehicle-icon" style="color: #34d399; font-size: 1.1rem; font-weight: 800;">🅿️</div>
                    <% } %>
                    <div class="slot-number"><%= s.getSlotId() %></div>
                    <div class="slot-status-pill"><%= s.getStatus() %></div>
                </div>
            <% } %>
        </div>

        <!-- Sticky Bottom Action Bar -->
        <div class="slot-action-bar" id="slotActionBar" style="display: none;">
            <div>
                <span style="color: #94a3b8; font-size: 0.85rem; text-transform: uppercase;">Selected Parking Bay</span>
                <div style="font-size: 1.4rem; font-weight: 800; color: var(--color-accent);" id="actionBarBay">
                    --
                </div>
            </div>
            <div style="display: flex; align-items: center; gap: 16px;">
                <div style="text-align: right;">
                    <div style="font-size: 0.85rem; color: #94a3b8;">Hourly Tariff</div>
                    <div style="font-weight: 700;">₹ <%= String.format("%.2f", zone.getEffectiveHourlyRate()) %>/hr</div>
                </div>
                <a href="#" id="actionBarBookBtn" class="btn btn-primary">
                    Proceed to Booking &rarr;
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

    <script src="<%= request.getContextPath() %>/resources/js/slotStatus.js"></script>
    <% if (currentUser != null) { %>
    <script>
        (async function() {
            try {
                const res = await fetch('<%= request.getContextPath() %>/booking?action=notifications');
                const data = await res.json();
                if (data && typeof data.unread === 'number') {
                    const badge = document.getElementById('notifBadge');
                    if (badge) {
                        if (data.unread > 0) {
                            badge.textContent = data.unread;
                            badge.style.display = 'flex';
                        } else {
                            badge.style.display = 'none';
                        }
                    }
                    const list = document.getElementById('notifList');
                    if (list && data.notifications) {
                        if (data.notifications.length === 0) {
                            list.innerHTML = '<div class="notif-empty">No notifications yet</div>';
                        } else {
                            list.innerHTML = data.notifications.map(n => `
                                <div class="notif-item \${!n.read ? 'unread' : ''} \${n.type === 'CANCELLATION' ? 'cancellation' : ''}" onclick="markNotifRead(\${n.id}, this)">
                                    <div class="notif-icon">\${n.type === 'CANCELLATION' ? '⚠️' : '🔔'}</div>
                                    <div class="notif-content">
                                        <div class="notif-title">\${n.title}</div>
                                        <div class="notif-msg">\${n.message}</div>
                                        <div class="notif-time">\${n.time}</div>
                                    </div>
                                </div>
                            `).join('');
                        }
                    }
                }
            } catch (e) {}
        })();

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
                if (el) el.classList.remove('unread');
                const badge = document.getElementById('notifBadge');
                if (badge) {
                    let c = parseInt(badge.textContent, 10);
                    if (!isNaN(c) && c > 1) badge.textContent = c - 1;
                    else badge.style.display = 'none';
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
    </script>
    <% } %>
</body>
</html>
