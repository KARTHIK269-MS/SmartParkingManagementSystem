package com.parkingsystem.servlet;

import com.parkingsystem.dao.SlotDAO;
import com.parkingsystem.dao.ZoneDAO;
import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.Slot;
import com.parkingsystem.model.Zone;
import com.parkingsystem.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

@WebServlet("/zones")
public class ZoneServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private final ZoneDAO zoneDAO = new ZoneDAO();
    private final SlotDAO slotDAO = new SlotDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        if (action == null || action.trim().isEmpty()) {
            action = "zones";
        }

        switch (action) {
            case "slots":
                showSlots(request, response);
                break;
            case "slotStatusJson":
                handleSlotStatusJson(request, response);
                break;
            case "zoneStatusJson":
                handleZoneStatusJson(request, response);
                break;
            case "zones":
            default:
                showZones(request, response);
                break;
        }
    }

    private void showZones(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            List<Zone> zones = zoneDAO.getAllZones();
            request.setAttribute("zones", zones);
            request.getRequestDispatcher("/zones.jsp").forward(request, response);
        } catch (DatabaseException e) {
            request.setAttribute("errorMessage", "Error loading parking zones: " + e.getMessage());
            request.getRequestDispatcher("/zones.jsp").forward(request, response);
        }
    }

    private void showSlots(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String zoneId = request.getParameter("zone");
        if (zoneId == null || zoneId.trim().isEmpty()) {
            zoneId = "A";
        }

        try {
            Zone zone = zoneDAO.getZoneById(zoneId);
            List<Slot> slots = slotDAO.getSlotsByZone(zoneId);

            if (zone == null) {
                response.sendRedirect(request.getContextPath() + "/zones");
                return;
            }

            request.setAttribute("zone", zone);
            request.setAttribute("slots", slots);
            request.getRequestDispatcher("/slots.jsp").forward(request, response);

        } catch (DatabaseException e) {
            request.setAttribute("errorMessage", "Error loading bay availability: " + e.getMessage());
            request.getRequestDispatcher("/zones.jsp").forward(request, response);
        }
    }

    /**
     * Periodic AJAX Polling Endpoint:
     * Consumed by resources/js/slotStatus.js to fetch real-time bay availability
     * reflecting IoT simulator changes without full page reload.
     */
    private void handleSlotStatusJson(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String zoneId = request.getParameter("zone");
        if (zoneId == null || zoneId.trim().isEmpty()) {
            zoneId = "A";
        }

        try {
            List<Slot> slots = slotDAO.getSlotsByZone(zoneId);
            out.print(JsonUtil.slotsToJson(slots));
        } catch (DatabaseException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(JsonUtil.errorResponse("Failed to load live slot status: " + e.getMessage()));
        }
        out.flush();
    }

    private void handleZoneStatusJson(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        try {
            List<Zone> zones = zoneDAO.getAllZones();
            out.print(JsonUtil.zonesToJson(zones));
        } catch (DatabaseException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(JsonUtil.errorResponse("Failed to load zone metrics: " + e.getMessage()));
        }
        out.flush();
    }
}
