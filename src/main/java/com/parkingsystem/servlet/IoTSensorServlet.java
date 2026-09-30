package com.parkingsystem.servlet;

import com.parkingsystem.dao.BookingDAO;
import com.parkingsystem.dao.SlotDAO;
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
 * IoT & ANPR REST API Gateway:
 * Accepts hardware telemetry from ESP32 (Ultrasonic/Geomagnetic),
 * Raspberry Pi, and Computer Vision ANPR camera pipelines.
 */
@WebServlet("/api/iot-sensor")
public class IoTSensorServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

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

        try {
            if (slotId != null && !slotId.trim().isEmpty()) {
                Slot slot = slotDAO.getSlotById(slotId.trim().toUpperCase());
                if (slot != null) {
                    out.print(JsonUtil.slotToJson(slot));
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

        String slotId = params.get("slotId");
        String status = params.get("status");
        String sensorType = params.getOrDefault("sensorType", "ULTRASONIC");
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

            // 1. ANPR Camera Check-In Mode
            if ("ANPR".equalsIgnoreCase(sensorType) || "ANPR_CAMERA".equalsIgnoreCase(sensorType) || (vehicleNumber != null && !vehicleNumber.trim().isEmpty())) {
                String cleanVRN = (vehicleNumber != null) ? vehicleNumber.replaceAll("[^A-Za-z0-9]", "").toUpperCase() : "";
                if (cleanVRN.isEmpty()) cleanVRN = "KA01AB1234";

                try {
                    Booking checkedInBooking = bookingDAO.checkInWithNumberPlate(cleanVRN, slotId, null);
                    out.print("{" +
                            "\"success\":true," +
                            "\"message\":\"ANPR Check-in Successful\"," +
                            "\"slotId\":\"" + JsonUtil.escapeJson(slotId) + "\"," +
                            "\"status\":\"OCCUPIED\"," +
                            "\"vehicleNumber\":\"" + JsonUtil.escapeJson(cleanVRN) + "\"," +
                            "\"bookingId\":" + checkedInBooking.getBookingId() + "," +
                            "\"sensorType\":\"" + JsonUtil.escapeJson(sensorType) + "\"," +
                            "\"timestamp\":" + System.currentTimeMillis() +
                            "}");
                    return;
                } catch (Exception ex) {
                    // Fallback to manual occupancy if no active reservation was matched
                    slotDAO.overrideSlotStatus(slotId, "BOOKED");
                    out.print("{" +
                            "\"success\":true," +
                            "\"message\":\"Slot marked OCCUPIED by ANPR camera (" + JsonUtil.escapeJson(ex.getMessage()) + ")\"," +
                            "\"slotId\":\"" + JsonUtil.escapeJson(slotId) + "\"," +
                            "\"status\":\"BOOKED\"," +
                            "\"vehicleNumber\":\"" + JsonUtil.escapeJson(cleanVRN) + "\"," +
                            "\"sensorType\":\"" + JsonUtil.escapeJson(sensorType) + "\"," +
                            "\"timestamp\":" + System.currentTimeMillis() +
                            "}");
                    return;
                }
            }

            // 2. Hardware Ultrasonic / Geomagnetic Sensor Mode
            if (status != null && !status.trim().isEmpty()) {
                String normalizedStatus = status.trim().toUpperCase();
                if ("OCCUPIED".equals(normalizedStatus) || "BOOKED".equals(normalizedStatus) || "PRESENT".equals(normalizedStatus)) {
                    slotDAO.overrideSlotStatus(slotId, "BOOKED");
                } else if ("AVAILABLE".equals(normalizedStatus) || "EMPTY".equals(normalizedStatus) || "VACANT".equals(normalizedStatus)) {
                    slotDAO.overrideSlotStatus(slotId, "AVAILABLE");
                }

                out.print("{" +
                        "\"success\":true," +
                        "\"message\":\"IoT sensor pulse registered successfully\"," +
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
