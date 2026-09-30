<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Zone" %>
<%@ page import="com.parkingsystem.model.Slot" %>
<%@ page import="com.parkingsystem.model.Booking" %>
<%@ page import="com.parkingsystem.model.Feedback" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.LinkedHashMap" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/login?msg=admin_required");
        return;
    }

    List<Zone> zones = (List<Zone>) request.getAttribute("zones");
    List<Slot> allSlots = (List<Slot>) request.getAttribute("allSlots");
    List<Booking> allBookings = (List<Booking>) request.getAttribute("allBookings");
    List<Feedback> allFeedback = (List<Feedback>) request.getAttribute("allFeedback");
    Map<String, Object> revenueStats = (Map<String, Object>) request.getAttribute("revenueStats");
    Double avgRating = (Double) request.getAttribute("avgRating");
    if (avgRating == null) avgRating = 0.0;

    Integer totalBays = (Integer) request.getAttribute("totalBays");
    Integer availableBays = (Integer) request.getAttribute("availableBays");
    Integer bookedBays = (Integer) request.getAttribute("bookedBays");
    Integer blockedBays = (Integer) request.getAttribute("blockedBays");
    Boolean iotRunning = (Boolean) request.getAttribute("iotRunning");
    String iotLastEvent = (String) request.getAttribute("iotLastEvent");

    double totalRev = 0.0;
    double todayRev = 0.0;
    int confirmedCount = 0;
    if (revenueStats != null) {
        if (revenueStats.containsKey("totalRevenue")) totalRev = (Double) revenueStats.get("totalRevenue");
        if (revenueStats.containsKey("todayRevenue")) todayRev = (Double) revenueStats.get("todayRevenue");
        if (revenueStats.containsKey("totalConfirmedBookings")) confirmedCount = (Integer) revenueStats.get("totalConfirmedBookings");
    }

    String hourlyOccupancyJson = (String) request.getAttribute("hourlyOccupancyJson");
    String cityRevenueLabelsJson = (String) request.getAttribute("cityRevenueLabelsJson");
    String cityRevenueDataJson = (String) request.getAttribute("cityRevenueDataJson");
    String paymentLabelsJson = (String) request.getAttribute("paymentLabelsJson");
    String paymentDataJson = (String) request.getAttribute("paymentDataJson");
    Integer surgeZonesCount = (Integer) request.getAttribute("surgeZonesCount");
    if (surgeZonesCount == null) surgeZonesCount = 0;
    Zone highestOccZone = (Zone) request.getAttribute("highestOccZone");
    if (hourlyOccupancyJson == null) hourlyOccupancyJson = "[]";
    if (cityRevenueLabelsJson == null) cityRevenueLabelsJson = "[]";
    if (cityRevenueDataJson == null) cityRevenueDataJson = "[]";
    if (paymentLabelsJson == null) paymentLabelsJson = "[]";
    if (paymentDataJson == null) paymentDataJson = "[]";

    String activeTab = (String) request.getAttribute("activeTab");
    if (activeTab == null || activeTab.trim().isEmpty()) {
        activeTab = request.getParameter("tab");
    }
    if (activeTab == null || activeTab.trim().isEmpty()) {
        activeTab = "overview";
    }

    // Group zones by Metro City (3 Premier Smart Corridors)
    String[] metroCities = {"Bengaluru", "Hyderabad", "Chennai"};
    Map<String, List<Zone>> zonesByCity = new LinkedHashMap<>();
    for (String city : metroCities) {
        zonesByCity.put(city, new ArrayList<>());
    }
    Map<String, String> zoneCityMap = new HashMap<>();
    if (zones != null) {
        for (Zone z : zones) {
            String city = z.getCityName();
            if (zonesByCity.containsKey(city)) {
                zonesByCity.get(city).add(z);
                zoneCityMap.put(z.getZoneId(), city);
            }
        }
    }

    // Group slots by Zone ID
    Map<String, List<Slot>> slotsByZone = new LinkedHashMap<>();
    if (zones != null) {
        for (Zone z : zones) {
            slotsByZone.put(z.getZoneId(), new ArrayList<>());
        }
    }
    if (allSlots != null) {
        for (Slot s : allSlots) {
            if (!slotsByZone.containsKey(s.getZoneId())) {
                slotsByZone.put(s.getZoneId(), new ArrayList<>());
            }
            slotsByZone.get(s.getZoneId()).add(s);
        }
    }

    String msg = request.getParameter("msg");
    SimpleDateFormat sdf = new SimpleDateFormat("dd-MM-yyyy HH:mm");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Facility Manager Command Console | Smart Parking</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <script src="<%= request.getContextPath() %>/resources/js/chart.min.js"></script>
    <script>
        const contextPath = "<%= request.getContextPath() %>";
        const serverActiveTab = "<%= activeTab %>";
    </script>
    <style>
        .admin-stat-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }
        .analytics-main-grid {
            display: grid;
            grid-template-columns: 1.6fr 1fr;
            gap: 24px;
            margin-bottom: 32px;
        }
        @media (max-width: 1024px) {
            .analytics-main-grid {
                grid-template-columns: 1fr;
            }
        }
        .analytics-chart-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-lg);
            padding: 24px;
            box-shadow: var(--shadow-sm);
        }
        .analytics-chart-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 18px;
            padding-bottom: 12px;
            border-bottom: 1px solid var(--border-color);
        }
        .analytics-chart-title {
            font-size: 1.15rem;
            font-weight: 800;
            color: var(--color-primary);
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .chart-tag-badge {
            font-size: 0.72rem;
            font-weight: 700;
            padding: 3px 8px;
            border-radius: 20px;
            background: rgba(16, 185, 129, 0.12);
            color: #047857;
            border: 1px solid rgba(16, 185, 129, 0.25);
        }
        .surge-deck {
            background: linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%);
            color: #ffffff;
            border-radius: var(--border-radius-lg);
            padding: 24px;
            margin-bottom: 32px;
            border: 1px solid rgba(245, 158, 11, 0.3);
            box-shadow: 0 10px 25px -5px rgba(15, 23, 42, 0.25);
        }
        .surge-meter-progress {
            background: rgba(255, 255, 255, 0.1);
            height: 12px;
            border-radius: 6px;
            overflow: hidden;
            position: relative;
            margin-top: 8px;
        }
        .surge-meter-fill {
            height: 100%;
            border-radius: 6px;
            transition: width 0.6s ease;
        }
        .admin-stat-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 20px;
            box-shadow: var(--shadow-sm);
        }
        .admin-stat-val {
            font-size: 1.8rem;
            font-weight: 800;
            color: var(--color-primary);
        }
        .admin-stat-lbl {
            font-size: 0.78rem;
            color: var(--text-muted);
            text-transform: uppercase;
            font-weight: 700;
            margin-top: 4px;
        }
        .iot-panel {
            background: linear-gradient(135deg, #0b192c 0%, #1e293b 100%);
            color: #ffffff;
            border-radius: var(--border-radius-lg);
            padding: 24px;
            margin-bottom: 32px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 20px;
        }
        .admin-slot-clickable {
            cursor: pointer;
            position: relative;
        }
        .admin-slot-clickable:hover {
            transform: scale(1.05);
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        .overview-hub-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
            gap: 20px;
            margin-bottom: 28px;
        }
        .overview-hub-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 22px;
            box-shadow: var(--shadow-sm);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            gap: 16px;
        }
        .overview-hub-card:hover {
            border-color: var(--color-cyan);
            box-shadow: var(--shadow-md);
        }
        .city-filter-btn {
            border-radius: 20px;
            padding: 6px 16px;
            background: rgba(255, 255, 255, 0.08);
            color: #ffffff;
            border: 1px solid rgba(255, 255, 255, 0.2);
            font-size: 0.82rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            white-space: nowrap;
        }
        .city-filter-btn:hover {
            background: rgba(255, 255, 255, 0.18);
        }
        .zone-bays-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 18px 20px;
            margin-bottom: 20px;
            box-shadow: var(--shadow-sm);
            transition: box-shadow 0.2s ease;
        }
        .zone-bays-card:hover {
            box-shadow: var(--shadow-md);
        }
    </style>
</head>
<body>

    <!-- Navigation Bar -->
    <nav class="navbar">
        <a href="<%= request.getContextPath() %>/admin?action=dashboard" class="navbar-brand">
            <div class="brand-icon">P</div>
            <span>SmartParking<span class="brand-tag">ADMIN</span></span>
        </a>
        <ul class="nav-links">
            <li><a href="<%= request.getContextPath() %>/admin?action=dashboard" class="nav-link active">Dashboard</a></li>
            <li><a href="<%= request.getContextPath() %>/zones" class="nav-link" target="_blank">Driver Portal ↗</a></li>
        </ul>
        <div class="nav-actions">
            <div class="user-badge" style="background: rgba(6, 182, 212, 0.15); border-color: var(--color-cyan);">
                <div class="user-avatar" style="background: var(--color-cyan); color: #0b192c;">A</div>
                <span><%= currentUser.getName() %> (ADMIN)</span>
            </div>
            <a href="<%= request.getContextPath() %>/login?action=logout" class="btn btn-secondary btn-sm">Sign Out</a>
        </div>
    </nav>

    <!-- Main Container -->
    <main class="container">
        <% if ("slot_overridden".equals(msg)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>Slot status successfully overridden by Facility Manager.</div>
            </div>
        <% } else if ("iot_toggled".equals(msg)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>IoT Sensor Simulator state changed. Background thread updated.</div>
            </div>
        <% } else if ("iot_pulsed".equals(msg)) { %>
            <div class="alert alert-success">
                <span>⚡</span>
                <div>Simulated vehicle arrival/departure sensor event triggered.</div>
            </div>
        <% } else if ("surge_simulated".equals(msg)) { %>
            <div class="alert alert-warning" style="background: #fffbeb; border-color: #f59e0b; color: #92400e;">
                <span>⚡</span>
                <div><strong>AI Dynamic Surge Pricing Activated!</strong> Zone <strong><%= request.getParameter("zone") %></strong> occupancy pushed past 80%. Dynamic tariff adjusted to <strong>1.25x</strong> to balance urban vehicular load.</div>
            </div>
        <% } else if ("surge_reset".equals(msg)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>Zone <strong><%= request.getParameter("zone") %></strong> test occupancy reset to baseline. Operating tariff returned to standard 1.0x rate.</div>
            </div>
        <% } %>

        <div class="section-header" style="margin-bottom: 20px;">
            <div>
                <h2 class="section-title">Facility Manager Console</h2>
                <p class="section-subtitle">Real-time facility occupancy, transaction ledger, bay overrides & IoT simulator</p>
            </div>
            <div style="display: flex; gap: 10px; align-items: center;">
                <form action="<%= request.getContextPath() %>/admin" method="POST" style="display: inline; margin:0;">
                    <input type="hidden" name="action" value="triggerIotPulse">
                    <input type="hidden" name="tab" value="iot">
                    <button type="submit" class="btn btn-secondary btn-sm">⚡ Sensor Pulse</button>
                </form>
                <a href="<%= request.getContextPath() %>/zones" target="_blank" class="btn btn-primary btn-sm">Driver Portal ↗</a>
            </div>
        </div>

        <!-- ==========================================================================
             MODULAR TAB NAVIGATION BAR (Instant In-Page View Switching)
             ========================================================================== -->
        <div class="admin-nav-tabs" role="tablist">
            <button class="admin-tab-btn active" data-tab="overview" role="tab" title="Executive Summary & Key Metrics">
                <span>📊</span> Overview
            </button>
            <button class="admin-tab-btn" data-tab="analytics" role="tab" title="Occupancy Curves & Revenue Charts">
                <span>📈</span> Analytics & Charts
            </button>
            <button class="admin-tab-btn" data-tab="surge" role="tab" title="Dynamic Pricing & Peak Tariffs">
                <span>⚡</span> Surge Pricing
                <% if (surgeZonesCount > 0) { %>
                    <span class="tab-badge" style="background: #f59e0b; color: #000; font-weight: 800;">⚡ <%= surgeZonesCount %> Active</span>
                <% } %>
            </button>
            <button class="admin-tab-btn" data-tab="bays" role="tab" title="Visual Parking Bays Grid & Status Overrides">
                <span>🅿️</span> Bays Grid
                <span class="tab-badge"><%= totalBays %> Bays</span>
            </button>
            <button class="admin-tab-btn" data-tab="bookings" role="tab" title="Driver Bookings Audit Log & Transactions">
                <span>🚗</span> Bookings Ledger
                <span class="tab-badge"><%= allBookings.size() %></span>
            </button>
            <button class="admin-tab-btn" data-tab="iot" role="tab" title="Ultrasonic & Geomagnetic Sensor Simulator">
                <span>📡</span> IoT Simulator
                <span class="tab-badge" style="<%= Boolean.TRUE.equals(iotRunning) ? "background:#10b981; color:#fff;" : "" %>">
                    <%= Boolean.TRUE.equals(iotRunning) ? "LIVE" : "PAUSED" %>
                </span>
            </button>
            <button class="admin-tab-btn" data-tab="feedback" role="tab" title="Customer Reviews & Ratings">
                <span>⭐</span> Feedback
                <span class="tab-badge"><%= allFeedback.size() %></span>
            </button>
        </div>

        <!-- ==========================================================================
             TAB PANE 1: OVERVIEW (Executive Dashboard & Quick Actions)
             ========================================================================== -->
        <div id="tab-overview" class="tab-pane active" role="tabpanel">
            <!-- Clickable Metric Cards Grid -->
            <div class="admin-stat-grid">
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="bays" title="Click to view Bays Grid">
                    <div class="admin-stat-val"><%= totalBays %></div>
                    <div class="admin-stat-lbl">Total Capacity</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="bays" title="Click to view Available Bays">
                    <div class="admin-stat-val" style="color: var(--color-status-available);"><%= availableBays %></div>
                    <div class="admin-stat-lbl">Available Bays</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="bays" title="Click to view Occupied Bays">
                    <div class="admin-stat-val" style="color: var(--color-status-booked);"><%= bookedBays %></div>
                    <div class="admin-stat-lbl">Occupied Bays</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="bays" title="Click to view Maintenance Bays">
                    <div class="admin-stat-val" style="color: var(--color-status-blocked);"><%= blockedBays %></div>
                    <div class="admin-stat-lbl">Under Maintenance</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="analytics" title="Click to view Revenue Analytics">
                    <div class="admin-stat-val">₹ <%= String.format("%.0f", totalRev) %></div>
                    <div class="admin-stat-lbl">Total Revenue</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="analytics" title="Click to view Today's Revenue">
                    <div class="admin-stat-val" style="color: var(--color-accent);">₹ <%= String.format("%.0f", todayRev) %></div>
                    <div class="admin-stat-lbl">Today's Revenue</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="feedback" title="Click to view Driver Ratings">
                    <div class="admin-stat-val" style="color: #f59e0b;"><%= avgRating %> ★</div>
                    <div class="admin-stat-lbl">Driver Rating</div>
                </div>
            </div>

            <!-- Operations Command Deck -->
            <div class="overview-hub-grid">
                <!-- AI Surge Status Snapshot Card -->
                <div class="overview-hub-card" style="border-left: 4px solid #f59e0b;">
                    <div>
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                            <h4 style="font-size: 1.05rem; font-weight: 800; color: var(--color-primary); margin:0;">
                                ⚡ AI Dynamic Surge Pricing
                            </h4>
                            <% if (surgeZonesCount > 0) { %>
                                <span class="badge" style="background: #f59e0b; color: #000; font-weight: 800; font-size: 0.72rem;">
                                    <%= surgeZonesCount %> ZONE<%= surgeZonesCount > 1 ? "S" : "" %> ACTIVE
                                </span>
                            <% } else { %>
                                <span class="badge badge-success" style="font-size: 0.72rem;">NORMAL (1.0x)</span>
                            <% } %>
                        </div>
                        <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 12px; line-height: 1.4;">
                            <% if (highestOccZone != null) { %>
                                Peak facility: <strong>Zone <%= highestOccZone.getZoneId() %> (<%= highestOccZone.getCityName() %> - <%= highestOccZone.getFacilityName() %>)</strong> 
                                at <strong><%= highestOccZone.getOccupancyPercentage() %>% occupancy</strong> 
                                (<%= highestOccZone.isSurgeActive() ? "1.25x Dynamic Surge Active" : "Normal Rate" %>).
                            <% } else { %>
                                All 24 zones across 6 Indian metropolitan clusters operating under normal tariffs.
                            <% } %>
                        </p>
                    </div>
                    <button class="btn btn-warning btn-sm" data-jump-tab="surge" style="font-weight: 700;">
                        Open Surge Pricing Controls ➔
                    </button>
                </div>

                <!-- Live Analytics & Rush Hours Snapshot Card -->
                <div class="overview-hub-card" style="border-left: 4px solid var(--color-accent);">
                    <div>
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                            <h4 style="font-size: 1.05rem; font-weight: 800; color: var(--color-primary); margin:0;">
                                📈 Analytics & Peak Hours
                            </h4>
                            <span class="badge badge-success" style="font-size: 0.72rem;">Chart.js Active</span>
                        </div>
                        <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 12px; line-height: 1.4;">
                            Tracking 24-Hour occupancy curve across morning rush (08:00–10:00) & evening peak (17:00–20:00). 
                            Confirmed transactions: <strong><%= confirmedCount %></strong> across 6 Metros.
                        </p>
                    </div>
                    <button class="btn btn-primary btn-sm" data-jump-tab="analytics" style="font-weight: 700;">
                        View Interactive Charts ➔
                    </button>
                </div>

                <!-- IoT Sensor Hardware Snapshot Card -->
                <div class="overview-hub-card" style="border-left: 4px solid var(--color-cyan);">
                    <div>
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                            <h4 style="font-size: 1.05rem; font-weight: 800; color: var(--color-primary); margin:0;">
                                📡 IoT Sensor Network
                            </h4>
                            <span class="badge <%= Boolean.TRUE.equals(iotRunning) ? "badge-success" : "badge-secondary" %>" style="font-size: 0.72rem;">
                                <%= Boolean.TRUE.equals(iotRunning) ? "RUNNING" : "STANDBY" %>
                            </span>
                        </div>
                        <p style="font-size: 0.82rem; color: var(--text-muted); margin-bottom: 12px; line-height: 1.4;">
                            Broadcast status: <span style="color: var(--color-accent); font-weight: 600;"><%= iotLastEvent != null ? iotLastEvent : "Simulator standing by." %></span>
                        </p>
                    </div>
                    <button class="btn btn-secondary btn-sm" data-jump-tab="iot" style="font-weight: 700;">
                        Manage IoT Hardware Simulator ➔
                    </button>
                </div>
            </div>

            <!-- Recent Bookings Quick Glance Card -->
            <div class="card">
                <div class="card-header">
                    <div>
                        <h3 style="font-size: 1.15rem; font-weight: 800; color: var(--color-primary);">Recent Bookings Quick Glance</h3>
                        <p style="font-size: 0.82rem; color: var(--text-muted);">Latest parking sessions across facility network</p>
                    </div>
                    <button class="btn btn-secondary btn-sm" data-jump-tab="bookings">
                        View Full Ledger (<%= allBookings.size() %>) ➔
                    </button>
                </div>
                <div class="table-responsive">
                    <table class="custom-table">
                        <thead>
                            <tr>
                                <th>Booking ID</th>
                                <th>Driver</th>
                                <th>Bay & Zone</th>
                                <th>Vehicle Plate</th>
                                <th>Amount</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% 
                                int recentCount = Math.min(5, allBookings.size());
                                for (int i = 0; i < recentCount; i++) {
                                    Booking b = allBookings.get(i);
                                    String statusBadge = "badge-secondary";
                                    if (b.isConfirmed() || b.isCompleted() || b.isActive()) statusBadge = "badge-success";
                                    else if (b.isCancelled()) statusBadge = "badge-danger";
                                    else if (b.isPending() || b.isPaymentPending()) statusBadge = "badge-warning";
                            %>
                                <tr>
                                    <td><strong>#<%= b.getBookingId() %></strong></td>
                                    <td><%= b.getUserName() != null ? b.getUserName() : b.getUserId() %></td>
                                    <td><strong><%= b.getSlotId() %></strong> (Zone <%= b.getZoneId() %>)</td>
                                    <td>
                                        <span style="font-family: monospace; font-weight: 700; background: var(--bg-card-alt); padding: 2px 6px; border-radius: 4px; border: 1px solid var(--border-color);">
                                            <%= b.getVehicleNumber() %>
                                        </span>
                                    </td>
                                    <td><strong>₹ <%= String.format("%.2f", b.getTotalAmount()) %></strong></td>
                                    <td>
                                        <% if (b.isActive()) { %>
                                            <span class="badge badge-success" style="background:#059669; color:#fff; display:inline-flex; align-items:center; gap:4px;">
                                                <span class="pulse-dot" style="width:6px;height:6px;background:#fff;"></span> ACTIVE
                                            </span>
                                        <% } else { %>
                                            <span class="badge <%= statusBadge %>"><%= b.getStatus() %></span>
                                        <% } %>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 2: ANALYTICS & CHARTS (Interactive Chart.js Suite)
             ========================================================================== -->
        <div id="tab-analytics" class="tab-pane" role="tabpanel">
            <div class="analytics-main-grid">
                <!-- Left: 24-Hour Occupancy Curve (Area Chart) -->
                <div class="analytics-chart-card">
                    <div class="analytics-chart-header">
                        <div>
                            <div class="analytics-chart-title">
                                <span>📈</span> 24-Hour Facility Occupancy Curve
                            </div>
                            <p style="font-size: 0.8rem; color: var(--text-muted); margin: 2px 0 0 0;">
                                Hourly vehicle check-in trajectory identifying morning and evening rush hours
                            </p>
                        </div>
                        <div style="display: flex; gap: 6px; flex-wrap: wrap;">
                            <span class="chart-tag-badge" style="background: rgba(245, 158, 11, 0.12); color: #d97706; border-color: rgba(245, 158, 11, 0.25);">
                                ☀️ Morning Rush (08:00 - 10:00)
                            </span>
                            <span class="chart-tag-badge" style="background: rgba(239, 68, 68, 0.12); color: #dc2626; border-color: rgba(239, 68, 68, 0.25);">
                                🌙 Evening Peak (17:00 - 20:00)
                            </span>
                        </div>
                    </div>
                    <div style="position: relative; height: 340px; width: 100%;">
                        <canvas id="occupancyCurveChart"></canvas>
                    </div>
                </div>

                <!-- Right: Metropolitan Revenue & Payment Method Stack -->
                <div style="display: flex; flex-direction: column; gap: 24px;">
                    <!-- Revenue Breakdown by City (Bar Chart) -->
                    <div class="analytics-chart-card">
                        <div class="analytics-chart-header">
                            <div>
                                <div class="analytics-chart-title">
                                    <span>🏙️</span> Revenue by Metro City
                                </div>
                                <p style="font-size: 0.8rem; color: var(--text-muted); margin: 2px 0 0 0;">
                                    Bengaluru, Hyderabad, Chennai
                                </p>
                            </div>
                            <span class="chart-tag-badge">3 Metros</span>
                        </div>
                        <div style="position: relative; height: 180px; width: 100%;">
                            <canvas id="cityRevenueChart"></canvas>
                        </div>
                    </div>

                    <!-- Payment Method Distribution (Doughnut Chart) -->
                    <div class="analytics-chart-card">
                        <div class="analytics-chart-header">
                            <div>
                                <div class="analytics-chart-title">
                                    <span>💳</span> Payment Distribution
                                </div>
                                <p style="font-size: 0.8rem; color: var(--text-muted); margin: 2px 0 0 0;">
                                    UPI vs. FASTag vs. Cards vs. Net Banking vs. Wallet
                                </p>
                            </div>
                            <span class="chart-tag-badge" style="background: rgba(6, 182, 212, 0.12); color: #0891b2; border-color: rgba(6, 182, 212, 0.25);">
                                FASTag Active
                            </span>
                        </div>
                        <div style="position: relative; height: 180px; width: 100%;">
                            <canvas id="paymentDistChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 3: AI SURGE PRICING & PEAK TARIFFS (Grouped by City)
             ========================================================================== -->
        <div id="tab-surge" class="tab-pane" role="tabpanel">
            <div class="surge-deck">
                <div style="display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 20px; margin-bottom: 24px;">
                    <div>
                        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 6px;">
                            <span style="font-size: 1.5rem;">⚡</span>
                            <h3 style="font-size: 1.3rem; font-weight: 800; color: #f59e0b; margin: 0;">
                                AI Dynamic Surge Pricing & Peak Hour Tariffs
                            </h3>
                            <% if (surgeZonesCount > 0) { %>
                                <span class="badge badge-warning" style="background: #f59e0b; color: #000; font-weight: 800;">
                                    <%= surgeZonesCount %> ZONE<%= surgeZonesCount > 1 ? "S" : "" %> IN 1.25x SURGE
                                </span>
                            <% } else { %>
                                <span class="badge badge-success" style="background: #10b981; color: #fff;">
                                    ALL ZONES NORMAL (1.0x)
                                </span>
                            <% } %>
                        </div>
                        <p style="font-size: 0.88rem; color: #cbd5e1; max-width: 680px; margin: 0; line-height: 1.5;">
                            Automatically adjusts facility tariffs in real time based on live bay occupancy. When a zone reaches or exceeds <strong>80% occupancy</strong>, the tariff dynamically scales by <strong>1.25x (Surge Meter)</strong>.
                            Aligned with <strong>UN SDG 11 (Sustainable Cities & Communities)</strong>, this intelligent pricing encourages drivers to distribute evenly across neighboring urban facilities, curbing city congestion.
                        </p>
                    </div>
                    <div style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
                        <form action="<%= request.getContextPath() %>/admin" method="POST" style="margin: 0; display: flex; gap: 8px;">
                            <input type="hidden" name="action" value="simulateSurge">
                            <input type="hidden" name="tab" value="surge">
                            <select name="zoneId" class="form-control" style="padding: 6px 12px; font-size: 0.82rem; background: rgba(255,255,255,0.1); color: #fff; border-color: rgba(255,255,255,0.25); width: auto;">
                                <% for (String city : metroCities) { 
                                    List<Zone> cZones = zonesByCity.get(city);
                                    if (cZones != null && !cZones.isEmpty()) {
                                %>
                                    <optgroup label="🏙️ <%= city %>" style="color: #000; font-weight: 700;">
                                        <% for (Zone z : cZones) { %>
                                            <option value="<%= z.getZoneId() %>" style="color: #000;">Zone <%= z.getZoneId() %> - <%= z.getFacilityName() %></option>
                                        <% } %>
                                    </optgroup>
                                <%  } 
                                   } %>
                            </select>
                            <button type="submit" class="btn btn-sm" style="background: #f59e0b; color: #0b192c; font-weight: 700;">
                                ⚡ Simulate Surge (>80%)
                            </button>
                        </form>
                        <form action="<%= request.getContextPath() %>/admin" method="POST" style="margin: 0;">
                            <input type="hidden" name="action" value="resetSurge">
                            <input type="hidden" name="tab" value="surge">
                            <input type="hidden" name="zoneId" value="A">
                            <button type="submit" class="btn btn-secondary btn-sm" style="background: rgba(255,255,255,0.1); color: #fff; border-color: rgba(255,255,255,0.2);">
                                ↺ Reset Surge
                            </button>
                        </form>
                    </div>
                </div>

                <!-- City Filter Toolbar Pills -->
                <div style="display: flex; gap: 8px; margin-bottom: 24px; overflow-x: auto; padding-bottom: 6px;" class="city-filter-bar">
                    <button type="button" class="city-filter-btn active" data-city="all">
                        🌐 All Cities (24 Zones)
                    </button>
                    <% for (String city : metroCities) { 
                        List<Zone> cZones = zonesByCity.get(city);
                        int cCount = cZones != null ? cZones.size() : 0;
                        int cSurge = 0;
                        if (cZones != null) {
                            for (Zone cz : cZones) {
                                if (cz.isSurgeActive()) cSurge++;
                            }
                        }
                        String citySlug = city.toLowerCase().replaceAll("\\s+", "-");
                    %>
                        <button type="button" class="city-filter-btn" data-city="<%= citySlug %>">
                            🏙️ <%= city %> (<%= cCount %>)
                            <% if (cSurge > 0) { %>
                                <span class="badge" style="background: #f59e0b; color: #000; font-size: 0.68rem; margin-left: 4px; font-weight: 800;">⚡ <%= cSurge %></span>
                            <% } %>
                        </button>
                    <% } %>
                </div>

                <!-- Grouped City Clusters Container -->
                <div id="surgeCityClusters">
                    <% for (String city : metroCities) { 
                        List<Zone> cZones = zonesByCity.get(city);
                        if (cZones == null || cZones.isEmpty()) continue;
                        int cSurge = 0;
                        for (Zone cz : cZones) {
                            if (cz.isSurgeActive()) cSurge++;
                        }
                        String citySlug = city.toLowerCase().replaceAll("\\s+", "-");
                    %>
                        <!-- City Cluster Block -->
                        <div class="city-cluster-block" data-city="<%= citySlug %>" style="margin-bottom: 32px;">
                            <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 10px; margin-bottom: 16px; border-bottom: 1px solid rgba(255,255,255,0.15);">
                                <div style="display: flex; align-items: center; gap: 10px;">
                                    <span style="font-size: 1.3rem;">🏙️</span>
                                    <h4 style="font-size: 1.2rem; font-weight: 800; color: #ffffff; margin: 0;">
                                        <%= city %> Metropolitan Cluster
                                    </h4>
                                    <span style="font-size: 0.82rem; color: #94a3b8;">(<%= cZones.size() %> Parking Zones)</span>
                                </div>
                                <div>
                                    <% if (cSurge > 0) { %>
                                        <span class="badge" style="background: #f59e0b; color: #000; font-weight: 800; font-size: 0.75rem;">
                                            ⚡ <%= cSurge %> OF <%= cZones.size() %> ZONES IN 1.25x SURGE
                                        </span>
                                    <% } else { %>
                                        <span class="badge" style="background: rgba(16, 185, 129, 0.2); color: #10b981; font-size: 0.75rem;">
                                            ✓ All Normal (1.0x)
                                        </span>
                                    <% } %>
                                </div>
                            </div>

                            <!-- 4 Zones Grid for this City -->
                            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px;">
                                <% for (Zone z : cZones) { 
                                    int occ = z.getOccupancyPercentage();
                                    boolean isSurge = z.isSurgeActive();
                                %>
                                    <div style="background: rgba(255, 255, 255, 0.06); border: 1px solid <%= isSurge ? "#f59e0b" : "rgba(255,255,255,0.12)" %>; border-radius: var(--border-radius-md); padding: 18px;">
                                        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 6px; gap: 8px;">
                                            <div>
                                                <strong style="color: #ffffff; font-size: 1rem; display: block;">
                                                    Zone <%= z.getZoneId() %>
                                                </strong>
                                                <span style="font-size: 0.82rem; color: #38bdf8; font-weight: 600;">
                                                    <%= z.getFacilityName() %>
                                                </span>
                                            </div>
                                            <% if (isSurge) { %>
                                                <span class="badge" style="background: #f59e0b; color: #000; font-size: 0.72rem; font-weight: 800; white-space: nowrap;">⚡ 1.25x SURGE</span>
                                            <% } else { %>
                                                <span class="badge" style="background: rgba(16, 185, 129, 0.2); color: #10b981; font-size: 0.72rem; white-space: nowrap;">1.0x NORMAL</span>
                                            <% } %>
                                        </div>
                                        <div style="font-size: 0.78rem; color: #94a3b8; margin-bottom: 10px; line-height: 1.3;">
                                            📍 <%= z.getLocation() %>
                                        </div>
                                        <div style="display: flex; justify-content: space-between; font-size: 0.82rem; color: #94a3b8; margin-bottom: 4px;">
                                            <span>Occupancy: <strong style="color: <%= isSurge ? "#f59e0b" : "#10b981" %>;"><%= occ %>%</strong> (<%= z.getTotalSlots() - z.getAvailableSlots() %>/<%= z.getTotalSlots() %> Bays)</span>
                                            <span>Tariff: <strong style="color: #fff;">₹ <%= String.format("%.2f", z.getEffectiveHourlyRate()) %>/hr</strong></span>
                                        </div>
                                        <div class="surge-meter-progress">
                                            <div class="surge-meter-fill" style="width: <%= Math.min(100, occ) %>%; background: <%= isSurge ? "linear-gradient(90deg, #f59e0b, #ef4444)" : "linear-gradient(90deg, #10b981, #06b6d4)" %>;"></div>
                                        </div>
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    <% } %>
                </div>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 4: PARKING BAYS SUPERVISORY GRID (Separated by City & Zone)
             ========================================================================== -->
        <div id="tab-bays" class="tab-pane" role="tabpanel">
            <div class="card" style="margin-bottom: 32px;">
                <div class="card-header">
                    <div>
                        <h3 style="font-size: 1.2rem; font-weight: 800; color: var(--color-primary);">Parking Bays Supervisory Grid</h3>
                        <p style="font-size: 0.85rem; color: var(--text-muted);">Organized by City & Zone. Click any bay box to manually override status.</p>
                    </div>
                    <div class="slot-legend" style="margin: 0; padding: 6px 14px;">
                        <div class="legend-item"><div class="legend-box available"></div><span>Available</span></div>
                        <div class="legend-item"><div class="legend-box booked"></div><span>Booked</span></div>
                        <div class="legend-item"><div class="legend-box reserved"></div><span>Reserved</span></div>
                        <div class="legend-item"><div class="legend-box blocked"></div><span>Maintenance</span></div>
                    </div>
                </div>

                <!-- City Filter Bar for Bays -->
                <div style="display: flex; gap: 8px; margin-bottom: 22px; flex-wrap: wrap; align-items: center;">
                    <span style="font-size: 0.82rem; font-weight: 700; color: var(--text-muted); margin-right: 4px;">Filter by City:</span>
                    <button type="button" class="bay-city-filter-btn active" data-city="all">All Cities (<%= totalBays %> Bays)</button>
                    <% for (String city : metroCities) { 
                        String citySlug = city.toLowerCase().replaceAll("\\s+", "-");
                        List<Zone> cZones = zonesByCity.get(city);
                        int cBays = 0;
                        if (cZones != null) {
                            for (Zone cz : cZones) cBays += cz.getTotalSlots();
                        }
                    %>
                        <button type="button" class="bay-city-filter-btn" data-city="<%= citySlug %>"><%= city %> (<%= cBays %>)</button>
                    <% } %>
                </div>

                <!-- Grouped City Blocks with Separated Zone Cards -->
                <div id="adminBaysContainer">
                    <% for (String city : metroCities) { 
                        List<Zone> cZones = zonesByCity.get(city);
                        if (cZones == null || cZones.isEmpty()) continue;
                        String citySlug = city.toLowerCase().replaceAll("\\s+", "-");

                        int cityTotalSlots = 0;
                        int cityAvailSlots = 0;
                        int cityBookedSlots = 0;
                        int cityBlockedSlots = 0;
                        for (Zone cz : cZones) {
                            List<Slot> zSlots = slotsByZone.get(cz.getZoneId());
                            if (zSlots != null) {
                                cityTotalSlots += zSlots.size();
                                for (Slot s : zSlots) {
                                    if ("AVAILABLE".equalsIgnoreCase(s.getStatus())) cityAvailSlots++;
                                    else if ("BLOCKED".equalsIgnoreCase(s.getStatus())) cityBlockedSlots++;
                                    else cityBookedSlots++;
                                }
                            }
                        }
                    %>
                        <!-- City Block -->
                        <div class="bay-city-block" data-city="<%= citySlug %>" style="margin-bottom: 32px;">
                            <!-- City Cluster Banner -->
                            <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 18px; background: linear-gradient(90deg, #0b192c 0%, #1e293b 100%); color: #ffffff; border-radius: var(--border-radius-md); margin-bottom: 20px; box-shadow: var(--shadow-sm); flex-wrap: wrap; gap: 10px;">
                                <div style="display: flex; align-items: center; gap: 10px;">
                                    <span style="font-size: 1.3rem;">🏙️</span>
                                    <div>
                                        <h4 style="font-size: 1.15rem; font-weight: 800; margin: 0; color: #ffffff;">
                                            <%= city %> Metropolitan Cluster
                                        </h4>
                                        <span style="font-size: 0.8rem; color: #94a3b8;">
                                            <%= cZones.size() %> Facilities &bull; Total <%= cityTotalSlots %> Bays
                                        </span>
                                    </div>
                                </div>
                                <div style="display: flex; gap: 8px; align-items: center;">
                                    <span class="badge" style="background: rgba(16, 185, 129, 0.2); color: #10b981; font-weight: 700; font-size: 0.75rem;">
                                        <%= cityAvailSlots %> Available
                                    </span>
                                    <span class="badge" style="background: rgba(239, 68, 68, 0.2); color: #ef4444; font-weight: 700; font-size: 0.75rem;">
                                        <%= cityBookedSlots %> Occupied
                                    </span>
                                    <% if (cityBlockedSlots > 0) { %>
                                        <span class="badge" style="background: rgba(100, 116, 139, 0.2); color: #94a3b8; font-weight: 700; font-size: 0.75rem;">
                                            <%= cityBlockedSlots %> Maint.
                                        </span>
                                    <% } %>
                                </div>
                            </div>

                            <!-- Separated Zone Cards inside this City -->
                            <% for (Zone z : cZones) { 
                                List<Slot> zSlots = slotsByZone.get(z.getZoneId());
                                if (zSlots == null) zSlots = new ArrayList<>();
                                int zAvail = 0;
                                int zBooked = 0;
                                int zBlocked = 0;
                                for (Slot s : zSlots) {
                                    if ("AVAILABLE".equalsIgnoreCase(s.getStatus())) zAvail++;
                                    else if ("BLOCKED".equalsIgnoreCase(s.getStatus())) zBlocked++;
                                    else zBooked++;
                                }
                            %>
                                <div class="zone-bays-card">
                                    <!-- Zone Header with Name, Address and Metrics -->
                                    <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px; margin-bottom: 14px; padding-bottom: 10px; border-bottom: 1px solid var(--border-color);">
                                        <div>
                                            <div style="display: flex; align-items: center; gap: 8px;">
                                                <span class="badge" style="background: var(--color-primary); color: #fff; font-weight: 800; font-size: 0.8rem;">
                                                    Zone <%= z.getZoneId() %>
                                                </span>
                                                <strong style="font-size: 1.05rem; color: var(--color-primary);">
                                                    <%= z.getFacilityName() %>
                                                </strong>
                                                <% if (z.isSurgeActive()) { %>
                                                    <span class="badge" style="background: #f59e0b; color: #000; font-weight: 800; font-size: 0.7rem;">⚡ 1.25x SURGE</span>
                                                <% } %>
                                            </div>
                                            <div style="font-size: 0.78rem; color: var(--text-muted); margin-top: 3px;">
                                                📍 <%= z.getLocation() %> &bull; Tariff: <strong>₹ <%= String.format("%.2f", z.getEffectiveHourlyRate()) %>/hr</strong>
                                            </div>
                                        </div>
                                        <div style="display: flex; gap: 10px; font-size: 0.8rem; align-items: center;">
                                            <span style="color: var(--color-status-available); font-weight: 700;">● <%= zAvail %> Available</span>
                                            <span style="color: var(--color-status-booked); font-weight: 700;">● <%= zBooked %> Occupied</span>
                                            <% if (zBlocked > 0) { %>
                                                <span style="color: var(--color-status-blocked); font-weight: 700;">● <%= zBlocked %> Blocked</span>
                                            <% } %>
                                            <span style="color: var(--text-muted);">/ <%= zSlots.size() %> Bays</span>
                                        </div>
                                    </div>

                                    <!-- Grid for this Zone Only -->
                                    <div class="parking-grid">
                                        <% for (Slot s : zSlots) { 
                                            String statusLower = s.getStatus().toLowerCase();
                                        %>
                                            <div class="slot-box <%= statusLower %> admin-slot-clickable" 
                                                 data-slot-id="<%= s.getSlotId() %>" 
                                                 data-status="<%= s.getStatus() %>"
                                                 title="Click to override <%= s.getSlotId() %>">
                                                <div class="slot-sensor-dome"></div>
                                                <div class="slot-type-badge"><%= s.getZoneId() %>-L<%= s.getFloor() %></div>
                                                <% if ("BOOKED".equalsIgnoreCase(s.getStatus())) { %>
                                                    <div class="slot-vehicle-icon">🚗</div>
                                                <% } else if ("RESERVED".equalsIgnoreCase(s.getStatus())) { %>
                                                    <div class="slot-vehicle-icon">⏱️</div>
                                                <% } else { %>
                                                    <div class="slot-vehicle-icon" style="color: #34d399; font-size: 1rem;">🅿️</div>
                                                <% } %>
                                                <div class="slot-number"><%= s.getSlotId() %></div>
                                                <div class="slot-status-pill"><%= s.getStatus() %></div>
                                            </div>
                                        <% } %>
                                    </div>
                                </div>
                            <% } %>
                        </div>
                    <% } %>
                </div>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 5: DRIVER BOOKINGS LEDGER
             ========================================================================== -->
        <div id="tab-bookings" class="tab-pane" role="tabpanel">
            <div class="card" style="margin-bottom: 32px;">
                <div class="card-header">
                    <div>
                        <h3 style="font-size: 1.2rem; font-weight: 800; color: var(--color-primary);">Driver Bookings Ledger</h3>
                        <p style="font-size: 0.85rem; color: var(--text-muted);">Audit log of all parking transactions, passes, and durations</p>
                    </div>
                    <div style="display: flex; gap: 10px; align-items: center;">
                        <input type="text" id="bookingSearchInput" class="form-control" placeholder="Search ID, driver, VRN, bay..." style="padding: 8px 12px; font-size: 0.85rem; width: 220px;">
                        <select id="bookingStatusFilter" class="form-control" style="padding: 8px 12px; font-size: 0.85rem; width: 140px;">
                            <option value="ALL">All Statuses</option>
                            <option value="ACTIVE">ACTIVE (Parked)</option>
                            <option value="COMPLETED">COMPLETED</option>
                            <option value="CONFIRMED">CONFIRMED</option>
                            <option value="PAYMENT_PENDING">PAYMENT_PENDING</option>
                            <option value="CANCELLED">CANCELLED</option>
                            <option value="PENDING">PENDING</option>
                        </select>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="custom-table" id="adminBookingsTable">
                        <thead>
                            <tr>
                                <th data-sortable="true">ID ⬍</th>
                                <th data-sortable="true">Driver Name ⬍</th>
                                <th data-sortable="true">Bay & Zone ⬍</th>
                                <th data-sortable="true">Vehicle Plate ⬍</th>
                                <th data-sortable="true">Duration ⬍</th>
                                <th data-sortable="true">Amount ⬍</th>
                                <th data-sortable="true">Status ⬍</th>
                                <th>Payment Txn</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Booking b : allBookings) { 
                                String statusBadge = "badge-secondary";
                                if (b.isConfirmed() || b.isCompleted()) statusBadge = "badge-success";
                                else if (b.isActive()) statusBadge = "badge-success";
                                else if (b.isCancelled()) statusBadge = "badge-danger";
                                else if (b.isPending() || b.isPaymentPending()) statusBadge = "badge-warning";
                            %>
                                <tr>
                                    <td><strong>#<%= b.getBookingId() %></strong></td>
                                    <td>
                                        <strong><%= b.getUserName() != null ? b.getUserName() : b.getUserId() %></strong>
                                        <div style="font-size: 0.75rem; color: var(--text-muted);"><%= b.getUserEmail() != null ? b.getUserEmail() : "" %></div>
                                    </td>
                                    <td>
                                        <strong><%= b.getSlotId() %></strong> (Zone <%= b.getZoneId() %>)
                                    </td>
                                    <td>
                                        <span style="font-family: monospace; font-weight: 700; background: var(--bg-card-alt); padding: 2px 6px; border-radius: 4px; border: 1px solid var(--border-color);">
                                            <%= b.getVehicleNumber() %>
                                        </span>
                                    </td>
                                    <td>
                                        <% if (b.isActive()) { %>
                                            <span style="color: #059669; font-weight: 700;">Live Stopwatch</span>
                                        <% } else { %>
                                            <%= b.getDurationHours() > 0 ? b.getDurationHours() + " hrs" : "1 hr" %>
                                        <% } %>
                                    </td>
                                    <td><strong>₹ <%= String.format("%.2f", b.getTotalAmount()) %></strong></td>
                                    <td>
                                        <% if (b.isActive()) { %>
                                            <span class="badge badge-success booking-status-badge" data-status="<%= b.getStatus() %>" style="background:#059669; color:#fff; display:inline-flex; align-items:center; gap:4px;">
                                                <span class="pulse-dot" style="width:6px;height:6px;background:#fff;"></span> ACTIVE
                                            </span>
                                        <% } else { %>
                                            <span class="badge <%= statusBadge %> booking-status-badge" data-status="<%= b.getStatus() %>"><%= b.getStatus() %></span>
                                        <% } %>
                                    </td>
                                    <td>
                                        <span style="font-family: monospace; font-size: 0.75rem; color: var(--text-muted);">
                                            <%= b.getPaymentId() != null ? b.getPaymentId() : "--" %>
                                        </span>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 6: IOT SENSOR HARDWARE NETWORK
             ========================================================================== -->
        <div id="tab-iot" class="tab-pane" role="tabpanel">
            <div class="iot-panel">
                <div>
                    <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 6px;">
                        <h3 style="font-size: 1.25rem; font-weight: 800;">IoT Hardware Sensor Simulator</h3>
                        <div id="iotLiveStatus">
                            <% if (Boolean.TRUE.equals(iotRunning)) { %>
                                <span class="badge badge-success">ACTIVE & BROADCASTING</span>
                            <% } else { %>
                                <span class="badge badge-secondary">PAUSED</span>
                            <% } %>
                        </div>
                    </div>
                    <p style="font-size: 0.88rem; color: #94a3b8; max-width: 600px;">
                        Simulates physical ultrasonic and geomagnetic parking sensors sending bay occupancy pulses. 
                        <strong>Protected by JDBC row locks</strong> to prevent overwriting active driver bookings.
                    </p>
                    <div style="font-size: 0.82rem; color: var(--color-accent); margin-top: 8px;" id="iotLastEventText">
                        <%= iotLastEvent != null ? iotLastEvent : "Simulator standing by." %>
                    </div>
                </div>
                <div style="display: flex; gap: 12px; align-items: center;">
                    <form action="<%= request.getContextPath() %>/admin" method="POST" style="margin: 0;">
                        <input type="hidden" name="action" value="toggleIot">
                        <input type="hidden" name="tab" value="iot">
                        <% if (Boolean.TRUE.equals(iotRunning)) { %>
                            <button type="submit" class="btn btn-danger btn-sm">Pause Simulation</button>
                        <% } else { %>
                            <button type="submit" class="btn btn-primary btn-sm">Start Sensor Simulator</button>
                        <% } %>
                    </form>
                    <form action="<%= request.getContextPath() %>/admin" method="POST" style="margin: 0;">
                        <input type="hidden" name="action" value="triggerIotPulse">
                        <input type="hidden" name="tab" value="iot">
                        <button type="submit" class="btn btn-secondary btn-sm" style="background: rgba(255,255,255,0.1); color: #fff; border-color: rgba(255,255,255,0.2);">
                            Trigger Event Now
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 7: DRIVER FEEDBACK & RATINGS
             ========================================================================== -->
        <div id="tab-feedback" class="tab-pane" role="tabpanel">
            <div class="card">
                <div class="card-header">
                    <div>
                        <h3 style="font-size: 1.2rem; font-weight: 800; color: var(--color-primary);">Driver Feedback & Ratings</h3>
                        <p style="font-size: 0.85rem; color: var(--text-muted);">Real-time customer satisfaction metrics</p>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="custom-table">
                        <thead>
                            <tr>
                                <th>Ref #</th>
                                <th>Driver</th>
                                <th>Bay</th>
                                <th>Rating</th>
                                <th>Review Comments</th>
                                <th>Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (allFeedback.isEmpty()) { %>
                                <tr><td colspan="6" style="text-align: center; color: var(--text-muted);">No feedback reviews submitted yet.</td></tr>
                            <% } else { %>
                                <% for (Feedback f : allFeedback) { %>
                                    <tr>
                                        <td>#<%= f.getFeedbackId() %></td>
                                        <td><strong><%= f.getUserName() != null ? f.getUserName() : f.getUserId() %></strong></td>
                                        <td><strong><%= f.getSlotId() != null ? f.getSlotId() : "--" %></strong></td>
                                        <td>
                                            <span style="color: #f59e0b; font-weight: 700;">
                                                <%= "★".repeat(Math.max(1, f.getRating())) %>
                                            </span>
                                            <span style="font-size: 0.8rem; color: var(--text-muted);">(<%= f.getRating() %>/5)</span>
                                        </td>
                                        <td><%= f.getComment() != null && !f.getComment().isEmpty() ? f.getComment() : "<em style='color:#94a3b8'>No written comment</em>" %></td>
                                        <td style="font-size: 0.8rem; color: var(--text-muted);"><%= f.getCreatedAt() != null ? sdf.format(f.getCreatedAt()) : "Recent" %></td>
                                    </tr>
                                <% } %>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </main>

    <!-- Modal for Slot Status Override -->
    <div id="slotOverrideModal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(11, 25, 44, 0.7); backdrop-filter: blur(4px); z-index: 2000; align-items: center; justify-content: center;">
        <div class="card" style="max-width: 400px; width: 90%; padding: 28px;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                <h3 style="font-size: 1.25rem; font-weight: 800; color: var(--color-primary);">Override Bay Status</h3>
                <span id="closeModalBtn" style="cursor: pointer; font-size: 1.5rem; color: var(--text-muted);">&times;</span>
            </div>

            <form action="<%= request.getContextPath() %>/admin" method="POST">
                <input type="hidden" name="action" value="overrideSlot">
                <input type="hidden" name="tab" value="bays">
                <input type="hidden" name="slotId" id="inputSlotId" value="">

                <div class="form-group">
                    <label class="form-label">Parking Bay</label>
                    <div id="modalSlotId" style="font-size: 1.4rem; font-weight: 800; color: var(--color-accent);">--</div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="overrideStatusSelect">New Operating Status</label>
                    <select name="newStatus" id="overrideStatusSelect" class="form-control">
                        <option value="AVAILABLE">AVAILABLE (Sensor Clear)</option>
                        <option value="BOOKED">BOOKED (Occupied)</option>
                        <option value="BLOCKED">BLOCKED (Maintenance / Closed)</option>
                    </select>
                </div>

                <button type="submit" class="btn btn-primary btn-block">Save Override</button>
            </form>
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

    <!-- Chart.js Analytics Suite Initialization -->
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            if (typeof Chart === 'undefined') {
                console.warn('Chart.js not loaded. Skipping chart initialization.');
                return;
            }

            // Set global Chart defaults
            Chart.defaults.font.family = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
            Chart.defaults.color = '#64748b';

            // 1. 24-Hour Occupancy Curve (Area Line Chart)
            const ctxCurve = document.getElementById('occupancyCurveChart');
            if (ctxCurve) {
                const hourlyData = <%= hourlyOccupancyJson %>;
                const hoursLabels = [
                    '00:00', '01:00', '02:00', '03:00', '04:00', '05:00',
                    '06:00', '07:00', '08:00 (Rush)', '09:00 (Peak)', '10:00', '11:00',
                    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00 (Rush)',
                    '18:00 (Peak)', '19:00 (Peak)', '20:00', '21:00', '22:00', '23:00'
                ];

                const pointRadii = hourlyData.map((val, idx) => {
                    return (idx >= 8 && idx <= 9) || (idx >= 17 && idx <= 19) ? 6 : 3;
                });
                const pointColors = hourlyData.map((val, idx) => {
                    if (idx >= 8 && idx <= 9) return '#f59e0b';
                    if (idx >= 17 && idx <= 19) return '#ef4444';
                    return '#10b981';
                });

                new Chart(ctxCurve, {
                    type: 'line',
                    data: {
                        labels: hoursLabels,
                        datasets: [{
                            label: 'Active Vehicles / Check-ins',
                            data: hourlyData,
                            borderColor: '#10b981',
                            borderWidth: 2.5,
                            backgroundColor: function(context) {
                                const chart = context.chart;
                                const {ctx, chartArea} = chart;
                                if (!chartArea) return 'rgba(16, 185, 129, 0.15)';
                                const gradient = ctx.createLinearGradient(0, chartArea.bottom, 0, chartArea.top);
                                gradient.addColorStop(0, 'rgba(16, 185, 129, 0.02)');
                                gradient.addColorStop(0.7, 'rgba(16, 185, 129, 0.22)');
                                gradient.addColorStop(1, 'rgba(245, 158, 11, 0.35)');
                                return gradient;
                            },
                            fill: true,
                            tension: 0.38,
                            pointRadius: pointRadii,
                            pointHoverRadius: 8,
                            pointBackgroundColor: pointColors,
                            pointBorderColor: '#ffffff',
                            pointBorderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        interaction: {
                            intersect: false,
                            mode: 'index'
                        },
                        plugins: {
                            legend: { display: false },
                            tooltip: {
                                backgroundColor: '#0b192c',
                                titleColor: '#ffffff',
                                bodyColor: '#cbd5e1',
                                padding: 12,
                                cornerRadius: 8,
                                callbacks: {
                                    title: function(items) {
                                        return 'Hour: ' + items[0].label;
                                    },
                                    label: function(item) {
                                        const hr = item.dataIndex;
                                        let note = '';
                                        if (hr >= 8 && hr <= 9) note = ' ⚡ [Morning Rush Surge]';
                                        else if (hr >= 17 && hr <= 19) note = ' ⚡ [Evening Peak Surge]';
                                        return ' ' + item.formattedValue + ' Vehicles Parked' + note;
                                    }
                                }
                            }
                        },
                        scales: {
                            x: {
                                grid: { display: false },
                                ticks: { maxRotation: 45, font: { size: 10 } }
                            },
                            y: {
                                beginAtZero: true,
                                grid: { color: '#f1f5f9' },
                                ticks: { font: { size: 10 } }
                            }
                        }
                    }
                });
            }

            // 2. Metropolitan Revenue Breakdown (Bar Chart)
            const ctxCity = document.getElementById('cityRevenueChart');
            if (ctxCity) {
                const cityLabels = <%= cityRevenueLabelsJson %>;
                const cityData = <%= cityRevenueDataJson %>;
                const barColors = ['#0b192c', '#10b981', '#f59e0b', '#8b5cf6', '#06b6d4', '#ec4899'];

                new Chart(ctxCity, {
                    type: 'bar',
                    data: {
                        labels: cityLabels,
                        datasets: [{
                            label: 'Revenue (₹)',
                            data: cityData,
                            backgroundColor: barColors.slice(0, cityLabels.length),
                            borderRadius: 6,
                            borderSkipped: false
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: { display: false },
                            tooltip: {
                                backgroundColor: '#0b192c',
                                padding: 10,
                                cornerRadius: 8,
                                callbacks: {
                                    label: function(item) {
                                        return ' Revenue: ₹ ' + Number(item.raw).toLocaleString('en-IN');
                                    }
                                }
                            }
                        },
                        scales: {
                            x: {
                                grid: { display: false },
                                ticks: { font: { size: 10 } }
                            },
                            y: {
                                beginAtZero: true,
                                grid: { color: '#f1f5f9' },
                                ticks: {
                                    font: { size: 9 },
                                    callback: function(val) { return '₹' + (val >= 1000 ? (val/1000) + 'k' : val); }
                                }
                            }
                        }
                    }
                });
            }

            // 3. Payment Method Distribution (Doughnut Chart)
            const ctxPayment = document.getElementById('paymentDistChart');
            if (ctxPayment) {
                const payLabels = <%= paymentLabelsJson %>;
                const payData = <%= paymentDataJson %>;
                const donutColors = ['#059669', '#2563eb', '#f59e0b', '#6366f1', '#14b8a6'];

                new Chart(ctxPayment, {
                    type: 'doughnut',
                    data: {
                        labels: payLabels,
                        datasets: [{
                            data: payData,
                            backgroundColor: donutColors.slice(0, payLabels.length),
                            borderWidth: 2,
                            borderColor: '#ffffff',
                            hoverOffset: 6
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        cutout: '62%',
                        plugins: {
                            legend: {
                                position: 'right',
                                labels: {
                                    boxWidth: 12,
                                    font: { size: 10 },
                                    padding: 8
                                }
                            },
                            tooltip: {
                                backgroundColor: '#0b192c',
                                padding: 10,
                                cornerRadius: 8,
                                callbacks: {
                                    label: function(item) {
                                        return ' ' + item.label + ': ' + item.formattedValue + ' txns';
                                    }
                                }
                            }
                        }
                    }
                });
            }
        });
    </script>

    <!-- Tab Switching and City Filtering Scripts -->
    <script>
        function switchAdminTab(targetTabId, updateHash) {
            const buttons = document.querySelectorAll('.admin-tab-btn');
            const panes = document.querySelectorAll('.tab-pane');
            let matched = false;

            buttons.forEach(btn => {
                if (btn.dataset.tab === targetTabId) {
                    btn.classList.add('active');
                    matched = true;
                } else {
                    btn.classList.remove('active');
                }
            });

            if (!matched) {
                targetTabId = 'overview';
                const defaultBtn = document.querySelector('.admin-tab-btn[data-tab="overview"]');
                if (defaultBtn) defaultBtn.classList.add('active');
            }

            panes.forEach(pane => {
                if (pane.id === 'tab-' + targetTabId) {
                    pane.classList.add('active');
                } else {
                    pane.classList.remove('active');
                }
            });

            if (updateHash !== false) {
                history.replaceState(null, null, '#' + targetTabId);
            }

            // When switching to analytics, trigger window resize so Chart.js recalculates canvas bounds
            if (targetTabId === 'analytics') {
                setTimeout(function() {
                    window.dispatchEvent(new Event('resize'));
                }, 60);
            }
        }

        document.addEventListener('DOMContentLoaded', function() {
            // Tab button clicks
            document.querySelectorAll('.admin-tab-btn').forEach(btn => {
                btn.addEventListener('click', function(e) {
                    e.preventDefault();
                    switchAdminTab(this.dataset.tab, true);
                });
            });

            // Jump card and shortcut clicks
            document.querySelectorAll('[data-jump-tab]').forEach(el => {
                el.addEventListener('click', function(e) {
                    e.preventDefault();
                    const target = this.dataset.jumpTab;
                    switchAdminTab(target, true);
                    window.scrollTo({ top: 120, behavior: 'smooth' });
                });
            });

            // Hash navigation and deep-linking support
            function syncFromHash() {
                const hash = window.location.hash.replace('#', '').trim();
                if (hash) {
                    switchAdminTab(hash, false);
                } else if (typeof serverActiveTab !== 'undefined' && serverActiveTab) {
                    switchAdminTab(serverActiveTab, false);
                } else {
                    switchAdminTab('overview', false);
                }
            }

            window.addEventListener('hashchange', syncFromHash);
            syncFromHash();

            // City Filter in Surge Pricing Tab
            document.querySelectorAll('.city-filter-btn').forEach(btn => {
                btn.addEventListener('click', function() {
                    document.querySelectorAll('.city-filter-btn').forEach(b => b.classList.remove('active'));
                    this.classList.add('active');
                    const selectedCity = this.dataset.city;

                    document.querySelectorAll('.city-cluster-block').forEach(block => {
                        if (selectedCity === 'all' || block.dataset.city === selectedCity) {
                            block.style.display = 'block';
                        } else {
                            block.style.display = 'none';
                        }
                    });
                });
            });

            // City Filter in Bays Supervisory Grid Tab
            document.querySelectorAll('.bay-city-filter-btn').forEach(btn => {
                btn.addEventListener('click', function() {
                    document.querySelectorAll('.bay-city-filter-btn').forEach(b => b.classList.remove('active'));
                    this.classList.add('active');
                    const selectedCity = this.dataset.city;

                    document.querySelectorAll('#adminBaysContainer .bay-city-block').forEach(block => {
                        if (selectedCity === 'all' || block.dataset.city === selectedCity) {
                            block.style.display = 'block';
                        } else {
                            block.style.display = 'none';
                        }
                    });
                });
            });
        });
    </script>

    <script src="<%= request.getContextPath() %>/resources/js/admin.js"></script>
</body>
</html>
