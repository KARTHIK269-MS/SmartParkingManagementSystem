<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.OccupancyPrediction" %>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Zone" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%
    User currentUser = (User) session.getAttribute("driverUser");
    if (currentUser == null) {
        currentUser = (User) session.getAttribute("user");
    }
    List<Zone> allZones = (List<Zone>) request.getAttribute("zones");
    Map<String, OccupancyPrediction> predictions = (Map<String, OccupancyPrediction>) request.getAttribute("predictions");
    if (allZones == null) {
        response.sendRedirect(request.getContextPath() + "/zones");
        return;
    }
    List<Zone> zones = new java.util.ArrayList<>();
    for (Zone z : allZones) {
        String t = (z.getName() + " " + z.getLocation()).toLowerCase();
        if (t.contains("bengaluru") || t.contains("bangalore") ||
            t.contains("hyderabad") ||
            t.contains("chennai")) {
            zones.add(z);
        }
    }
    int totalAvailable = 0;
    int totalCapacity = 0;
    for (Zone z : zones) {
        totalAvailable += z.getAvailableSlots();
        totalCapacity += z.getTotalSlots();
    }
    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Find live available parking zones and real-time bay availability across Bengaluru, Hyderabad, and Chennai.">
    <title>SmartParking | Parking Zones &amp; Live Occupancy</title>
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
            <li><a href="<%= request.getContextPath() %>/zones" class="nav-link active">Parking Zones</a></li>
            <% if (currentUser != null) { %>
                <li><a href="<%= request.getContextPath() %>/booking?action=myBookings" class="nav-link">My Bookings</a></li>
                <% if (currentUser.isAdmin()) { %>
                    <li><a href="<%= request.getContextPath() %>/admin?action=dashboard" class="nav-link" style="color: var(--color-cyan);">Admin Console</a></li>
                <% } %>
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

    <!-- Page Header -->
    <header class="hero">
        <div class="hero-container">
            <div class="hero-content">
                <h1 class="hero-title">Parking Zones</h1>
                <p class="hero-subtitle">
                    Find an available parking bay and reserve it before you arrive.
                </p>
                <div class="hero-stats">
                    <div class="hero-stat-card">
                        <div class="hero-stat-num"><%= totalAvailable %></div>
                        <div class="hero-stat-label">Bays Available Now</div>
                    </div>
                    <div class="hero-stat-card">
                        <div class="hero-stat-num"><%= totalCapacity %></div>
                        <div class="hero-stat-label">Total Monitored Bays</div>
                    </div>
                    <div class="hero-stat-card">
                        <div class="hero-stat-num"><%= zones.size() %></div>
                        <div class="hero-stat-label">Active Parking Zones</div>
                    </div>
                </div>
            </div>
        </div>
    </header>

    <!-- Main Container -->
    <main class="container">
        <% if ("welcome".equals(msg)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>Welcome to Smart Parking! Select your preferred parking facility below to reserve your bay.</div>
            </div>
        <% } else if ("session_expired".equals(msg)) { %>
            <div class="alert alert-danger">
                <span>⏱️</span>
                <div>Your reservation session expired. Please select a bay to start a new booking.</div>
            </div>
        <% } else if ("booking_cancelled".equals(msg)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>Pending reservation successfully cancelled and slot released.</div>
            </div>
        <% } %>

        <div class="section-header">
            <div>
                <h2 class="section-title">Select Parking Facility</h2>
                <p class="section-subtitle">Real-time parking availability across major city commercial centres</p>
            </div>
        </div>

        <!-- City Quick Filter Navigation -->
        <div class="city-filter-container">
            <button type="button" class="city-filter-btn active" data-city="BENGALURU">Bengaluru</button>
            <button type="button" class="city-filter-btn" data-city="HYDERABAD">Hyderabad</button>
            <button type="button" class="city-filter-btn" data-city="CHENNAI">Chennai</button>
        </div>

        <!-- Zones Grid -->
        <div class="zones-grid" id="zonesGrid">
            <% for (Zone z : zones) { 
                int occ = z.getOccupancyPercentage();
                String occClass = occ > 75 ? "high" : "";

                // Determine City Tag
                String cityKey = "OTHER";
                String cityName = "India";
                String text = (z.getName() + " " + z.getLocation()).toLowerCase();
                if (text.contains("bengaluru") || text.contains("bangalore")) { cityKey = "BENGALURU"; cityName = "Bengaluru"; }
                else if (text.contains("hyderabad")) { cityKey = "HYDERABAD"; cityName = "Hyderabad"; }
                else if (text.contains("chennai")) { cityKey = "CHENNAI"; cityName = "Chennai"; }

                String zoneKey = z.getZoneId().toLowerCase().replace("-", "_");
                String cardImg = request.getContextPath() + "/resources/images/zone_" + zoneKey + ".jpg";
            %>
                <div class="zone-card" data-city="<%= cityKey %>" style="<%= "BENGALURU".equals(cityKey) ? "display: flex;" : "display: none;" %>">
                    <!-- Facility Header Photo -->
                    <div class="zone-card-thumb-wrap">
                        <img src="<%= cardImg %>" alt="<%= z.getName() %>" class="zone-card-thumb" loading="lazy" onerror="this.src='<%= request.getContextPath() %>/resources/images/hero_garage.jpg'">
                        <div class="zone-thumb-overlay">
                            <span class="zone-tag">ZONE <%= z.getZoneId() %></span>
                            <span class="city-tag-pill"><%= cityName %></span>
                        </div>
                    </div>

                    <div class="zone-card-top">
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 10px; margin-bottom: 4px;">
                            <h3 class="zone-name"><%= z.getName() %></h3>
                            <div class="zone-rate" style="text-align: right; flex-shrink: 0; font-size: 1.15rem; font-weight: 700; color: var(--color-primary);">
                                ₹ <%= (int) z.getEffectiveHourlyRate() %><span style="font-size: 0.75rem; color: var(--text-muted); font-weight: 400;">/hr</span>
                            </div>
                        </div>
                        <div class="zone-location">
                            <span>📍</span> <%= z.getLocation() %>
                        </div>
                    </div>

                    <div class="zone-card-body">
                        <p class="zone-desc"><%= z.getDescription() %></p>

                        <div class="occupancy-box">
                            <div class="occupancy-labels">
                                <span><%= z.getAvailableSlots() %> Bays Available</span>
                                <span style="color: var(--text-muted);"><%= occ %>% Occupied</span>
                            </div>
                            <div class="occupancy-progress-bar">
                                <div class="occupancy-fill <%= occClass %>" style="width: <%= occ %>%;"></div>
                            </div>
                        </div>

                        <%
                            OccupancyPrediction pred = (predictions != null) ? predictions.get(z.getZoneId()) : null;
                        %>
                        <% if (pred != null) { %>
                            <div class="prediction-chip" style="margin-top: 10px; margin-bottom: 12px; font-size: 0.8rem; padding: 6px 10px; border-radius: 6px; background: rgba(37,99,235,0.06); border: 1px solid rgba(37,99,235,0.15); display: flex; align-items: center; justify-content: space-between;">
                                <span style="font-weight: 600; color: #1e3a8a; display: flex; align-items: center; gap: 5px;">
                                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>
                                    AI Forecast:
                                </span>
                                <% if (pred.isSufficientData()) { %>
                                    <span style="color: #1e40af; font-weight: 600;" title="Expected in 1 hour based on empirical trends">
                                        +1h: <%= pred.getPredicted1hAvailable() %> free (<%= Math.round(pred.getPredicted1hPercent()) %>%)
                                    </span>
                                <% } else { %>
                                    <span style="color: #64748b; font-style: italic; font-size: 0.76rem;" title="Historical observations accumulating">
                                        Data collecting (<%= pred.getObservationsCount() %>/3)
                                    </span>
                                <% } %>
                            </div>
                        <% } %>

                        <a href="<%= request.getContextPath() %>/zones?action=slots&zone=<%= z.getZoneId() %>" 
                           class="btn btn-primary btn-block">
                            Select Bay &rarr;
                        </a>
                    </div>
                </div>
            <% } %>
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

    <!-- Vanilla JavaScript for City Filtering -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const filterBtns = document.querySelectorAll('.city-filter-btn');
            const zoneCards = document.querySelectorAll('.zone-card');

            filterBtns.forEach(function(btn) {
                btn.addEventListener('click', function() {
                    filterBtns.forEach(function(b) { b.classList.remove('active'); });
                    this.classList.add('active');

                    const selectedCity = this.getAttribute('data-city');
                    zoneCards.forEach(function(card) {
                        if (card.getAttribute('data-city') === selectedCity) {
                            card.style.display = 'flex';
                        } else {
                            card.style.display = 'none';
                        }
                    });
                });
            });
        });

        // Load notifications asynchronously for navbar
        <% if (currentUser != null) { %>
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
        <% } %>
    </script>
    <script src="<%= request.getContextPath() %>/resources/js/cookieConsent.js"></script>
</body>
</html>
