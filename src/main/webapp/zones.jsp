<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Zone" %>
<%@ page import="java.util.List" %>
<%
    User currentUser = (User) session.getAttribute("user");
    List<Zone> allZones = (List<Zone>) request.getAttribute("zones");
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
    <title>Parking Zones | Smart Parking Management System</title>
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
                <a href="<%= request.getContextPath() %>/login?action=logout" class="btn btn-secondary btn-sm">Sign Out</a>
            <% } else { %>
                <a href="<%= request.getContextPath() %>/login" class="btn btn-secondary btn-sm">Sign In</a>
                <a href="<%= request.getContextPath() %>/register" class="btn btn-primary btn-sm">Register</a>
            <% } %>
        </div>
    </nav>

    <!-- Hero Section (Smart Parking UK Style) -->
    <header class="hero hero-video-wrapper">
        <!-- Background Video Animation -->
        <div class="video-bg-container">
            <video class="video-bg" autoplay muted loop playsinline poster="<%= request.getContextPath() %>/resources/images/hero_garage.jpg">
                <source src="<%= request.getContextPath() %>/resources/videos/parking_background.mp4" type="video/mp4">
            </video>
            <div class="video-bg-overlay"></div>
            <div class="video-ambient-glow"></div>
        </div>
        <div class="hero-container">
            <div class="hero-content">
                <div class="hero-pill">
                    <span class="pulse-dot"></span> Live Intelligent Bay Monitoring Active &bull; 📹 Facility Cam Online
                </div>
                <h1 class="hero-title">
                    Smarter, Greener & <span>Stress-Free</span> Urban Parking
                </h1>
                <p class="hero-subtitle">
                    Real-time geomagnetic sensor tracking, instant contactless bay reservation, and dynamic occupancy analytics across multi-storey parking facilities.
                </p>
                <div style="margin-bottom: 20px; display: inline-flex; align-items: center; gap: 10px; background: rgba(255, 255, 255, 0.08); backdrop-filter: blur(8px); padding: 8px 16px; border-radius: 24px; border: 1px solid rgba(255, 255, 255, 0.15); font-size: 0.82rem; color: #f1f5f9; flex-wrap: wrap;">
                    <span style="display: flex; align-items: center; gap: 5px;"><strong style="color: #60a5fa;">Dynamic Demand Pricing:</strong></span>
                    <span style="display: inline-flex; align-items: center; gap: 4px; background: rgba(239, 68, 68, 0.25); color: #fca5a5; padding: 2px 8px; border-radius: 12px; font-weight: 700;">⚡ Rush Hours: ₹50/hr</span>
                    <span style="display: inline-flex; align-items: center; gap: 4px; background: rgba(59, 130, 246, 0.25); color: #93c5fd; padding: 2px 8px; border-radius: 12px; font-weight: 700;">⚖️ Normal: ₹40/hr</span>
                    <span style="display: inline-flex; align-items: center; gap: 4px; background: rgba(16, 185, 129, 0.25); color: #6ee7b7; padding: 2px 8px; border-radius: 12px; font-weight: 700;">🏷️ No Rush: ₹30/hr</span>
                </div>
                <div class="hero-stats">
                    <div class="hero-stat-card">
                        <div class="hero-stat-num count-up" data-target="<%= totalAvailable %>">0</div>
                        <div class="hero-stat-label">Bays Available Now</div>
                    </div>
                    <div class="hero-stat-card">
                        <div class="hero-stat-num count-up" data-target="<%= totalCapacity %>">0</div>
                        <div class="hero-stat-label">Total Monitored Bays</div>
                    </div>
                    <div class="hero-stat-card">
                        <div class="hero-stat-num count-up" data-target="<%= zones.size() %>">0</div>
                        <div class="hero-stat-label">Active Parking Zones</div>
                    </div>
                </div>
            </div>

            <!-- Hero Visual: Multi-Storey Smart Garage Live Camera Video Feed -->
            <div class="hero-visual">
                <div class="hero-image-card" style="box-shadow: 0 16px 40px rgba(0, 0, 0, 0.5), 0 0 30px rgba(0, 208, 132, 0.25); border: 2px solid rgba(0, 208, 132, 0.4);">
                    <video class="hero-img" id="heroCamVideo" autoplay muted defaultMuted loop playsinline poster="<%= request.getContextPath() %>/resources/images/hero_garage.jpg" style="width: 100%; height: 100%; object-fit: cover; display: block;">
                        <source src="<%= request.getContextPath() %>/resources/videos/parking_background.mp4" type="video/mp4">
                    </video>
                    <div class="hero-image-overlay">
                        <div class="hero-live-badge" style="background: rgba(0, 208, 132, 0.95); color: #0b192c; font-weight: 700;">
                            <span class="pulse-dot" style="background: #0b192c;"></span> LIVE FACILITY CAM &bull; 60 FPS
                        </div>
                        <div class="hero-image-caption">
                            <strong>Multi-Storey Facility Live Feed</strong>
                            <span>Real-Time Overhead Ultrasonic Sensor Matrix &bull; Levels 1–3 Monitored</span>
                        </div>
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
                <div>Welcome to Smart Parking! Select your preferred parking zone below to reserve your bay.</div>
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
                <h2 class="section-title">Select City & Parking Facility</h2>
                <p class="section-subtitle">Real-time smart parking across India's premier commercial hubs and tech corridors</p>
            </div>
        </div>

        <!-- City Quick Filter Navigation -->
        <div class="city-filter-container">
            <button type="button" class="city-filter-btn active" data-city="BENGALURU">💻 Bengaluru</button>
            <button type="button" class="city-filter-btn" data-city="HYDERABAD">💎 Hyderabad</button>
            <button type="button" class="city-filter-btn" data-city="CHENNAI">🚗 Chennai</button>
        </div>

        <!-- Zones Grid -->
        <div class="zones-grid" id="zonesGrid">
            <% for (Zone z : zones) { 
                int occ = z.getOccupancyPercentage();
                String occClass = occ > 75 ? "high" : "";

                // Determine Indian City Tag
                String cityKey = "OTHER";
                String cityName = "India";
                String cityIcon = "📍";
                String text = (z.getName() + " " + z.getLocation()).toLowerCase();
                if (text.contains("bengaluru") || text.contains("bangalore")) { cityKey = "BENGALURU"; cityName = "Bengaluru"; cityIcon = "💻"; }
                else if (text.contains("hyderabad")) { cityKey = "HYDERABAD"; cityName = "Hyderabad"; cityIcon = "💎"; }
                else if (text.contains("chennai")) { cityKey = "CHENNAI"; cityName = "Chennai"; cityIcon = "🚗"; }

                // 1-to-1 Dedicated Unique Landmark Facility Photo for Every Zone (Zero Repetition)
                String zoneKey = z.getZoneId().toLowerCase().replace("-", "_");
                String cardImg = request.getContextPath() + "/resources/images/zone_" + zoneKey + ".jpg";
                String tierClass = z.isRushHour() ? "surge-active rush-hour" : (z.isOffPeak() ? "no-rush-active" : "normal-hours");
            %>
                <div class="zone-card <%= tierClass %>" data-city="<%= cityKey %>" style="<%= "BENGALURU".equals(cityKey) ? "display: flex;" : "display: none;" %>">
                    <!-- Facility Header Photo (Unique per zone, no repetition) -->
                    <div class="zone-card-thumb-wrap">
                        <img src="<%= cardImg %>" alt="<%= z.getName() %>" class="zone-card-thumb" loading="lazy" onerror="this.src='<%= request.getContextPath() %>/resources/images/hero_garage.jpg'">
                        <div class="zone-thumb-overlay">
                            <div style="display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                                <span class="zone-tag">ZONE <%= z.getZoneId() %></span>
                                <span class="city-tag-pill"><%= cityIcon %> <%= cityName %></span>
                            </div>
                            <% if (z.isRushHour()) { %>
                                <span class="badge" style="background: #ef4444; color: #ffffff; font-weight: 800; font-size: 0.68rem; padding: 3px 8px; border-radius: 12px; box-shadow: 0 0 10px rgba(239, 68, 68, 0.4);">
                                    ⚡ RUSH HOUR (₹50)
                                </span>
                            <% } else if (z.isOffPeak()) { %>
                                <span class="badge" style="background: #10b981; color: #ffffff; font-weight: 800; font-size: 0.68rem; padding: 3px 8px; border-radius: 12px; box-shadow: 0 0 10px rgba(16, 185, 129, 0.4);">
                                    🏷️ NO RUSH (₹30)
                                </span>
                            <% } else { %>
                                <span class="badge" style="background: #3b82f6; color: #ffffff; font-weight: 800; font-size: 0.68rem; padding: 3px 8px; border-radius: 12px; box-shadow: 0 0 10px rgba(59, 130, 246, 0.3);">
                                    ⚖️ NORMAL (₹40)
                                </span>
                            <% } %>
                        </div>
                    </div>

                    <div class="zone-card-top">
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 10px; margin-bottom: 6px;">
                            <h3 class="zone-name" style="margin-bottom: 0; font-size: 1.12rem; line-height: 1.3;"><%= z.getName() %></h3>
                            <div class="zone-rate" style="text-align: right; flex-shrink: 0;">
                                <% if (z.isRushHour()) { %>
                                    <div style="text-decoration: line-through; color: var(--text-muted); font-size: 0.75rem; line-height: 1;">
                                        ₹ 40
                                    </div>
                                    <div style="color: #dc2626; font-weight: 800; font-size: 1.22rem; line-height: 1.1;">
                                        ₹ 50<span style="font-size: 0.72rem; color: var(--text-muted); font-weight: 500;">/hr</span>
                                    </div>
                                <% } else if (z.isOffPeak()) { %>
                                    <div style="text-decoration: line-through; color: var(--text-muted); font-size: 0.75rem; line-height: 1;">
                                        ₹ 40
                                    </div>
                                    <div style="color: #059669; font-weight: 800; font-size: 1.22rem; line-height: 1.1;">
                                        ₹ 30<span style="font-size: 0.72rem; color: var(--text-muted); font-weight: 500;">/hr</span>
                                    </div>
                                <% } else { %>
                                    <div style="font-size: 1.22rem; font-weight: 800; color: var(--color-primary);">
                                        ₹ 40<span style="font-size: 0.72rem; color: var(--text-muted); font-weight: 500;">/hr</span>
                                    </div>
                                <% } %>
                            </div>
                        </div>
                        <div class="zone-location">
                            <span>📍</span> <%= z.getLocation() %>
                        </div>
                    </div>

                    <div class="zone-card-body">
                        <p class="zone-desc"><%= z.getDescription() %></p>

                        <% if (z.isRushHour()) { %>
                            <div style="background: #fef2f2; border: 1px solid #fecaca; border-radius: var(--border-radius-sm); padding: 6px 10px; font-size: 0.78rem; color: #991b1b; margin-bottom: 12px; display: flex; align-items: center; gap: 6px;">
                                <span>⚡</span> <strong>Rush Hour Active:</strong> High demand (occupancy ≥75%) &bull; Peak tariff at <strong>₹50/hr</strong>.
                            </div>
                        <% } else if (z.isOffPeak()) { %>
                            <div style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: var(--border-radius-sm); padding: 6px 10px; font-size: 0.78rem; color: #166534; margin-bottom: 12px; display: flex; align-items: center; gap: 6px;">
                                <span>🏷️</span> <strong>No Rush Hours:</strong> Low demand (<40% occupancy) &bull; Saver tariff at <strong>₹30/hr</strong>.
                            </div>
                        <% } else { %>
                            <div style="background: #eff6ff; border: 1px solid #bfdbfe; border-radius: var(--border-radius-sm); padding: 6px 10px; font-size: 0.78rem; color: #1e40af; margin-bottom: 12px; display: flex; align-items: center; gap: 6px;">
                                <span>⚖️</span> <strong>Normal Hours:</strong> Moderate demand (40%–74%) &bull; Standard tariff at <strong>₹40/hr</strong>.
                            </div>
                        <% } %>

                        <div class="occupancy-box">
                            <div class="occupancy-labels">
                                <span style="display: flex; align-items: center; gap: 6px;">
                                    <span class="pulse-dot"></span> <%= z.getAvailableSlots() %> Bays Available
                                </span>
                                <span style="color: var(--text-muted);"><%= occ %>% Occupied</span>
                            </div>
                            <div class="occupancy-progress-bar">
                                <div class="occupancy-fill <%= occClass %>" style="width: <%= occ %>%;"></div>
                            </div>
                            <!-- 10-Dot Miniature Availability Distribution -->
                            <div class="dot-matrix-preview" title="Live Bay Distribution: Green = Free, Gray = Occupied">
                                <% 
                                   int totalDots = 10;
                                   int occDots = (int) Math.round((occ / 100.0) * totalDots);
                                   for (int d = 0; d < totalDots; d++) {
                                       boolean isOcc = d < occDots;
                                %>
                                    <span class="matrix-dot <%= isOcc ? "occupied" : "free" %>"></span>
                                <% } %>
                            </div>
                        </div>

                        <a href="<%= request.getContextPath() %>/zones?action=slots&zone=<%= z.getZoneId() %>" 
                           class="btn btn-primary btn-block">
                            Select Zone <%= z.getZoneId() %> Bays &rarr;
                        </a>
                    </div>
                </div>
            <% } %>
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

    <!-- Vanilla JavaScript for Interactive City Filtering & Number Count-Up Animations -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // 1. City Quick Filtering
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

            // 2. Smooth Number Count-Up for Hero Stats
            const counters = document.querySelectorAll('.count-up');
            counters.forEach(counter => {
                const target = parseInt(counter.getAttribute('data-target') || '0', 10);
                const duration = 1200; // 1.2 seconds
                const stepTime = 20;
                const steps = duration / stepTime;
                const increment = target / steps;
                let current = 0;

                const timer = setInterval(() => {
                    current += increment;
                    if (current >= target) {
                        counter.textContent = target.toLocaleString();
                        clearInterval(timer);
                    } else {
                        counter.textContent = Math.floor(current).toLocaleString();
                    }
                }, stepTime);
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
    <script>
        // Ensure background & preview videos autoplay smoothly and loop
        document.addEventListener('DOMContentLoaded', function() {
            var vids = document.querySelectorAll('video');
            vids.forEach(function(v) {
                v.muted = true;
                var playPromise = v.play();
                if (playPromise !== undefined) {
                    playPromise.catch(function(err) {
                        console.warn("Autoplay deferred, retrying muted:", err);
                        v.muted = true;
                        v.play();
                    });
                }
            });
        });
    </script>
</body>
</html>
