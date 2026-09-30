package com.parkingsystem.util;

import com.parkingsystem.model.Booking;
import com.parkingsystem.model.Slot;
import com.parkingsystem.model.Zone;

import java.util.List;

public class JsonUtil {

    public static String escapeJson(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char ch = s.charAt(i);
            switch (ch) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\b': sb.append("\\b"); break;
                case '\f': sb.append("\\f"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (ch < ' ') {
                        String hex = Integer.toHexString(ch);
                        sb.append("\\u");
                        for (int k = 0; k < 4 - hex.length(); k++) sb.append('0');
                        sb.append(hex);
                    } else {
                        sb.append(ch);
                    }
            }
        }
        return sb.toString();
    }

    public static String slotToJson(Slot slot) {
        if (slot == null) return "null";
        return "{" +
                "\"slotId\":\"" + escapeJson(slot.getSlotId()) + "\"," +
                "\"zoneId\":\"" + escapeJson(slot.getZoneId()) + "\"," +
                "\"slotNumber\":" + slot.getSlotNumber() + "," +
                "\"floor\":" + slot.getFloor() + "," +
                "\"type\":\"" + escapeJson(slot.getType()) + "\"," +
                "\"status\":\"" + escapeJson(slot.getStatus()) + "\"" +
                "}";
    }

    public static String slotsToJson(List<Slot> slots) {
        if (slots == null) return "[]";
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < slots.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append(slotToJson(slots.get(i)));
        }
        sb.append("]");
        return sb.toString();
    }

    public static String zoneToJson(Zone zone) {
        if (zone == null) return "null";
        return "{" +
                "\"zoneId\":\"" + escapeJson(zone.getZoneId()) + "\"," +
                "\"name\":\"" + escapeJson(zone.getName()) + "\"," +
                "\"location\":\"" + escapeJson(zone.getLocation()) + "\"," +
                "\"hourlyRate\":" + zone.getHourlyRate() + "," +
                "\"totalSlots\":" + zone.getTotalSlots() + "," +
                "\"availableSlots\":" + zone.getAvailableSlots() + "," +
                "\"occupiedSlots\":" + zone.getOccupiedSlots() + "," +
                "\"occupancyPercentage\":" + zone.getOccupancyPercentage() +
                "}";
    }

    public static String zonesToJson(List<Zone> zones) {
        if (zones == null) return "[]";
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < zones.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append(zoneToJson(zones.get(i)));
        }
        sb.append("]");
        return sb.toString();
    }

    public static String successResponse(String message, String extraJson) {
        return "{\"success\":true,\"message\":\"" + escapeJson(message) + "\"" +
                (extraJson != null && !extraJson.isEmpty() ? "," + extraJson : "") + "}";
    }

    public static String errorResponse(String message) {
        return "{\"success\":false,\"message\":\"" + escapeJson(message) + "\"}";
    }
}
