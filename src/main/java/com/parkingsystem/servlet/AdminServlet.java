package com.parkingsystem.servlet;

import com.parkingsystem.dao.BookingDAO;
import com.parkingsystem.dao.FeedbackDAO;
import com.parkingsystem.dao.SlotDAO;
import com.parkingsystem.dao.ZoneDAO;
import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.Booking;
import com.parkingsystem.model.Feedback;
import com.parkingsystem.model.Slot;
import com.parkingsystem.model.User;
import com.parkingsystem.model.Zone;
import com.parkingsystem.util.IoTSimulator;
import com.parkingsystem.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;

@WebServlet("/admin")
public class AdminServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private final BookingDAO bookingDAO = new BookingDAO();
    private final SlotDAO slotDAO = new SlotDAO();
    private final ZoneDAO zoneDAO = new ZoneDAO();
    private final FeedbackDAO feedbackDAO = new FeedbackDAO();

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
            case "iotStatusJson":
                handleIotStatusJson(request, response);
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
            default:
                doGet(request, response);
                break;
        }
    }

    private User checkAdminAuth(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login?msg=admin_required");
            return null;
        }
        User user = (User) session.getAttribute("user");
        if (!user.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/zones?msg=unauthorized");
            return null;
        }
        return user;
    }

    private void showDashboard(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            List<Zone> zones = zoneDAO.getAllZones();
            List<Slot> allSlots = slotDAO.getAllSlots();
            List<Booking> allBookings = bookingDAO.getAllBookings();
            List<Feedback> allFeedback = feedbackDAO.getAllFeedback();
            Map<String, Object> revenueStats = bookingDAO.getRevenueStats();
            double avgRating = feedbackDAO.getAverageRating();

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

            // AI Dynamic Surge Pricing Statistics
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

            // Chart 1: 24-Hour Occupancy Curve Data
            int[] hourlyOccupancy = bookingDAO.get24HourOccupancyCurve();
            StringBuilder hourlyJson = new StringBuilder("[");
            for (int i = 0; i < hourlyOccupancy.length; i++) {
                hourlyJson.append(hourlyOccupancy[i]);
                if (i < hourlyOccupancy.length - 1) hourlyJson.append(",");
            }
            hourlyJson.append("]");

            // Chart 2: Revenue Breakdown by City Data
            Map<String, Double> cityRevenue = bookingDAO.getRevenueByCityData();
            StringBuilder cityLabelsJson = new StringBuilder("[");
            StringBuilder cityDataJson = new StringBuilder("[");
            int cIdx = 0;
            for (Map.Entry<String, Double> entry : cityRevenue.entrySet()) {
                if (cIdx > 0) {
                    cityLabelsJson.append(",");
                    cityDataJson.append(",");
                }
                cityLabelsJson.append("\"").append(entry.getKey()).append("\"");
                cityDataJson.append(String.format(java.util.Locale.US, "%.0f", entry.getValue()));
                cIdx++;
            }
            cityLabelsJson.append("]");
            cityDataJson.append("]");

            // Chart 3: Payment Method Distribution Data
            Map<String, Integer> paymentDist = bookingDAO.getPaymentMethodDistributionData();
            StringBuilder payLabelsJson = new StringBuilder("[");
            StringBuilder payDataJson = new StringBuilder("[");
            int pIdx = 0;
            for (Map.Entry<String, Integer> entry : paymentDist.entrySet()) {
                if (pIdx > 0) {
                    payLabelsJson.append(",");
                    payDataJson.append(",");
                }
                payLabelsJson.append("\"").append(entry.getKey()).append("\"");
                payDataJson.append(entry.getValue());
                pIdx++;
            }
            payLabelsJson.append("]");
            payDataJson.append("]");

            request.setAttribute("zones", zones);
            request.setAttribute("allSlots", allSlots);
            request.setAttribute("allBookings", allBookings);
            request.setAttribute("allFeedback", allFeedback);
            request.setAttribute("revenueStats", revenueStats);
            request.setAttribute("avgRating", avgRating);
            request.setAttribute("totalBays", totalBays);
            request.setAttribute("availableBays", availableBays);
            request.setAttribute("bookedBays", bookedBays);
            request.setAttribute("blockedBays", blockedBays);
            request.setAttribute("iotRunning", IoTSimulator.getInstance().isRunning());
            request.setAttribute("iotLastEvent", IoTSimulator.getInstance().getLastEventMessage());

            // Pass analytics & surge attributes
            request.setAttribute("hourlyOccupancyJson", hourlyJson.toString());
            request.setAttribute("cityRevenueLabelsJson", cityLabelsJson.toString());
            request.setAttribute("cityRevenueDataJson", cityDataJson.toString());
            request.setAttribute("paymentLabelsJson", payLabelsJson.toString());
            request.setAttribute("paymentDataJson", payDataJson.toString());
            request.setAttribute("surgeZonesCount", surgeZonesCount);
            request.setAttribute("highestOccZone", highestOccZone);

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

    private void handleOverrideSlot(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String slotId = request.getParameter("slotId");
        String newStatus = request.getParameter("newStatus");
        String tab = request.getParameter("tab");
        if (tab == null || tab.trim().isEmpty()) tab = "bays";

        if (slotId != null && newStatus != null) {
            try {
                slotDAO.overrideSlotStatus(slotId, newStatus);
            } catch (DatabaseException ignored) {}
        }
        response.sendRedirect(request.getContextPath() + "/admin?action=dashboard&tab=" + tab + "&msg=slot_overridden");
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
                    slotDAO.overrideSlotStatus(s.getSlotId(), "BOOKED");
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
                slotDAO.overrideSlotStatus(s.getSlotId(), "AVAILABLE");
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
}
