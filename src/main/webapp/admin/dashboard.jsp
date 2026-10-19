<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Zone" %>
<%@ page import="com.parkingsystem.model.Slot" %>
<%@ page import="com.parkingsystem.model.Booking" %>
<%@ page import="com.parkingsystem.model.GateActivityEvent" %>
<%@ page import="com.parkingsystem.model.Feedback" %>
<%@ page import="com.parkingsystem.model.OccupancyPrediction" %>
<%@ page import="com.parkingsystem.model.OccupancyReportItem" %>
<%@ page import="com.parkingsystem.model.OccupancyReportSummary" %>
<%@ page import="com.parkingsystem.model.BookingReportItem" %>
<%@ page import="com.parkingsystem.model.BookingReportSummary" %>
<%@ page import="com.parkingsystem.model.RevenueReportItem" %>
<%@ page import="com.parkingsystem.model.RevenueReportSummary" %>
<%@ page import="com.parkingsystem.dao.PredictionDAO" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.LinkedHashMap" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User currentUser = (User) session.getAttribute("adminUser");
    if (currentUser == null) {
        currentUser = (User) session.getAttribute("user");
    }
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/login?msg=admin_required");
        return;
    }

    List<Zone> zones = (List<Zone>) request.getAttribute("zones");
    List<Slot> allSlots = (List<Slot>) request.getAttribute("allSlots");
    List<Booking> allBookings = (List<Booking>) request.getAttribute("allBookings");
    List<Booking> activeParkingSessions = (List<Booking>) request.getAttribute("activeParkingSessions");
    if (activeParkingSessions == null) activeParkingSessions = new ArrayList<>();
    List<GateActivityEvent> gateActivity = (List<GateActivityEvent>) request.getAttribute("gateActivity");
    if (gateActivity == null) gateActivity = new ArrayList<>();
    Double estimatedAccruedRevenue = (Double) request.getAttribute("estimatedAccruedRevenue");
    if (estimatedAccruedRevenue == null) estimatedAccruedRevenue = 0.0;
    List<Feedback> allFeedback = (List<Feedback>) request.getAttribute("allFeedback");
    List<User> allUsers = (List<User>) request.getAttribute("allUsers");
    if (allUsers == null) allUsers = new ArrayList<>();
    Map<String, Integer> userBookingCounts = (Map<String, Integer>) request.getAttribute("userBookingCounts");
    if (userBookingCounts == null) userBookingCounts = new HashMap<>();

    int activeDriversCount = 0;
    int adminUsersCount = 0;
    for (User u : allUsers) {
        if (u.isAdmin()) {
            adminUsersCount++;
        } else {
            activeDriversCount++;
        }
    }

    Map<String, Object> revenueStats = (Map<String, Object>) request.getAttribute("revenueStats");
    Double avgRating = (Double) request.getAttribute("avgRating");
    if (avgRating == null) avgRating = 0.0;

    Integer totalBays = (Integer) request.getAttribute("totalBays");
    Integer availableBays = (Integer) request.getAttribute("availableBays");
    Integer bookedBays = (Integer) request.getAttribute("bookedBays");
    Integer blockedBays = (Integer) request.getAttribute("blockedBays");
    Boolean iotRunning = (Boolean) request.getAttribute("iotRunning");
    String iotLastEvent = (String) request.getAttribute("iotLastEvent");

    OccupancyPrediction currentPrediction = (OccupancyPrediction) request.getAttribute("currentPrediction");
    Map<String, OccupancyPrediction> allPredictions = (Map<String, OccupancyPrediction>) request.getAttribute("allPredictions");
    String predZoneId = (String) request.getAttribute("predZoneId");
    if (predZoneId == null) predZoneId = "A";

    double totalRev = 0.0;
    double todayRev = 0.0;
    int confirmedCount = 0;
    double pendingRev = 0.0;
    int pendingCount = 0;
    if (revenueStats != null) {
        if (revenueStats.containsKey("totalRevenue")) totalRev = (Double) revenueStats.get("totalRevenue");
        if (revenueStats.containsKey("todayRevenue")) todayRev = (Double) revenueStats.get("todayRevenue");
        if (revenueStats.containsKey("totalConfirmedBookings")) confirmedCount = (Integer) revenueStats.get("totalConfirmedBookings");
        if (revenueStats.containsKey("pendingRevenue")) pendingRev = (Double) revenueStats.get("pendingRevenue");
        if (revenueStats.containsKey("pendingCount")) pendingCount = (Integer) revenueStats.get("pendingCount");
    }

    String hourlyOccupancyJson = (String) request.getAttribute("hourlyOccupancyJson");
    String paymentLabelsJson = (String) request.getAttribute("paymentLabelsJson");
    String paymentDataJson = (String) request.getAttribute("paymentDataJson");
    Integer surgeZonesCount = (Integer) request.getAttribute("surgeZonesCount");
    if (surgeZonesCount == null) surgeZonesCount = 0;
    Zone highestOccZone = (Zone) request.getAttribute("highestOccZone");
    if (hourlyOccupancyJson == null) hourlyOccupancyJson = "[]";
    if (paymentLabelsJson == null) paymentLabelsJson = "[]";
    if (paymentDataJson == null) paymentDataJson = "[]";

    String activeTab = (String) request.getAttribute("activeTab");
    if (activeTab == null || activeTab.trim().isEmpty()) {
        activeTab = request.getParameter("tab");
    }
    if (activeTab == null || activeTab.trim().isEmpty()) {
        activeTab = "overview";
    }

    // Supported Metro Corridors (Bengaluru, Hyderabad, Chennai)
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

    // Analytics Data Presence Flags & Metrics
    Boolean hasOccupancyData = (Boolean) request.getAttribute("hasOccupancyData");
    if (hasOccupancyData == null) hasOccupancyData = false;
    Boolean hasRevenueData = (Boolean) request.getAttribute("hasRevenueData");
    if (hasRevenueData == null) hasRevenueData = false;
    Boolean hasPaymentData = (Boolean) request.getAttribute("hasPaymentData");
    if (hasPaymentData == null) hasPaymentData = false;
    String cleanCityRevenueLabelsJson = (String) request.getAttribute("cityRevenueLabelsJson");
    if (cleanCityRevenueLabelsJson == null) cleanCityRevenueLabelsJson = "[]";
    String cleanCityRevenueDataJson = (String) request.getAttribute("cityRevenueDataJson");
    if (cleanCityRevenueDataJson == null) cleanCityRevenueDataJson = "[]";

    // Feedback rating distribution breakdown (calculated from live records)
    int star5Count = 0, star4Count = 0, star3Count = 0, star2Count = 0, star1Count = 0;
    if (allFeedback != null) {
        for (Feedback f : allFeedback) {
            int r = f.getRating();
            if (r == 5) star5Count++;
            else if (r == 4) star4Count++;
            else if (r == 3) star3Count++;
            else if (r == 2) star2Count++;
            else star1Count++;
        }
    }
    int totalReviewsCount = allFeedback != null ? allFeedback.size() : 0;

    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    SimpleDateFormat sdf = new SimpleDateFormat("dd-MM-yyyy HH:mm");

    // Reports & Export Attributes
    String reportType = (String) request.getAttribute("reportType");
    if (reportType == null || reportType.trim().isEmpty()) reportType = "occupancy";
    String reportZone = (String) request.getAttribute("reportZone");
    if (reportZone == null) reportZone = "ALL";
    String reportStartDate = (String) request.getAttribute("reportStartDate");
    if (reportStartDate == null) reportStartDate = "";
    String reportEndDate = (String) request.getAttribute("reportEndDate");
    if (reportEndDate == null) reportEndDate = "";
    String reportStatus = (String) request.getAttribute("reportStatus");
    if (reportStatus == null) reportStatus = "ALL";
    String reportDateError = (String) request.getAttribute("reportDateError");

    List<OccupancyReportItem> occupancyReportItems = (List<OccupancyReportItem>) request.getAttribute("occupancyReportItems");
    if (occupancyReportItems == null) occupancyReportItems = new ArrayList<>();
    OccupancyReportSummary occupancyReportSummary = (OccupancyReportSummary) request.getAttribute("occupancyReportSummary");

    List<BookingReportItem> bookingReportItems = (List<BookingReportItem>) request.getAttribute("bookingReportItems");
    if (bookingReportItems == null) bookingReportItems = new ArrayList<>();
    BookingReportSummary bookingReportSummary = (BookingReportSummary) request.getAttribute("bookingReportSummary");

    List<RevenueReportItem> revenueReportItems = (List<RevenueReportItem>) request.getAttribute("revenueReportItems");
    if (revenueReportItems == null) revenueReportItems = new ArrayList<>();
    RevenueReportSummary revenueReportSummary = (RevenueReportSummary) request.getAttribute("revenueReportSummary");

    List<Map<String, Object>> historicalSnapshots = (List<Map<String, Object>>) request.getAttribute("historicalSnapshots");
    if (historicalSnapshots == null) historicalSnapshots = new ArrayList<>();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Central facility operations console for managing parking bays, bookings, dynamic pricing, and sensor simulation.">
    <title>SmartParking | Admin Operations Console</title>
    <link rel="icon" type="image/svg+xml" href="<%= request.getContextPath() %>/resources/images/favicon.svg">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <script src="<%= request.getContextPath() %>/resources/js/chart.min.js"></script>
    <script>
        const contextPath = "<%= request.getContextPath() %>";
        const serverActiveTab = "<%= activeTab %>";
    </script>
    <style>
        .admin-stat-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
            gap: 14px;
            margin-bottom: 24px;
        }
        .analytics-main-grid {
            display: grid;
            grid-template-columns: 1.6fr 1fr;
            gap: 20px;
            margin-bottom: 24px;
        }
        @media (max-width: 1024px) {
            .analytics-main-grid {
                grid-template-columns: 1fr;
            }
        }
        .analytics-chart-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 20px;
            box-shadow: var(--shadow-sm);
        }
        .analytics-chart-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
            padding-bottom: 10px;
            border-bottom: 1px solid var(--border-color);
        }
        .analytics-chart-title {
            font-size: 1.05rem;
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
            border-radius: var(--border-radius-full);
            background: rgba(16, 185, 129, 0.1);
            color: #059669;
            border: 1px solid rgba(16, 185, 129, 0.2);
        }
        .surge-deck {
            background: #ffffff;
            color: var(--text-color);
            border-radius: var(--border-radius-md);
            padding: 24px;
            margin-bottom: 24px;
            border: 1px solid var(--border-color);
            box-shadow: var(--shadow-sm);
        }
        .surge-meter-progress {
            background: #e2e8f0;
            height: 8px;
            border-radius: 4px;
            overflow: hidden;
            position: relative;
            margin-top: 8px;
        }
        .surge-meter-fill {
            height: 100%;
            border-radius: 4px;
            transition: width 0.4s ease;
        }
        .admin-stat-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 18px 20px;
            box-shadow: var(--shadow-sm);
        }
        .admin-stat-val {
            font-size: 1.75rem;
            font-weight: 800;
            color: var(--color-primary);
            line-height: 1.2;
        }
        .admin-stat-lbl {
            font-size: 0.75rem;
            color: var(--text-muted);
            text-transform: uppercase;
            font-weight: 700;
            margin-top: 4px;
            letter-spacing: 0.5px;
        }
        .iot-panel {
            background: #ffffff;
            color: var(--text-color);
            border-radius: var(--border-radius-md);
            border: 1px solid var(--border-color);
            box-shadow: var(--shadow-sm);
            padding: 24px;
            margin-bottom: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 20px;
        }
        .admin-slot-clickable {
            cursor: pointer;
            position: relative;
            transition: var(--transition);
        }
        .admin-slot-clickable:hover {
            transform: translateY(-2px);
            box-shadow: var(--shadow-md);
            border-color: var(--color-primary) !important;
        }
        .overview-hub-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 18px;
            margin-bottom: 24px;
        }
        .overview-hub-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 20px;
            box-shadow: var(--shadow-sm);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            gap: 14px;
            transition: var(--transition-base);
        }
        .overview-hub-card:hover {
            border-color: #cbd5e1;
            box-shadow: var(--shadow-md);
            transform: translateY(-2px);
        }
        .city-filter-btn {
            border-radius: var(--border-radius-full);
            padding: 5px 14px;
            background: #ffffff;
            color: var(--text-muted);
            border: 1px solid var(--border-color);
            font-size: 0.82rem;
            font-weight: 600;
            cursor: pointer;
            transition: var(--transition);
            white-space: nowrap;
        }
        .city-filter-btn:hover {
            background: var(--bg-card-alt);
            color: var(--color-primary);
        }
        .city-filter-btn.active {
            background: var(--color-primary);
            color: #ffffff;
            border-color: var(--color-primary);
        }
        .zone-bays-card {
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 18px 20px;
            margin-bottom: 20px;
            box-shadow: var(--shadow-sm);
        }
        /* HyperPark-inspired Gate Movements & Active Sessions */
        .vrn-plate {
            display: inline-block;
            font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
            font-weight: 800;
            font-size: 0.85rem;
            letter-spacing: 0.75px;
            padding: 3px 8px;
            background: #f8fafc;
            color: #0f172a;
            border: 1.5px solid #cbd5e1;
            border-radius: 4px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            white-space: nowrap;
        }
        .gate-badge-entry {
            background: rgba(16, 185, 129, 0.12);
            color: #059669;
            border: 1px solid rgba(16, 185, 129, 0.3);
            font-weight: 800;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }
        .gate-badge-exit {
            background: rgba(30, 41, 59, 0.08);
            color: #1e293b;
            border: 1px solid rgba(30, 41, 59, 0.2);
            font-weight: 800;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }
        .stopwatch-live {
            font-family: 'SFMono-Regular', Consolas, monospace;
            font-size: 0.92rem;
            font-weight: 700;
            color: #0f172a;
            background: #f1f5f9;
            padding: 3px 8px;
            border-radius: 4px;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            border: 1px solid #e2e8f0;
        }
        .prototype-sim-banner {
            background: #f8fafc;
            border: 1px dashed #cbd5e1;
            border-radius: 6px;
            padding: 10px 14px;
            font-size: 0.83rem;
            color: #64748b;
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 16px;
        }
        .table-filter-group {
            display: flex;
            gap: 10px;
            align-items: center;
            flex-wrap: wrap;
        }
        .table-filter-input {
            padding: 7px 12px;
            font-size: 0.85rem;
            width: 220px;
            max-width: 100%;
        }
        .table-filter-select {
            padding: 7px 12px;
            font-size: 0.85rem;
            width: 150px;
            max-width: 100%;
        }
        #activeSessionsTable, #gateActivityTable {
            min-width: 880px;
            margin-bottom: 0;
        }
        #activeSessionsTable th, #gateActivityTable th {
            white-space: nowrap;
            background: #f8fafc;
        }
        #activeSessionsTable td, #gateActivityTable td {
            white-space: nowrap;
        }
        .table-scroll-hint {
            display: none;
            font-size: 0.72rem;
            color: var(--text-muted);
            margin-top: 6px;
        }
        @media (max-width: 768px) {
            .table-filter-group {
                width: 100%;
                flex-direction: column;
                align-items: stretch;
            }
            .table-filter-input, .table-filter-select {
                width: 100% !important;
            }
            .table-scroll-hint {
                display: block;
            }
        }
    </style>
</head>
<body>

    <!-- Navigation Bar -->
    <nav class="navbar">
        <a href="<%= request.getContextPath() %>/admin?action=dashboard" class="navbar-brand">
            <div class="brand-icon">P</div>
            <span>SmartParking <span class="admin-badge-tag">Admin</span></span>
        </a>
        <ul class="nav-links">
            <li><a href="<%= request.getContextPath() %>/admin?action=dashboard" class="nav-link active">Dashboard</a></li>
        </ul>
        <div class="nav-actions">
            <div class="user-badge">
                <div class="user-avatar">A</div>
                <span><%= currentUser.getName() %></span>
            </div>
            <a href="<%= request.getContextPath() %>/login?action=logout&role=admin" class="btn btn-secondary btn-sm">Sign Out</a>
        </div>
    </nav>

    <!-- Main Container -->
    <main class="container">
        <% if ("active_booking_present".equals(error)) { %>
            <div class="alert alert-danger">
                <span>⚠️</span>
                <div><strong>Action Prohibited:</strong> Cannot change bay status. An active user reservation or occupied vehicle currently occupies this bay. Wait for driver departure or cancellation before updating.</div>
            </div>
        <% } else if ("override_failed".equals(error)) { %>
            <div class="alert alert-danger">
                <span>⚠️</span>
                <div><strong>Override Failed:</strong> Database error occurred while attempting to update bay status.</div>
            </div>
        <% } %>
        <% if ("slot_overridden".equals(msg)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>Bay status updated successfully.</div>
            </div>
        <% } else if ("iot_toggled".equals(msg)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>IoT Sensor Simulator state changed. Background simulation thread updated.</div>
            </div>
        <% } else if ("iot_pulsed".equals(msg)) { %>
            <div class="alert alert-success">
                <span>⚡</span>
                <div>Simulated vehicle arrival/departure sensor event triggered.</div>
            </div>
        <% } else if ("surge_simulated".equals(msg)) { %>
            <div class="alert alert-warning">
                <span>⚡</span>
                <div><strong>Dynamic Demand Pricing Activated:</strong> Zone <strong><%= request.getParameter("zone") %></strong> reached 80% occupancy threshold. Operating tariff adjusted to <strong>1.25x</strong>.</div>
            </div>
        <% } else if ("surge_reset".equals(msg)) { %>
            <div class="alert alert-success">
                <span>✓</span>
                <div>Zone <strong><%= request.getParameter("zone") %></strong> occupancy reset to normal. Operating tariff restored to standard 1.0x rate.</div>
            </div>
        <% } %>

        <div class="section-header" style="margin-bottom: 20px;">
            <div>
                <h2 class="section-title">Facility Admin Console</h2>
                <p class="section-subtitle">Real-time facility occupancy, transaction ledger, bay overrides &amp; IoT sensor simulation</p>
            </div>
            <div style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
                <form action="<%= request.getContextPath() %>/admin" method="POST" style="display: inline; margin:0;">
                    <input type="hidden" name="action" value="triggerIotPulse">
                    <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                    <input type="hidden" name="tab" value="iot">
                    <button type="submit" class="btn btn-secondary btn-sm" title="Trigger simulated sensor arrival or departure event">
                        ⚡ Trigger Sensor Pulse
                    </button>
                </form>
            </div>
        </div>

        <!-- ==========================================================================
             MODULAR TAB NAVIGATION BAR (Compact, responsive, zero scrollbar overflow)
             ========================================================================== -->
        <div class="admin-nav-tabs" role="tablist">
            <button class="admin-tab-btn active" data-tab="overview" role="tab" title="Executive Summary & Key Metrics">
                Overview
            </button>
            <button class="admin-tab-btn" data-tab="analytics" role="tab" title="Occupancy Curves & Revenue Charts">
                Analytics
            </button>
            <button class="admin-tab-btn" data-tab="surge" role="tab" title="Dynamic Pricing & Peak-Hour Tariffs">
                Dynamic Pricing
                <% if (surgeZonesCount > 0) { %>
                    <span class="tab-badge surge"><%= surgeZonesCount %> Active</span>
                <% } %>
            </button>
            <button class="admin-tab-btn" data-tab="bays" role="tab" title="Visual Parking Bays Grid & Status Overrides">
                Bays Grid
                <span class="tab-badge"><%= totalBays %></span>
            </button>
            <button class="admin-tab-btn" data-tab="bookings" role="tab" title="Driver Bookings Audit Log & Transactions">
                Bookings Ledger
                <span class="tab-badge"><%= allBookings.size() %></span>
            </button>
            <button class="admin-tab-btn" data-tab="gate" role="tab" title="HyperPark Gate Movements & Active Parking Sessions">
                Gate &amp; Sessions
                <span class="tab-badge <%= (!activeParkingSessions.isEmpty()) ? "live" : "" %>" id="activeSessionsBadge">
                    <%= activeParkingSessions.size() %> Active
                </span>
            </button>
            <button class="admin-tab-btn" data-tab="users" role="tab" title="Registered Drivers & Application Users">
                Users &amp; Drivers
                <span class="tab-badge"><%= allUsers.size() %></span>
            </button>
            <button class="admin-tab-btn" data-tab="iot" role="tab" title="Ultrasonic & Geomagnetic Sensor Simulator">
                IoT Simulator
                <span class="tab-badge <%= Boolean.TRUE.equals(iotRunning) ? "live" : "" %>">
                    <%= Boolean.TRUE.equals(iotRunning) ? "Running" : "Paused" %>
                </span>
            </button>
            <button class="admin-tab-btn" data-tab="feedback" role="tab" title="Customer Reviews & Ratings">
                Feedback
                <span class="tab-badge"><%= allFeedback.size() %></span>
            </button>
            <button class="admin-tab-btn" data-tab="prediction" role="tab" title="Smart Occupancy Prediction & Capacity Forecasting">
                Smart Prediction
                <span class="tab-badge" style="background: rgba(14, 165, 233, 0.15); color: #0284c7;">AI Forecast</span>
            </button>
            <button class="admin-tab-btn" data-tab="reports" role="tab" title="Smart Parking Reports & Data Export (CSV & PDF)">
                Reports &amp; Export
                <span class="tab-badge" style="background: rgba(16, 185, 129, 0.15); color: #059669;">CSV &bull; PDF</span>
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
                    <div class="admin-stat-val">₹ <%= String.format(java.util.Locale.US, "%.0f", totalRev) %></div>
                    <div class="admin-stat-lbl">Total Revenue</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="analytics" title="Click to view Today's Revenue">
                    <div class="admin-stat-val">₹ <%= String.format(java.util.Locale.US, "%.0f", todayRev) %></div>
                    <div class="admin-stat-lbl">Today's Revenue</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="gate" title="Click to view Active Parking Sessions">
                    <div class="admin-stat-val" style="color: #059669;"><%= activeParkingSessions.size() %></div>
                    <div class="admin-stat-lbl">Active Parked</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="gate" title="Click to view Gate Movement Telemetry">
                    <div class="admin-stat-val" style="color: var(--color-primary);"><%= gateActivity.size() %></div>
                    <div class="admin-stat-lbl">Gate Movements</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="feedback" title="Click to view Driver Ratings">
                    <div class="admin-stat-val" style="color: #f59e0b;"><%= totalReviewsCount > 0 ? String.format(java.util.Locale.US, "%.1f ★", avgRating) : "No Reviews" %></div>
                    <div class="admin-stat-lbl">Driver Rating</div>
                </div>
                <div class="admin-stat-card admin-stat-card-clickable" data-jump-tab="users" title="Click to view Registered Users & Drivers">
                    <div class="admin-stat-val" style="color: var(--color-primary);"><%= allUsers.size() %></div>
                    <div class="admin-stat-lbl">Registered Users (<%= activeDriversCount %> Drivers)</div>
                </div>
            </div>

            <% if (surgeZonesCount > 0) { %>
                <div class="alert alert-warning" style="margin-bottom: 24px;">
                    <span>⚡</span>
                    <div><strong>High Demand Alert:</strong> <%= surgeZonesCount %> parking zone(s) have reached &ge;80% occupancy. Dynamic surge pricing (1.25x) is actively regulating parking demand.</div>
                </div>
            <% } %>

            <!-- Operational Facility Cards Grid -->
            <div class="overview-hub-grid">
                <!-- Dynamic Demand Pricing Card -->
                <div class="overview-hub-card">
                    <div>
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                            <h4 style="font-size: 1.05rem; font-weight: 800; color: var(--color-primary); margin:0;">
                                Dynamic Demand Pricing
                            </h4>
                            <% if (surgeZonesCount > 0) { %>
                                <span class="badge badge-warning" style="font-size: 0.72rem; font-weight: 800;">
                                    <%= surgeZonesCount %> Active (1.25x)
                                </span>
                            <% } else { %>
                                <span class="badge badge-success" style="font-size: 0.72rem;">Normal (1.0x)</span>
                            <% } %>
                        </div>
                        <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 12px; line-height: 1.45;">
                            <% if (highestOccZone != null) { %>
                                Peak facility: <strong>Zone <%= highestOccZone.getZoneId() %> (<%= highestOccZone.getFacilityName() %>)</strong> 
                                at <strong><%= highestOccZone.getOccupancyPercentage() %>% occupancy</strong> 
                                (<%= highestOccZone.isSurgeActive() ? "1.25x Surge Tariff Active: ₹50/hr" : "Standard Tariff: ₹40/hr" %>).
                            <% } else { %>
                                All parking zones currently operating under standard baseline tariffs.
                            <% } %>
                        </p>
                    </div>
                    <button class="btn btn-secondary btn-sm" data-jump-tab="surge" style="font-weight: 600;">
                        Manage Pricing ➔
                    </button>
                </div>

                <!-- Analytics & Peak Hours Card -->
                <div class="overview-hub-card">
                    <div>
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                            <h4 style="font-size: 1.05rem; font-weight: 800; color: var(--color-primary); margin:0;">
                                Occupancy &amp; Rush Hours
                            </h4>
                            <span class="badge badge-secondary" style="font-size: 0.72rem;">24-Hour Curve</span>
                        </div>
                        <p style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 12px; line-height: 1.45;">
                            Tracking 24-Hour curve across morning peak (08:00–10:00) &amp; evening peak (17:00–20:00). 
                            Total completed transactions: <strong><%= confirmedCount %></strong>.
                        </p>
                    </div>
                    <button class="btn btn-secondary btn-sm" data-jump-tab="analytics" style="font-weight: 600;">
                        View Analytics ➔
                    </button>
                </div>

                <!-- IoT Sensor Simulator Card -->
                <div class="overview-hub-card">
                    <div>
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                            <h4 style="font-size: 1.05rem; font-weight: 800; color: var(--color-primary); margin:0;">
                                IoT Sensor Simulator
                            </h4>
                            <span class="badge <%= Boolean.TRUE.equals(iotRunning) ? "badge-success" : "badge-secondary" %>" style="font-size: 0.72rem;">
                                <%= Boolean.TRUE.equals(iotRunning) ? "Running" : "Paused" %>
                            </span>
                        </div>
                        <p style="font-size: 0.82rem; color: var(--text-muted); margin-bottom: 12px; line-height: 1.45;">
                            Last event: <span style="font-weight: 600; color: var(--color-primary);"><%= iotLastEvent != null ? iotLastEvent : "Simulator standing by." %></span>
                        </p>
                    </div>
                    <button class="btn btn-secondary btn-sm" data-jump-tab="iot" style="font-weight: 600;">
                        Open Simulator ➔
                    </button>
                </div>
            </div>

            <!-- Operational System Status & Recent Activity Log -->
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 18px; margin-bottom: 24px;">
                <!-- System Health Card -->
                <div class="card" style="padding: 18px 20px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; padding-bottom: 8px; border-bottom: 1px solid var(--border-color);">
                        <h4 style="font-size: 0.95rem; font-weight: 800; color: var(--color-primary); margin:0;">
                            Operational System Status
                        </h4>
                        <span style="font-size: 0.72rem; color: var(--text-muted);">Real-time</span>
                    </div>
                    <div style="display: flex; flex-direction: column; gap: 10px; font-size: 0.85rem;">
                        <div style="display: flex; justify-content: space-between; align-items: center;">
                            <span style="color: var(--text-color);">Booking Engine &amp; Tariff Service</span>
                            <span class="badge badge-success" style="font-size: 0.72rem;">Online</span>
                        </div>
                        <div style="display: flex; justify-content: space-between; align-items: center;">
                            <span style="color: var(--text-color);">MySQL Database Connection Pool</span>
                            <span class="badge badge-success" style="font-size: 0.72rem;">Connected</span>
                        </div>
                        <div style="display: flex; justify-content: space-between; align-items: center;">
                            <span style="color: var(--text-color);">Ultrasonic Sensor Simulator</span>
                            <span class="badge <%= Boolean.TRUE.equals(iotRunning) ? "badge-success" : "badge-secondary" %>" style="font-size: 0.72rem;">
                                <%= Boolean.TRUE.equals(iotRunning) ? "Running" : "Paused" %>
                            </span>
                        </div>
                        <div style="display: flex; justify-content: space-between; align-items: center;">
                            <span style="color: var(--text-color);">Grace Expiration Sweep Service</span>
                            <span class="badge badge-success" style="font-size: 0.72rem;">Active (30m grace)</span>
                        </div>
                    </div>
                </div>

                <!-- Recent Activity Log Card -->
                <div class="card" style="padding: 18px 20px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; padding-bottom: 8px; border-bottom: 1px solid var(--border-color);">
                        <h4 style="font-size: 0.95rem; font-weight: 800; color: var(--color-primary); margin:0;">
                            Recent Facility Activity
                        </h4>
                        <button class="btn btn-secondary btn-sm" data-jump-tab="bookings" style="font-size: 0.72rem; padding: 2px 8px;">View All</button>
                    </div>
                    <div style="display: flex; flex-direction: column; gap: 8px; font-size: 0.82rem;">
                        <% 
                            if (allBookings == null || allBookings.isEmpty()) {
                        %>
                            <div style="color: var(--text-muted); font-size: 0.82rem; padding: 10px 0; text-align: center;">
                                No recent activity logged yet. System updates automatically upon driver reservation or sensor check-in.
                            </div>
                        <%
                            } else {
                                int actCount = Math.min(4, allBookings.size());
                                for (int i = 0; i < actCount; i++) {
                                    Booking ab = allBookings.get(i);
                        %>
                            <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 6px; border-bottom: 1px solid #f1f5f9;">
                                <div>
                                    <strong>#<%= ab.getBookingId() %></strong>: Bay <%= ab.getSlotId() %> &bull; <span style="font-family: monospace;"><%= ab.getVehicleNumber() %></span>
                                </div>
                                <span class="badge <%= ab.isActive() || ab.isConfirmed() ? "badge-success" : (ab.isCancelled() ? "badge-danger" : "badge-secondary") %>" style="font-size: 0.68rem;">
                                    <%= ab.getStatus() %>
                                </span>
                            </div>
                        <% 
                                } 
                            }
                        %>
                    </div>
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
                                <th>Bay &amp; Zone</th>
                                <th>Vehicle Plate</th>
                                <th class="text-right">Amount</th>
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
                                    <td class="text-right tabular-nums"><strong>₹ <%= String.format(java.util.Locale.US, "%.2f", b.getTotalAmount()) %></strong></td>
                                    <td>
                                        <% if (b.isActive()) { %>
                                            <span class="badge badge-success" style="display:inline-flex; align-items:center; gap:4px;">
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
             TAB PANE 2: ANALYTICS & CHARTS (Restrained Chart.js Suite)
             ========================================================================== -->
        <div id="tab-analytics" class="tab-pane" role="tabpanel">
            <div class="analytics-main-grid">
                <!-- Left: 24-Hour Occupancy Curve (Area Chart) -->
                <div class="analytics-chart-card">
                    <div class="analytics-chart-header">
                        <div>
                            <div class="analytics-chart-title">
                                <%= hasOccupancyData ? "Observed 24-Hour Facility Occupancy Curve" : "24-Hour Facility Occupancy Curve" %>
                            </div>
                            <p style="font-size: 0.8rem; color: var(--text-muted); margin: 2px 0 0 0;">
                                <%= hasOccupancyData ? "Hourly observed vehicle check-ins and active sessions (Today: 00:00 – 23:00 IST)" : "Hourly vehicle observation history across the 24-hour operating cycle (00:00 to 23:00 IST)" %>
                            </p>
                        </div>
                        <% if (hasOccupancyData) { %>
                            <div style="display: flex; gap: 6px; flex-wrap: wrap;">
                                <span class="chart-tag-badge" style="background: rgba(15, 23, 42, 0.08); color: #0f172a; border-color: rgba(15, 23, 42, 0.2);">
                                    Observed Records (00:00 – 23:00 IST)
                                </span>
                            </div>
                        <% } %>
                    </div>
                    <% if (hasOccupancyData) { %>
                        <div style="position: relative; height: 340px; width: 100%;">
                            <canvas id="occupancyCurveChart"></canvas>
                        </div>
                    <% } else { %>
                        <div class="analytics-empty-state" style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 340px; text-align: center; padding: 24px; color: var(--text-muted);">
                            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 12px; opacity: 0.45;">
                                <line x1="18" y1="20" x2="18" y2="10"></line>
                                <line x1="12" y1="20" x2="12" y2="4"></line>
                                <line x1="6" y1="20" x2="6" y2="14"></line>
                            </svg>
                            <h4 style="font-size: 1rem; font-weight: 700; color: var(--text-main); margin: 0 0 6px 0;">No Occupancy History Recorded Yet</h4>
                            <p style="font-size: 0.85rem; max-width: 440px; margin: 0; line-height: 1.45;">
                                Observed facility occupancy across 24-hour time ranges (00:00 to 23:00 IST) will appear here once vehicle check-ins or active parking sessions are recorded.
                            </p>
                        </div>
                    <% } %>
                </div>

                <!-- Right: Supported Metro Revenue & Payment Method Stack -->
                <div style="display: flex; flex-direction: column; gap: 20px;">
                    <!-- Revenue Breakdown by Supported Metro City -->
                    <div class="analytics-chart-card">
                        <div class="analytics-chart-header">
                            <div>
                                <div class="analytics-chart-title">
                                    Revenue by Metro Corridor
                                </div>
                                <p style="font-size: 0.8rem; color: var(--text-muted); margin: 2px 0 0 0;">
                                    <%= hasRevenueData ? "Settled collections from successful transactions" : "Settled revenue distribution across metro corridors" %>
                                </p>
                            </div>
                            <% if (hasRevenueData) { %>
                                <span class="chart-tag-badge" style="background: rgba(16, 185, 129, 0.12); color: #047857;">Settled Payments</span>
                            <% } %>
                        </div>
                        <% if (hasRevenueData) { %>
                            <div style="position: relative; height: 180px; width: 100%;">
                                <canvas id="cityRevenueChart"></canvas>
                            </div>
                        <% } else { %>
                            <div class="analytics-empty-state" style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 180px; text-align: center; padding: 16px; color: var(--text-muted);">
                                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 8px; opacity: 0.45;">
                                    <rect x="2" y="5" width="20" height="14" rx="2"></rect>
                                    <line x1="2" y1="10" x2="22" y2="10"></line>
                                </svg>
                                <div style="font-size: 0.88rem; font-weight: 700; color: var(--text-main); margin-bottom: 4px;">No Settled Revenue Recorded Yet</div>
                                <div style="font-size: 0.78rem; max-width: 280px; line-height: 1.4;">
                                    Metro revenue breakdown will display here as payments are successfully completed.
                                </div>
                            </div>
                        <% } %>
                    </div>

                    <!-- Payment Method Distribution (Doughnut Chart) -->
                    <div class="analytics-chart-card">
                        <div class="analytics-chart-header">
                            <div>
                                <div class="analytics-chart-title">
                                    Payment Method Distribution
                                </div>
                                <p style="font-size: 0.8rem; color: var(--text-muted); margin: 2px 0 0 0;">
                                    <%= hasPaymentData ? "Active payment channels used by drivers" : "Channels used for settled transactions" %>
                                </p>
                            </div>
                            <% if (hasPaymentData) { %>
                                <span class="chart-tag-badge" style="background: rgba(14, 165, 233, 0.12); color: #0284c7;">Active Channels</span>
                            <% } %>
                        </div>
                        <% if (hasPaymentData) { %>
                            <div style="position: relative; height: 180px; width: 100%;">
                                <canvas id="paymentDistChart"></canvas>
                            </div>
                        <% } else { %>
                            <div class="analytics-empty-state" style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 180px; text-align: center; padding: 16px; color: var(--text-muted);">
                                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 8px; opacity: 0.45;">
                                    <circle cx="12" cy="12" r="10"></circle>
                                    <path d="M12 6v6l4 2"></path>
                                </svg>
                                <div style="font-size: 0.88rem; font-weight: 700; color: var(--text-main); margin-bottom: 4px;">No Payment Data Yet</div>
                                <div style="font-size: 0.78rem; max-width: 280px; line-height: 1.4;">
                                    Payment method distribution will appear once transactions are processed.
                                </div>
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 3: DEMAND PRICING & PEAK TARIFFS (Clean White Card Layout)
             ========================================================================== -->
        <div id="tab-surge" class="tab-pane" role="tabpanel">
            <div class="surge-deck">
                <div style="display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 20px; margin-bottom: 24px; padding-bottom: 18px; border-bottom: 1px solid var(--border-color);">
                    <div>
                        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 6px;">
                            <h3 style="font-size: 1.25rem; font-weight: 800; color: var(--color-primary); margin: 0;">
                                Dynamic Demand Pricing &amp; Tariff Management
                            </h3>
                            <% if (surgeZonesCount > 0) { %>
                                <span class="badge badge-warning" style="font-weight: 800;">
                                    <%= surgeZonesCount %> ZONE<%= surgeZonesCount > 1 ? "S" : "" %> IN 1.25x SURGE
                                </span>
                            <% } else { %>
                                <span class="badge badge-success">
                                    ALL ZONES NORMAL (1.0x)
                                </span>
                            <% } %>
                        </div>
                        <p style="font-size: 0.85rem; color: var(--text-muted); max-width: 680px; margin: 0; line-height: 1.45;">
                            Adjusts facility tariffs in real time based on live bay occupancy. When a zone reaches or exceeds <strong>80% occupancy</strong>, the tariff scales by <strong>1.25x</strong> to manage parking demand.
                        </p>
                    </div>
                    <div style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
                        <form action="<%= request.getContextPath() %>/admin" method="POST" style="margin: 0; display: flex; gap: 8px;">
                            <input type="hidden" name="action" value="simulateSurge">
                            <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                            <input type="hidden" name="tab" value="surge">
                            <select name="zoneId" class="form-control" style="padding: 6px 12px; font-size: 0.82rem; width: auto;">
                                <% for (String city : metroCities) { 
                                    List<Zone> cZones = zonesByCity.get(city);
                                    if (cZones != null && !cZones.isEmpty()) {
                                %>
                                    <optgroup label="<%= city %>">
                                        <% for (Zone z : cZones) { %>
                                            <option value="<%= z.getZoneId() %>">Zone <%= z.getZoneId() %> - <%= z.getFacilityName() %></option>
                                        <% } %>
                                    </optgroup>
                                <%  } 
                                   } %>
                            </select>
                            <button type="submit" class="btn btn-warning btn-sm" style="font-weight: 700;">
                                ⚡ Simulate Surge (&gt;80%)
                            </button>
                        </form>
                        <form action="<%= request.getContextPath() %>/admin" method="POST" style="margin: 0;">
                            <input type="hidden" name="action" value="resetSurge">
                            <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                            <input type="hidden" name="tab" value="surge">
                            <input type="hidden" name="zoneId" value="B">
                            <button type="submit" class="btn btn-secondary btn-sm">
                                ↺ Reset Surge
                            </button>
                        </form>
                    </div>
                </div>

                <!-- City Filter Toolbar Buttons -->
                <div style="display: flex; gap: 8px; margin-bottom: 24px; flex-wrap: wrap;" class="city-filter-bar">
                    <button type="button" class="city-filter-btn active" data-city="all">
                        All Facilities (<%= zones != null ? zones.size() : 12 %> Zones)
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
                            <%= city %> (<%= cCount %>)
                            <% if (cSurge > 0) { %>
                                <span class="badge badge-warning" style="font-size: 0.68rem; margin-left: 4px; font-weight: 800;">⚡ <%= cSurge %></span>
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
                        <div class="city-cluster-block" data-city="<%= citySlug %>" style="margin-bottom: 30px;">
                            <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 10px; margin-bottom: 16px; border-bottom: 1px solid var(--border-color);">
                                <div style="display: flex; align-items: center; gap: 8px;">
                                    <h4 style="font-size: 1.15rem; font-weight: 800; color: var(--color-primary); margin: 0;">
                                        <%= city %> Corridor
                                    </h4>
                                    <span style="font-size: 0.8rem; color: var(--text-muted);">(<%= cZones.size() %> Parking Facilities)</span>
                                </div>
                                <div>
                                    <% if (cSurge > 0) { %>
                                        <span class="badge badge-warning" style="font-weight: 800; font-size: 0.72rem;">
                                            ⚡ <%= cSurge %> OF <%= cZones.size() %> IN 1.25x SURGE
                                        </span>
                                    <% } else { %>
                                        <span class="badge badge-success" style="font-size: 0.72rem;">
                                            ✓ All Normal (1.0x)
                                        </span>
                                    <% } %>
                                </div>
                            </div>

                            <!-- Zones Grid for this City -->
                            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px;">
                                <% for (Zone z : cZones) { 
                                    int occ = z.getOccupancyPercentage();
                                    boolean isSurge = z.isSurgeActive();
                                %>
                                    <div style="background: #ffffff; border: 1px solid <%= isSurge ? "#f59e0b" : "var(--border-color)" %>; border-radius: var(--border-radius-md); padding: 18px; box-shadow: var(--shadow-sm);">
                                        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 6px; gap: 8px;">
                                            <div>
                                                <strong style="color: var(--color-primary); font-size: 0.95rem; display: block;">
                                                    Zone <%= z.getZoneId() %>
                                                </strong>
                                                <span style="font-size: 0.82rem; color: var(--color-primary); font-weight: 600;">
                                                    <%= z.getFacilityName() %>
                                                </span>
                                            </div>
                                            <% if (isSurge) { %>
                                                <span class="badge badge-warning" style="font-size: 0.7rem; font-weight: 800; white-space: nowrap;">⚡ 1.25x SURGE</span>
                                            <% } else { %>
                                                <span class="badge badge-success" style="font-size: 0.7rem; white-space: nowrap;">1.0x NORMAL</span>
                                            <% } %>
                                        </div>
                                        <div style="font-size: 0.78rem; color: var(--text-muted); margin-bottom: 10px; line-height: 1.3;">
                                            📍 <%= z.getLocation() %>
                                        </div>
                                        <div style="display: flex; justify-content: space-between; font-size: 0.8rem; color: var(--text-muted); margin-bottom: 4px;">
                                            <span>Occupancy: <strong style="color: <%= isSurge ? "#d97706" : "var(--color-primary)" %>;"><%= occ %>%</strong> (<%= z.getTotalSlots() - z.getAvailableSlots() %>/<%= z.getTotalSlots() %> Bays)</span>
                                            <span>Tariff: <strong style="color: var(--color-primary);">₹ <%= String.format(java.util.Locale.US, "%.2f", z.getEffectiveHourlyRate()) %>/hr</strong></span>
                                        </div>
                                        <div class="surge-meter-progress">
                                            <div class="surge-meter-fill" style="width: <%= Math.min(100, occ) %>%; background: <%= isSurge ? "#f59e0b" : "#10b981" %>;"></div>
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
             TAB PANE 4: PARKING BAYS SUPERVISORY GRID (Clean scanable layout)
             ========================================================================== -->
        <div id="tab-bays" class="tab-pane" role="tabpanel">
            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header" style="flex-wrap: wrap; gap: 14px;">
                    <div>
                        <h3 style="font-size: 1.2rem; font-weight: 800; color: var(--color-primary); margin: 0 0 4px 0;">Parking Bays Supervisory Console</h3>
                        <p style="font-size: 0.85rem; color: var(--text-muted); margin: 0;">Organized by City Corridor &amp; Zone. Inspect live vehicle telemetry and override bay statuses.</p>
                    </div>
                    <div style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
                        <div class="view-mode-toggle" id="adminBayViewToggle" role="group" aria-label="Bay layout view mode">
                            <button type="button" class="view-mode-btn" data-view="grid" title="Multi-Zone Card Grid View">
                                ▦ Grid View
                            </button>
                            <button type="button" class="view-mode-btn active" data-view="map" title="Lot Vulture Architectural Visual Map">
                                🗺 Visual Lot Map
                            </button>
                        </div>
                        <div class="slot-legend" style="margin: 0; padding: 6px 14px;">
                            <div class="legend-item"><div class="legend-box available"></div><span>Available</span></div>
                            <div class="legend-item"><div class="legend-box booked"></div><span>Occupied</span></div>
                            <div class="legend-item"><div class="legend-box reserved"></div><span>Reserved</span></div>
                            <div class="legend-item"><div class="legend-box blocked"></div><span>Maintenance</span></div>
                        </div>
                    </div>
                </div>

                <!-- Visual Lot Map Facility Selector Toolbar (Shown in Map View) -->
                <div id="adminLotMapToolbar" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; margin-bottom: 20px; padding: 12px 18px; background: #f8fafc; border: 1px solid var(--border-color); border-radius: var(--border-radius-md);">
                    <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                        <label for="adminMapZoneSelect" style="font-size: 0.85rem; font-weight: 800; color: var(--color-primary); margin: 0;">
                            🏢 Monitored Facility:
                        </label>
                        <select id="adminMapZoneSelect" class="form-control" style="width: auto; padding: 6px 14px; font-size: 0.85rem; font-weight: 700;">
                            <% for (String city : metroCities) { 
                                List<Zone> cZones = zonesByCity.get(city);
                                if (cZones != null && !cZones.isEmpty()) {
                            %>
                                <optgroup label="<%= city %> Metropolitan Corridor">
                                    <% for (Zone cz : cZones) { %>
                                        <option value="<%= cz.getZoneId() %>" 
                                                data-hourly="<%= cz.getEffectiveHourlyRate() %>" 
                                                data-name="<%= cz.getFacilityName() %>" 
                                                data-location="<%= cz.getLocation() %>"
                                                data-city="<%= city %>">
                                            Zone <%= cz.getZoneId() %> &bull; <%= cz.getFacilityName() %> (<%= cz.getTotalSlots() %> Bays)
                                        </option>
                                    <% } %>
                                </optgroup>
                            <%  } 
                               } %>
                        </select>
                    </div>
                    <div style="font-size: 0.8rem; color: var(--text-muted); display: flex; align-items: center; gap: 6px;">
                        <span>🔒</span> Authorized supervisory mode active: Full plate and booking telemetry enabled.
                    </div>
                </div>

                <!-- Lot Vulture Interactive Blueprint for Admin -->
                <div id="adminLotMapContainer" style="display: block; margin-bottom: 24px;"></div>

                <!-- Traditional Grid Fallback Section (Toggled via Grid View button) -->
                <div id="adminBaysGridSection" style="display: none;">
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
                        <div class="bay-city-block" data-city="<%= citySlug %>" style="margin-bottom: 30px;">
                            <!-- City Cluster Banner -->
                            <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 18px; background: #f8fafc; border: 1px solid var(--border-color); color: var(--color-primary); border-radius: var(--border-radius-md); margin-bottom: 18px; flex-wrap: wrap; gap: 10px;">
                                <div style="display: flex; align-items: center; gap: 10px;">
                                    <div>
                                        <h4 style="font-size: 1.05rem; font-weight: 800; margin: 0; color: var(--color-primary);">
                                            <%= city %> Metropolitan Corridor
                                        </h4>
                                        <span style="font-size: 0.78rem; color: var(--text-muted);">
                                            <%= cZones.size() %> Facilities &bull; Total <%= cityTotalSlots %> Monitored Bays
                                        </span>
                                    </div>
                                </div>
                                <div style="display: flex; gap: 8px; align-items: center;">
                                    <span class="badge badge-success" style="font-size: 0.72rem;">
                                        <%= cityAvailSlots %> Available
                                    </span>
                                    <span class="badge badge-danger" style="font-size: 0.72rem;">
                                        <%= cityBookedSlots %> Occupied
                                    </span>
                                    <% if (cityBlockedSlots > 0) { %>
                                        <span class="badge badge-secondary" style="font-size: 0.72rem;">
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
                                                <span class="badge" style="background: var(--color-primary); color: #fff; font-weight: 800; font-size: 0.75rem;">
                                                    Zone <%= z.getZoneId() %>
                                                </span>
                                                <strong style="font-size: 1rem; color: var(--color-primary);">
                                                    <%= z.getFacilityName() %>
                                                </strong>
                                                <% if (z.isSurgeActive()) { %>
                                                    <span class="badge badge-warning" style="font-size: 0.68rem; font-weight: 800;">⚡ 1.25x SURGE</span>
                                                <% } %>
                                            </div>
                                            <div style="font-size: 0.78rem; color: var(--text-muted); margin-top: 3px;">
                                                📍 <%= z.getLocation() %> &bull; Tariff: <strong>₹ <%= String.format(java.util.Locale.US, "%.2f", z.getEffectiveHourlyRate()) %>/hr</strong>
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

                                    <!-- Grid for this Zone -->
                                    <div class="parking-grid">
                                        <% for (Slot s : zSlots) { 
                                            String statusLower = s.getStatus().toLowerCase();
                                        %>
                                            <div class="slot-box <%= statusLower %> admin-slot-clickable" 
                                                 data-slot-id="<%= s.getSlotId() %>" 
                                                 data-status="<%= s.getStatus() %>"
                                                 title="Click to override <%= s.getSlotId() %>">
                                                <div class="slot-type-badge"><%= s.getZoneId() %>-L<%= s.getFloor() %></div>
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
                </div> <!-- End #adminBaysGridSection -->
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 5: DRIVER BOOKINGS LEDGER
             ========================================================================== -->
        <div id="tab-bookings" class="tab-pane" role="tabpanel">
            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header">
                    <div>
                        <h3 style="font-size: 1.2rem; font-weight: 800; color: var(--color-primary);">Driver Bookings Ledger</h3>
                        <p style="font-size: 0.85rem; color: var(--text-muted);">Audit log of all parking transactions, durations, and billing statuses</p>
                    </div>
                    <div style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
                        <input type="text" id="bookingSearchInput" class="form-control" placeholder="Search ID, driver, VRN, bay..." style="padding: 7px 12px; font-size: 0.85rem; width: 200px;">
                        <select id="bookingZoneFilter" class="form-control" style="padding: 7px 12px; font-size: 0.85rem; width: 120px;">
                            <option value="ALL">All Zones</option>
                            <% for (Zone z : zones) { %>
                                <option value="<%= z.getZoneId() %>">Zone <%= z.getZoneId() %></option>
                            <% } %>
                        </select>
                        <select id="bookingStatusFilter" class="form-control" style="padding: 7px 12px; font-size: 0.85rem; width: 130px;">
                            <option value="ALL">All Statuses</option>
                            <option value="ACTIVE">ACTIVE</option>
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
                                <th data-sortable="true">Driver ⬍</th>
                                <th data-sortable="true">Bay &amp; Zone ⬍</th>
                                <th data-sortable="true">Vehicle Plate ⬍</th>
                                <th data-sortable="true">Reservation Time ⬍</th>
                                <th data-sortable="true">Actual Check-In ⬍</th>
                                <th data-sortable="true">Actual Checkout ⬍</th>
                                <th data-sortable="true">Total Duration ⬍</th>
                                <th data-sortable="true" class="text-right">Amount ⬍</th>
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

                                String adminResFormatted = b.getBookingTime() != null ? sdf.format(b.getBookingTime()) : "--";
                                String adminCheckinFormatted = b.getEntryTime() != null ? sdf.format(b.getEntryTime()) : (b.isReserved() ? "<span style='color:#b45309;font-weight:600;'>Awaiting Arrival</span>" : "--");
                                String adminCheckoutFormatted = b.getExitTime() != null ? sdf.format(b.getExitTime()) : (b.isActive() ? "<span style='color:#059669;font-weight:600;'>Currently Parked</span>" : "--");

                                String adminDurDisplay = "--";
                                if (b.isActive()) {
                                    adminDurDisplay = "<span style='color:#059669; font-weight:700;'>Live Stopwatch</span>";
                                } else if (b.getEntryTime() != null && b.getExitTime() != null) {
                                    long diffSec = Math.max(0, (b.getExitTime().getTime() - b.getEntryTime().getTime()) / 1000);
                                    long h = diffSec / 3600;
                                    long m = (diffSec % 3600) / 60;
                                    adminDurDisplay = h > 0 ? (h + "h " + (m < 10 ? "0" + m : m) + "m") : (Math.max(1, m) + "m");
                                } else if (b.isReserved()) {
                                    adminDurDisplay = "<span style='color:#b45309; font-size:0.82rem;'>Timer Not Started</span>";
                                } else if (b.getDurationHours() > 0) {
                                    adminDurDisplay = b.getDurationHours() + "h";
                                }
                            %>
                                <tr data-zone="<%= b.getZoneId() %>">
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
                                        <div style="font-size: 0.82rem; font-weight: 600;"><%= adminResFormatted %></div>
                                    </td>
                                    <td>
                                        <div style="font-size: 0.82rem;"><%= adminCheckinFormatted %></div>
                                    </td>
                                    <td>
                                        <div style="font-size: 0.82rem;"><%= adminCheckoutFormatted %></div>
                                    </td>
                                    <td>
                                        <%= adminDurDisplay %>
                                    </td>
                                    <td class="text-right tabular-nums"><strong>₹ <%= String.format(java.util.Locale.US, "%.2f", b.getTotalAmount()) %></strong></td>
                                    <td>
                                        <% if (b.isActive()) { %>
                                            <span class="badge badge-success booking-status-badge" data-status="<%= b.getStatus() %>" style="display:inline-flex; align-items:center; gap:4px;">
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
             TAB PANE: HYPERPARK VEHICLE ENTRY/EXIT & ACTIVE PARKING SESSIONS
             ========================================================================== -->
        <div id="tab-gate" class="tab-pane" role="tabpanel">
            <!-- HyperPark Financial Audit & Telemetry Overview KPI Bar -->
            <div class="admin-stat-grid" style="margin-bottom: 20px;">
                <div class="admin-stat-card" style="border-left: 4px solid #10b981;">
                    <div class="admin-stat-val" style="color: #059669;">₹ <%= String.format(java.util.Locale.US, "%.2f", totalRev) %></div>
                    <div class="admin-stat-lbl">Collected Revenue (Settled)</div>
                    <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 3px;">Completed &amp; paid sessions only</div>
                </div>
                <div class="admin-stat-card" style="border-left: 4px solid var(--color-primary);">
                    <div class="admin-stat-val" style="color: var(--color-primary);">₹ <%= String.format(java.util.Locale.US, "%.2f", todayRev) %></div>
                    <div class="admin-stat-lbl">Today's Revenue</div>
                    <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 3px;">Collected in current operating day</div>
                </div>
                <div class="admin-stat-card" style="border-left: 4px solid #f59e0b;">
                    <div class="admin-stat-val" style="color: #d97706;">₹ <%= String.format(java.util.Locale.US, "%.2f", pendingRev) %></div>
                    <div class="admin-stat-lbl">Pending Collections</div>
                    <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 3px;"><%= pendingCount %> vehicles departed &bull; awaiting payment</div>
                </div>
                <div class="admin-stat-card" style="border-left: 4px solid #3b82f6;">
                    <div class="admin-stat-val" style="color: #2563eb;">₹ <%= String.format(java.util.Locale.US, "%.2f", estimatedAccruedRevenue) %></div>
                    <div class="admin-stat-lbl">Live Parked Accrual</div>
                    <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 3px;">Estimated tariff for <%= activeParkingSessions.size() %> active vehicles</div>
                </div>
            </div>

            <!-- Prototype Telemetry Notice -->
            <div class="prototype-sim-banner">
                <span style="font-size: 1.1rem;">⚡</span>
                <div>
                    <strong>Prototype Telemetry Notice:</strong> All vehicle number plate scans, gate camera detections, and departure sensors are <strong>simulated IoT &amp; ANPR events</strong> for academic prototype demonstration.
                </div>
            </div>

            <!-- SECTION 1: Active Parking Sessions (Live In-Facility Vehicles) -->
            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header">
                    <div>
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <h3 style="font-size: 1.15rem; font-weight: 800; color: var(--color-primary); margin:0;">
                                Active Parking Sessions
                            </h3>
                            <span class="badge badge-success" style="font-size: 0.72rem; font-weight: 800;">
                                <%= activeParkingSessions.size() %> In Facility
                            </span>
                        </div>
                        <p style="font-size: 0.85rem; color: var(--text-muted); margin-top: 4px;">
                            Live vehicles currently occupying bays with active entry timestamps, running stopwatches, and dynamically accrued charges
                        </p>
                    </div>
                    <div class="table-filter-group">
                        <input type="text" id="activeSessionsSearchInput" class="form-control table-filter-input" placeholder="Search plate, driver, bay...">
                        <button type="button" class="btn btn-secondary btn-sm" onclick="location.reload();" title="Refresh session metrics">
                            🔄 Refresh
                        </button>
                    </div>
                </div>

                <div class="table-scroll-hint">↔ Scroll table horizontally to view all columns</div>
                <div class="table-responsive">
                    <table class="custom-table" id="activeSessionsTable">
                        <thead>
                            <tr>
                                <th>Vehicle Plate (VRN)</th>
                                <th>Driver Reference</th>
                                <th>Facility &amp; Bay</th>
                                <th>Actual Check-In</th>
                                <th>Elapsed Duration</th>
                                <th>Rate Tier &amp; Tariff</th>
                                <th>Live Accrued Charge</th>
                                <th>Billing Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (activeParkingSessions.isEmpty()) { %>
                                <tr>
                                    <td colspan="9" style="text-align: center; padding: 36px 20px; color: var(--text-muted);">
                                        <div style="font-size: 1.8rem; margin-bottom: 8px;">🅿️</div>
                                        <strong>No active parking sessions in progress.</strong><br>
                                        <span style="font-size: 0.85rem;">All parking bays are currently vacant or reserved. When drivers scan into a bay, their live session will stream here.</span>
                                    </td>
                                </tr>
                            <% } else { %>
                                <% for (Booking s : activeParkingSessions) { 
                                    long elapsedSec = s.getElapsedSeconds();
                                    long hrs = elapsedSec / 3600;
                                    long mins = (elapsedSec % 3600) / 60;
                                    long secs = elapsedSec % 60;
                                    String clockStr = String.format("%02d:%02d:%02d", hrs, mins, secs);
                                    double accrued = s.isPaymentPending() ? s.getTotalAmount() : s.getLiveEstimatedAmount(s.getHourlyRate());
                                    String rateStr = String.format(java.util.Locale.US, "₹%.2f/hr", s.getHourlyRate());
                                    String checkInFormatted = s.getEntryTime() != null ? new SimpleDateFormat("dd MMM, hh:mm a").format(s.getEntryTime()) : "--";
                                %>
                                    <tr class="active-session-row" 
                                        data-booking-id="<%= s.getBookingId() %>"
                                        data-entry-epoch="<%= s.getEntryTime() != null ? s.getEntryTime().getTime() : 0 %>"
                                        data-hourly-rate="<%= s.getHourlyRate() %>"
                                        data-pending="<%= s.isPaymentPending() %>">
                                        <td>
                                            <span class="vrn-plate"><%= s.getVehicleNumber() %></span>
                                        </td>
                                        <td>
                                            <div style="font-weight: 700; color: var(--color-primary);"><%= s.getUserName() != null ? s.getUserName() : "Driver" %></div>
                                            <span style="font-size: 0.75rem; color: var(--text-muted);"><%= s.getUserId() %></span>
                                        </td>
                                        <td>
                                            <div style="font-weight: 700; color: #0f172a;"><%= s.getSlotId() %></div>
                                            <span style="font-size: 0.75rem; color: var(--text-muted);">Zone <%= s.getZoneId() %></span>
                                        </td>
                                        <td>
                                            <div style="font-size: 0.85rem; font-weight: 600;"><%= checkInFormatted %></div>
                                            <% if (s.getBookingTime() != null) { %>
                                                <div style="font-size: 0.72rem; color: var(--text-muted);">Res: <%= new SimpleDateFormat("dd MMM, hh:mm a").format(s.getBookingTime()) %></div>
                                            <% } %>
                                        </td>
                                        <td>
                                            <span class="stopwatch-live" id="stopwatch-<%= s.getBookingId() %>">
                                                ⏱ <span class="stopwatch-digits"><%= clockStr %></span>
                                            </span>
                                        </td>
                                        <td>
                                            <span style="font-weight: 700; color: #1e293b;"><%= rateStr %></span>
                                        </td>
                                        <td>
                                            <span style="font-weight: 800; color: #059669; font-size: 1rem;" class="live-accrued-val" id="accrued-<%= s.getBookingId() %>">
                                                ₹ <%= String.format(java.util.Locale.US, "%.2f", accrued) %>
                                            </span>
                                        </td>
                                        <td>
                                            <% if (s.isPaymentPending()) { %>
                                                <span class="badge badge-warning" style="font-size: 0.72rem; font-weight: 800;">
                                                    PAYMENT PENDING
                                                </span>
                                            <% } else { %>
                                                <span class="badge badge-success" style="font-size: 0.72rem; font-weight: 800;">
                                                    ESTIMATED (ACTIVE)
                                                </span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <button type="button" class="btn btn-secondary btn-sm" onclick="switchAdminTab('bays', true); if(window.LotMap) window.LotMap.selectSlot('<%= s.getSlotId() %>');" title="View bay location on visual map">
                                                View Bay ↗
                                            </button>
                                        </td>
                                    </tr>
                                <% } %>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- SECTION 2: Vehicle Entry & Exit Gate Activity Ledger -->
            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header">
                    <div>
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <h3 style="font-size: 1.15rem; font-weight: 800; color: var(--color-primary); margin:0;">
                                Entry &amp; Exit Activity Ledger
                            </h3>
                            <span class="badge badge-primary" style="font-size: 0.72rem; font-weight: 800;">
                                <%= gateActivity.size() %> Logged Movements
                            </span>
                        </div>
                        <p style="font-size: 0.85rem; color: var(--text-muted); margin-top: 4px;">
                            Chronological gate movement events captured by automated ANPR camera simulation and facility departure sensors
                        </p>
                    </div>
                    <div class="table-filter-group">
                        <input type="text" id="gateSearchInput" class="form-control table-filter-input" placeholder="Search plate, bay, event...">
                        <select id="gateEventTypeFilter" class="form-control table-filter-select">
                            <option value="ALL">All Movements</option>
                            <option value="ENTRY">ENTRY (Check-In)</option>
                            <option value="EXIT">EXIT (Departure)</option>
                            <option value="REJECTED">REJECTED (Access Denied)</option>
                        </select>
                    </div>
                </div>

                <div class="table-scroll-hint">↔ Scroll table horizontally to view all columns</div>
                <div class="table-responsive">
                    <table class="custom-table" id="gateActivityTable">
                        <thead>
                            <tr>
                                <th>Event Time</th>
                                <th>Movement</th>
                                <th>Vehicle Plate</th>
                                <th>Driver Reference</th>
                                <th>Bay &amp; Facility</th>
                                <th>Booking Ref</th>
                                <th>Telemetry Source</th>
                                <th>Gate Result</th>
                                <th>Payment / Txn Ref</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (gateActivity.isEmpty()) { %>
                                <tr>
                                    <td colspan="9" style="text-align: center; padding: 36px 20px; color: var(--text-muted);">
                                        <div style="font-size: 1.8rem; margin-bottom: 8px;">🚪</div>
                                        <strong>No gate activity recorded yet.</strong><br>
                                        <span style="font-size: 0.85rem;">As vehicles enter through simulated ANPR gates or depart via outgate sensors, events will log here.</span>
                                    </td>
                                </tr>
                            <% } else { %>
                                <% for (GateActivityEvent g : gateActivity) { 
                                    String eventTimeFormatted = g.getEventTime() != null ? new SimpleDateFormat("dd MMM, hh:mm:ss a").format(g.getEventTime()) : "--";
                                %>
                                    <tr class="gate-event-row" data-event-type="<%= g.getEventType() %>">
                                        <td>
                                            <div style="font-size: 0.82rem; font-weight: 700; color: #1e293b;"><%= eventTimeFormatted %></div>
                                        </td>
                                        <td>
                                            <% if (g.isEntry()) { %>
                                                <span class="gate-badge-entry">⬇ ENTRY</span>
                                                <div style="font-size:0.7rem; color: #059669; margin-top:2px; font-weight:600;">Check-in: Session Start</div>
                                            <% } else if (g.isRejected()) { %>
                                                <span class="gate-badge-danger" style="background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; padding: 3px 8px; border-radius: 12px; font-weight: 700; font-size: 0.75rem;">⛔ REJECTED</span>
                                            <% } else { %>
                                                <span class="gate-badge-exit">⬆ EXIT</span>
                                                <div style="font-size:0.7rem; color: #2563eb; margin-top:2px; font-weight:600;">Duration: <%= g.getDurationFormatted() %></div>
                                            <% } %>
                                        </td>
                                        <td>
                                            <span class="vrn-plate"><%= g.getVehicleNumber() %></span>
                                        </td>
                                        <td>
                                            <div style="font-weight: 700; color: var(--color-primary); font-size: 0.85rem;"><%= g.getUserName() != null ? g.getUserName() : "Driver" %></div>
                                            <span style="font-size: 0.72rem; color: var(--text-muted);"><%= g.getUserId() %></span>
                                        </td>
                                        <td>
                                            <div style="font-weight: 700; font-size: 0.85rem;"><%= g.getSlotId() %></div>
                                            <span style="font-size: 0.72rem; color: var(--text-muted);"><%= g.getZoneName() != null ? g.getZoneName() : ("Zone " + g.getZoneId()) %></span>
                                        </td>
                                        <td>
                                            <span style="font-family: monospace; font-size: 0.8rem; font-weight: 700; color: #475569;">
                                                <%= (g.getBookingId() > 0) ? ("#" + g.getBookingId()) : "--" %>
                                            </span>
                                            <% if (g.getBookingTime() != null) { %>
                                                <div style="font-size:0.7rem; color: var(--text-muted);">Res: <%= new SimpleDateFormat("dd MMM, hh:mm a").format(g.getBookingTime()) %></div>
                                            <% } %>
                                        </td>
                                        <td>
                                            <span style="font-size: 0.75rem; color: var(--text-muted); display: inline-flex; align-items: center; gap: 4px;">
                                                <span>⚡</span> <%= g.getEventSource() %>
                                            </span>
                                        </td>
                                        <td>
                                            <% if (g.isRejected()) { %>
                                                <span style="font-size: 0.8rem; font-weight: 700; color: #dc2626;">
                                                    ⛔ <%= g.getEventResult() %>
                                                </span>
                                            <% } else if (g.isEntry()) { %>
                                                <span style="font-size: 0.8rem; font-weight: 700; color: #059669;">
                                                    ✓ <%= g.getEventResult() %>
                                                </span>
                                            <% } else if ("COMPLETED".equalsIgnoreCase(g.getBookingStatus())) { %>
                                                <span style="font-size: 0.8rem; font-weight: 700; color: #2563eb;">
                                                    ✓ <%= g.getEventResult() %>
                                                </span>
                                            <% } else { %>
                                                <span style="font-size: 0.8rem; font-weight: 700; color: #d97706;">
                                                    ⏳ <%= g.getEventResult() %>
                                                </span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <% if (g.isRejected()) { %>
                                                <span style="font-size: 0.75rem; color: #dc2626; font-weight: 600;">
                                                    Access Denied
                                                </span>
                                            <% } else if ("COMPLETED".equalsIgnoreCase(g.getPaymentStatus())) { %>
                                                <span class="badge badge-success" style="font-size: 0.72rem; font-weight: 800;">
                                                    PAID (₹ <%= String.format(java.util.Locale.US, "%.0f", g.getAmount()) %>)
                                                </span>
                                                <div style="font-size: 0.7rem; font-family: monospace; color: var(--text-muted); margin-top: 2px;">
                                                    <%= g.getTransactionId() != null && !g.getTransactionId().isEmpty() ? g.getTransactionId() : "--" %>
                                                </div>
                                            <% } else if ("PENDING".equalsIgnoreCase(g.getPaymentStatus())) { %>
                                                <span class="badge badge-warning" style="font-size: 0.72rem; font-weight: 800;">
                                                    PENDING (₹ <%= String.format(java.util.Locale.US, "%.0f", g.getAmount()) %>)
                                                </span>
                                            <% } else { %>
                                                <span style="font-size: 0.75rem; color: var(--text-muted); font-style: italic;">
                                                    Accruing in bay
                                                </span>
                                            <% } %>
                                        </td>
                                    </tr>
                                <% } %>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 6: REGISTERED USERS & DRIVERS (Account Directory & Activity Audit)
             ========================================================================== -->
        <div id="tab-users" class="tab-pane" role="tabpanel">
            <!-- User Metrics Summary Cards -->
            <div class="admin-stat-grid" style="margin-bottom: 20px;">
                <div class="admin-stat-card">
                    <div class="admin-stat-val"><%= allUsers.size() %></div>
                    <div class="admin-stat-lbl">Total Registered Accounts</div>
                </div>
                <div class="admin-stat-card">
                    <div class="admin-stat-val" style="color: var(--color-primary);"><%= activeDriversCount %></div>
                    <div class="admin-stat-lbl">Active Drivers</div>
                </div>
                <div class="admin-stat-card">
                    <div class="admin-stat-val" style="color: var(--color-status-available);"><%= adminUsersCount %></div>
                    <div class="admin-stat-lbl">System Administrators</div>
                </div>
                <div class="admin-stat-card">
                    <div class="admin-stat-val"><%= allBookings.size() %></div>
                    <div class="admin-stat-lbl">Total Parking Sessions</div>
                </div>
            </div>

            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header">
                    <div>
                        <h3 style="font-size: 1.2rem; font-weight: 800; color: var(--color-primary);">Registered Drivers &amp; Users Directory</h3>
                        <p style="font-size: 0.85rem; color: var(--text-muted);">Accounts authenticated with username and password, with reservation activity and contact details</p>
                    </div>
                    <div style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
                        <input type="text" id="userSearchInput" class="form-control" placeholder="Search name, email, phone, ID..." style="padding: 7px 12px; font-size: 0.85rem; width: 220px;">
                        <select id="userRoleFilter" class="form-control" style="padding: 7px 12px; font-size: 0.85rem; width: 140px;">
                            <option value="ALL">All Roles</option>
                            <option value="USER">Drivers (USER)</option>
                            <option value="ADMIN">Admins (ADMIN)</option>
                        </select>
                    </div>
                </div>

                <div class="table-responsive">
                    <table class="custom-table" id="adminUsersTable">
                        <thead>
                            <tr>
                                <th data-sortable="true">User ID ⇅</th>
                                <th data-sortable="true">Driver / User Name ⇅</th>
                                <th data-sortable="true">Email Address ⇅</th>
                                <th>Phone Number</th>
                                <th data-sortable="true">Account Role ⇅</th>
                                <th data-sortable="true">Total Bookings ⇅</th>
                                <th data-sortable="true">Registration Date ⇅</th>
                                <th>Account Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (allUsers.isEmpty()) { %>
                                <tr>
                                    <td colspan="8" style="text-align: center; padding: 36px 20px; color: var(--text-muted);">
                                        <div style="font-size: 1.3rem; margin-bottom: 6px;">👥</div>
                                        <div>No registered drivers or users found.</div>
                                    </td>
                                </tr>
                            <% } else {
                                for (User u : allUsers) {
                                    int bCount = userBookingCounts.getOrDefault(u.getUserId(), 0);
                                    String regDate = u.getCreatedAt() != null ? sdf.format(u.getCreatedAt()) : "Pre-configured";
                                    boolean isAdmin = u.isAdmin();
                            %>
                                <tr data-role="<%= u.getRole() != null ? u.getRole().toUpperCase() : "USER" %>">
                                    <td>
                                        <span class="badge <%= isAdmin ? "badge-secondary" : "badge-outline" %>" style="font-family: monospace; font-size: 0.8rem;">
                                            <%= com.parkingsystem.util.HtmlEscaper.escape(u.getUserId()) %>
                                        </span>
                                    </td>
                                    <td>
                                        <div style="font-weight: 700; color: var(--color-primary);">
                                            <%= com.parkingsystem.util.HtmlEscaper.escape(u.getName() != null ? u.getName() : "Driver") %>
                                        </div>
                                    </td>
                                    <td>
                                        <div style="font-size: 0.86rem; color: var(--text-color);">
                                            <%= com.parkingsystem.util.HtmlEscaper.escape(u.getEmail() != null ? u.getEmail() : "--") %>
                                        </div>
                                    </td>
                                    <td>
                                        <div style="font-size: 0.85rem; color: var(--text-muted);">
                                            <%= com.parkingsystem.util.HtmlEscaper.escape(u.getPhoneNumber() != null && !u.getPhoneNumber().isEmpty() ? u.getPhoneNumber() : "--") %>
                                        </div>
                                    </td>
                                    <td>
                                        <span class="user-role-badge <%= isAdmin ? "badge-danger" : "badge-info" %>" data-role="<%= u.getRole() != null ? u.getRole().toUpperCase() : "USER" %>" style="font-size: 0.75rem; padding: 3px 8px; border-radius: 4px; font-weight: 700;">
                                            <%= isAdmin ? "ADMIN" : "DRIVER" %>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge <%= bCount > 0 ? "badge-success" : "badge-secondary" %>" style="font-weight: 700;">
                                            <%= bCount %> <%= bCount == 1 ? "booking" : "bookings" %>
                                        </span>
                                    </td>
                                    <td style="font-size: 0.82rem; color: var(--text-muted);">
                                        <%= regDate %>
                                    </td>
                                    <td>
                                        <span class="badge badge-success" style="font-size: 0.72rem; padding: 2px 7px;">
                                            Active
                                        </span>
                                    </td>
                                </tr>
                            <%  }
                               } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 7: IOT SENSOR HARDWARE SIMULATOR (Prototype / Academic Demo)
             ========================================================================== -->
        <div id="tab-iot" class="tab-pane" role="tabpanel">
            <div class="iot-panel">
                <div>
                    <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 6px;">
                        <h3 style="font-size: 1.25rem; font-weight: 800; color: var(--color-primary); margin: 0;">IoT Sensor Simulator</h3>
                        <div id="iotLiveStatus">
                            <% if (Boolean.TRUE.equals(iotRunning)) { %>
                                <span class="badge badge-success">ACTIVE &amp; BROADCASTING</span>
                            <% } else { %>
                                <span class="badge badge-secondary">PAUSED</span>
                            <% } %>
                        </div>
                    </div>
                    <p style="font-size: 0.85rem; color: var(--text-muted); max-width: 600px; margin: 4px 0 0 0; line-height: 1.45;">
                        Simulates physical ultrasonic presence and geomagnetic parking sensors sending vehicle arrival/departure pulses for academic demonstration. 
                        <strong>Protected by JDBC row locks</strong> to prevent overwriting active driver bookings.
                    </p>
                    <div style="font-size: 0.82rem; color: var(--color-primary); font-weight: 600; margin-top: 10px;" id="iotLastEventText">
                        Last Event: <%= iotLastEvent != null ? iotLastEvent : "Simulator standing by." %>
                    </div>
                </div>
                <div style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
                    <form action="<%= request.getContextPath() %>/admin" method="POST" style="margin: 0;">
                        <input type="hidden" name="action" value="toggleIot">
                        <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                        <input type="hidden" name="tab" value="iot">
                        <% if (Boolean.TRUE.equals(iotRunning)) { %>
                            <button type="submit" class="btn btn-danger btn-sm">Pause Simulation</button>
                        <% } else { %>
                            <button type="submit" class="btn btn-primary btn-sm">Start Sensor Simulator</button>
                        <% } %>
                    </form>
                    <form action="<%= request.getContextPath() %>/admin" method="POST" style="margin: 0;">
                        <input type="hidden" name="action" value="triggerIotPulse">
                        <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                        <input type="hidden" name="tab" value="iot">
                        <button type="submit" class="btn btn-secondary btn-sm">
                            Trigger Single Event
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 7: DRIVER FEEDBACK & RATINGS (With Dynamic Star Distribution)
             ========================================================================== -->
        <div id="tab-feedback" class="tab-pane" role="tabpanel">
            <div class="card">
                <div class="card-header">
                    <div>
                        <h3 style="font-size: 1.2rem; font-weight: 800; color: var(--color-primary);">Driver Feedback &amp; Reviews</h3>
                        <p style="font-size: 0.85rem; color: var(--text-muted);">Real customer satisfaction ratings submitted after completed parking sessions</p>
                    </div>
                </div>

                <!-- Dynamically Computed Star Rating Distribution Summary -->
                <div class="feedback-rating-deck">
                    <div style="text-align: center; border-right: 1px solid var(--border-color); padding-right: 18px;">
                        <div style="font-size: 2.8rem; font-weight: 800; color: var(--color-primary); line-height: 1;">
                            <%= totalReviewsCount > 0 ? String.format(java.util.Locale.US, "%.1f", avgRating) : "--" %>
                        </div>
                        <div style="color: #f59e0b; font-size: 1.1rem; margin: 4px 0;">
                            <%= totalReviewsCount > 0 ? "★★★★★" : "☆☆☆☆☆" %>
                        </div>
                        <div style="font-size: 0.78rem; color: var(--text-muted);">
                            <%= totalReviewsCount %> Verified Reviews
                        </div>
                    </div>
                    <div style="display: flex; flex-direction: column; gap: 6px;">
                        <!-- 5 Star -->
                        <div style="display: flex; align-items: center; gap: 10px; font-size: 0.8rem;">
                            <span style="width: 50px; font-weight: 600;">5 Stars</span>
                            <div style="flex: 1; height: 8px; background: #e2e8f0; border-radius: 4px; overflow: hidden;">
                                <div style="height: 100%; background: #10b981; width: <%= totalReviewsCount > 0 ? (star5Count * 100 / totalReviewsCount) : 0 %>%;"></div>
                            </div>
                            <span style="width: 30px; text-align: right; color: var(--text-muted);"><%= star5Count %></span>
                        </div>
                        <!-- 4 Star -->
                        <div style="display: flex; align-items: center; gap: 10px; font-size: 0.8rem;">
                            <span style="width: 50px; font-weight: 600;">4 Stars</span>
                            <div style="flex: 1; height: 8px; background: #e2e8f0; border-radius: 4px; overflow: hidden;">
                                <div style="height: 100%; background: #0284c7; width: <%= totalReviewsCount > 0 ? (star4Count * 100 / totalReviewsCount) : 0 %>%;"></div>
                            </div>
                            <span style="width: 30px; text-align: right; color: var(--text-muted);"><%= star4Count %></span>
                        </div>
                        <!-- 3 Star -->
                        <div style="display: flex; align-items: center; gap: 10px; font-size: 0.8rem;">
                            <span style="width: 50px; font-weight: 600;">3 Stars</span>
                            <div style="flex: 1; height: 8px; background: #e2e8f0; border-radius: 4px; overflow: hidden;">
                                <div style="height: 100%; background: #f59e0b; width: <%= totalReviewsCount > 0 ? (star3Count * 100 / totalReviewsCount) : 0 %>%;"></div>
                            </div>
                            <span style="width: 30px; text-align: right; color: var(--text-muted);"><%= star3Count %></span>
                        </div>
                        <!-- 2 Star -->
                        <div style="display: flex; align-items: center; gap: 10px; font-size: 0.8rem;">
                            <span style="width: 50px; font-weight: 600;">2 Stars</span>
                            <div style="flex: 1; height: 8px; background: #e2e8f0; border-radius: 4px; overflow: hidden;">
                                <div style="height: 100%; background: #f97316; width: <%= totalReviewsCount > 0 ? (star2Count * 100 / totalReviewsCount) : 0 %>%;"></div>
                            </div>
                            <span style="width: 30px; text-align: right; color: var(--text-muted);"><%= star2Count %></span>
                        </div>
                        <!-- 1 Star -->
                        <div style="display: flex; align-items: center; gap: 10px; font-size: 0.8rem;">
                            <span style="width: 50px; font-weight: 600;">1 Star</span>
                            <div style="flex: 1; height: 8px; background: #e2e8f0; border-radius: 4px; overflow: hidden;">
                                <div style="height: 100%; background: #ef4444; width: <%= totalReviewsCount > 0 ? (star1Count * 100 / totalReviewsCount) : 0 %>%;"></div>
                            </div>
                            <span style="width: 30px; text-align: right; color: var(--text-muted);"><%= star1Count %></span>
                        </div>
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
                                <tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 24px;">No driver reviews submitted yet. Live reviews submitted by drivers after completing parking sessions will appear here.</td></tr>
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

        <!-- ==========================================================================
             TAB PANE 8: SMART OCCUPANCY PREDICTION & CAPACITY FORECASTING
             ========================================================================== -->
        <div id="tab-prediction" class="tab-pane" role="tabpanel">
            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
                    <div>
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <h3 style="font-size: 1.25rem; font-weight: 800; color: var(--color-primary); margin: 0;">Smart Occupancy Prediction</h3>
                            <span class="badge" style="background: rgba(14, 165, 233, 0.15); color: #0284c7; font-weight: 700; padding: 3px 8px; border-radius: 6px; font-size: 0.75rem;">AI Forecast Engine</span>
                        </div>
                        <p style="font-size: 0.85rem; color: var(--text-muted); margin: 4px 0 0 0;">
                            Empirical probabilistic demand modeling (+1h, +3h, +6h) calibrated on verified parking events
                        </p>
                    </div>

                    <!-- Facility Selection & Snapshot Controls -->
                    <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                        <form method="GET" action="<%= request.getContextPath() %>/admin" style="margin: 0; display: flex; align-items: center; gap: 8px;">
                            <input type="hidden" name="tab" value="prediction">
                            <label for="predZoneSelect" style="font-size: 0.85rem; font-weight: 700; color: var(--text-muted); margin: 0;">Facility:</label>
                            <select id="predZoneSelect" name="predZone" class="form-control" onchange="this.form.submit()" style="padding: 6px 12px; font-size: 0.85rem; font-weight: 600; min-width: 220px;">
                                <% if (zones != null) { %>
                                    <% for (Zone z : zones) { %>
                                        <option value="<%= z.getZoneId() %>" <%= z.getZoneId().equals(predZoneId) ? "selected" : "" %>>
                                            Zone <%= z.getZoneId() %> — <%= z.getName() %> (<%= z.getCity() %>)
                                        </option>
                                    <% } %>
                                <% } %>
                            </select>
                            <noscript><button type="submit" class="btn btn-primary btn-sm">View</button></noscript>
                        </form>

                        <form method="POST" action="<%= request.getContextPath() %>/admin" style="margin: 0;">
                            <input type="hidden" name="action" value="recordSnapshot">
                            <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                            <input type="hidden" name="tab" value="prediction">
                            <input type="hidden" name="predZone" value="<%= predZoneId %>">
                            <button type="submit" class="btn btn-secondary btn-sm" title="Capture current bay occupancy across all zones to telemetry log" style="display: flex; align-items: center; gap: 6px; font-weight: 600;">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                                Log Telemetry Snapshot
                            </button>
                        </form>
                    </div>
                </div>

                <!-- Forecast Metric Cards Grid -->
                <% if (currentPrediction != null) { %>
                    <div style="padding: 24px; display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 18px; border-bottom: 1px solid var(--border-color); background: #fafbfc;">
                        <!-- Card 1: Ground Truth (Now) -->
                        <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 10px; padding: 18px; box-shadow: 0 1px 3px rgba(0,0,0,0.04);">
                            <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
                                <span style="font-size: 0.8rem; font-weight: 700; color: var(--text-muted); text-transform: uppercase;">Live Now</span>
                                <span style="font-size: 0.72rem; font-weight: 700; color: #0284c7; background: rgba(14, 165, 233, 0.1); padding: 2px 6px; border-radius: 4px;">Ground Truth</span>
                            </div>
                            <div style="font-size: 2.2rem; font-weight: 800; color: var(--color-primary); line-height: 1.1;">
                                <%= Math.round(currentPrediction.getLiveOccupancyPercent()) %>%
                            </div>
                            <div style="font-size: 0.85rem; color: var(--text-muted); margin-top: 4px;">
                                <strong><%= currentPrediction.getLiveAvailableBays() %></strong> / <%= currentPrediction.getTotalBays() %> bays available
                            </div>
                            <div style="margin-top: 10px; background: #e2e8f0; height: 6px; border-radius: 3px; overflow: hidden;">
                                <div style="background: <%= currentPrediction.getLiveOccupancyPercent() > 75 ? "#ef4444" : "var(--color-primary)" %>; height: 100%; width: <%= currentPrediction.getLiveOccupancyPercent() %>%;"></div>
                            </div>
                        </div>

                        <!-- Card 2: +1 Hour Forecast -->
                        <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 10px; padding: 18px; box-shadow: 0 1px 3px rgba(0,0,0,0.04);">
                            <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
                                <span style="font-size: 0.8rem; font-weight: 700; color: var(--text-muted); text-transform: uppercase;">+1 Hour Forecast</span>
                                <% if (currentPrediction.isSufficientData()) { %>
                                    <% String t1 = currentPrediction.getTrendDirection(); %>
                                    <span style="font-size: 0.72rem; font-weight: 700; color: <%= "UP".equals(t1) ? "#b45309" : ("DOWN".equals(t1) ? "#047857" : "#475569") %>; background: <%= "UP".equals(t1) ? "rgba(245, 158, 11, 0.12)" : ("DOWN".equals(t1) ? "rgba(16, 185, 129, 0.12)" : "rgba(100, 116, 139, 0.12)") %>; padding: 2px 6px; border-radius: 4px;">
                                        <%= "UP".equals(t1) ? "↗ Inflow Surge" : ("DOWN".equals(t1) ? "↘ Outflow Release" : "→ Stable Flow") %>
                                    </span>
                                <% } else { %>
                                    <span style="font-size: 0.72rem; font-weight: 700; color: #94a3b8; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;">
                                        Awaiting Data
                                    </span>
                                <% } %>
                            </div>
                            <div style="font-size: 2.2rem; font-weight: 800; color: <%= currentPrediction.isSufficientData() ? "#1e3a8a" : "#94a3b8" %>; line-height: 1.1;">
                                <%= currentPrediction.isSufficientData() ? (Math.round(currentPrediction.getPredicted1hPercent()) + "%") : "--" %>
                            </div>
                            <div style="font-size: 0.85rem; color: var(--text-muted); margin-top: 4px;">
                                <%= currentPrediction.isSufficientData() ? ("<strong>~" + currentPrediction.getPredicted1hAvailable() + "</strong> bays expected free") : "Requires min. 3 sessions" %>
                            </div>
                            <div style="margin-top: 10px; background: #e2e8f0; height: 6px; border-radius: 3px; overflow: hidden;">
                                <div style="background: #3b82f6; height: 100%; width: <%= currentPrediction.isSufficientData() ? currentPrediction.getPredicted1hPercent() : 0 %>%;"></div>
                            </div>
                        </div>

                        <!-- Card 3: +3 Hours Forecast -->
                        <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 10px; padding: 18px; box-shadow: 0 1px 3px rgba(0,0,0,0.04);">
                            <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
                                <span style="font-size: 0.8rem; font-weight: 700; color: var(--text-muted); text-transform: uppercase;">+3 Hours Forecast</span>
                                <span style="font-size: 0.72rem; font-weight: 700; color: <%= currentPrediction.isSufficientData() ? "#6366f1" : "#94a3b8" %>; background: <%= currentPrediction.isSufficientData() ? "rgba(99, 102, 241, 0.12)" : "#f1f5f9" %>; padding: 2px 6px; border-radius: 4px;">
                                    <%= currentPrediction.isSufficientData() ? "Mid-Term Window" : "Awaiting Data" %>
                                </span>
                            </div>
                            <div style="font-size: 2.2rem; font-weight: 800; color: <%= currentPrediction.isSufficientData() ? "#4338ca" : "#94a3b8" %>; line-height: 1.1;">
                                <%= currentPrediction.isSufficientData() ? (Math.round(currentPrediction.getPredicted3hPercent()) + "%") : "--" %>
                            </div>
                            <div style="font-size: 0.85rem; color: var(--text-muted); margin-top: 4px;">
                                <%= currentPrediction.isSufficientData() ? ("<strong>~" + currentPrediction.getPredicted3hAvailable() + "</strong> bays expected free") : "Requires min. 3 sessions" %>
                            </div>
                            <div style="margin-top: 10px; background: #e2e8f0; height: 6px; border-radius: 3px; overflow: hidden;">
                                <div style="background: #6366f1; height: 100%; width: <%= currentPrediction.isSufficientData() ? currentPrediction.getPredicted3hPercent() : 0 %>%;"></div>
                            </div>
                        </div>

                        <!-- Card 4: +6 Hours Forecast -->
                        <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 10px; padding: 18px; box-shadow: 0 1px 3px rgba(0,0,0,0.04);">
                            <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
                                <span style="font-size: 0.8rem; font-weight: 700; color: var(--text-muted); text-transform: uppercase;">+6 Hours Forecast</span>
                                <span style="font-size: 0.72rem; font-weight: 700; color: <%= currentPrediction.isSufficientData() ? "#059669" : "#94a3b8" %>; background: <%= currentPrediction.isSufficientData() ? "rgba(16, 185, 129, 0.12)" : "#f1f5f9" %>; padding: 2px 6px; border-radius: 4px;">
                                    <%= currentPrediction.isSufficientData() ? "Shift Horizon" : "Awaiting Data" %>
                                </span>
                            </div>
                            <div style="font-size: 2.2rem; font-weight: 800; color: <%= currentPrediction.isSufficientData() ? "#047857" : "#94a3b8" %>; line-height: 1.1;">
                                <%= currentPrediction.isSufficientData() ? (Math.round(currentPrediction.getPredicted6hPercent()) + "%") : "--" %>
                            </div>
                            <div style="font-size: 0.85rem; color: var(--text-muted); margin-top: 4px;">
                                <%= currentPrediction.isSufficientData() ? ("<strong>~" + currentPrediction.getPredicted6hAvailable() + "</strong> bays expected free") : "Requires min. 3 sessions" %>
                            </div>
                            <div style="margin-top: 10px; background: #e2e8f0; height: 6px; border-radius: 3px; overflow: hidden;">
                                <div style="background: #10b981; height: 100%; width: <%= currentPrediction.isSufficientData() ? currentPrediction.getPredicted6hPercent() : 0 %>%;"></div>
                            </div>
                        </div>
                    </div>

                    <!-- Peak Analysis & Status Banner -->
                    <div style="padding: 20px 24px; border-bottom: 1px solid var(--border-color); display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 16px; background: #ffffff;">
                        <div style="display: flex; align-items: center; gap: 14px; flex-wrap: wrap;">
                            <div style="padding: 10px 16px; background: <%= currentPrediction.isSufficientData() ? "rgba(245, 158, 11, 0.08)" : "#f8fafc" %>; border: 1px solid <%= currentPrediction.isSufficientData() ? "rgba(245, 158, 11, 0.25)" : "#e2e8f0" %>; border-radius: 8px;">
                                <span style="font-size: 0.78rem; font-weight: 700; color: <%= currentPrediction.isSufficientData() ? "#b45309" : "#64748b" %>; text-transform: uppercase; display: block;">Expected Peak Window</span>
                                <span style="font-size: 1.05rem; font-weight: 800; color: <%= currentPrediction.isSufficientData() ? "#92400e" : "#475569" %>;">
                                    <%= currentPrediction.isSufficientData() ? currentPrediction.getPeakPeriodLabel() : "Awaiting Data (Accumulating history)" %>
                                </span>
                            </div>
                            <div style="padding: 10px 16px; background: <%= currentPrediction.isSufficientData() ? "rgba(16, 185, 129, 0.08)" : "#f8fafc" %>; border: 1px solid <%= currentPrediction.isSufficientData() ? "rgba(16, 185, 129, 0.25)" : "#e2e8f0" %>; border-radius: 8px;">
                                <span style="font-size: 0.78rem; font-weight: 700; color: <%= currentPrediction.isSufficientData() ? "#047857" : "#64748b" %>; text-transform: uppercase; display: block;">Recommended Arrival</span>
                                <span style="font-size: 1.05rem; font-weight: 800; color: <%= currentPrediction.isSufficientData() ? "#065f46" : "#475569" %>;">
                                    <%= currentPrediction.isSufficientData() ? "06:00 – 08:00 or 13:00 – 15:00 (Lowest Demand)" : "Awaiting traffic profile" %>
                                </span>
                            </div>
                        </div>

                        <div>
                            <% if (currentPrediction.isSufficientData()) { %>
                                <span style="display: inline-flex; align-items: center; gap: 6px; font-size: 0.85rem; font-weight: 700; color: #059669; background: rgba(16, 185, 129, 0.12); padding: 6px 14px; border-radius: 20px;">
                                    <span style="width: 8px; height: 8px; border-radius: 50%; background: #059669;"></span>
                                    Empirical Model Active (<%= currentPrediction.getObservationsCount() %> verified sessions)
                                </span>
                            <% } else { %>
                                <span style="display: inline-flex; align-items: center; gap: 6px; font-size: 0.85rem; font-weight: 700; color: #b45309; background: rgba(245, 158, 11, 0.12); padding: 6px 14px; border-radius: 20px;">
                                    <span style="width: 8px; height: 8px; border-radius: 50%; background: #f59e0b;"></span>
                                    Collecting data — prediction not yet available (<%= currentPrediction.getObservationsCount() %>/3 required)
                                </span>
                            <% } %>
                        </div>
                    </div>

                    <!-- 24-Hour Comparison Chart / Clean Empty State -->
                    <% if (currentPrediction.isSufficientData()) { %>
                        <div style="padding: 24px;">
                            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; flex-wrap: wrap; gap: 10px;">
                                <div>
                                    <h4 style="font-size: 1.05rem; font-weight: 700; color: var(--color-primary); margin: 0;">24-Hour Occupancy Trajectory: Live vs. Forecast</h4>
                                    <p style="font-size: 0.8rem; color: var(--text-muted); margin: 2px 0 0 0;">Hourly expected bay utilization across the entire operating cycle (00:00 to 23:00)</p>
                                </div>
                                <div style="display: flex; gap: 14px; font-size: 0.8rem; font-weight: 600;">
                                    <span style="display: flex; align-items: center; gap: 6px; color: #1e40af;">
                                        <span style="width: 12px; height: 12px; background: #2563eb; border-radius: 3px; display: inline-block;"></span>
                                        Live Observed Bays
                                    </span>
                                    <span style="display: flex; align-items: center; gap: 6px; color: #047857;">
                                        <span style="width: 12px; height: 3px; background: #10b981; border-top: 2px dashed #10b981; display: inline-block;"></span>
                                        Predicted Demand Curve
                                    </span>
                                </div>
                            </div>
                            <div style="position: relative; height: 260px; width: 100%;">
                                <canvas id="predictionChart"></canvas>
                            </div>
                        </div>
                    <% } else { %>
                        <div style="padding: 40px 24px; text-align: center; background: #ffffff;">
                            <div style="width: 56px; height: 56px; border-radius: 50%; background: rgba(14, 165, 233, 0.1); color: #0284c7; display: inline-flex; align-items: center; justify-content: center; margin-bottom: 14px;">
                                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M3 3v18h18"></path>
                                    <path d="M18.7 8l-5.1 5.2-2.8-2.7L7 14.3"></path>
                                </svg>
                            </div>
                            <h4 style="font-size: 1.15rem; font-weight: 800; color: var(--color-primary); margin: 0 0 8px 0;">
                                Collecting occupancy data. Predictions will appear when sufficient real parking activity is recorded.
                            </h4>
                            <p style="font-size: 0.88rem; color: var(--text-muted); max-width: 580px; margin: 0 auto 16px auto; line-height: 1.5;">
                                The smart prediction engine calibrates forecasts using empirical moving averages from verified check-ins and telemetry snapshots.
                                A minimum of <strong><%= PredictionDAO.MIN_OBSERVATIONS_THRESHOLD %> verified sessions</strong> is required for facility <strong><%= currentPrediction.getZoneName() %></strong> (currently recorded: <strong><%= currentPrediction.getObservationsCount() %></strong>).
                            </p>
                            <div style="display: inline-flex; align-items: center; gap: 8px; font-size: 0.82rem; font-weight: 700; color: #475569; background: #f1f5f9; padding: 6px 14px; border-radius: 20px;">
                                <span>Accumulation Progress: <%= currentPrediction.getObservationsCount() %> / <%= PredictionDAO.MIN_OBSERVATIONS_THRESHOLD %> Sessions</span>
                            </div>
                        </div>
                    <% } %>

                    <!-- Transparency & Audit Disclosure Notice -->
                    <div style="margin: 0 24px 24px 24px; padding: 16px 20px; border-radius: 8px; background: #f8fafc; border: 1px solid #e2e8f0;">
                        <div style="display: flex; align-items: flex-start; gap: 12px;">
                            <div style="color: #64748b; font-size: 1.2rem; line-height: 1; margin-top: 2px;">ℹ️</div>
                            <div style="font-size: 0.82rem; color: #475569; line-height: 1.5;">
                                <strong style="color: var(--color-primary);">Explainable Forecasting Methodology:</strong>
                                <%= currentPrediction.getStatusNotice() != null ? currentPrediction.getStatusNotice() : "Predictions are derived from empirical moving average occupancy counts over historical operating days. Physical limits ensure forecasts never exceed physical bay capacity." %>
                                <div style="margin-top: 6px; color: #64748b; font-size: 0.78rem;">
                                    <strong>Audit Guarantee:</strong> When historical records are under threshold (N &lt; 3), the system transparently indicates data accumulation rather than synthesizing artificial metrics.
                                </div>
                            </div>
                        </div>
                    </div>
                <% } %>
            </div>
        </div>

        <!-- ==========================================================================
             TAB PANE 11: REPORTS & DATA EXPORT (Real-Time Occupancy, Bookings, Settled Revenue)
             ========================================================================== -->
        <div id="tab-reports" class="tab-pane" role="tabpanel">
            <div class="card" style="margin-bottom: 24px;">
                <div class="card-header" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
                    <div>
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <h3 style="font-size: 1.25rem; font-weight: 800; color: var(--color-primary); margin: 0;">Smart Parking Reports &amp; Data Export</h3>
                            <span class="badge" style="background: rgba(16, 185, 129, 0.15); color: #059669; font-weight: 700; padding: 3px 8px; border-radius: 6px; font-size: 0.75rem;">Admin Analytics Hub</span>
                        </div>
                        <p style="font-size: 0.85rem; color: var(--text-muted); margin: 4px 0 0 0;">
                            Audited reporting engine for bay occupancy, driver bookings, and settled revenue with RFC 4180 CSV &amp; printable PDF exports
                        </p>
                    </div>

                    <!-- Quick Export Action Buttons for Active Filtered Dataset -->
                    <div style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
                        <a href="<%= request.getContextPath() %>/admin?action=exportReport&reportType=<%= reportType %>&format=csv&zone=<%= reportZone %>&startDate=<%= reportStartDate %>&endDate=<%= reportEndDate %>&status=<%= reportStatus %>" 
                           class="btn btn-secondary" style="display: inline-flex; align-items: center; gap: 6px; font-weight: 700; font-size: 0.85rem; padding: 8px 16px;"
                           id="btnExportCsv" title="Export filtered records to RFC 4180 CSV (with UTF-8 BOM and formula injection protection)">
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                            Export CSV
                        </a>
                        <a href="<%= request.getContextPath() %>/admin?action=exportReport&reportType=<%= reportType %>&format=pdf&zone=<%= reportZone %>&startDate=<%= reportStartDate %>&endDate=<%= reportEndDate %>&status=<%= reportStatus %>" 
                           class="btn btn-primary" style="display: inline-flex; align-items: center; gap: 6px; font-weight: 700; font-size: 0.85rem; padding: 8px 16px;"
                           id="btnExportPdf" target="_blank" title="Export filtered records to printable PDF (A4 Landscape, KPI blocks, running page footers)">
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
                            Export PDF
                        </a>
                    </div>
                </div>

                <!-- Report Type Switcher Tabs/Pills -->
                <div style="padding: 14px 24px; border-bottom: 1px solid var(--border-color); background: #f8fafc; display: flex; gap: 10px; flex-wrap: wrap; align-items: center;">
                    <span style="font-size: 0.8rem; font-weight: 800; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; margin-right: 6px;">Select Report:</span>
                    <a href="<%= request.getContextPath() %>/admin?tab=reports&reportType=occupancy&reportZone=<%= reportZone %>&reportStartDate=<%= reportStartDate %>&reportEndDate=<%= reportEndDate %>" 
                       class="city-filter-btn <%= "occupancy".equals(reportType) ? "active" : "" %>" style="display: inline-flex; align-items: center; gap: 6px; text-decoration: none; padding: 6px 16px;">
                        <span>🏢</span> Real-Time Bay Occupancy
                    </a>
                    <a href="<%= request.getContextPath() %>/admin?tab=reports&reportType=booking&reportZone=<%= reportZone %>&reportStatus=<%= reportStatus %>&reportStartDate=<%= reportStartDate %>&reportEndDate=<%= reportEndDate %>" 
                       class="city-filter-btn <%= "booking".equals(reportType) ? "active" : "" %>" style="display: inline-flex; align-items: center; gap: 6px; text-decoration: none; padding: 6px 16px;">
                        <span>📋</span> Driver Bookings Ledger
                    </a>
                    <a href="<%= request.getContextPath() %>/admin?tab=reports&reportType=revenue&reportZone=<%= reportZone %>&reportStartDate=<%= reportStartDate %>&reportEndDate=<%= reportEndDate %>" 
                       class="city-filter-btn <%= "revenue".equals(reportType) ? "active" : "" %>" style="display: inline-flex; align-items: center; gap: 6px; text-decoration: none; padding: 6px 16px;">
                        <span>💰</span> Settled Revenue &amp; Financials
                    </a>
                </div>

                <!-- Parameterized Filters Bar -->
                <div style="padding: 20px 24px; background: #ffffff;">
                    <form action="<%= request.getContextPath() %>/admin" method="GET" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; align-items: flex-end;">
                        <input type="hidden" name="tab" value="reports">
                        <input type="hidden" name="reportType" value="<%= reportType %>">

                        <!-- Facility / Corridor Filter -->
                        <div>
                            <label class="form-label" style="font-size: 0.8rem; font-weight: 700; margin-bottom: 6px;">Facility / Corridor</label>
                            <select name="reportZone" class="form-control" style="font-size: 0.85rem; padding: 8px 12px;">
                                <option value="ALL" <%= "ALL".equalsIgnoreCase(reportZone) ? "selected" : "" %>>All Facilities (All Metro Corridors)</option>
                                <% if (zones != null) { 
                                    for (Zone z : zones) { %>
                                        <option value="<%= z.getZoneId() %>" <%= z.getZoneId().equalsIgnoreCase(reportZone) ? "selected" : "" %>>
                                            Zone <%= z.getZoneId() %> &bull; <%= z.getName() %> (<%= z.getCityName() %>)
                                        </option>
                                <%  }
                                } %>
                            </select>
                        </div>

                        <!-- Date Range Filters (From Date to To Date, inclusive through 23:59:59 IST) -->
                        <div>
                            <label class="form-label" style="font-size: 0.8rem; font-weight: 700; margin-bottom: 6px;">From Date</label>
                            <input type="date" name="reportStartDate" value="<%= reportStartDate %>" class="form-control" style="font-size: 0.85rem; padding: 8px 12px;" placeholder="YYYY-MM-DD">
                        </div>
                        <div>
                            <label class="form-label" style="font-size: 0.8rem; font-weight: 700; margin-bottom: 6px;">To Date (Through 23:59:59 IST)</label>
                            <input type="date" name="reportEndDate" value="<%= reportEndDate %>" class="form-control" style="font-size: 0.85rem; padding: 8px 12px;" placeholder="YYYY-MM-DD">
                        </div>

                        <!-- Booking Status Filter -->
                        <% if ("booking".equals(reportType)) { %>
                        <div>
                            <label class="form-label" style="font-size: 0.8rem; font-weight: 700; margin-bottom: 6px;">Booking Status</label>
                            <select name="reportStatus" class="form-control" style="font-size: 0.85rem; padding: 8px 12px;">
                                <option value="ALL" <%= "ALL".equalsIgnoreCase(reportStatus) ? "selected" : "" %>>All Statuses</option>
                                <option value="CONFIRMED" <%= "CONFIRMED".equalsIgnoreCase(reportStatus) ? "selected" : "" %>>CONFIRMED (Reserved)</option>
                                <option value="CHECKED_IN" <%= "CHECKED_IN".equalsIgnoreCase(reportStatus) ? "selected" : "" %>>CHECKED_IN (Occupied)</option>
                                <option value="COMPLETED" <%= "COMPLETED".equalsIgnoreCase(reportStatus) ? "selected" : "" %>>COMPLETED (Released)</option>
                                <option value="CANCELLED" <%= "CANCELLED".equalsIgnoreCase(reportStatus) ? "selected" : "" %>>CANCELLED</option>
                                <option value="PAYMENT_PENDING" <%= "PAYMENT_PENDING".equalsIgnoreCase(reportStatus) ? "selected" : "" %>>PAYMENT_PENDING</option>
                            </select>
                        </div>
                        <% } %>

                        <!-- Actions -->
                        <div style="display: flex; gap: 8px;">
                            <button type="submit" class="btn btn-primary" style="padding: 8px 18px; font-size: 0.85rem; font-weight: 700;">
                                Apply Filters
                            </button>
                            <a href="<%= request.getContextPath() %>/admin?tab=reports&reportType=<%= reportType %>" class="btn btn-secondary" style="padding: 8px 14px; font-size: 0.85rem; text-decoration: none;">
                                Reset
                            </a>
                        </div>
                    </form>

                    <% if (reportDateError != null) { %>
                        <div style="margin-top: 14px; padding: 12px 16px; background: #fef2f2; border: 1px solid #fecaca; border-radius: 6px; color: #b91c1c; font-size: 0.85rem; display: flex; align-items: center; gap: 8px;">
                            <span>⚠️</span>
                            <span><strong>Date Range Error:</strong> <%= reportDateError %></span>
                        </div>
                    <% } %>
                </div>
            </div>

            <%
                String activeZoneTitle = "All Facilities (All Metro Corridors)";
                if (!"ALL".equalsIgnoreCase(reportZone) && zones != null) {
                    for (Zone z : zones) {
                        if (z.getZoneId().equalsIgnoreCase(reportZone)) {
                            activeZoneTitle = "Zone " + z.getZoneId() + " — " + z.getName() + " (" + z.getCityName() + ")";
                            break;
                        }
                    }
                }
                String activeDateTitle = (reportStartDate != null && !reportStartDate.isEmpty() ? reportStartDate : "All Time") +
                        " to " + (reportEndDate != null && !reportEndDate.isEmpty() ? reportEndDate + " (Through 23:59:59 IST)" : "Present");
            %>

            <!-- Active Report Scope & Heading Banner -->
            <div style="margin-bottom: 24px; padding: 16px 20px; border-radius: 8px; background: #ffffff; border: 1px solid var(--border-color); box-shadow: var(--shadow-sm); display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 14px;">
                <div>
                    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
                        <h3 style="font-size: 1.15rem; font-weight: 800; color: var(--color-primary); margin: 0;">
                            <%= "occupancy".equals(reportType) ? "🏢 Real-Time Bay Occupancy & Historical Snapshots" : ("booking".equals(reportType) ? "📋 Driver Bookings & Parking Sessions Ledger" : "💰 Verified Settled Revenue & Collections Report") %>
                        </h3>
                        <span class="badge badge-secondary" style="font-size: 0.72rem; text-transform: uppercase;"><%= reportType %></span>
                    </div>
                    <div style="font-size: 0.85rem; color: var(--text-color); display: flex; align-items: center; gap: 16px; flex-wrap: wrap;">
                        <span><strong style="color: var(--text-muted);">Facility:</strong> <span style="font-weight: 700; color: var(--color-primary);"><%= activeZoneTitle %></span></span>
                        <span><strong style="color: var(--text-muted);">Reporting Period:</strong> <span style="font-weight: 700; color: var(--color-primary);"><%= activeDateTitle %></span></span>
                        <% if ("booking".equals(reportType)) { %>
                            <span><strong style="color: var(--text-muted);">Status Filter:</strong> <span class="badge <%= "ALL".equalsIgnoreCase(reportStatus) ? "badge-secondary" : "badge-success" %>" style="font-size: 0.72rem;"><%= reportStatus %></span></span>
                        <% } %>
                    </div>
                </div>
                <div style="text-align: right; font-size: 0.75rem; color: var(--text-muted);">
                    <div>Timezone: <strong>IST (Asia/Kolkata)</strong></div>
                    <div>Scope: <strong>Audited Admin Records</strong></div>
                </div>
            </div>

            <!-- ==========================================================================
                 REPORT VIEW A: REAL-TIME OCCUPANCY REPORT
                 ========================================================================== -->
            <% if ("occupancy".equals(reportType)) { %>
                <!-- Occupancy KPI Cards -->
                <div class="admin-stat-grid" style="margin-bottom: 24px;">
                    <div class="admin-stat-card">
                        <div class="admin-stat-val"><%= occupancyReportSummary != null ? occupancyReportSummary.getTotalFacilities() : 0 %></div>
                        <div class="admin-stat-lbl">Monitored Facilities</div>
                    </div>
                    <div class="admin-stat-card">
                        <div class="admin-stat-val"><%= occupancyReportSummary != null ? occupancyReportSummary.getTotalSlots() : 0 %></div>
                        <div class="admin-stat-lbl">Total Capacity</div>
                    </div>
                    <div class="admin-stat-card" style="border-left: 4px solid var(--color-success);">
                        <div class="admin-stat-val" style="color: var(--color-success);"><%= occupancyReportSummary != null ? occupancyReportSummary.getAvailableSlots() : 0 %></div>
                        <div class="admin-stat-lbl">Available Bays</div>
                    </div>
                    <div class="admin-stat-card" style="border-left: 4px solid var(--color-danger);">
                        <div class="admin-stat-val" style="color: var(--color-danger);"><%= occupancyReportSummary != null ? occupancyReportSummary.getOccupiedSlots() : 0 %></div>
                        <div class="admin-stat-lbl">Occupied Bays</div>
                    </div>
                    <div class="admin-stat-card" style="border-left: 4px solid var(--color-warning);">
                        <div class="admin-stat-val" style="color: var(--color-warning);"><%= occupancyReportSummary != null ? occupancyReportSummary.getReservedSlots() : 0 %></div>
                        <div class="admin-stat-lbl">Reserved Bays</div>
                    </div>
                    <div class="admin-stat-card">
                        <div class="admin-stat-val"><%= occupancyReportSummary != null ? occupancyReportSummary.getBlockedSlots() : 0 %></div>
                        <div class="admin-stat-lbl">Maintenance / Blocked</div>
                    </div>
                    <div class="admin-stat-card" style="border-left: 4px solid var(--color-primary);">
                        <div class="admin-stat-val" style="color: var(--color-primary);"><%= occupancyReportSummary != null ? String.format(java.util.Locale.US, "%.1f%%", occupancyReportSummary.getOccupancyRate()) : "0.0%" %></div>
                        <div class="admin-stat-lbl">Live Occupancy Rate</div>
                    </div>
                </div>

                <!-- Distinction Guidance Notice -->
                <div style="margin-bottom: 20px; padding: 14px 18px; border-radius: 8px; background: #f0fdf4; border: 1px solid #bbf7d0; display: flex; align-items: center; gap: 10px;">
                    <span style="font-size: 1.1rem;">💡</span>
                    <span style="font-size: 0.85rem; color: #166534; line-height: 1.4;">
                        <strong>Real-Time Physical Source of Truth:</strong> The figures in the table below are calculated strictly from live bay statuses in the database (<code>slots</code> &amp; <code>zones</code>). Historical telemetry recordings are tracked separately in the bottom log.
                    </span>
                </div>

                <!-- Occupancy Facility Table -->
                <div class="card" style="margin-bottom: 24px;">
                    <div class="card-header" style="display: flex; justify-content: space-between; align-items: center;">
                        <h4 style="font-size: 1.05rem; font-weight: 800; color: var(--color-primary); margin: 0;">Facility Real-Time Bay Status</h4>
                        <span style="font-size: 0.8rem; color: var(--text-muted);"><%= occupancyReportItems.size() %> facilities reporting</span>
                    </div>

                    <% if (occupancyReportItems.isEmpty()) { %>
                        <div style="padding: 40px 20px; text-align: center; color: var(--text-muted);">
                            <div style="font-size: 2rem; margin-bottom: 8px;">🔍</div>
                            <h4 style="font-weight: 700; color: var(--color-primary); margin: 0 0 6px 0;">No records found for the selected filters</h4>
                            <p style="font-size: 0.85rem; margin: 0;">No parking facilities match the chosen corridor criteria.</p>
                        </div>
                    <% } else { %>
                        <div class="table-responsive">
                            <table class="custom-table">
                                <thead>
                                    <tr>
                                        <th>Facility ID</th>
                                        <th>Facility Name</th>
                                        <th>Metro Corridor</th>
                                        <th>Location</th>
                                        <th class="text-right">Total Bays</th>
                                        <th class="text-right" style="color: var(--color-success);">Available</th>
                                        <th class="text-right" style="color: var(--color-danger);">Occupied</th>
                                        <th class="text-right" style="color: var(--color-warning);">Reserved</th>
                                        <th class="text-right">Blocked</th>
                                        <th class="text-right">Occupancy %</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (OccupancyReportItem item : occupancyReportItems) { %>
                                        <tr>
                                            <td><strong>Zone <%= item.getZoneId() %></strong></td>
                                            <td><strong><%= item.getZoneName() %></strong></td>
                                            <td><span class="badge" style="background: #f1f5f9; color: #334155; font-weight: 700;"><%= item.getCityName() %></span></td>
                                            <td style="font-size: 0.8rem; color: var(--text-muted);"><%= item.getLocation() %></td>
                                            <td class="text-right font-weight-bold"><%= item.getTotalSlots() %></td>
                                            <td class="text-right" style="font-weight: 700; color: var(--color-success);"><%= item.getAvailableSlots() %></td>
                                            <td class="text-right" style="font-weight: 700; color: var(--color-danger);"><%= item.getOccupiedSlots() %></td>
                                            <td class="text-right" style="font-weight: 700; color: var(--color-warning);"><%= item.getReservedSlots() %></td>
                                            <td class="text-right" style="color: var(--text-muted);"><%= item.getBlockedSlots() %></td>
                                            <td class="text-right">
                                                <div style="display: flex; align-items: center; justify-content: flex-end; gap: 8px;">
                                                    <div style="width: 50px; background: #e2e8f0; height: 6px; border-radius: 3px; overflow: hidden;">
                                                        <div style="width: <%= Math.min(100, item.getOccupancyRate()) %>%; background: <%= item.getOccupancyRate() > 80 ? "#ef4444" : (item.getOccupancyRate() > 50 ? "#f59e0b" : "#10b981") %>; height: 100%;"></div>
                                                    </div>
                                                    <strong><%= String.format(java.util.Locale.US, "%.1f%%", item.getOccupancyRate()) %></strong>
                                                </div>
                                            </td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    <% } %>
                </div>

                <!-- Historical Telemetry Snapshots Sub-Section -->
                <div class="card" style="margin-bottom: 24px;">
                    <div class="card-header" style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <h4 style="font-size: 1.05rem; font-weight: 800; color: var(--color-primary); margin: 0;">Historical Telemetry Snapshots (Contrasted with Live State)</h4>
                            <p style="font-size: 0.8rem; color: var(--text-muted); margin: 2px 0 0 0;">Periodic IoT and manual system snapshots recorded in <code>occupancy_snapshots</code></p>
                        </div>
                        <span style="font-size: 0.8rem; color: var(--text-muted);"><%= historicalSnapshots.size() %> snapshots found</span>
                    </div>

                    <% if (historicalSnapshots.isEmpty()) { %>
                        <div style="padding: 35px 20px; text-align: center; color: var(--text-muted);">
                            <div style="font-size: 1.8rem; margin-bottom: 8px;">⏱️</div>
                            <h4 style="font-weight: 700; color: var(--color-primary); margin: 0 0 6px 0;">Historical occupancy data is unavailable for the selected period.</h4>
                            <p style="font-size: 0.85rem; margin: 0; max-width: 600px; margin-left: auto; margin-right: auto; line-height: 1.5;">
                                <%= (reportStartDate != null && !reportStartDate.isEmpty()) ? "No verified telemetry snapshots recorded for the date range " + reportStartDate + " through " + (reportEndDate != null && !reportEndDate.isEmpty() ? reportEndDate : "present") + "." : "No historical occupancy snapshots have been captured in the system yet." %>
                                Live bay availability in the table above reflects current ground truth from physical slots and is never fabricated for past dates.
                            </p>
                        </div>
                    <% } else { %>
                        <div class="table-responsive">
                            <table class="custom-table">
                                <thead>
                                    <tr>
                                        <th>Snapshot ID</th>
                                        <th>Facility</th>
                                        <th class="text-right">Total Bays</th>
                                        <th class="text-right">Occupied Bays</th>
                                        <th class="text-right">Recorded Occupancy %</th>
                                        <th>Recorded Timestamp (IST)</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Map<String, Object> snap : historicalSnapshots) { 
                                        java.sql.Timestamp recAt = (java.sql.Timestamp) snap.get("recordedAt");
                                    %>
                                        <tr>
                                            <td><code>#<%= snap.get("snapshotId") %></code></td>
                                            <td><strong>Zone <%= snap.get("zoneId") %></strong> (<%= snap.get("zoneName") %>)</td>
                                            <td class="text-right"><%= snap.get("totalBays") %></td>
                                            <td class="text-right font-weight-bold" style="color: var(--color-danger);"><%= snap.get("occupiedBays") %></td>
                                            <td class="text-right"><strong><%= String.format(java.util.Locale.US, "%.1f%%", snap.get("occupancyPercent")) %></strong></td>
                                            <td style="font-size: 0.8rem; color: var(--text-muted);"><%= recAt != null ? sdf.format(recAt) : "N/A" %></td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    <% } %>
                </div>
            <% } %>

            <!-- ==========================================================================
                 REPORT VIEW B: DRIVER BOOKINGS AUDIT LEDGER
                 ========================================================================== -->
            <% if ("booking".equals(reportType)) { %>
                <!-- Booking KPI Cards -->
                <div class="admin-stat-grid" style="margin-bottom: 24px;">
                    <div class="admin-stat-card">
                        <div class="admin-stat-val"><%= bookingReportSummary != null ? bookingReportSummary.getTotalBookings() : 0 %></div>
                        <div class="admin-stat-lbl">Matching Bookings</div>
                    </div>
                    <div class="admin-stat-card" style="border-left: 4px solid var(--color-danger);">
                        <div class="admin-stat-val" style="color: var(--color-danger);"><%= bookingReportSummary != null ? bookingReportSummary.getActiveCount() : 0 %></div>
                        <div class="admin-stat-lbl">Active Parked</div>
                    </div>
                    <div class="admin-stat-card" style="border-left: 4px solid var(--color-success);">
                        <div class="admin-stat-val" style="color: var(--color-success);"><%= bookingReportSummary != null ? bookingReportSummary.getCompletedCount() : 0 %></div>
                        <div class="admin-stat-lbl">Completed Sessions</div>
                    </div>
                    <div class="admin-stat-card" style="border-left: 4px solid #64748b;">
                        <div class="admin-stat-val" style="color: #64748b;"><%= bookingReportSummary != null ? bookingReportSummary.getCancelledCount() : 0 %></div>
                        <div class="admin-stat-lbl">Cancelled Bookings</div>
                    </div>
                    <div class="admin-stat-card" style="border-left: 4px solid var(--color-primary);">
                        <div class="admin-stat-val" style="color: var(--color-primary);">₹ <%= bookingReportSummary != null ? String.format(java.util.Locale.US, "%.2f", bookingReportSummary.getTotalBilledAmount()) : "0.00" %></div>
                        <div class="admin-stat-lbl">Total Billed Amount</div>
                    </div>
                </div>

                <!-- Bookings Table -->
                <div class="card" style="margin-bottom: 24px;">
                    <div class="card-header" style="display: flex; justify-content: space-between; align-items: center;">
                        <h4 style="font-size: 1.05rem; font-weight: 800; color: var(--color-primary); margin: 0;">Bookings Audit Ledger</h4>
                        <span style="font-size: 0.8rem; color: var(--text-muted);"><%= bookingReportItems.size() %> records found</span>
                    </div>

                    <% if (bookingReportItems.isEmpty()) { %>
                        <div style="padding: 40px 20px; text-align: center; color: var(--text-muted);">
                            <div style="font-size: 2rem; margin-bottom: 8px;">📋</div>
                            <h4 style="font-weight: 700; color: var(--color-primary); margin: 0 0 6px 0;">No records found for the selected filters</h4>
                            <p style="font-size: 0.85rem; margin: 0;">Try broadening your facility, date range, or status filter.</p>
                        </div>
                    <% } else { %>
                        <div class="table-responsive">
                            <table class="custom-table">
                                <thead>
                                    <tr>
                                        <th>Booking ID</th>
                                        <th>Driver</th>
                                        <th>Facility &amp; Bay</th>
                                        <th>Vehicle VRN</th>
                                        <th>Booking Time</th>
                                        <th>Entry &bull; Exit (IST)</th>
                                        <th>Duration</th>
                                        <th class="text-right">Amount</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (BookingReportItem b : bookingReportItems) { 
                                        String badgeCls = "badge-secondary";
                                        if ("COMPLETED".equalsIgnoreCase(b.getStatus())) badgeCls = "badge-success";
                                        else if ("CHECKED_IN".equalsIgnoreCase(b.getStatus())) badgeCls = "badge-danger";
                                        else if ("CONFIRMED".equalsIgnoreCase(b.getStatus())) badgeCls = "badge-warning";
                                        else if ("CANCELLED".equalsIgnoreCase(b.getStatus())) badgeCls = "badge-secondary";
                                    %>
                                        <tr>
                                            <td><strong>#<%= b.getBookingId() %></strong></td>
                                            <td>
                                                <strong><%= b.getUserName() != null ? b.getUserName() : b.getUserId() %></strong>
                                                <div style="font-size: 0.75rem; color: var(--text-muted);"><%= b.getUserEmail() != null ? b.getUserEmail() : "" %></div>
                                            </td>
                                            <td>
                                                <strong><%= b.getSlotId() %></strong>
                                                <div style="font-size: 0.75rem; color: var(--text-muted);">Zone <%= b.getZoneId() %> (<%= b.getZoneName() %>)</div>
                                            </td>
                                            <td>
                                                <span class="vrn-plate"><%= b.getVehicleNumber() %></span>
                                            </td>
                                            <td style="font-size: 0.8rem; color: var(--text-muted);"><%= b.getBookingTime() != null ? sdf.format(b.getBookingTime()) : "N/A" %></td>
                                            <td style="font-size: 0.8rem;">
                                                <div><%= b.getEntryTime() != null ? sdf.format(b.getEntryTime()) : "--" %></div>
                                                <div style="color: var(--text-muted);"><%= b.getExitTime() != null ? sdf.format(b.getExitTime()) : "--" %></div>
                                            </td>
                                            <td style="font-size: 0.85rem;"><%= b.getDurationHours() %> hr</td>
                                            <td class="text-right font-weight-bold">₹ <%= String.format(java.util.Locale.US, "%.2f", b.getTotalAmount()) %></td>
                                            <td><span class="badge <%= badgeCls %>"><%= b.getStatus() %></span></td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    <% } %>
                </div>
            <% } %>

            <!-- ==========================================================================
                 REPORT VIEW C: SETTLED REVENUE & FINANCIALS
                 ========================================================================== -->
            <% if ("revenue".equals(reportType)) { %>
                <!-- Strict Revenue Definition Notice Box -->
                <div style="margin-bottom: 20px; padding: 16px 20px; border-radius: 8px; background: #eff6ff; border: 1px solid #bfdbfe; display: flex; align-items: flex-start; gap: 12px;">
                    <div style="font-size: 1.25rem; line-height: 1; margin-top: 2px;">🛡️</div>
                    <div style="font-size: 0.85rem; color: #1e40af; line-height: 1.5;">
                        <strong style="color: #1e3a8a;">Strict Revenue Recognition Policy:</strong>
                        Revenue reported below reflects strictly genuine, completed transactions verified in the database with status <code>SUCCESS</code>. Pending collections, unverified dues, failed attempts, and cancelled bookings are strictly excluded from collected revenue totals.
                    </div>
                </div>

                <!-- Revenue KPI Cards -->
                <div class="admin-stat-grid" style="margin-bottom: 24px;">
                    <div class="admin-stat-card" style="border-left: 4px solid var(--color-success);">
                        <div class="admin-stat-val" style="color: var(--color-success);"><%= revenueReportSummary != null ? revenueReportSummary.getTransactionCount() : 0 %></div>
                        <div class="admin-stat-lbl">Settled Transactions</div>
                    </div>
                    <div class="admin-stat-card" style="border-left: 4px solid var(--color-primary);">
                        <div class="admin-stat-val" style="color: var(--color-primary);">₹ <%= revenueReportSummary != null ? String.format(java.util.Locale.US, "%.2f", revenueReportSummary.getTotalRevenue()) : "0.00" %></div>
                        <div class="admin-stat-lbl">Collected Net Revenue</div>
                    </div>
                    <div class="admin-stat-card">
                        <div class="admin-stat-val">₹ <%= revenueReportSummary != null ? String.format(java.util.Locale.US, "%.2f", revenueReportSummary.getAverageTicket()) : "0.00" %></div>
                        <div class="admin-stat-lbl">Average Ticket Size</div>
                    </div>
                </div>

                <!-- Channel & Corridor Breakdown Cards -->
                <% if (revenueReportSummary != null && revenueReportSummary.getTransactionCount() > 0) { %>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 18px; margin-bottom: 24px;">
                        <div class="card" style="padding: 18px;">
                            <h4 style="font-size: 0.95rem; font-weight: 800; color: var(--color-primary); margin: 0 0 12px 0;">Collected Revenue by Payment Channel</h4>
                            <div style="display: flex; flex-direction: column; gap: 8px;">
                                <% for (Map.Entry<String, Double> mEntry : revenueReportSummary.getMethodBreakdown().entrySet()) { %>
                                    <div style="display: flex; justify-content: space-between; align-items: center; font-size: 0.85rem; padding: 6px 10px; background: #f8fafc; border-radius: 6px;">
                                        <strong><%= mEntry.getKey() %></strong>
                                        <span style="font-weight: 700; color: var(--color-primary);">₹ <%= String.format(java.util.Locale.US, "%.2f", mEntry.getValue()) %></span>
                                    </div>
                                <% } %>
                            </div>
                        </div>

                        <div class="card" style="padding: 18px;">
                            <h4 style="font-size: 0.95rem; font-weight: 800; color: var(--color-primary); margin: 0 0 12px 0;">Collected Revenue by Metro Corridor</h4>
                            <div style="display: flex; flex-direction: column; gap: 8px;">
                                <% for (Map.Entry<String, Double> cEntry : revenueReportSummary.getCityBreakdown().entrySet()) { %>
                                    <div style="display: flex; justify-content: space-between; align-items: center; font-size: 0.85rem; padding: 6px 10px; background: #f8fafc; border-radius: 6px;">
                                        <strong><%= cEntry.getKey() %></strong>
                                        <span style="font-weight: 700; color: var(--color-primary);">₹ <%= String.format(java.util.Locale.US, "%.2f", cEntry.getValue()) %></span>
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                <% } %>

                <!-- Revenue Transactions Table -->
                <div class="card" style="margin-bottom: 24px;">
                    <div class="card-header" style="display: flex; justify-content: space-between; align-items: center;">
                        <h4 style="font-size: 1.05rem; font-weight: 800; color: var(--color-primary); margin: 0;">Verified Payment Records</h4>
                        <span style="font-size: 0.8rem; color: var(--text-muted);"><%= revenueReportItems.size() %> settled payments</span>
                    </div>

                    <% if (revenueReportItems.isEmpty()) { %>
                        <div style="padding: 40px 20px; text-align: center; color: var(--text-muted);">
                            <div style="font-size: 2rem; margin-bottom: 8px;">💳</div>
                            <h4 style="font-weight: 700; color: var(--color-primary); margin: 0 0 6px 0;">No records found for the selected filters</h4>
                            <p style="font-size: 0.85rem; margin: 0;">No successful payments have been collected matching the current filters.</p>
                        </div>
                    <% } else { %>
                        <div class="table-responsive">
                            <table class="custom-table">
                                <thead>
                                    <tr>
                                        <th>Payment ID</th>
                                        <th>Transaction Ref</th>
                                        <th>Booking ID</th>
                                        <th>Driver</th>
                                        <th>Facility &amp; Bay</th>
                                        <th>Metro Corridor</th>
                                        <th>Channel</th>
                                        <th class="text-right">Settled Amount</th>
                                        <th>Payment Time (IST)</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (RevenueReportItem r : revenueReportItems) { %>
                                        <tr>
                                            <td><code>#<%= r.getPaymentId() %></code></td>
                                            <td><span style="font-family: monospace; font-size: 0.8rem;"><%= r.getTransactionId() %></span></td>
                                            <td><strong>#<%= r.getBookingId() %></strong></td>
                                            <td><strong><%= r.getUserName() != null ? r.getUserName() : r.getUserId() %></strong></td>
                                            <td><strong><%= r.getSlotId() %></strong> (Zone <%= r.getZoneId() %>)</td>
                                            <td><span class="badge" style="background: #f1f5f9; color: #334155; font-weight: 700;"><%= r.getCityName() %></span></td>
                                            <td><span class="badge" style="background: rgba(37, 99, 235, 0.1); color: #2563eb; font-weight: 700;"><%= r.getPaymentMethod() %></span></td>
                                            <td class="text-right font-weight-bold" style="color: var(--color-success);">₹ <%= String.format(java.util.Locale.US, "%.2f", r.getAmount()) %></td>
                                            <td style="font-size: 0.8rem; color: var(--text-muted);"><%= r.getPaymentTime() != null ? sdf.format(r.getPaymentTime()) : "N/A" %></td>
                                            <td><span class="badge badge-success">SUCCESS</span></td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    <% } %>
                </div>
            <% } %>

        </div>
    </main>

    <!-- Modal for Slot Status Override -->
    <div id="slotOverrideModal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(11, 25, 44, 0.6); backdrop-filter: blur(4px); z-index: 2000; align-items: center; justify-content: center;">
        <div class="card" style="max-width: 400px; width: 90%; padding: 24px;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px;">
                <h3 style="font-size: 1.2rem; font-weight: 800; color: var(--color-primary); margin: 0;">Override Bay Status</h3>
                <span id="closeModalBtn" style="cursor: pointer; font-size: 1.5rem; color: var(--text-muted);">&times;</span>
            </div>

            <form action="<%= request.getContextPath() %>/admin" method="POST">
                <input type="hidden" name="action" value="overrideSlot">
                <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">
                <input type="hidden" name="tab" value="bays">
                <input type="hidden" name="slotId" id="inputSlotId" value="">

                <div class="form-group">
                    <label class="form-label">Parking Bay</label>
                    <div id="modalSlotId" style="font-size: 1.3rem; font-weight: 800; color: var(--color-primary);">--</div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="overrideStatusSelect">New Operating Status</label>
                    <select name="newStatus" id="overrideStatusSelect" class="form-control">
                        <option value="AVAILABLE">AVAILABLE (Sensor Clear)</option>
                        <option value="OCCUPIED">OCCUPIED (Vehicle Parked)</option>
                        <option value="BOOKED">BOOKED (Reserved)</option>
                        <option value="BLOCKED">BLOCKED (Maintenance / Closed)</option>
                    </select>
                </div>

                <button type="submit" class="btn btn-primary btn-block">Save Override</button>
            </form>
        </div>
    </div>

    <!-- Standardized Academic Mini-Project Footer -->
    <footer class="footer" role="contentinfo">
        <div class="footer-container">
            <div>
                <div class="footer-brand">SmartParking</div>
                <div class="footer-sub">Smart Parking Management System &bull; Academic Mini Project</div>
                <div class="footer-sub" style="margin-top: 4px;">Developed with Java 17, JSP, Servlets, JDBC &amp; MySQL</div>
            </div>
            <div style="text-align: right;">
                <div class="footer-links" style="margin-bottom: 6px; justify-content: flex-end;">
                    <a href="<%= request.getContextPath() %>/privacy.jsp">Privacy Policy</a>
                    <a href="<%= request.getContextPath() %>/terms.jsp">Terms &amp; Conditions</a>
                    <a href="<%= request.getContextPath() %>/cookies.jsp">Cookie Policy</a>
                    <a href="<%= request.getContextPath() %>/refund.jsp">Refund Policy</a>
                </div>
                <div class="footer-copy">
                    &copy; 2026 SmartParking &bull; Academic Mini Project
                </div>
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

            // 1. 24-Hour Occupancy Curve (Line Area Chart)
            const ctxCurve = document.getElementById('occupancyCurveChart');
            if (ctxCurve) {
                const hourlyData = <%= hourlyOccupancyJson %>;
                const hoursLabels = [
                    '00:00', '01:00', '02:00', '03:00', '04:00', '05:00',
                    '06:00', '07:00', '08:00 (Rush)', '09:00 (Peak)', '10:00', '11:00',
                    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00 (Rush)',
                    '18:00 (Peak)', '19:00 (Peak)', '20:00', '21:00', '22:00', '23:00'
                ];

                const pointColors = hourlyData.map((val, idx) => {
                    if (idx >= 8 && idx <= 9) return '#f59e0b';
                    if (idx >= 17 && idx <= 19) return '#f59e0b';
                    return '#0f172a';
                });

                new Chart(ctxCurve, {
                    type: 'line',
                    data: {
                        labels: hoursLabels,
                        datasets: [{
                            label: 'Active Vehicles / Check-ins',
                            data: hourlyData,
                            borderColor: '#0f172a',
                            borderWidth: 2,
                            backgroundColor: 'rgba(15, 23, 42, 0.05)',
                            fill: true,
                            tension: 0.35,
                            pointRadius: 3,
                            pointHoverRadius: 6,
                            pointBackgroundColor: pointColors,
                            pointBorderColor: '#ffffff',
                            pointBorderWidth: 1.5
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
                                backgroundColor: '#0f172a',
                                titleColor: '#ffffff',
                                bodyColor: '#cbd5e1',
                                padding: 10,
                                cornerRadius: 6,
                                callbacks: {
                                    title: function(items) {
                                        return 'Hour: ' + items[0].label;
                                    },
                                    label: function(item) {
                                        const hr = item.dataIndex;
                                        let note = '';
                                        if (hr >= 8 && hr <= 9) note = ' ⚡ [Morning Rush]';
                                        else if (hr >= 17 && hr <= 19) note = ' ⚡ [Evening Peak]';
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

            // 2. Metropolitan Revenue Breakdown (Supported Corridors Only)
            const ctxCity = document.getElementById('cityRevenueChart');
            if (ctxCity) {
                const cityLabels = <%= cleanCityRevenueLabelsJson %>;
                const cityData = <%= cleanCityRevenueDataJson %>;
                const barColors = ['#0f172a', '#10b981', '#0284c7'];

                new Chart(ctxCity, {
                    type: 'bar',
                    data: {
                        labels: cityLabels,
                        datasets: [{
                            label: 'Revenue (₹)',
                            data: cityData,
                            backgroundColor: barColors.slice(0, cityLabels.length),
                            borderRadius: 4,
                            borderSkipped: false
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: { display: false },
                            tooltip: {
                                backgroundColor: '#0f172a',
                                padding: 10,
                                cornerRadius: 6,
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
                const donutColors = ['#10b981', '#0284c7', '#334155', '#64748b', '#94a3b8'];

                new Chart(ctxPayment, {
                    type: 'doughnut',
                    data: {
                        labels: payLabels,
                        datasets: [{
                            data: payData,
                            backgroundColor: donutColors.slice(0, payLabels.length),
                            borderWidth: 2,
                            borderColor: '#ffffff',
                            hoverOffset: 4
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        cutout: '65%',
                        plugins: {
                            legend: {
                                position: 'right',
                                labels: {
                                    boxWidth: 10,
                                    font: { size: 10 },
                                    padding: 8
                                }
                            },
                            tooltip: {
                                backgroundColor: '#0f172a',
                                padding: 10,
                                cornerRadius: 6,
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

            // Chart 4: Smart Occupancy Prediction (Live vs. Forecast)
            const ctxPred = document.getElementById('predictionChart');
            if (ctxPred) {
                const liveCurve = <%= currentPrediction != null ? currentPrediction.getCurrentHourlyJson() : "[]" %>;
                const predCurve = <%= currentPrediction != null ? currentPrediction.getPredictedHourlyJson() : "[]" %>;
                const hoursLabels = ['00:00', '01:00', '02:00', '03:00', '04:00', '05:00', '06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00'];

                new Chart(ctxPred, {
                    type: 'line',
                    data: {
                        labels: hoursLabels,
                        datasets: [
                            {
                                label: 'Observed Live Bays',
                                data: liveCurve,
                                borderColor: '#2563eb',
                                backgroundColor: 'rgba(37, 99, 235, 0.1)',
                                fill: true,
                                tension: 0.35,
                                pointRadius: 3,
                                pointHoverRadius: 6,
                                borderWidth: 2.5
                            },
                            {
                                label: 'Predicted Demand Curve',
                                data: predCurve,
                                borderColor: '#10b981',
                                borderDash: [5, 5],
                                backgroundColor: 'transparent',
                                fill: false,
                                tension: 0.35,
                                pointRadius: 2,
                                pointHoverRadius: 5,
                                borderWidth: 2
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        interaction: { mode: 'index', intersect: false },
                        scales: {
                            y: {
                                beginAtZero: true,
                                max: <%= currentPrediction != null ? currentPrediction.getTotalBays() : 20 %>,
                                title: { display: true, text: 'Occupied Bays', font: { weight: 'bold', size: 11 } }
                            },
                            x: {
                                grid: { display: false }
                            }
                        },
                        plugins: {
                            legend: { display: true, position: 'top' },
                            tooltip: {
                                callbacks: {
                                    label: function(context) {
                                        return context.dataset.label + ': ' + context.parsed.y + ' bays';
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

            // Recalculate Chart bounds upon tab switch
            if (targetTabId === 'analytics') {
                setTimeout(function() {
                    window.dispatchEvent(new Event('resize'));
                }, 60);
            }

            // Trigger visual map render upon switching to supervisory bays tab
            if (targetTabId === 'bays') {
                setTimeout(function() {
                    if (window.adminLotMapInstance) {
                        window.adminLotMapInstance.renderMap();
                    } else if (typeof window.initAdminLotMap === 'function') {
                        window.initAdminLotMap();
                    }
                }, 50);
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
    <script>
        var adminActiveBookingsBySlot = {
            <% 
            boolean firstB = true;
            if (allBookings != null) {
                for (Booking b : allBookings) {
                    if ("ACTIVE".equalsIgnoreCase(b.getStatus()) || "OCCUPIED".equalsIgnoreCase(b.getStatus()) 
                        || "CONFIRMED".equalsIgnoreCase(b.getStatus()) || "RESERVED".equalsIgnoreCase(b.getStatus())
                        || "PENDING".equalsIgnoreCase(b.getStatus()) || "PAYMENT_PENDING".equalsIgnoreCase(b.getStatus())) {
                        if (!firstB) { out.print(","); }
                        firstB = false;
            %>
                "<%= b.getSlotId() %>": {
                    "bookingId": <%= b.getBookingId() %>,
                    "userId": "<%= com.parkingsystem.util.JsonUtil.escapeJson(b.getUserId()) %>",
                    "slotId": "<%= com.parkingsystem.util.JsonUtil.escapeJson(b.getSlotId()) %>",
                    "vehicleNumber": "<%= com.parkingsystem.util.JsonUtil.escapeJson(b.getVehicleNumber()) %>",
                    "status": "<%= com.parkingsystem.util.JsonUtil.escapeJson(b.getStatus()) %>",
                    "bookingTime": "<%= b.getBookingTime() != null ? b.getBookingTime().toString() : "" %>",
                    "entryTime": "<%= b.getEntryTime() != null ? b.getEntryTime().toString() : "" %>"
                }
            <% 
                    }
                }
            } 
            %>
        };

        var adminAllSlotsData = [
            <% 
            if (allSlots != null) {
                for (int i = 0; i < allSlots.size(); i++) {
                    Slot s = allSlots.get(i);
            %>
                <%= (i > 0 ? "," : "") %>{"slotId":"<%= s.getSlotId() %>","zoneId":"<%= s.getZoneId() %>","slotNumber":<%= s.getSlotNumber() %>,"floor":<%= s.getFloor() %>,"type":"<%= s.getType() %>","status":"<%= s.getStatus() %>"}
            <% 
                }
            } 
            %>
        ];
    </script>

    <script src="<%= request.getContextPath() %>/resources/js/lotMap.js?v=20261009"></script>
    <script src="<%= request.getContextPath() %>/resources/js/admin.js?v=20261009"></script>
    <script src="<%= request.getContextPath() %>/resources/js/cookieConsent.js"></script>
</body>
</html>
