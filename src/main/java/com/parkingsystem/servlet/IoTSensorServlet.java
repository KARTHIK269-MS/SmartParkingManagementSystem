package com.parkingsystem.servlet;

import com.parkingsystem.dao.BookingDAO;
import com.parkingsystem.dao.SlotDAO;
import com.parkingsystem.exception.BookingException;
import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.Booking;
import com.parkingsystem.model.Slot;
import com.parkingsystem.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Simulated IoT & ANPR REST API Gateway (Academic Prototype Demonstration):
 * Demonstrates simulated telemetry and prototype vehicle arrival/departure events.
 * Protected with a local prototype API key for academic demonstration.
 */
@WebServlet("/api/iot-sensor")
public class IoTSensorServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // Academic prototype API key for local demonstration
    public static final String PROTOTYPE_API_KEY = "DEMO_IOT_KEY_2026";

    private final SlotDAO slotDAO = new SlotDAO();
    private final BookingDAO bookingDAO = new BookingDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String slotId = request.getParameter("slotId");
        String zoneId = request.getParameter("zoneId");
        String details = request.getParameter("details");

        try {
            if (slotId != null && !slotId.trim().isEmpty()) {
                Slot slot = slotDAO.getSlotById(slotId.trim().toUpperCase());
                if (slot != null) {
                    if ("true".equalsIgnoreCase(details)) {
                        com.parkingsystem.model.User sessionUser = null;
                        com.parkingsystem.model.User adminUser = null;
                        com.parkingsystem.model.User driverUser = null;
                        javax.servlet.http.HttpSession session = request.getSession(false);
                        if (session != null) {
                            adminUser = (com.parkingsystem.model.User) session.getAttribute("adminUser");
                            driverUser = (com.parkingsystem.model.User) session.getAttribute("driverUser");
                            sessionUser = (com.parkingsystem.model.User) session.getAttribute("user");
                        }
                        boolean isAuthorizedAdmin = (adminUser != null && adminUser.isAdmin()) ||
                                                    (sessionUser != null && sessionUser.isAdmin());
                        Booking activeBooking = bookingDAO.getActiveBookingForSlot(slot.getSlotId());
                        boolean isOwner = false;
                        if (activeBooking != null) {
                            if (driverUser != null && driverUser.getUserId().equalsIgnoreCase(activeBooking.getUserId())) isOwner = true;
                            else if (sessionUser != null && sessionUser.getUserId().equalsIgnoreCase(activeBooking.getUserId())) isOwner = true;
                            else if (adminUser != null && adminUser.getUserId().equalsIgnoreCase(activeBooking.getUserId())) isOwner = true;
                        }

                        StringBuilder sb = new StringBuilder("{");
                        sb.append("\"slotId\":\"").append(JsonUtil.escapeJson(slot.getSlotId())).append("\",");
                        sb.append("\"zoneId\":\"").append(JsonUtil.escapeJson(slot.getZoneId())).append("\",");
                        sb.append("\"slotNumber\":").append(slot.getSlotNumber()).append(",");
                        sb.append("\"floor\":").append(slot.getFloor()).append(",");
                        sb.append("\"type\":\"").append(JsonUtil.escapeJson(slot.getType())).append("\",");
                        sb.append("\"status\":\"").append(JsonUtil.escapeJson(slot.getStatus())).append("\"");

                        if (activeBooking != null && (isAuthorizedAdmin || isOwner)) {
                            sb.append(",\"authorized\":true");
                            sb.append(",\"bookingId\":").append(activeBooking.getBookingId());
                            sb.append(",\"vehicleNumber\":\"").append(JsonUtil.escapeJson(activeBooking.getVehicleNumber())).append("\"");
                            sb.append(",\"userId\":\"").append(JsonUtil.escapeJson(activeBooking.getUserId())).append("\"");
                            sb.append(",\"bookingStatus\":\"").append(JsonUtil.escapeJson(activeBooking.getStatus())).append("\"");
                            if (activeBooking.getEntryTime() != null) {
                                sb.append(",\"entryTime\":\"").append(activeBooking.getEntryTime().toString()).append("\"");
                            }
                        } else if (activeBooking != null) {
                            sb.append(",\"authorized\":false");
                            sb.append(",\"bookingStatus\":\"OCCUPIED\"");
                            sb.append(",\"occupancyNotice\":\"Occupied by registered driver\"");
                        }
                        sb.append("}");
                        out.print(sb.toString());
                    } else {
                        out.print(JsonUtil.slotToJson(slot));
                    }
                } else {
                    response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                    out.print(JsonUtil.errorResponse("Slot not found: " + slotId));
                }
            } else if (zoneId != null && !zoneId.trim().isEmpty()) {
                List<Slot> slots = slotDAO.getSlotsByZone(zoneId.trim().toUpperCase());
                out.print(JsonUtil.slotsToJson(slots));
            } else {
                List<Slot> slots = slotDAO.getAllSlots();
                out.print(JsonUtil.slotsToJson(slots));
            }
        } catch (DatabaseException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(JsonUtil.errorResponse("Database error: " + e.getMessage()));
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        Map<String, String> params = extractParameters(request);

        // Security check: Validate prototype API key
        String apiKey = params.get("apiKey");
        if (apiKey == null || apiKey.trim().isEmpty()) {
            apiKey = request.getHeader("X-API-KEY");
        }
        if (!PROTOTYPE_API_KEY.equals(apiKey)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print(JsonUtil.errorResponse("Unauthorized: Missing or invalid IoT prototype API key."));
            return;
        }

        String slotId = params.get("slotId");
        String status = params.get("status");
        String sensorType = params.getOrDefault("sensorType", "SIMULATED_SENSOR");
        String vehicleNumber = params.get("vehicleNumber");
        String distanceCmStr = params.get("distanceCm");

        if (slotId == null || slotId.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print(JsonUtil.errorResponse("Missing required parameter: slotId"));
            return;
        }

        slotId = slotId.trim().toUpperCase();

        try {
            Slot slot = slotDAO.getSlotById(slotId);
            if (slot == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                out.print(JsonUtil.errorResponse("Slot not found: " + slotId));
                return;
            }

            // 1. ANPR Camera Check-In Mode (Prototype / Simulation)
            if ("ANPR".equalsIgnoreCase(sensorType) || "ANPR_CAMERA".equalsIgnoreCase(sensorType) || (vehicleNumber != null && !vehicleNumber.trim().isEmpty())) {
                String cleanVRN = (vehicleNumber != null) ? vehicleNumber.replaceAll("[^A-Za-z0-9]", "").toUpperCase() : "";
                if (cleanVRN.isEmpty()) {
                    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print(JsonUtil.errorResponse("Missing vehicle number plate for ANPR check-in."));
                    return;
                }

                try {
                    Booking checkedInBooking = bookingDAO.checkInWithNumberPlate(cleanVRN, slotId, null);
                    out.print("{" +
                            "\"success\":true," +
                            "\"message\":\"ANPR Check-in Successful (Prototype Simulation)\"," +
                            "\"slotId\":\"" + JsonUtil.escapeJson(slotId) + "\"," +
                            "\"status\":\"OCCUPIED\"," +
                            "\"vehicleNumber\":\"" + JsonUtil.escapeJson(cleanVRN) + "\"," +
                            "\"bookingId\":" + checkedInBooking.getBookingId() + "," +
                            "\"sensorType\":\"" + JsonUtil.escapeJson(sensorType) + "\"," +
                            "\"timestamp\":" + System.currentTimeMillis() +
                            "}");
                    return;
                } catch (BookingException ex) {
                    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.print("{" +
                            "\"success\":false," +
                            "\"error\":\"" + JsonUtil.escapeJson(ex.getMessage()) + "\"," +
                            "\"slotId\":\"" + JsonUtil.escapeJson(slotId) + "\"," +
                            "\"vehicleNumber\":\"" + JsonUtil.escapeJson(cleanVRN) + "\"," +
                            "\"sensorType\":\"" + JsonUtil.escapeJson(sensorType) + "\"," +
                            "\"timestamp\":" + System.currentTimeMillis() +
                            "}");
                    return;
                } catch (DatabaseException ex) {
                    response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                    out.print(JsonUtil.errorResponse("Database error during plate check-in: " + ex.getMessage()));
                    return;
                }
            }

            // 2. Simulated Sensor Mode
            if (status != null && !status.trim().isEmpty()) {
                String normalizedStatus = status.trim().toUpperCase();
                if ("OCCUPIED".equals(normalizedStatus) || "BOOKED".equals(normalizedStatus) || "PRESENT".equals(normalizedStatus)) {
                    slotDAO.overrideSlotStatus(slotId, "OCCUPIED");
                } else if ("AVAILABLE".equals(normalizedStatus) || "EMPTY".equals(normalizedStatus) || "VACANT".equals(normalizedStatus)) {
                    // Safety check: Prevent IoT simulation from clearing an active user booking
                    if (bookingDAO.hasActiveBookingForSlot(slotId)) {
                        response.setStatus(HttpServletResponse.SC_CONFLICT);
                        out.print(JsonUtil.errorResponse("Slot has an active user booking; cannot be cleared by sensor simulation."));
                        return;
                    }
                    slotDAO.overrideSlotStatus(slotId, "AVAILABLE");
                }

                out.print("{" +
                        "\"success\":true," +
                        "\"message\":\"Simulated sensor pulse registered successfully\"," +
                        "\"slotId\":\"" + JsonUtil.escapeJson(slotId) + "\"," +
                        "\"status\":\"" + JsonUtil.escapeJson(normalizedStatus) + "\"," +
                        "\"sensorType\":\"" + JsonUtil.escapeJson(sensorType) + "\"," +
                        (distanceCmStr != null ? "\"distanceCm\":" + distanceCmStr + "," : "") +
                        "\"timestamp\":" + System.currentTimeMillis() +
                        "}");
            } else {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print(JsonUtil.errorResponse("Either 'status' or 'vehicleNumber' must be provided."));
            }

        } catch (DatabaseException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(JsonUtil.errorResponse("Sensor update failed: " + e.getMessage()));
        }
    }

    private Map<String, String> extractParameters(HttpServletRequest request) throws IOException {
        Map<String, String> map = new HashMap<>();

        // 1. Read query/form params
        for (Map.Entry<String, String[]> entry : request.getParameterMap().entrySet()) {
            if (entry.getValue() != null && entry.getValue().length > 0) {
                map.put(entry.getKey(), entry.getValue()[0]);
            }
        }

        // 2. If body is JSON, parse keys simply
        String contentType = request.getContentType();
        if (contentType != null && contentType.toLowerCase().contains("application/json")) {
            StringBuilder sb = new StringBuilder();
            try (BufferedReader reader = request.getReader()) {
                String line;
                while ((line = reader.readLine()) != null) {
                    sb.append(line);
                }
            }
            String json = sb.toString().trim();
            if (json.startsWith("{") && json.endsWith("}")) {
                json = json.substring(1, json.length() - 1);
                String[] pairs = json.split(",");
                for (String pair : pairs) {
                    String[] kv = pair.split(":", 2);
                    if (kv.length == 2) {
                        String key = kv[0].replaceAll("[\"\\s]", "");
                        String val = kv[1].replaceAll("[\"\\s]", "");
                        if (!key.isEmpty()) {
                            map.put(key, val);
                        }
                    }
                }
            }
        }

        return map;
    }
}
