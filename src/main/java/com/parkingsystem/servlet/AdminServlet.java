package com.parkingsystem.servlet;

import com.parkingsystem.dao.BookingDAO;
import com.parkingsystem.dao.FeedbackDAO;
import com.parkingsystem.dao.PredictionDAO;
import com.parkingsystem.dao.SlotDAO;
import com.parkingsystem.dao.UserDAO;
import com.parkingsystem.dao.ZoneDAO;
import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.dao.ReportDAO;
import com.parkingsystem.model.*;
import com.parkingsystem.util.CsvExportUtil;
import com.parkingsystem.util.IoTSimulator;
import com.parkingsystem.util.JsonUtil;
import com.parkingsystem.util.PdfExportUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Map;

@WebServlet("/admin")
public class AdminServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private final BookingDAO bookingDAO = new BookingDAO();
    private final SlotDAO slotDAO = new SlotDAO();
    private final ZoneDAO zoneDAO = new ZoneDAO();
    private final FeedbackDAO feedbackDAO = new FeedbackDAO();
    private final UserDAO userDAO = new UserDAO();
    private final PredictionDAO predictionDAO = new PredictionDAO();
    private final ReportDAO reportDAO = new ReportDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = checkAdminAuth(request, response);
        if (user == null) return;

        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "dashboard";
        }

        switch (action) {
            case "dashboard":
                showDashboard(request, response);
                break;
            case "exportReport":
                handleExportReport(request, response);
                break;
            case "iotStatusJson":
                handleIotStatusJson(request, response);
                break;
            case "activeSessionsJson":
                handleActiveSessionsJson(request, response);
                break;
            case "gateActivityJson":
                handleGateActivityJson(request, response);
                break;
            default:
                showDashboard(request, response);
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = checkAdminAuth(request, response);
        if (user == null) return;

        // CSRF validation for admin action forms
        if (!com.parkingsystem.util.CsrfUtil.isValid(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Invalid or missing CSRF token");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "dashboard";

        switch (action) {
            case "overrideSlot":
                handleOverrideSlot(request, response);
                break;
            case "simulateSurge":
                handleSimulateSurge(request, response);
                break;
            case "resetSurge":
                handleResetSurge(request, response);
                break;
            case "toggleIot":
                handleToggleIot(request, response);
                break;
            case "triggerIotPulse":
                handleTriggerIotPulse(request, response);
                break;
            case "recordSnapshot":
                handleRecordSnapshot(request, response);
                break;
            default:
                doGet(request, response);
                break;
        }
    }

    private User checkAdminAuth(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.sendRedirect(request.getContextPath() + "/login?msg=admin_required");
            return null;
        }
        User user = (User) session.getAttribute("adminUser");
        if (user == null) {
            User fallback = (User) session.getAttribute("user");
            if (fallback != null && fallback.isAdmin()) {
                user = fallback;
            }
        }
        if (user == null || !user.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/login?msg=admin_required");
            return null;
        }
        return user;
    }

    private void showDashboard(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            // Synchronize physical slot statuses with active bookings
            try {
                slotDAO.syncSlotStatuses();
            } catch (Exception ignored) {}

            List<Zone> zones = zoneDAO.getAllZones();
            List<Slot> allSlots = slotDAO.getAllSlots();
            List<Booking> allBookings = bookingDAO.getAllBookings();
            List<Booking> activeParkingSessions = bookingDAO.getActiveParkingSessions();
            List<GateActivityEvent> gateActivity = bookingDAO.getRecentGateActivity(35);
            List<Feedback> allFeedback = feedbackDAO.getAllFeedback();
            List<User> allUsers = userDAO.getAllUsers();
            Map<String, Integer> userBookingCounts = userDAO.getUserBookingCounts();
            Map<String, Object> revenueStats = bookingDAO.getRevenueStats();
            double avgRating = feedbackDAO.getAverageRating();

            // Compute live accrued estimated revenue across currently parked vehicles
            double estimatedAccruedRevenue = 0.0;
            for (Booking active : activeParkingSessions) {
                if (active.isActive()) {
                    estimatedAccruedRevenue += active.getLiveEstimatedAmount(active.getHourlyRate());
                }
            }

            // Calculate overall counts
            int totalBays = allSlots.size();
            int availableBays = 0;
            int bookedBays = 0;
            int blockedBays = 0;

            for (Slot s : allSlots) {
                if ("AVAILABLE".equalsIgnoreCase(s.getStatus())) availableBays++;
                else if ("BLOCKED".equalsIgnoreCase(s.getStatus())) blockedBays++;
                else bookedBays++;
            }

            // Demand Pricing Statistics
            int surgeZonesCount = 0;
            Zone highestOccZone = null;
            int maxOcc = -1;
            for (Zone z : zones) {
                if (z.isSurgeActive()) {
                    surgeZonesCount++;
                }
                if (z.getOccupancyPercentage() > maxOcc) {
                    maxOcc = z.getOccupancyPercentage();
                    highestOccZone = z;
                }
            }

            // Chart 1: 24-Hour Occupancy Curve Data (Strictly genuine vehicle check-ins)
            int[] hourlyOccupancy = bookingDAO.get24HourOccupancyCurve();
            int totalObservedOccupancy = 0;
            StringBuilder hourlyJson = new StringBuilder("[");
            for (int i = 0; i < hourlyOccupancy.length; i++) {
                hourlyJson.append(hourlyOccupancy[i]);
                totalObservedOccupancy += hourlyOccupancy[i];
                if (i < hourlyOccupancy.length - 1) hourlyJson.append(",");
            }
            hourlyJson.append("]");
            boolean hasOccupancyData = totalObservedOccupancy > 0;

            // Chart 2: Revenue Breakdown by City Data (Strictly settled payments)
            Map<String, Double> cityRevenue = bookingDAO.getRevenueByCityData();
            double totalCityRevenue = 0.0;
            StringBuilder cityLabelsJson = new StringBuilder("[");
            StringBuilder cityDataJson = new StringBuilder("[");
            int cIdx = 0;
            for (Map.Entry<String, Double> entry : cityRevenue.entrySet()) {
                if (entry.getValue() > 0.0) {
                    if (cIdx > 0) {
                        cityLabelsJson.append(",");
                        cityDataJson.append(",");
                    }
                    cityLabelsJson.append("\"").append(entry.getKey()).append("\"");
                    cityDataJson.append(String.format(java.util.Locale.US, "%.0f", entry.getValue()));
                    totalCityRevenue += entry.getValue();
                    cIdx++;
                }
            }
            cityLabelsJson.append("]");
            cityDataJson.append("]");
            boolean hasRevenueData = totalCityRevenue > 0.0;

            // Chart 3: Payment Method Distribution Data (Only used payment channels)
            Map<String, Integer> paymentDist = bookingDAO.getPaymentMethodDistributionData();
            int totalPaymentCount = 0;
            StringBuilder payLabelsJson = new StringBuilder("[");
            StringBuilder payDataJson = new StringBuilder("[");
            int pIdx = 0;
            for (Map.Entry<String, Integer> entry : paymentDist.entrySet()) {
                if (entry.getValue() > 0) {
                    if (pIdx > 0) {
                        payLabelsJson.append(",");
                        payDataJson.append(",");
                    }
                    payLabelsJson.append("\"").append(entry.getKey()).append("\"");
                    payDataJson.append(entry.getValue());
                    totalPaymentCount += entry.getValue();
                    pIdx++;
                }
            }
            payLabelsJson.append("]");
            payDataJson.append("]");
            boolean hasPaymentData = totalPaymentCount > 0;

            request.setAttribute("zones", zones);
            request.setAttribute("allSlots", allSlots);
            request.setAttribute("allBookings", allBookings);
            request.setAttribute("activeParkingSessions", activeParkingSessions);
            request.setAttribute("gateActivity", gateActivity);
            request.setAttribute("estimatedAccruedRevenue", estimatedAccruedRevenue);
            request.setAttribute("allFeedback", allFeedback);
            request.setAttribute("allUsers", allUsers);
            request.setAttribute("userBookingCounts", userBookingCounts);
            request.setAttribute("revenueStats", revenueStats);
            request.setAttribute("avgRating", avgRating);
            request.setAttribute("totalBays", totalBays);
            request.setAttribute("availableBays", availableBays);
            request.setAttribute("bookedBays", bookedBays);
            request.setAttribute("blockedBays", blockedBays);
            request.setAttribute("iotRunning", IoTSimulator.getInstance().isRunning());
            request.setAttribute("iotLastEvent", IoTSimulator.getInstance().getLastEventMessage());

            // Pass analytics & surge attributes
            request.setAttribute("hasOccupancyData", hasOccupancyData);
            request.setAttribute("hasRevenueData", hasRevenueData);
            request.setAttribute("hasPaymentData", hasPaymentData);
            request.setAttribute("hourlyOccupancyJson", hourlyJson.toString());
            request.setAttribute("cityRevenueLabelsJson", cityLabelsJson.toString());
            request.setAttribute("cityRevenueDataJson", cityDataJson.toString());
            request.setAttribute("paymentLabelsJson", payLabelsJson.toString());
            request.setAttribute("paymentDataJson", payDataJson.toString());
            request.setAttribute("surgeZonesCount", surgeZonesCount);
            request.setAttribute("highestOccZone", highestOccZone);

            // Smart Occupancy Prediction
            String predZoneId = request.getParameter("predZone");
            if (predZoneId == null || predZoneId.trim().isEmpty()) {
                predZoneId = (zones != null && !zones.isEmpty()) ? zones.get(0).getZoneId() : "A";
            }
            OccupancyPrediction currentPrediction = predictionDAO.getPredictionForZone(predZoneId);
            Map<String, OccupancyPrediction> allPredictions = predictionDAO.getAllZonePredictions();
            request.setAttribute("currentPrediction", currentPrediction);
            request.setAttribute("predZoneId", predZoneId);
            request.setAttribute("allPredictions", allPredictions);

            // Reports & Export Section
            String reportType = request.getParameter("reportType");
            if (reportType == null || reportType.trim().isEmpty()) {
                reportType = "occupancy";
            }
            reportType = reportType.trim().toLowerCase();

            String reportZone = request.getParameter("reportZone");
            if (reportZone == null || reportZone.trim().isEmpty()) {
                reportZone = "ALL";
            } else {
                reportZone = reportZone.trim().toUpperCase();
            }

            String reportStartDate = request.getParameter("reportStartDate");
            String reportEndDate = request.getParameter("reportEndDate");
            if (reportStartDate != null && reportStartDate.trim().isEmpty()) reportStartDate = null;
            if (reportEndDate != null && reportEndDate.trim().isEmpty()) reportEndDate = null;

            String reportStatus = request.getParameter("reportStatus");
            if (reportStatus == null || reportStatus.trim().isEmpty()) {
                reportStatus = "ALL";
            } else {
                reportStatus = reportStatus.trim().toUpperCase();
            }

            String reportDateError = reportDAO.validateDateRange(reportStartDate, reportEndDate);

            List<OccupancyReportItem> occItems = Collections.emptyList();
            OccupancyReportSummary occSummary = null;
            List<Map<String, Object>> histSnapshots = Collections.emptyList();
            try {
                occItems = reportDAO.getOccupancyReport(reportZone);
                occSummary = reportDAO.buildOccupancySummary(occItems, reportZone, reportStartDate, reportEndDate);
                if (reportDateError == null) {
                    histSnapshots = reportDAO.getHistoricalOccupancySnapshots(reportZone, reportStartDate, reportEndDate, 50);
                }
            } catch (Exception ignored) {}

            List<BookingReportItem> bookItems = Collections.emptyList();
            BookingReportSummary bookSummary = null;
            try {
                if (reportDateError == null) {
                    bookItems = reportDAO.getBookingReport(reportZone, reportStartDate, reportEndDate, reportStatus);
                }
                bookSummary = reportDAO.buildBookingSummary(bookItems, reportZone, reportStatus, reportStartDate, reportEndDate);
            } catch (Exception ignored) {}

            List<RevenueReportItem> revItems = Collections.emptyList();
            RevenueReportSummary revSummary = null;
            try {
                if (reportDateError == null) {
                    revItems = reportDAO.getRevenueReport(reportZone, reportStartDate, reportEndDate);
                }
                revSummary = reportDAO.buildRevenueSummary(revItems, reportZone, reportStartDate, reportEndDate);
            } catch (Exception ignored) {}

            request.setAttribute("reportType", reportType);
            request.setAttribute("reportZone", reportZone);
            request.setAttribute("reportStartDate", reportStartDate != null ? reportStartDate : "");
            request.setAttribute("reportEndDate", reportEndDate != null ? reportEndDate : "");
            request.setAttribute("reportStatus", reportStatus);
            request.setAttribute("reportDateError", reportDateError);
            request.setAttribute("occupancyReportItems", occItems);
            request.setAttribute("occupancyReportSummary", occSummary);
            request.setAttribute("historicalSnapshots", histSnapshots);
            request.setAttribute("bookingReportItems", bookItems);
            request.setAttribute("bookingReportSummary", bookSummary);
            request.setAttribute("revenueReportItems", revItems);
            request.setAttribute("revenueReportSummary", revSummary);

            String tab = request.getParameter("tab");
            if (tab == null || tab.trim().isEmpty()) {
                tab = "overview";
            }
            request.setAttribute("activeTab", tab);

            request.getRequestDispatcher("/admin/dashboard.jsp").forward(request, response);

        } catch (DatabaseException e) {
            request.setAttribute("errorMessage", "Error loading admin dashboard: " + e.getMessage());
            request.getRequestDispatcher("/admin/dashboard.jsp").forward(request, response);
        }
    }

    private void handleExportReport(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String reportType = request.getParameter("reportType");
        if (reportType == null || reportType.trim().isEmpty()) {
            reportType = "occupancy";
        }
        reportType = reportType.trim().toLowerCase();

        String format = request.getParameter("format");
        if (format == null || format.trim().isEmpty()) {
            format = "csv";
        }
        format = format.trim().toLowerCase();

        String zone = request.getParameter("zone");
        if (zone == null || zone.trim().isEmpty()) {
            zone = "ALL";
        } else {
            zone = zone.trim().toUpperCase();
        }

        String startDate = request.getParameter("startDate");
        String endDate = request.getParameter("endDate");
        if (startDate != null && startDate.trim().isEmpty()) startDate = null;
        if (endDate != null && endDate.trim().isEmpty()) endDate = null;

        String status = request.getParameter("status");
        if (status == null || status.trim().isEmpty()) {
            status = "ALL";
        } else {
            status = status.trim().toUpperCase();
        }

        String dateValidationError = reportDAO.validateDateRange(startDate, endDate);
        if (dateValidationError != null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, dateValidationError);
            return;
        }

        SimpleDateFormat fileDateFmt = new SimpleDateFormat("yyyyMMdd_HHmmss");
        String timestampStr = fileDateFmt.format(new Date());

        try {
            OutputStream out = response.getOutputStream();

            if ("csv".equals(format)) {
                String safeFilename = "smartparking_" + reportType + "_report_" + timestampStr + ".csv";
                response.setContentType("text/csv; charset=UTF-8");
                response.setHeader("Content-Disposition", "attachment; filename=\"" + safeFilename + "\"");

                if ("booking".equals(reportType)) {
                    List<BookingReportItem> items = reportDAO.getBookingReport(zone, startDate, endDate, status);
                    BookingReportSummary summary = reportDAO.buildBookingSummary(items, zone, status, startDate, endDate);
                    CsvExportUtil.exportBookingCsv(out, items, summary, zone, startDate, endDate, status);
                } else if ("revenue".equals(reportType)) {
                    List<RevenueReportItem> items = reportDAO.getRevenueReport(zone, startDate, endDate);
                    RevenueReportSummary summary = reportDAO.buildRevenueSummary(items, zone, startDate, endDate);
                    CsvExportUtil.exportRevenueCsv(out, items, summary, zone, startDate, endDate);
                } else {
                    List<OccupancyReportItem> items = reportDAO.getOccupancyReport(zone);
                    OccupancyReportSummary summary = reportDAO.buildOccupancySummary(items, zone, startDate, endDate);
                    CsvExportUtil.exportOccupancyCsv(out, items, summary, zone, startDate, endDate);
                }
                out.flush();
            } else if ("pdf".equals(format)) {
                String safeFilename = "smartparking_" + reportType + "_report_" + timestampStr + ".pdf";
                response.setContentType("application/pdf");
                response.setHeader("Content-Disposition", "attachment; filename=\"" + safeFilename + "\"");

                if ("booking".equals(reportType)) {
                    List<BookingReportItem> items = reportDAO.getBookingReport(zone, startDate, endDate, status);
                    BookingReportSummary summary = reportDAO.buildBookingSummary(items, zone, status, startDate, endDate);
                    PdfExportUtil.exportBookingPdf(out, items, summary, zone, startDate, endDate, status);
                } else if ("revenue".equals(reportType)) {
                    List<RevenueReportItem> items = reportDAO.getRevenueReport(zone, startDate, endDate);
                    RevenueReportSummary summary = reportDAO.buildRevenueSummary(items, zone, startDate, endDate);
                    PdfExportUtil.exportRevenuePdf(out, items, summary, zone, startDate, endDate);
                } else {
                    List<OccupancyReportItem> items = reportDAO.getOccupancyReport(zone);
                    OccupancyReportSummary summary = reportDAO.buildOccupancySummary(items, zone, startDate, endDate);
                    PdfExportUtil.exportOccupancyPdf(out, items, summary, zone, startDate, endDate);
                }
                out.flush();
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unsupported export format: " + format);
            }
        } catch (Exception e) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Export generation error: " + e.getMessage());
        }
    }

    private void handleRecordSnapshot(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String predZone = request.getParameter("predZone");
        if (predZone == null || predZone.trim().isEmpty()) {
            predZone = "B";
        }
        try {
            List<Zone> zones = zoneDAO.getAllZones();
            for (Zone z : zones) {
                int total = z.getTotalSlots();
                int occupied = z.getOccupiedSlots();
                predictionDAO.recordSnapshot(z.getZoneId(), total, occupied);
            }
            response.sendRedirect(request.getContextPath() + "/admin?tab=prediction&predZone=" + predZone + "&msg=snapshot_recorded");
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/admin?tab=prediction&predZone=" + predZone + "&error=snapshot_failed");
        }
    }

    private void handleOverrideSlot(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String slotId = request.getParameter("slotId");
        String newStatus = request.getParameter("newStatus");
        String tab = request.getParameter("tab");
        if (tab == null || tab.trim().isEmpty()) tab = "bays";

        if (slotId != null && newStatus != null) {
            try {
                slotDAO.safeOverrideSlotStatus(slotId, newStatus);
                response.sendRedirect(request.getContextPath() + "/admin?action=dashboard&tab=" + tab + "&msg=slot_overridden");
                return;
            } catch (com.parkingsystem.exception.BookingException be) {
                response.sendRedirect(request.getContextPath() + "/admin?action=dashboard&tab=" + tab + "&error=active_booking_present");
                return;
            } catch (DatabaseException e) {
                response.sendRedirect(request.getContextPath() + "/admin?action=dashboard&tab=" + tab + "&error=override_failed");
                return;
            }
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=dashboard&tab=" + tab);
    }

    private void handleToggleIot(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        IoTSimulator sim = IoTSimulator.getInstance();
        if (sim.isRunning()) {
            sim.stop();
        } else {
            sim.start();
        }
        String tab = request.getParameter("tab");
        if (tab == null || tab.trim().isEmpty()) tab = "iot";
        response.sendRedirect(request.getContextPath() + "/admin?action=dashboard&tab=" + tab + "&msg=iot_toggled");
    }

    private void handleTriggerIotPulse(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        IoTSimulator sim = IoTSimulator.getInstance();
        sim.triggerSimulationStep();
        String tab = request.getParameter("tab");
        if (tab == null || tab.trim().isEmpty()) tab = "iot";
        response.sendRedirect(request.getContextPath() + "/admin?action=dashboard&tab=" + tab + "&msg=iot_pulsed");
    }

    private void handleSimulateSurge(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String zoneId = request.getParameter("zoneId");
        if (zoneId == null || zoneId.trim().isEmpty()) zoneId = "A";
        try {
            List<Slot> slots = slotDAO.getSlotsByZone(zoneId);
            int targetOccupied = (int) Math.ceil(slots.size() * 0.85); // 85% occupancy
            int occupied = 0;
            for (Slot s : slots) {
                if (occupied < targetOccupied) {
                    // Do not overwrite if slot has active booking
                    if (!bookingDAO.hasActiveBookingForSlot(s.getSlotId())) {
                        slotDAO.overrideSlotStatus(s.getSlotId(), "BOOKED");
                    }
                    occupied++;
                }
            }
        } catch (DatabaseException ignored) {}
        response.sendRedirect(request.getContextPath() + "/admin?action=dashboard&tab=surge&msg=surge_simulated&zone=" + zoneId);
    }

    private void handleResetSurge(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String zoneId = request.getParameter("zoneId");
        if (zoneId == null || zoneId.trim().isEmpty()) zoneId = "A";
        try {
            List<Slot> slots = slotDAO.getSlotsByZone(zoneId);
            for (Slot s : slots) {
                // Do not let admin reset overwrite an active user booking
                if (!bookingDAO.hasActiveBookingForSlot(s.getSlotId())) {
                    slotDAO.overrideSlotStatus(s.getSlotId(), "AVAILABLE");
                }
            }
        } catch (DatabaseException ignored) {}
        response.sendRedirect(request.getContextPath() + "/admin?action=dashboard&tab=surge&msg=surge_reset&zone=" + zoneId);
    }

    private void handleIotStatusJson(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        IoTSimulator sim = IoTSimulator.getInstance();
        out.print("{" +
                "\"running\":" + sim.isRunning() + "," +
                "\"interval\":" + sim.getIntervalSeconds() + "," +
                "\"lastEvent\":\"" + JsonUtil.escapeJson(sim.getLastEventMessage()) + "\"" +
                "}");
        out.flush();
    }

    private void handleActiveSessionsJson(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        try {
            List<Booking> sessions = bookingDAO.getActiveParkingSessions();
            StringBuilder sb = new StringBuilder("[");
            for (int i = 0; i < sessions.size(); i++) {
                Booking b = sessions.get(i);
                if (i > 0) sb.append(",");
                long elapsed = b.getElapsedSeconds();
                long hrs = elapsed / 3600;
                long mins = (elapsed % 3600) / 60;
                long secs = elapsed % 60;
                String digitalClock = String.format("%02d:%02d:%02d", hrs, mins, secs);
                double liveAmount = b.isPaymentPending() ? b.getTotalAmount() : b.getLiveEstimatedAmount(b.getHourlyRate());

                sb.append("{")
                        .append("\"bookingId\":").append(b.getBookingId()).append(",")
                        .append("\"userId\":\"").append(JsonUtil.escapeJson(b.getUserId())).append("\",")
                        .append("\"userName\":\"").append(JsonUtil.escapeJson(b.getUserName() != null ? b.getUserName() : "Driver")).append("\",")
                        .append("\"slotId\":\"").append(JsonUtil.escapeJson(b.getSlotId())).append("\",")
                        .append("\"zoneId\":\"").append(JsonUtil.escapeJson(b.getZoneId() != null ? b.getZoneId() : "")).append("\",")
                        .append("\"vehicleNumber\":\"").append(JsonUtil.escapeJson(b.getVehicleNumber())).append("\",")
                        .append("\"status\":\"").append(JsonUtil.escapeJson(b.getStatus())).append("\",")
                        .append("\"entryTime\":").append(b.getEntryTime() != null ? b.getEntryTime().getTime() : 0).append(",")
                        .append("\"elapsedSeconds\":").append(elapsed).append(",")
                        .append("\"digitalClock\":\"").append(digitalClock).append("\",")
                        .append("\"hourlyRate\":").append(String.format(java.util.Locale.US, "%.2f", b.getHourlyRate())).append(",")
                        .append("\"liveAmount\":").append(String.format(java.util.Locale.US, "%.2f", liveAmount))
                        .append("}");
            }
            sb.append("]");
            out.print(sb.toString());
        } catch (Exception e) {
            out.print("[]");
        }
        out.flush();
    }

    private void handleGateActivityJson(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        try {
            int limit = 25;
            String limStr = request.getParameter("limit");
            if (limStr != null) {
                try { limit = Integer.parseInt(limStr); } catch (Exception ignored) {}
            }
            List<GateActivityEvent> events = bookingDAO.getRecentGateActivity(limit);
            StringBuilder sb = new StringBuilder("[");
            java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("dd MMM, hh:mm:ss a");
            for (int i = 0; i < events.size(); i++) {
                GateActivityEvent evt = events.get(i);
                if (i > 0) sb.append(",");
                sb.append("{")
                        .append("\"bookingId\":").append(evt.getBookingId()).append(",")
                        .append("\"vehicleNumber\":\"").append(JsonUtil.escapeJson(evt.getVehicleNumber())).append("\",")
                        .append("\"userId\":\"").append(JsonUtil.escapeJson(evt.getUserId())).append("\",")
                        .append("\"userName\":\"").append(JsonUtil.escapeJson(evt.getUserName() != null ? evt.getUserName() : "Driver")).append("\",")
                        .append("\"slotId\":\"").append(JsonUtil.escapeJson(evt.getSlotId())).append("\",")
                        .append("\"zoneId\":\"").append(JsonUtil.escapeJson(evt.getZoneId() != null ? evt.getZoneId() : "")).append("\",")
                        .append("\"zoneName\":\"").append(JsonUtil.escapeJson(evt.getZoneName() != null ? evt.getZoneName() : "")).append("\",")
                        .append("\"eventType\":\"").append(JsonUtil.escapeJson(evt.getEventType())).append("\",")
                        .append("\"eventTime\":\"").append(evt.getEventTime() != null ? sdf.format(evt.getEventTime()) : "").append("\",")
                        .append("\"eventSource\":\"").append(JsonUtil.escapeJson(evt.getEventSource())).append("\",")
                        .append("\"eventResult\":\"").append(JsonUtil.escapeJson(evt.getEventResult())).append("\",")
                        .append("\"bookingStatus\":\"").append(JsonUtil.escapeJson(evt.getBookingStatus())).append("\",")
                        .append("\"amount\":").append(String.format(java.util.Locale.US, "%.2f", evt.getAmount())).append(",")
                        .append("\"paymentStatus\":\"").append(JsonUtil.escapeJson(evt.getPaymentStatus())).append("\",")
                        .append("\"paymentMethod\":\"").append(JsonUtil.escapeJson(evt.getPaymentMethod())).append("\",")
                        .append("\"transactionId\":\"").append(JsonUtil.escapeJson(evt.getTransactionId())).append("\",")
                        .append("\"bookingTime\":\"").append(evt.getBookingTime() != null ? sdf.format(evt.getBookingTime()) : "").append("\",")
                        .append("\"entryTime\":\"").append(evt.getEntryTime() != null ? sdf.format(evt.getEntryTime()) : "").append("\",")
                        .append("\"exitTime\":\"").append(evt.getExitTime() != null ? sdf.format(evt.getExitTime()) : "").append("\",")
                        .append("\"durationFormatted\":\"").append(JsonUtil.escapeJson(evt.getDurationFormatted())).append("\"")
                        .append("}");
            }
            sb.append("]");
            out.print(sb.toString());
        } catch (Exception e) {
            out.print("[]");
        }
        out.flush();
    }
}
