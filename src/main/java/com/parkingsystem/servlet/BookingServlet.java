package com.parkingsystem.servlet;

import com.parkingsystem.dao.BookingDAO;
import com.parkingsystem.dao.FeedbackDAO;
import com.parkingsystem.dao.SlotDAO;
import com.parkingsystem.dao.ZoneDAO;
import com.parkingsystem.exception.BookingException;
import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.exception.SlotUnavailableException;
import com.parkingsystem.dao.NotificationDAO;
import com.parkingsystem.model.Booking;
import com.parkingsystem.model.Feedback;
import com.parkingsystem.model.Notification;
import com.parkingsystem.model.Payment;
import com.parkingsystem.model.Slot;
import com.parkingsystem.model.User;
import com.parkingsystem.model.Zone;
import com.parkingsystem.util.JsonUtil;
import com.parkingsystem.util.ReservationCleanupService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Timestamp;
import java.util.List;
import java.util.Random;

@WebServlet("/booking")
public class BookingServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private final BookingDAO bookingDAO = new BookingDAO();
    private final SlotDAO slotDAO = new SlotDAO();
    private final ZoneDAO zoneDAO = new ZoneDAO();
    private final FeedbackDAO feedbackDAO = new FeedbackDAO();
    private final NotificationDAO notificationDAO = new NotificationDAO();
    private final Random random = new Random();

    @Override
    public void init() throws ServletException {
        super.init();
        ReservationCleanupService.getInstance().start();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        if (action == null) action = "myBookings";

        switch (action) {
            case "book":
                showBookingForm(request, response);
                break;
            case "payment":
                showPaymentScreen(request, response);
                break;
            case "leaveAndPay":
            case "checkout":
                handleLeaveAndPay(request, response);
                break;
            case "liveTimer":
                handleLiveTimerJson(request, response);
                break;
            case "cancelPending":
                handleCancelPending(request, response);
                break;
            case "expirePending":
                handleExpirePending(request, response);
                break;
            case "cancelReservation":
                handleCancelReservation(request, response);
                break;
            case "notifications":
                handleGetNotificationsJson(request, response);
                break;
            case "markNotificationRead":
                handleMarkNotificationRead(request, response);
                break;
            case "simulateOvertime":
                handleSimulateOvertime(request, response);
                break;
            case "myBookings":
                showMyBookings(request, response);
                break;
            case "feedback":
                showFeedbackForm(request, response);
                break;
            default:
                showMyBookings(request, response);
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        if (action == null) action = "reserveSlot";

        switch (action) {
            case "reserveSlot":
                handleReserveSlot(request, response);
                break;
            case "scanPlateCheckIn":
                handleScanPlateCheckIn(request, response);
                break;
            case "cancelReservation":
                handleCancelReservation(request, response);
                break;
            case "parkVehicle":
            case "createPending":
                handleParkVehicle(request, response);
                break;
            case "leaveAndPay":
            case "checkout":
                handleLeaveAndPay(request, response);
                break;
            case "finalizePayment":
                handleFinalizePayment(request, response);
                break;
            case "cancelBooking":
                handleCancelBooking(request, response);
                break;
            case "submitFeedback":
                handleSubmitFeedback(request, response);
                break;
            case "expirePending":
                handleExpirePending(request, response);
                break;
            default:
                doGet(request, response);
                break;
        }
    }

    private User getAuthenticatedUser(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login?msg=auth_required");
            return null;
        }
        return (User) session.getAttribute("user");
    }

    private void showBookingForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        String slotId = request.getParameter("slotId");
        if (slotId == null || slotId.trim().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/zones");
            return;
        }

        try {
            Slot slot = slotDAO.getSlotById(slotId);
            if (slot == null || !slot.isAvailable()) {
                request.setAttribute("errorMessage", "Selected bay is no longer available. Please choose another.");
                response.sendRedirect(request.getContextPath() + "/zones?action=slots&zone=" + (slot != null ? slot.getZoneId() : "MUM-A"));
                return;
            }

            Zone zone = zoneDAO.getZoneById(slot.getZoneId());
            request.setAttribute("slot", slot);
            request.setAttribute("zone", zone);
            request.getRequestDispatcher("/booking.jsp").forward(request, response);

        } catch (DatabaseException e) {
            request.setAttribute("errorMessage", "Error preparing booking: " + e.getMessage());
            request.getRequestDispatcher("/zones.jsp").forward(request, response);
        }
    }

    /**
     * SENSOR SCAN-IN: Vehicle arrives at parking bay.
     * Sensor scans vehicle plate, bay is locked as BOOKED immediately.
     * Timer starts counting up from 0hr 0min 0sec (00:00:00).
     */
    private void handleParkVehicle(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        String slotId = request.getParameter("slotId");
        String zoneId = request.getParameter("zoneId");
        String vehicleNumber = request.getParameter("vehicleNumber");

        if (vehicleNumber != null) {
            vehicleNumber = vehicleNumber.replaceAll("[^A-Za-z0-9]", "").toUpperCase();
        }
        if (vehicleNumber == null || vehicleNumber.isEmpty()) {
            vehicleNumber = "KA01AB1234";
        }

        try {
            Zone zone = zoneDAO.getZoneById(zoneId);
            double hourlyRate = (zone != null) ? zone.getEffectiveHourlyRate() : 40.0;

            Booking booking = new Booking();
            booking.setUserId(user.getUserId());
            booking.setSlotId(slotId);
            booking.setVehicleNumber(vehicleNumber);
            booking.setZoneId(zoneId);
            booking.setHourlyRate(hourlyRate);

            // Starts live parking session atomically
            int bookingId = bookingDAO.startParkingSession(booking);

            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&parked=true&bookingId=" + bookingId);

        } catch (SlotUnavailableException sue) {
            request.setAttribute("errorMessage", "The bay was just occupied by another driver. Please pick another slot.");
            response.sendRedirect(request.getContextPath() + "/zones?action=slots&zone=" + zoneId + "&error=slot_taken");
        } catch (DatabaseException e) {
            request.setAttribute("errorMessage", "Sensor check-in error: " + e.getMessage());
            request.getRequestDispatcher("/zones.jsp").forward(request, response);
        }
    }

    /**
     * SENSOR SCAN-OUT & CALCULATE TOTAL:
     * When vehicle is leaving the parking zone, sensor scans vehicle departure.
     * Computes exact elapsed time and total payable bill.
     */
    private void handleLeaveAndPay(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        String bookingIdStr = request.getParameter("bookingId");
        int bookingId = 0;
        try {
            if (bookingIdStr != null) bookingId = Integer.parseInt(bookingIdStr);
        } catch (NumberFormatException ignored) {}

        if (bookingId == 0) {
            try {
                Booking active = bookingDAO.getActiveBookingForUser(user.getUserId());
                if (active != null) bookingId = active.getBookingId();
            } catch (DatabaseException ignored) {}
        }

        if (bookingId == 0) {
            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings");
            return;
        }

        try {
            Booking booking = bookingDAO.getBookingById(bookingId);
            if (booking == null) {
                response.sendRedirect(request.getContextPath() + "/booking?action=myBookings");
                return;
            }

            // If already awaiting payment, directly view payment screen
            if (booking.isPaymentPending()) {
                response.sendRedirect(request.getContextPath() + "/booking?action=payment&bookingId=" + bookingId);
                return;
            }

            // End session: records exit_time = NOW, computes duration and total amount with dynamic surge rate
            Zone zone = (booking.getZoneId() != null) ? zoneDAO.getZoneById(booking.getZoneId()) : null;
            double rate = (zone != null) ? zone.getEffectiveHourlyRate() : (booking.getHourlyRate() > 0 ? booking.getHourlyRate() : 40.0);
            Booking endedBooking = bookingDAO.endParkingSession(bookingId, rate);

            HttpSession session = request.getSession();
            session.setAttribute("pendingBooking", endedBooking);
            session.setAttribute("pendingBookingId", bookingId);

            response.sendRedirect(request.getContextPath() + "/booking?action=payment&bookingId=" + bookingId);

        } catch (BookingException | DatabaseException e) {
            request.setAttribute("errorMessage", "Error checking out vehicle: " + e.getMessage());
            showMyBookings(request, response);
        }
    }

    /**
     * Shows payment checkout screen for vehicle departure billing.
     */
    private void showPaymentScreen(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        HttpSession session = request.getSession();
        Booking pendingBooking = (Booking) session.getAttribute("pendingBooking");

        String bookingIdParam = request.getParameter("bookingId");
        int bookingId = 0;
        try {
            if (bookingIdParam != null) bookingId = Integer.parseInt(bookingIdParam);
        } catch (NumberFormatException ignored) {}

        if (pendingBooking == null || (bookingId > 0 && pendingBooking.getBookingId() != bookingId)) {
            try {
                if (bookingId == 0) {
                    Booking active = bookingDAO.getActiveBookingForUser(user.getUserId());
                    if (active != null) bookingId = active.getBookingId();
                }
                pendingBooking = bookingDAO.getBookingById(bookingId);
                if (pendingBooking == null || (!pendingBooking.isPaymentPending() && !pendingBooking.isPending())) {
                    response.sendRedirect(request.getContextPath() + "/booking?action=myBookings");
                    return;
                }
                session.setAttribute("pendingBooking", pendingBooking);
                session.setAttribute("pendingBookingId", pendingBooking.getBookingId());
            } catch (DatabaseException e) {
                response.sendRedirect(request.getContextPath() + "/zones");
                return;
            }
        }

        request.setAttribute("pendingBooking", pendingBooking);
        request.getRequestDispatcher("/payment.jsp").forward(request, response);
    }

    /**
     * FINAL PAYMENT & SENSOR RELEASE:
     * Driver pays calculated bill. Slot is released back to AVAILABLE in sensor network.
     */
    private void handleFinalizePayment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        HttpSession session = request.getSession();
        String bookingIdStr = request.getParameter("bookingId");
        String paymentMethod = request.getParameter("paymentMethod");
        String amountStr = request.getParameter("amount");

        int bookingId = 0;
        double amount = 0.0;
        try {
            bookingId = Integer.parseInt(bookingIdStr);
            amount = Double.parseDouble(amountStr);
        } catch (Exception ignored) {}

        if (paymentMethod == null || paymentMethod.trim().isEmpty()) {
            paymentMethod = "UPI";
        }

        String txnId = "TXN" + System.currentTimeMillis() + (1000 + random.nextInt(9000));

        Payment payment = new Payment();
        payment.setBookingId(bookingId);
        payment.setAmount(amount);
        payment.setPaymentMethod(paymentMethod);
        payment.setTransactionId(txnId);
        payment.setStatus("SUCCESS");

        try {
            Booking booking = bookingDAO.getBookingById(bookingId);
            boolean finalized = false;
            if (booking != null && (booking.isPaymentPending() || booking.isActive())) {
                // Exit payment flow (Pay on Exit)
                finalized = bookingDAO.finalizeExitPayment(bookingId, payment);
            } else {
                // Legacy pending booking flow
                finalized = bookingDAO.finalizeBooking(bookingId, payment);
            }

            if (finalized) {
                session.removeAttribute("pendingBooking");
                session.removeAttribute("pendingBookingId");
                session.removeAttribute("pendingExpiryMillis");

                response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&paid=true&bookingId=" + bookingId);
            } else {
                request.setAttribute("errorMessage", "Payment confirmation failed. Slot may have timed out.");
                request.getRequestDispatcher("/payment.jsp").forward(request, response);
            }
        } catch (BookingException | DatabaseException e) {
            request.setAttribute("errorMessage", e.getMessage());
            request.getRequestDispatcher("/payment.jsp").forward(request, response);
        }
    }

    /**
     * AJAX JSON endpoint for live stopwatch & tariff calculation.
     */
    private void handleLiveTimerJson(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        User user = getAuthenticatedUser(request, response);
        if (user == null) {
            out.print("{\"found\":false,\"error\":\"unauthorized\"}");
            out.flush();
            return;
        }

        String bookingIdStr = request.getParameter("bookingId");
        try {
            Booking booking = null;
            if (bookingIdStr != null && !bookingIdStr.trim().isEmpty()) {
                int bookingId = Integer.parseInt(bookingIdStr);
                booking = bookingDAO.getBookingById(bookingId);
            } else {
                booking = bookingDAO.getActiveBookingForUser(user.getUserId());
            }

            if (booking == null) {
                out.print("{\"found\":false}");
            } else {
                long elapsedSeconds = booking.getElapsedSeconds();
                Zone zone = (booking.getZoneId() != null) ? zoneDAO.getZoneById(booking.getZoneId()) : null;
                boolean surgeActive = (zone != null && zone.isSurgeActive());
                boolean isRush = (zone != null && zone.isRushHour());
                boolean isOffPeak = (zone != null && zone.isOffPeak());
                String tierName = (zone != null) ? zone.getPricingTierName() : "Normal";
                double surgeMultiplier = (zone != null) ? zone.getSurgeMultiplier() : 1.0;
                double baseRate = (zone != null) ? zone.getBaseHourlyRate() : (booking.getHourlyRate() > 0 ? booking.getHourlyRate() : 40.0);
                double hourlyRate = (zone != null) ? zone.getEffectiveHourlyRate() : baseRate;
                double currentAccrued = booking.getLiveEstimatedAmount(hourlyRate);
                String formatted = booking.getFormattedElapsed();

                long hrs = elapsedSeconds / 3600;
                long mins = (elapsedSeconds % 3600) / 60;
                long secs = elapsedSeconds % 60;
                String digitalClock = String.format("%02d:%02d:%02d", hrs, mins, secs);

                out.print(String.format(
                        java.util.Locale.US,
                        "{\"found\":true,\"bookingId\":%d,\"status\":\"%s\",\"slotId\":\"%s\",\"zoneId\":\"%s\",\"entryTime\":%d,\"elapsedSeconds\":%d,\"digitalClock\":\"%s\",\"formatted\":\"%s\",\"hourlyRate\":%.2f,\"baseRate\":%.2f,\"surgeActive\":%b,\"rushHour\":%b,\"offPeak\":%b,\"pricingTier\":\"%s\",\"surgeMultiplier\":%.2f,\"currentAccrued\":%.2f}",
                        booking.getBookingId(),
                        booking.getStatus(),
                        booking.getSlotId(),
                        booking.getZoneId() != null ? booking.getZoneId() : "",
                        booking.getEntryTime() != null ? booking.getEntryTime().getTime() : System.currentTimeMillis(),
                        elapsedSeconds,
                        digitalClock,
                        formatted,
                        hourlyRate,
                        baseRate,
                        surgeActive,
                        isRush,
                        isOffPeak,
                        tierName,
                        surgeMultiplier,
                        currentAccrued
                ));
            }
        } catch (Exception e) {
            out.print("{\"found\":false,\"error\":\"" + JsonUtil.escapeJson(e.getMessage()) + "\"}");
        }
        out.flush();
    }

    private void handleCancelPending(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession();
        Integer bookingId = (Integer) session.getAttribute("pendingBookingId");
        if (bookingId == null) {
            String bId = request.getParameter("bookingId");
            try {
                if (bId != null) bookingId = Integer.parseInt(bId);
            } catch (NumberFormatException ignored) {}
        }

        if (bookingId != null) {
            try {
                bookingDAO.cancelPendingBooking(bookingId);
            } catch (DatabaseException ignored) {}
        }

        session.removeAttribute("pendingBooking");
        session.removeAttribute("pendingBookingId");
        session.removeAttribute("pendingExpiryMillis");

        response.sendRedirect(request.getContextPath() + "/zones?msg=booking_cancelled");
    }

    private void handleExpirePending(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        Integer bookingId = null;
        if (session != null) {
            bookingId = (Integer) session.getAttribute("pendingBookingId");
            session.removeAttribute("pendingBooking");
            session.removeAttribute("pendingBookingId");
            session.removeAttribute("pendingExpiryMillis");
        }

        if (bookingId == null) {
            String bId = request.getParameter("bookingId");
            try {
                if (bId != null) bookingId = Integer.parseInt(bId);
            } catch (NumberFormatException ignored) {}
        }

        if (bookingId != null) {
            try {
                bookingDAO.cancelPendingBooking(bookingId);
                out.print("{\"success\":true,\"expired\":true,\"message\":\"Pending booking expired and slot released.\"}");
            } catch (DatabaseException e) {
                out.print("{\"success\":false,\"message\":\"" + JsonUtil.escapeJson(e.getMessage()) + "\"}");
            }
        } else {
            out.print("{\"success\":true,\"expired\":true,\"message\":\"No active pending session.\"}");
        }
        out.flush();
    }

    private void showMyBookings(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        try {
            // Proactively purge any reservations that exceeded 15-minute grace period
            bookingDAO.cancelExpiredReservations(15);

            List<Booking> bookings = bookingDAO.getBookingsByUser(user.getUserId());
            Booking activeBooking = bookingDAO.getActiveBookingForUser(user.getUserId());
            List<Notification> notifs = notificationDAO.getNotificationsByUserId(user.getUserId(), 15);
            int unreadCount = notificationDAO.getUnreadCount(user.getUserId());

            request.setAttribute("bookings", bookings);
            request.setAttribute("activeBooking", activeBooking);
            request.setAttribute("notifications", notifs);
            request.setAttribute("unreadCount", unreadCount);
            request.getRequestDispatcher("/myBookings.jsp").forward(request, response);
        } catch (DatabaseException e) {
            request.setAttribute("errorMessage", "Error loading your bookings: " + e.getMessage());
            request.getRequestDispatcher("/myBookings.jsp").forward(request, response);
        }
    }

    private void handleReserveSlot(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        String slotId = request.getParameter("slotId");
        String zoneId = request.getParameter("zoneId");
        String vehicleNumber = request.getParameter("vehicleNumber");
        String bookingDate = request.getParameter("bookingDate");
        String bookingTime = request.getParameter("bookingTime");
        String arrivalOption = request.getParameter("arrivalOption");
        String customTime = request.getParameter("customTime");

        if (vehicleNumber != null) {
            vehicleNumber = vehicleNumber.replaceAll("[^A-Za-z0-9]", "").toUpperCase();
        }
        if (vehicleNumber == null || vehicleNumber.isEmpty()) {
            vehicleNumber = "KA01AB1234";
        }

        long nowMillis = System.currentTimeMillis();
        Timestamp scheduledArrival;

        if (bookingDate != null && !bookingDate.trim().isEmpty() &&
            bookingTime != null && !bookingTime.trim().isEmpty()) {
            try {
                java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm");
                sdf.setLenient(false);
                java.util.Date parsedDate = sdf.parse(bookingDate.trim() + " " + bookingTime.trim());
                scheduledArrival = new Timestamp(parsedDate.getTime());
            } catch (Exception e) {
                scheduledArrival = new Timestamp(nowMillis + (15 * 60 * 1000L));
            }
        } else if ("30m".equalsIgnoreCase(arrivalOption)) {
            scheduledArrival = new Timestamp(nowMillis + (30 * 60 * 1000L));
        } else if ("1h".equalsIgnoreCase(arrivalOption)) {
            scheduledArrival = new Timestamp(nowMillis + (60 * 60 * 1000L));
        } else if ("custom".equalsIgnoreCase(arrivalOption) && customTime != null && customTime.contains(":")) {
            try {
                String[] parts = customTime.split(":");
                int hr = Integer.parseInt(parts[0]);
                int mn = Integer.parseInt(parts[1]);
                java.util.Calendar cal = java.util.Calendar.getInstance();
                cal.set(java.util.Calendar.HOUR_OF_DAY, hr);
                cal.set(java.util.Calendar.MINUTE, mn);
                cal.set(java.util.Calendar.SECOND, 0);
                if (cal.getTimeInMillis() < nowMillis - (5 * 60 * 1000L)) {
                    cal.add(java.util.Calendar.DAY_OF_MONTH, 1);
                }
                scheduledArrival = new Timestamp(cal.getTimeInMillis());
            } catch (Exception e) {
                scheduledArrival = new Timestamp(nowMillis + (15 * 60 * 1000L));
            }
        } else {
            scheduledArrival = new Timestamp(nowMillis + (15 * 60 * 1000L)); // default 15 mins
        }

        try {
            Zone zone = zoneDAO.getZoneById(zoneId);
            double hourlyRate = (zone != null) ? zone.getEffectiveHourlyRate() : 40.0;

            Booking booking = new Booking();
            booking.setUserId(user.getUserId());
            booking.setSlotId(slotId);
            booking.setVehicleNumber(vehicleNumber);
            booking.setZoneId(zoneId);
            booking.setHourlyRate(hourlyRate);
            booking.setScheduledArrivalTime(scheduledArrival);

            int bookingId = bookingDAO.createScheduledReservation(booking);
            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&reserved=true&bookingId=" + bookingId);

        } catch (SlotUnavailableException sue) {
            response.sendRedirect(request.getContextPath() + "/zones?action=slots&zone=" + zoneId + "&error=slot_taken");
        } catch (DatabaseException e) {
            request.setAttribute("errorMessage", "Reservation error: " + e.getMessage());
            showMyBookings(request, response);
        }
    }

    private void handleScanPlateCheckIn(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        String vehicleNumber = request.getParameter("vehicleNumber");
        String slotId = request.getParameter("slotId");

        try {
            Booking booking = bookingDAO.checkInWithNumberPlate(vehicleNumber, slotId, user.getUserId());
            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&parked=true&bookingId=" + booking.getBookingId());
        } catch (BookingException be) {
            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&error=" + java.net.URLEncoder.encode(be.getMessage(), "UTF-8"));
        } catch (DatabaseException e) {
            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&error=" + java.net.URLEncoder.encode("Sensor check-in error: " + e.getMessage(), "UTF-8"));
        }
    }

    private void handleCancelReservation(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        String bookingIdStr = request.getParameter("bookingId");
        try {
            int bookingId = Integer.parseInt(bookingIdStr);
            bookingDAO.cancelReservationByUser(bookingId, user.getUserId());
            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&cancelled=true");
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    private void handleGetNotificationsJson(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();
        User user = (User) request.getSession().getAttribute("user");
        if (user == null) {
            out.print("{\"unread\":0,\"notifications\":[]}");
            return;
        }

        try {
            int unread = notificationDAO.getUnreadCount(user.getUserId());
            List<Notification> list = notificationDAO.getNotificationsByUserId(user.getUserId(), 10);

            StringBuilder json = new StringBuilder();
            json.append("{\"unread\":").append(unread).append(",\"notifications\":[");
            for (int i = 0; i < list.size(); i++) {
                Notification n = list.get(i);
                if (i > 0) json.append(",");
                json.append("{")
                        .append("\"id\":").append(n.getNotificationId()).append(",")
                        .append("\"title\":\"").append(JsonUtil.escapeJson(n.getTitle())).append("\",")
                        .append("\"message\":\"").append(JsonUtil.escapeJson(n.getMessage())).append("\",")
                        .append("\"type\":\"").append(JsonUtil.escapeJson(n.getType())).append("\",")
                        .append("\"read\":").append(n.isRead()).append(",")
                        .append("\"time\":\"").append(new java.text.SimpleDateFormat("dd MMM, hh:mm a").format(n.getCreatedAt())).append("\"")
                        .append("}");
            }
            json.append("]}");
            out.print(json.toString());
        } catch (Exception e) {
            out.print("{\"unread\":0,\"notifications\":[],\"error\":\"" + JsonUtil.escapeJson(e.getMessage()) + "\"}");
        }
    }

    private void handleMarkNotificationRead(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();
        User user = (User) request.getSession().getAttribute("user");
        if (user == null) {
            out.print("{\"success\":false}");
            return;
        }

        String notifIdStr = request.getParameter("id");
        try {
            if ("all".equalsIgnoreCase(notifIdStr)) {
                notificationDAO.markAllAsRead(user.getUserId());
            } else if (notifIdStr != null) {
                int nId = Integer.parseInt(notifIdStr);
                notificationDAO.markAsRead(nId);
            }
            out.print("{\"success\":true}");
        } catch (Exception e) {
            out.print("{\"success\":false,\"error\":\"" + JsonUtil.escapeJson(e.getMessage()) + "\"}");
        }
    }

    private void handleSimulateOvertime(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        int cancelled = 0;
        try {
            cancelled = bookingDAO.cancelExpiredReservations(0); // Cancel immediately
        } catch (Exception ignored) {}
        response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&overtimeChecked=true&cancelledCount=" + cancelled);
    }

    private void handleCancelBooking(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        String bookingIdStr = request.getParameter("bookingId");
        try {
            int bookingId = Integer.parseInt(bookingIdStr);
            bookingDAO.cancelConfirmedBooking(bookingId, user.getUserId());
            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&cancelled=true");
        } catch (BookingException | DatabaseException | NumberFormatException e) {
            request.setAttribute("errorMessage", "Cancellation failed: " + e.getMessage());
            showMyBookings(request, response);
        }
    }

    private void showFeedbackForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        String bookingIdStr = request.getParameter("bookingId");
        try {
            int bookingId = Integer.parseInt(bookingIdStr);
            Booking booking = bookingDAO.getBookingById(bookingId);
            request.setAttribute("booking", booking);
            request.getRequestDispatcher("/feedback.jsp").forward(request, response);
        } catch (Exception e) {
            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings");
        }
    }

    private void handleSubmitFeedback(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getAuthenticatedUser(request, response);
        if (user == null) return;

        String bookingIdStr = request.getParameter("bookingId");
        String ratingStr = request.getParameter("rating");
        String comment = request.getParameter("comment");

        try {
            int bookingId = Integer.parseInt(bookingIdStr);
            int rating = Integer.parseInt(ratingStr);
            if (rating < 1) rating = 1;
            if (rating > 5) rating = 5;

            Feedback fb = new Feedback();
            fb.setBookingId(bookingId);
            fb.setUserId(user.getUserId());
            fb.setRating(rating);
            fb.setComment(comment != null ? comment.trim() : "");

            feedbackDAO.submitFeedback(fb);
            response.sendRedirect(request.getContextPath() + "/booking?action=myBookings&feedbackSuccess=true");

        } catch (DatabaseException | NumberFormatException e) {
            request.setAttribute("errorMessage", "Error submitting feedback: " + e.getMessage());
            showMyBookings(request, response);
        }
    }
}
