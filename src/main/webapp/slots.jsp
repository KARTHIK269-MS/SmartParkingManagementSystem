<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Zone" %>
<%@ page import="com.parkingsystem.model.Slot" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("driverUser");
    if (currentUser == null) {
        currentUser = (User) session.getAttribute("user");
    }
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
    <meta name="description" content="View real-time bay availability and reserve a spot in <%= zone.getName() %>.">
    <title>SmartParking | <%= zone.getName() %> Bays</title>
    <link rel="icon" type="image/svg+xml" href="<%= request.getContextPath() %>/resources/images/favicon.svg">
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
                <a href="<%= request.getContextPath() %>/login?action=logout&role=driver" class="btn btn-secondary btn-sm">Sign Out</a>
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

        <div class="section-header">
            <div>
                <a href="<%= request.getContextPath() %>/zones" style="color: var(--text-muted); font-size: 0.85rem; font-weight: 600; display: inline-flex; align-items: center; gap: 4px; margin-bottom: 6px;">
                    &larr; Back to Parking Zones
                </a>
                <h2 class="section-title"><%= zone.getName() %></h2>
                <p class="section-subtitle">
                    📍 <%= zone.getLocation() %> &bull; Tariff: 
                    <strong style="color: var(--color-primary);">₹ <%= String.format("%.2f", zone.getEffectiveHourlyRate()) %>/hr</strong>
                </p>
            </div>
            <div style="text-align: right;">
                <div style="font-size: 1.8rem; font-weight: 700; color: var(--color-status-available);" id="liveAvailableCount">
                    <%= availableCount %>
                </div>
                <div style="font-size: 0.75rem; color: var(--text-muted); font-weight: 600; text-transform: uppercase;">
                    Bays Available Now
                </div>
            </div>
        </div>

        <!-- Legend -->
        <div class="slot-legend">
            <div class="legend-item">
                <div class="legend-box available"></div>
                <span>Available</span>
            </div>
            <div class="legend-item">
                <div class="legend-box booked"></div>
                <span>Occupied</span>
            </div>
            <div class="legend-item">
                <div class="legend-box reserved"></div>
                <span>Reserved</span>
            </div>
            <div class="legend-item">
                <div class="legend-box" style="background: #e0f2fe; border-color: #0284c7;"></div>
                <span>EV Charging</span>
            </div>
            <div class="legend-item">
                <div class="legend-box blocked"></div>
                <span>Maintenance</span>
            </div>
        </div>

        <!-- Floor Filter Tabs and View Mode Switcher -->
        <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; margin-bottom: 20px;">
            <div class="floor-tabs" style="margin-bottom: 0;">
                <button class="floor-tab-btn active" data-floor="1">Level 1 (Ground Floor)</button>
                <button class="floor-tab-btn" data-floor="2">Level 2 (First Floor)</button>
            </div>
            <div class="view-mode-toggle" id="driverViewModeToggle" role="group" aria-label="Layout view mode">
                <button type="button" class="view-mode-btn" data-view="grid" title="Standard Cards Grid">
                    ▦ Grid View
                </button>
                <button type="button" class="view-mode-btn active" data-view="map" title="Lot Vulture Live Visual Deck">
                    🗺 Visual Lot Map
                </button>
            </div>
        </div>

        <!-- Lot Vulture 2D Live Visual Deck Container (Driver View) -->
        <div id="driverLotMapContainer" style="display: block;"></div>

        <!-- Interactive Parking Grid Fallback -->
        <div class="parking-grid" id="parkingGrid" data-zone-id="<%= zone.getZoneId() %>" data-hourly-rate="<%= zone.getHourlyRate() %>" style="display: none;">
            <% for (Slot s : slots) { 
                String statusLower = s.getStatus().toLowerCase();
                boolean isEv = "EV".equalsIgnoreCase(s.getType()) || s.getSlotId().endsWith("1") || s.getSlotId().endsWith("5");
                String evClass = isEv ? "ev-slot" : "";
            %>
                <div class="slot-box <%= statusLower %> <%= evClass %>" 
                     data-slot-id="<%= s.getSlotId() %>" 
                     data-floor="<%= s.getFloor() %>"
                     data-status="<%= s.getStatus() %>">
                    <div class="slot-sensor-dome" title="Sensor Status"></div>
                    <div class="slot-type-badge"><%= isEv ? "EV Bay" : s.getType() %></div>
                    <% if ("BOOKED".equalsIgnoreCase(s.getStatus()) || "OCCUPIED".equalsIgnoreCase(s.getStatus())) { %>
                        <div class="slot-vehicle-icon" title="Vehicle Detected">🚗</div>
                    <% } else if ("RESERVED".equalsIgnoreCase(s.getStatus())) { %>
                        <div class="slot-vehicle-icon" title="Reserved Bay">⏱️</div>
                    <% } else { %>
                        <div class="slot-vehicle-icon" style="color: #10b981;">🅿️</div>
                    <% } %>
                    <div class="slot-number"><%= s.getSlotId() %></div>
                    <div class="slot-status-pill"><%= s.getStatus() %></div>
                </div>
            <% } %>
        </div>

        <!-- Sticky Bottom Action Bar -->
        <div class="slot-action-bar" id="slotActionBar" style="display: none;">
            <div>
                <span style="color: #94a3b8; font-size: 0.8rem; text-transform: uppercase;">Selected Bay</span>
                <div style="font-size: 1.3rem; font-weight: 700; color: var(--color-accent);" id="actionBarBay">
                    --
                </div>
            </div>
            <div style="display: flex; align-items: center; gap: 16px;">
                <div style="text-align: right;">
                    <div style="font-size: 0.8rem; color: #94a3b8;">Hourly Tariff</div>
                    <div style="font-weight: 600;">₹ <%= String.format("%.2f", zone.getEffectiveHourlyRate()) %>/hr</div>
                </div>
                <a href="#" id="actionBarBookBtn" class="btn btn-primary">
                    Proceed to Booking &rarr;
                </a>
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
    <script>
        var initialDriverSlots = [
            <% for (int i = 0; i < slots.size(); i++) { 
                Slot s = slots.get(i);
            %>
                <%= (i > 0 ? "," : "") %>{"slotId":"<%= s.getSlotId() %>","zoneId":"<%= s.getZoneId() %>","slotNumber":<%= s.getSlotNumber() %>,"floor":<%= s.getFloor() %>,"type":"<%= s.getType() %>","status":"<%= s.getStatus() %>"}
            <% } %>
        ];
        var driverZoneInfo = {
            zoneId: "<%= zone.getZoneId() %>",
            name: "<%= com.parkingsystem.util.JsonUtil.escapeJson(zone.getName()) %>",
            location: "<%= com.parkingsystem.util.JsonUtil.escapeJson(zone.getLocation()) %>",
            hourlyRate: <%= zone.getEffectiveHourlyRate() %>
        };
    </script>
    <script src="<%= request.getContextPath() %>/resources/js/lotMap.js?v=20261009"></script>
    <script src="<%= request.getContextPath() %>/resources/js/slotStatus.js?v=20261009"></script>
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
    <script src="<%= request.getContextPath() %>/resources/js/cookieConsent.js"></script>
</body>
</html>
