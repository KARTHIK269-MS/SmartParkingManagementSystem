package com.parkingsystem.dao;

import com.parkingsystem.exception.BookingException;
import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.exception.SlotUnavailableException;
import com.parkingsystem.model.Booking;
import com.parkingsystem.model.GateActivityEvent;
import com.parkingsystem.model.Notification;
import com.parkingsystem.model.Payment;
import com.parkingsystem.model.Slot;
import com.parkingsystem.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class BookingDAO {

    private final SlotDAO slotDAO = new SlotDAO();

    /**
     * SENSOR SCAN-IN CHECK-IN (Pay-on-Exit Architecture):
     * Driver arrives at bay. Sensor scans vehicle plate and detects presence.
     * Atomically locks bay as BOOKED, starts stopwatch from 00:00:00 (entry_time = NOW).
     */
    public int startParkingSession(Booking booking) throws DatabaseException, SlotUnavailableException {
        Connection conn = null;
        PreparedStatement psBooking = null;
        ResultSet rsKeys = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false); // Transaction begins

            // 1. Transactionally check slot and mark as BOOKED (vehicle present in bay)
            slotDAO.lockAndParkSlot(conn, booking.getSlotId());

            // 2. Insert ACTIVE booking record with entry_time = NOW
            Timestamp now = new Timestamp(System.currentTimeMillis());
            String sql = "INSERT INTO bookings (user_id, slot_id, vehicle_number, duration_hours, total_amount, status, booking_time, entry_time) " +
                    "VALUES (?, ?, ?, 0, 0.00, 'ACTIVE', ?, ?)";
            psBooking = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            psBooking.setString(1, booking.getUserId());
            psBooking.setString(2, booking.getSlotId());
            psBooking.setString(3, booking.getVehicleNumber());
            psBooking.setTimestamp(4, now);
            psBooking.setTimestamp(5, now);

            psBooking.executeUpdate();
            rsKeys = psBooking.getGeneratedKeys();

            int bookingId = 0;
            if (rsKeys.next()) {
                bookingId = rsKeys.getInt(1);
            }

            conn.commit();
            return bookingId;

        } catch (SlotUnavailableException sue) {
            DBConnection.rollback(conn);
            throw sue;
        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Failed to start parking session: " + e.getMessage(), e);
        } finally {
            DBConnection.close(null, psBooking, rsKeys);
            DBConnection.close(conn, null, null);
        }
    }

    /**
     * Fetches current active or payment-pending parking session for the driver.
     */
    public Booking getActiveBookingForUser(String userId) throws DatabaseException {
        // Lazily cancel any expired reservations
        try {
            cancelExpiredReservations(15);
        } catch (Exception ignored) {}

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT b.booking_id, b.user_id, b.slot_id, b.vehicle_number, b.duration_hours, b.total_amount, " +
                    "b.status, b.booking_time, b.entry_time, b.exit_time, b.expires_at, b.scheduled_arrival_time, b.cancellation_reason, b.payment_id, s.zone_id, z.name AS zone_name, z.hourly_rate " +
                    "FROM bookings b " +
                    "JOIN slots s ON b.slot_id = s.slot_id " +
                    "JOIN zones z ON s.zone_id = z.zone_id " +
                    "WHERE b.user_id = ? AND b.status IN ('RESERVED', 'ACTIVE', 'PAYMENT_PENDING') " +
                    "ORDER BY b.booking_id DESC LIMIT 1";

            ps = conn.prepareStatement(sql);
            ps.setString(1, userId);
            rs = ps.executeQuery();

            if (rs.next()) {
                Booking b = new Booking();
                b.setBookingId(rs.getInt("booking_id"));
                b.setUserId(rs.getString("user_id"));
                b.setSlotId(rs.getString("slot_id"));
                b.setVehicleNumber(rs.getString("vehicle_number"));
                b.setDurationHours(rs.getInt("duration_hours"));
                b.setTotalAmount(rs.getDouble("total_amount"));
                b.setStatus(rs.getString("status"));
                b.setBookingTime(rs.getTimestamp("booking_time"));
                b.setEntryTime(rs.getTimestamp("entry_time"));
                b.setExitTime(rs.getTimestamp("exit_time"));
                b.setExpiresAt(rs.getTimestamp("expires_at"));
                b.setScheduledArrivalTime(rs.getTimestamp("scheduled_arrival_time"));
                b.setCancellationReason(rs.getString("cancellation_reason"));
                b.setPaymentId(rs.getString("payment_id"));
                b.setZoneId(rs.getString("zone_id"));
                b.setHourlyRate(rs.getDouble("hourly_rate"));
                return b;
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch active session for driver: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * SENSOR SCAN-OUT & DYNAMIC BILL CALCULATION:
     * When vehicle is leaving the bay, sensor records departure.
     * Computes exact elapsed parked duration and total amount based on zone tariff.
     */
    public Booking endParkingSession(int bookingId, double hourlyRate) throws DatabaseException, BookingException {
        Connection conn = null;
        PreparedStatement psSelect = null;
        PreparedStatement psUpdate = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            String sqlSelect = "SELECT b.booking_id, b.user_id, b.slot_id, b.entry_time, b.exit_time, b.status, z.hourly_rate " +
                    "FROM bookings b " +
                    "JOIN slots s ON b.slot_id = s.slot_id " +
                    "JOIN zones z ON s.zone_id = z.zone_id " +
                    "WHERE b.booking_id = ? FOR UPDATE";
            psSelect = conn.prepareStatement(sqlSelect);
            psSelect.setInt(1, bookingId);
            rs = psSelect.executeQuery();

            if (!rs.next()) {
                throw new BookingException("Booking #" + bookingId + " not found.");
            }

            String currentStatus = rs.getString("status");
            if ("COMPLETED".equalsIgnoreCase(currentStatus)) {
                conn.rollback();
                return getBookingById(bookingId);
            }
            if ("PAYMENT_PENDING".equalsIgnoreCase(currentStatus) && rs.getTimestamp("exit_time") != null) {
                conn.rollback();
                return getBookingById(bookingId);
            }
            if ("CANCELLED".equalsIgnoreCase(currentStatus)) {
                conn.rollback();
                throw new BookingException("Cannot check out a cancelled booking (#" + bookingId + ").");
            }

            Timestamp entryTime = rs.getTimestamp("entry_time");
            if (entryTime == null) {
                conn.rollback();
                throw new BookingException("Cannot check out booking #" + bookingId + " because vehicle has not checked in (no entry timestamp).");
            }

            double rate = (hourlyRate > 0) ? hourlyRate : rs.getDouble("hourly_rate");
            if (rate <= 0) rate = 30.0;

            Timestamp exitTime = new Timestamp(System.currentTimeMillis());
            long elapsedSeconds = Math.max(1L, (exitTime.getTime() - entryTime.getTime()) / 1000L);
            int durationHours = (int) Math.max(1, Math.ceil(elapsedSeconds / 3600.0));
            double totalAmount = durationHours * rate;

            double alreadyPaid = 0.0;
            try (PreparedStatement psPayCheck = conn.prepareStatement("SELECT COALESCE(SUM(amount), 0.0) FROM payments WHERE booking_id = ? AND status = 'SUCCESS'")) {
                psPayCheck.setInt(1, bookingId);
                try (ResultSet rsPay = psPayCheck.executeQuery()) {
                    if (rsPay.next()) {
                        alreadyPaid = rsPay.getDouble(1);
                    }
                }
            }

            if (alreadyPaid > 0 && alreadyPaid >= totalAmount) {
                // Booking was already fully prepaid - complete booking and release slot back to AVAILABLE
                String sqlUpdate = "UPDATE bookings SET exit_time = ?, duration_hours = ?, status = 'COMPLETED' WHERE booking_id = ?";
                psUpdate = conn.prepareStatement(sqlUpdate);
                psUpdate.setTimestamp(1, exitTime);
                psUpdate.setInt(2, durationHours);
                psUpdate.setInt(3, bookingId);
                psUpdate.executeUpdate();
                slotDAO.releaseSlot(conn, rs.getString("slot_id"));
            } else {
                double billAmount = (alreadyPaid > 0) ? Math.max(0.0, totalAmount - alreadyPaid) : totalAmount;
                String sqlUpdate = "UPDATE bookings SET exit_time = ?, duration_hours = ?, total_amount = ?, status = 'PAYMENT_PENDING' WHERE booking_id = ?";
                psUpdate = conn.prepareStatement(sqlUpdate);
                psUpdate.setTimestamp(1, exitTime);
                psUpdate.setInt(2, durationHours);
                psUpdate.setDouble(3, billAmount);
                psUpdate.setInt(4, bookingId);
                psUpdate.executeUpdate();
            }

            conn.commit();
            return getBookingById(bookingId);

        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Failed to calculate exit bill: " + e.getMessage(), e);
        } finally {
            DBConnection.close(null, psSelect, rs);
            DBConnection.close(null, psUpdate, null);
            DBConnection.close(conn, null, null);
        }
    }

    /**
     * FINAL PAYMENT & BAY SENSOR RELEASE:
     * Records transaction, marks booking COMPLETED, and releases slot back to AVAILABLE.
     */
    public boolean finalizeExitPayment(int bookingId, Payment payment) throws DatabaseException, BookingException {
        Connection conn = null;
        PreparedStatement psVerify = null;
        PreparedStatement psUpdateBooking = null;
        PreparedStatement psPayment = null;
        ResultSet rsVerify = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            psVerify = conn.prepareStatement("SELECT slot_id, status FROM bookings WHERE booking_id = ? FOR UPDATE");
            psVerify.setInt(1, bookingId);
            rsVerify = psVerify.executeQuery();

            if (!rsVerify.next()) {
                throw new BookingException("Booking #" + bookingId + " not found.");
            }

            String slotId = rsVerify.getString("slot_id");
            String currentStatus = rsVerify.getString("status");
            if ("COMPLETED".equalsIgnoreCase(currentStatus)) {
                throw new BookingException("Payment has already been finalized for booking #" + bookingId);
            }
            if ("CANCELLED".equalsIgnoreCase(currentStatus)) {
                throw new BookingException("Cannot process payment for a cancelled booking #" + bookingId);
            }
            if (payment == null || payment.getAmount() <= 0) {
                throw new BookingException("Invalid payment amount for booking #" + bookingId + ": Rs " + (payment != null ? payment.getAmount() : 0));
            }
            if (payment.getTransactionId() == null || payment.getTransactionId().trim().isEmpty()) {
                payment.setTransactionId("TXN_" + System.currentTimeMillis() + "_" + bookingId);
            }

            // Duplicate payment guard: Verify no successful payment record exists for this booking
            try (PreparedStatement psCheck = conn.prepareStatement("SELECT payment_id FROM payments WHERE booking_id = ? AND status = 'SUCCESS'")) {
                psCheck.setInt(1, bookingId);
                try (ResultSet rsCheck = psCheck.executeQuery()) {
                    if (rsCheck.next()) {
                        throw new BookingException("Payment has already been finalized for booking #" + bookingId);
                    }
                }
            }

            psUpdateBooking = conn.prepareStatement("UPDATE bookings SET status = 'COMPLETED', payment_id = ? WHERE booking_id = ?");
            psUpdateBooking.setString(1, payment.getTransactionId());
            psUpdateBooking.setInt(2, bookingId);
            psUpdateBooking.executeUpdate();

            // Release bay back to AVAILABLE in IoT sensor network
            slotDAO.releaseSlot(conn, slotId);

            // Record payment record
            String sqlPay = "INSERT INTO payments (booking_id, amount, payment_method, transaction_id, status) VALUES (?, ?, ?, ?, 'SUCCESS')";
            psPayment = conn.prepareStatement(sqlPay);
            psPayment.setInt(1, bookingId);
            psPayment.setDouble(2, payment.getAmount());
            psPayment.setString(3, payment.getPaymentMethod());
            psPayment.setString(4, payment.getTransactionId());
            psPayment.executeUpdate();

            conn.commit();
            return true;

        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Failed to process exit payment: " + e.getMessage(), e);
        } finally {
            DBConnection.close(null, psVerify, rsVerify);
            DBConnection.close(null, psUpdateBooking, null);
            DBConnection.close(null, psPayment, null);
            DBConnection.close(conn, null, null);
        }
    }

    /**
     * SCHEDULED SLOT RESERVATION:
     * User reserves a slot for a particular scheduled arrival time.
     * Slot status is set to RESERVED. 15-minute grace window is set (expires_at = scheduledArrivalTime + 15 mins).
     * Timer does NOT start yet (entry_time = NULL).
     */
    public int createScheduledReservation(Booking booking) throws DatabaseException, SlotUnavailableException {
        Connection conn = null;
        PreparedStatement psBooking = null;
        ResultSet rsKeys = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false); // Transaction begins

            // 1. Transactionally lock slot and mark as RESERVED
            slotDAO.lockAndReserveSlot(conn, booking.getSlotId());

            // 2. Scheduled arrival time & 15-minute grace window calculation
            Timestamp now = new Timestamp(System.currentTimeMillis());
            Timestamp scheduledArrival = booking.getScheduledArrivalTime() != null ? booking.getScheduledArrivalTime() : now;
            long graceMillis = 15 * 60 * 1000L; // 15 minutes grace
            Timestamp expiresAt = new Timestamp(scheduledArrival.getTime() + graceMillis);

            // 3. Insert RESERVED booking (entry_time = NULL until vehicle arrives & plate is scanned)
            String sql = "INSERT INTO bookings (user_id, slot_id, vehicle_number, duration_hours, total_amount, status, booking_time, scheduled_arrival_time, expires_at, entry_time) " +
                    "VALUES (?, ?, ?, 0, 0.00, 'RESERVED', ?, ?, ?, NULL)";
            psBooking = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            psBooking.setString(1, booking.getUserId());
            psBooking.setString(2, booking.getSlotId());
            psBooking.setString(3, booking.getVehicleNumber());
            psBooking.setTimestamp(4, now);
            psBooking.setTimestamp(5, scheduledArrival);
            psBooking.setTimestamp(6, expiresAt);

            psBooking.executeUpdate();
            rsKeys = psBooking.getGeneratedKeys();

            int bookingId = 0;
            if (rsKeys.next()) {
                bookingId = rsKeys.getInt(1);
            }

            // 4. Create confirmation notification for user
            NotificationDAO notifDAO = new NotificationDAO();
            Notification n = new Notification(
                    booking.getUserId(),
                    bookingId,
                    "Bay Reserved: " + booking.getSlotId(),
                    "Your bay " + booking.getSlotId() + " is reserved for scheduled arrival at " +
                            new java.text.SimpleDateFormat("hh:mm a").format(scheduledArrival) +
                            ". Please arrive and scan your vehicle plate within 15 minutes (by " +
                            new java.text.SimpleDateFormat("hh:mm a").format(expiresAt) + ").",
                    "INFO"
            );
            try {
                notifDAO.createNotification(n);
            } catch (Exception ignored) {}

            conn.commit();
            return bookingId;

        } catch (SlotUnavailableException sue) {
            DBConnection.rollback(conn);
            throw sue;
        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Failed to reserve slot: " + e.getMessage(), e);
        } finally {
            DBConnection.close(null, psBooking, rsKeys);
            DBConnection.close(conn, null, null);
        }
    }

    /**
     * VEHICLE ARRIVAL & LICENSE PLATE SCAN CHECK-IN:
     * Driver arrives at the zone and scans vehicle number plate.
     * Validates active reservation, marks slot as BOOKED (occupied),
     * sets entry_time = NOW, and starts the live parking stopwatch from 00:00:00.
     */
    public Booking checkInWithNumberPlate(String vehicleNumber, String slotId, String userId) throws DatabaseException, BookingException {
        Connection conn = null;
        PreparedStatement psSelect = null;
        PreparedStatement psUpdateBooking = null;
        PreparedStatement psUpdateSlot = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            String cleanPlate = (vehicleNumber != null) ? vehicleNumber.replaceAll("[^A-Za-z0-9]", "").toUpperCase() : "";
            if (cleanPlate.isEmpty()) {
                throw new BookingException("Missing vehicle number plate for ANPR check-in.");
            }

            // Concurrency & double check-in guard: Verify vehicle or bay is not already actively parked
            if (!cleanPlate.isEmpty() || (slotId != null && !slotId.trim().isEmpty())) {
                String dupSql = "SELECT booking_id, slot_id, vehicle_number FROM bookings WHERE status = 'ACTIVE' " +
                        "AND (slot_id = ? OR REPLACE(REPLACE(UPPER(vehicle_number), '-', ''), ' ', '') = ?) LIMIT 1";
                try (PreparedStatement psDup = conn.prepareStatement(dupSql)) {
                    psDup.setString(1, (slotId != null) ? slotId.trim() : "");
                    psDup.setString(2, cleanPlate);
                    try (ResultSet rsDup = psDup.executeQuery()) {
                        if (rsDup.next()) {
                            String activeSlot = rsDup.getString("slot_id");
                            String activeVrn = rsDup.getString("vehicle_number");
                            String cleanActiveVrn = (activeVrn != null) ? activeVrn.replaceAll("[^A-Za-z0-9]", "").toUpperCase() : "";
                            if (!cleanPlate.isEmpty() && cleanActiveVrn.equalsIgnoreCase(cleanPlate)) {
                                throw new BookingException("Duplicate entry attempt: Vehicle [" + vehicleNumber + "] is already checked in and actively parked in Bay [" + activeSlot + "].");
                            } else {
                                throw new BookingException("Bay [" + slotId + "] is already occupied by an active parking session.");
                            }
                        }
                    }
                }
            }

            // Verify slot is not under maintenance
            if (slotId != null && !slotId.trim().isEmpty()) {
                Slot curSlot = slotDAO.getSlotById(slotId.trim());
                if (curSlot != null && "MAINTENANCE".equalsIgnoreCase(curSlot.getStatus())) {
                    throw new BookingException("Bay [" + slotId + "] is currently under maintenance and cannot be checked in.");
                }
            }

            // Query active RESERVED or CONFIRMED booking
            StringBuilder sqlSelect = new StringBuilder(
                    "SELECT b.booking_id, b.user_id, b.slot_id, b.vehicle_number, b.status, b.scheduled_arrival_time, b.expires_at " +
                    "FROM bookings b WHERE b.status IN ('RESERVED', 'CONFIRMED') "
            );
            if (slotId != null && !slotId.trim().isEmpty()) {
                sqlSelect.append("AND b.slot_id = ? ");
            }
            if (cleanPlate != null && !cleanPlate.isEmpty()) {
                sqlSelect.append("AND REPLACE(REPLACE(UPPER(b.vehicle_number), '-', ''), ' ', '') = ? ");
            }
            if (userId != null && !userId.trim().isEmpty()) {
                sqlSelect.append("AND b.user_id = ? ");
            }
            sqlSelect.append("ORDER BY b.booking_id DESC LIMIT 1 FOR UPDATE");

            psSelect = conn.prepareStatement(sqlSelect.toString());
            int pIdx = 1;
            if (slotId != null && !slotId.trim().isEmpty()) psSelect.setString(pIdx++, slotId.trim());
            if (cleanPlate != null && !cleanPlate.isEmpty()) psSelect.setString(pIdx++, cleanPlate);
            if (userId != null && !userId.trim().isEmpty()) psSelect.setString(pIdx++, userId.trim());

            rs = psSelect.executeQuery();
            if (!rs.next()) {
                // Diagnostic check to give the exact reason for rejection
                String diagSql = "SELECT b.booking_id, b.user_id, b.slot_id, b.vehicle_number, b.status, b.expires_at " +
                        "FROM bookings b WHERE (REPLACE(REPLACE(UPPER(b.vehicle_number), '-', ''), ' ', '') = ? " +
                        "OR (b.slot_id = ? AND b.status IN ('RESERVED', 'CONFIRMED', 'CANCELLED', 'COMPLETED', 'ACTIVE'))) " +
                        "ORDER BY b.booking_id DESC LIMIT 1";
                try (PreparedStatement psDiag = conn.prepareStatement(diagSql)) {
                    psDiag.setString(1, cleanPlate);
                    psDiag.setString(2, (slotId != null) ? slotId.trim() : "");
                    try (ResultSet rsDiag = psDiag.executeQuery()) {
                        if (rsDiag.next()) {
                            int dBookingId = rsDiag.getInt("booking_id");
                            String dStatus = rsDiag.getString("status");
                            String dSlot = rsDiag.getString("slot_id");
                            String dVrn = rsDiag.getString("vehicle_number");
                            String cleanDVrn = (dVrn != null) ? dVrn.replaceAll("[^A-Za-z0-9]", "").toUpperCase() : "";

                            if (!cleanPlate.isEmpty() && cleanPlate.equalsIgnoreCase(cleanDVrn) && "CANCELLED".equalsIgnoreCase(dStatus)) {
                                throw new BookingException("Entry rejected: Reservation #" + dBookingId + " for vehicle [" + (cleanDVrn.isEmpty() ? vehicleNumber : dVrn) + "] has been CANCELLED.");
                            } else if (!cleanPlate.isEmpty() && cleanPlate.equalsIgnoreCase(cleanDVrn) && "COMPLETED".equalsIgnoreCase(dStatus)) {
                                throw new BookingException("Entry rejected: Booking #" + dBookingId + " for vehicle [" + (cleanDVrn.isEmpty() ? vehicleNumber : dVrn) + "] has already been COMPLETED.");
                            } else if (slotId != null && !slotId.trim().isEmpty() && dSlot != null && dSlot.equalsIgnoreCase(slotId.trim()) && ("RESERVED".equalsIgnoreCase(dStatus) || "CONFIRMED".equalsIgnoreCase(dStatus) || "ACTIVE".equalsIgnoreCase(dStatus)) && !cleanPlate.equalsIgnoreCase(cleanDVrn)) {
                                throw new BookingException("Entry rejected: Scanned plate [" + vehicleNumber + "] does not match reserved vehicle [" + dVrn + "] for Bay [" + slotId + "].");
                            } else if (!cleanPlate.isEmpty() && cleanPlate.equalsIgnoreCase(cleanDVrn) && slotId != null && !slotId.trim().isEmpty() && !slotId.trim().equalsIgnoreCase(dSlot)) {
                                throw new BookingException("Entry rejected: Vehicle [" + vehicleNumber + "] is reserved for Bay [" + dSlot + "], not Bay [" + slotId + "].");
                            } else if (userId != null && !userId.trim().isEmpty() && !userId.trim().equalsIgnoreCase(rsDiag.getString("user_id"))) {
                                throw new BookingException("Entry rejected: Reservation #" + dBookingId + " belongs to another driver account.");
                            }
                        }
                    }
                }
                throw new BookingException("Entry rejected: Unknown number plate [" + vehicleNumber + "]. No active reservation found.");
            }

            int bookingId = rs.getInt("booking_id");
            String bookingStatus = rs.getString("status");
            String actualSlotId = rs.getString("slot_id");
            String bookingUserId = rs.getString("user_id");
            Timestamp expiresAt = rs.getTimestamp("expires_at");
            Timestamp now = new Timestamp(System.currentTimeMillis());

            // If 15-minute grace window expired for unconfirmed reservation, reject check-in and auto-cancel
            if ("RESERVED".equals(bookingStatus) && expiresAt != null && now.after(expiresAt)) {
                conn.rollback();
                cancelExpiredReservations(15);
                throw new BookingException("Reservation #" + bookingId + " has expired (exceeded 15-minute arrival window). The bay has been released.");
            }

            // 1. Update booking: status = 'ACTIVE', entry_time = NOW
            psUpdateBooking = conn.prepareStatement(
                    "UPDATE bookings SET status = 'ACTIVE', entry_time = ? WHERE booking_id = ?"
            );
            psUpdateBooking.setTimestamp(1, now);
            psUpdateBooking.setInt(2, bookingId);
            psUpdateBooking.executeUpdate();

            // 2. Update slot: status = 'OCCUPIED' (occupied)
            psUpdateSlot = conn.prepareStatement(
                    "UPDATE slots SET status = 'OCCUPIED' WHERE slot_id = ?"
            );
            psUpdateSlot.setString(1, actualSlotId);
            psUpdateSlot.executeUpdate();

            // 3. User notification
            NotificationDAO notifDAO = new NotificationDAO();
            Notification n = new Notification(
                    bookingUserId,
                    bookingId,
                    "Vehicle Scanned • Bay Occupied",
                    "Vehicle plate " + vehicleNumber + " scanned and verified at Bay " + actualSlotId + ". Slot is now occupied and your live parking timer has started from 00:00:00.",
                    "SUCCESS"
            );
            try {
                notifDAO.createNotification(n);
            } catch (Exception ignored) {}

            conn.commit();
            return getBookingById(bookingId);

        } catch (BookingException be) {
            DBConnection.rollback(conn);
            recordRejectedGateAttempt(vehicleNumber, slotId, userId, be.getMessage(), "Simulated ANPR Camera");
            throw be;
        } catch (SQLException e) {
            DBConnection.rollback(conn);
            recordRejectedGateAttempt(vehicleNumber, slotId, userId, "Database error: " + e.getMessage(), "Simulated ANPR Camera");
            throw new DatabaseException("Plate check-in error: " + e.getMessage(), e);
        } finally {
            DBConnection.close(null, psSelect, rs);
            DBConnection.close(null, psUpdateBooking, null);
            DBConnection.close(null, psUpdateSlot, null);
            DBConnection.close(conn, null, null);
        }
    }

    /**
     * 15-MINUTE OVERTIME AUTO-CANCELLATION & NOTIFICATION:
     * If vehicle does not arrive within grace period (default 15 minutes) after scheduled arrival time,
     * the reservation is cancelled, slot released to AVAILABLE, and driver is notified.
     */
    public int cancelExpiredReservations(int graceMinutes) throws DatabaseException {
        Connection conn = null;
        PreparedStatement psSelect = null;
        PreparedStatement psUpdateBooking = null;
        PreparedStatement psReleaseSlot = null;
        ResultSet rs = null;
        int cancelledCount = 0;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            String sqlSelect = "SELECT booking_id, user_id, slot_id, vehicle_number, scheduled_arrival_time, expires_at " +
                    "FROM bookings " +
                    "WHERE status = 'RESERVED' AND entry_time IS NULL " +
                    "AND NOW() > COALESCE(expires_at, DATE_ADD(scheduled_arrival_time, INTERVAL ? MINUTE)) FOR UPDATE";

            psSelect = conn.prepareStatement(sqlSelect);
            psSelect.setInt(1, graceMinutes);
            rs = psSelect.executeQuery();

            List<Map<String, Object>> expiredList = new ArrayList<>();
            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("bookingId", rs.getInt("booking_id"));
                map.put("userId", rs.getString("user_id"));
                map.put("slotId", rs.getString("slot_id"));
                map.put("vehicleNumber", rs.getString("vehicle_number"));
                map.put("scheduledArrival", rs.getTimestamp("scheduled_arrival_time"));
                expiredList.add(map);
            }

            if (expiredList.isEmpty()) {
                conn.rollback();
                return 0;
            }

            psUpdateBooking = conn.prepareStatement(
                    "UPDATE bookings SET status = 'CANCELLED', cancellation_reason = ? WHERE booking_id = ?"
            );
            psReleaseSlot = conn.prepareStatement(
                    "UPDATE slots SET status = 'AVAILABLE' WHERE slot_id = ?"
            );

            NotificationDAO notifDAO = new NotificationDAO();
            String reason = "Cancelled due to overtime non-arrival (exceeded " + graceMinutes + "-minute grace window).";

            for (Map<String, Object> exp : expiredList) {
                int bId = (int) exp.get("bookingId");
                String uId = (String) exp.get("userId");
                String sId = (String) exp.get("slotId");
                String vNum = (String) exp.get("vehicleNumber");
                Timestamp sched = (Timestamp) exp.get("scheduledArrival");
                String schedStr = (sched != null) ? new java.text.SimpleDateFormat("hh:mm a").format(sched) : "scheduled time";

                // Update booking
                psUpdateBooking.setString(1, reason);
                psUpdateBooking.setInt(2, bId);
                psUpdateBooking.executeUpdate();

                // Release slot back to AVAILABLE safely
                slotDAO.releaseSlot(conn, sId);

                // Send and persist cancellation notification to driver
                Notification n = new Notification(
                        uId,
                        bId,
                        "⚠️ Reservation Cancelled - Overtime Non-Arrival",
                        "We are cancelling your reservation for Bay " + sId + " (Vehicle: " + vNum +
                                ") due to overtime non-arrival (over " + graceMinutes + " minutes past scheduled arrival at " +
                                schedStr + "). The slot has been released back to public availability.",
                        "CANCELLATION"
                );
                try {
                    notifDAO.createNotification(n);
                } catch (Exception ignored) {}

                cancelledCount++;
                System.out.println("[Reservation Cleaner] Auto-cancelled overtime reservation #" + bId + " (Slot " + sId + ")");
            }

            conn.commit();
            return cancelledCount;

        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Failed to cancel expired reservations: " + e.getMessage(), e);
        } finally {
            DBConnection.close(null, psSelect, rs);
            DBConnection.close(null, psUpdateBooking, null);
            DBConnection.close(null, psReleaseSlot, null);
            DBConnection.close(conn, null, null);
        }
    }

    /**
     * Voluntary driver cancellation ahead of arrival.
     */
    public boolean cancelReservationByUser(int bookingId, String userId) throws DatabaseException, BookingException {
        Connection conn = null;
        PreparedStatement ps = null;
        PreparedStatement psUpdate = null;
        PreparedStatement psRelease = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            ps = conn.prepareStatement("SELECT user_id, slot_id, status FROM bookings WHERE booking_id = ? FOR UPDATE");
            ps.setInt(1, bookingId);
            rs = ps.executeQuery();

            if (!rs.next()) {
                throw new BookingException("Booking #" + bookingId + " not found.");
            }

            String ownerId = rs.getString("user_id");
            String slotId = rs.getString("slot_id");
            String status = rs.getString("status");

            if (userId != null && !userId.equalsIgnoreCase(ownerId)) {
                throw new BookingException("Unauthorized: You do not own booking #" + bookingId);
            }

            if (!"RESERVED".equalsIgnoreCase(status) && !"PENDING".equalsIgnoreCase(status)) {
                throw new BookingException("Only unparked reservations can be cancelled. Current status: " + status);
            }

            psUpdate = conn.prepareStatement("UPDATE bookings SET status = 'CANCELLED', cancellation_reason = 'Cancelled by driver' WHERE booking_id = ?");
            psUpdate.setInt(1, bookingId);
            psUpdate.executeUpdate();

            // Safely release slot back to AVAILABLE
            slotDAO.releaseSlot(conn, slotId);

            conn.commit();
            return true;

        } catch (BookingException be) {
            DBConnection.rollback(conn);
            throw be;
        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Error cancelling reservation: " + e.getMessage(), e);
        } finally {
            DBConnection.close(null, ps, rs);
            DBConnection.close(null, psUpdate, null);
            DBConnection.close(null, psRelease, null);
            DBConnection.close(conn, null, null);
        }
    }

    /**
     * Legacy / Pre-paid reservation method (retained for backward compatibility).
     */
    public int createPendingBooking(Booking booking) throws DatabaseException, SlotUnavailableException {
        Connection conn = null;
        PreparedStatement psBooking = null;
        ResultSet rsKeys = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false); // Transaction begins

            // 1. Transactional check & reserve
            slotDAO.lockAndReserveSlot(conn, booking.getSlotId());

            // 2. Insert PENDING booking record
            String sql = "INSERT INTO bookings (user_id, slot_id, vehicle_number, duration_hours, total_amount, status, booking_time, expires_at) " +
                    "VALUES (?, ?, ?, ?, ?, 'PENDING', CURRENT_TIMESTAMP, ?)";
            psBooking = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            psBooking.setString(1, booking.getUserId());
            psBooking.setString(2, booking.getSlotId());
            psBooking.setString(3, booking.getVehicleNumber());
            psBooking.setInt(4, booking.getDurationHours());
            psBooking.setDouble(5, booking.getTotalAmount());

            // 5 minutes expiry window for mock payment
            long expiryTime = System.currentTimeMillis() + (5 * 60 * 1000L);
            psBooking.setTimestamp(6, new Timestamp(expiryTime));

            psBooking.executeUpdate();
            rsKeys = psBooking.getGeneratedKeys();

            int bookingId = 0;
            if (rsKeys.next()) {
                bookingId = rsKeys.getInt(1);
            }

            conn.commit(); // Transaction committed
            return bookingId;

        } catch (SlotUnavailableException sue) {
            DBConnection.rollback(conn);
            throw sue;
        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Failed to initiate pending booking: " + e.getMessage(), e);
        } finally {
            DBConnection.close(null, psBooking, rsKeys);
            DBConnection.close(conn, null, null);
        }
    }

    /**
     * Step 2: Finalize booking after successful mock payment.
     * Atomically marks booking CONFIRMED, slot BOOKED, and inserts PAYMENT record.
     */
    public boolean finalizeBooking(int bookingId, Payment payment) throws DatabaseException, BookingException {
        Connection conn = null;
        PreparedStatement psVerify = null;
        PreparedStatement psUpdateBooking = null;
        PreparedStatement psPayment = null;
        ResultSet rsVerify = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false); // Transaction begins

            // 1. Verify booking is still PENDING and slot is RESERVED
            psVerify = conn.prepareStatement("SELECT slot_id, status FROM bookings WHERE booking_id = ? FOR UPDATE");
            psVerify.setInt(1, bookingId);
            rsVerify = psVerify.executeQuery();

            if (!rsVerify.next()) {
                throw new BookingException("Booking #" + bookingId + " not found.");
            }

            String currentStatus = rsVerify.getString("status");
            String slotId = rsVerify.getString("slot_id");

            if (!"PENDING".equalsIgnoreCase(currentStatus)) {
                throw new BookingException("Booking #" + bookingId + " is no longer in PENDING state (Status: " + currentStatus + ").");
            }

            // 2. Mark booking as CONFIRMED
            psUpdateBooking = conn.prepareStatement("UPDATE bookings SET status = 'CONFIRMED', payment_id = ? WHERE booking_id = ?");
            psUpdateBooking.setString(1, payment.getTransactionId());
            psUpdateBooking.setInt(2, bookingId);
            psUpdateBooking.executeUpdate();

            // 3. Mark slot as BOOKED
            slotDAO.confirmSlot(conn, slotId);

            // 4. Record payment
            String sqlPay = "INSERT INTO payments (booking_id, amount, payment_method, transaction_id, status) VALUES (?, ?, ?, ?, 'SUCCESS')";
            psPayment = conn.prepareStatement(sqlPay);
            psPayment.setInt(1, bookingId);
            psPayment.setDouble(2, payment.getAmount());
            psPayment.setString(3, payment.getPaymentMethod());
            psPayment.setString(4, payment.getTransactionId());
            psPayment.executeUpdate();

            conn.commit(); // Transaction committed
            return true;

        } catch (BookingException be) {
            DBConnection.rollback(conn);
            throw be;
        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Failed to finalize booking: " + e.getMessage(), e);
        } finally {
            DBConnection.close(null, psVerify, rsVerify);
            DBConnection.close(null, psUpdateBooking, null);
            DBConnection.close(null, psPayment, null);
            DBConnection.close(conn, null, null);
        }
    }

    /**
     * Cancels or expires a PENDING booking, releasing the held slot back to AVAILABLE.
     */
    public boolean cancelPendingBooking(int bookingId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        PreparedStatement psUpdate = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            ps = conn.prepareStatement("SELECT slot_id, status FROM bookings WHERE booking_id = ? FOR UPDATE");
            ps.setInt(1, bookingId);
            rs = ps.executeQuery();

            if (rs.next()) {
                String slotId = rs.getString("slot_id");
                String status = rs.getString("status");

                if ("PENDING".equalsIgnoreCase(status)) {
                    psUpdate = conn.prepareStatement("UPDATE bookings SET status = 'CANCELLED' WHERE booking_id = ?");
                    psUpdate.setInt(1, bookingId);
                    psUpdate.executeUpdate();

                    slotDAO.releaseSlot(conn, slotId);
                    conn.commit();
                    return true;
                }
            }
            conn.rollback();
            return false;
        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Failed to cancel pending booking", e);
        } finally {
            DBConnection.close(null, ps, rs);
            DBConnection.close(null, psUpdate, null);
            DBConnection.close(conn, null, null);
        }
    }

    /**
     * Cancels a CONFIRMED booking, releases slot back to AVAILABLE, and records mock refund.
     */
    public boolean cancelConfirmedBooking(int bookingId, String userId) throws DatabaseException, BookingException {
        Connection conn = null;
        PreparedStatement ps = null;
        PreparedStatement psUpdate = null;
        PreparedStatement psRefund = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            ps = conn.prepareStatement("SELECT slot_id, status, user_id FROM bookings WHERE booking_id = ? FOR UPDATE");
            ps.setInt(1, bookingId);
            rs = ps.executeQuery();

            if (!rs.next()) {
                throw new BookingException("Booking #" + bookingId + " does not exist.");
            }

            String slotId = rs.getString("slot_id");
            String status = rs.getString("status");
            String ownerId = rs.getString("user_id");

            if (userId != null && !userId.equalsIgnoreCase(ownerId)) {
                throw new BookingException("Unauthorized: You do not own booking #" + bookingId);
            }

            if (!"CONFIRMED".equalsIgnoreCase(status)) {
                throw new BookingException("Only CONFIRMED bookings can be cancelled. Current status: " + status);
            }

            // Update booking status
            psUpdate = conn.prepareStatement("UPDATE bookings SET status = 'CANCELLED' WHERE booking_id = ?");
            psUpdate.setInt(1, bookingId);
            psUpdate.executeUpdate();

            // Release slot
            slotDAO.releaseSlot(conn, slotId);

            // Update payment record to REFUNDED
            psRefund = conn.prepareStatement("UPDATE payments SET status = 'REFUNDED' WHERE booking_id = ?");
            psRefund.setInt(1, bookingId);
            psRefund.executeUpdate();

            conn.commit();
            return true;

        } catch (BookingException be) {
            DBConnection.rollback(conn);
            throw be;
        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Error cancelling booking: " + e.getMessage(), e);
        } finally {
            DBConnection.close(null, ps, rs);
            DBConnection.close(null, psUpdate, null);
            DBConnection.close(null, psRefund, null);
            DBConnection.close(conn, null, null);
        }
    }

    public List<Booking> getBookingsByUser(String userId) throws DatabaseException {
        List<Booking> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT b.booking_id, b.user_id, b.slot_id, b.vehicle_number, b.duration_hours, b.total_amount, " +
                    "b.status, b.booking_time, b.entry_time, b.exit_time, b.expires_at, b.scheduled_arrival_time, b.cancellation_reason, b.payment_id, s.zone_id, z.hourly_rate, " +
                    "(SELECT COUNT(*) FROM feedback f WHERE f.booking_id = b.booking_id) AS feedback_count " +
                    "FROM bookings b " +
                    "JOIN slots s ON b.slot_id = s.slot_id " +
                    "JOIN zones z ON s.zone_id = z.zone_id " +
                    "WHERE b.user_id = ? " +
                    "ORDER BY b.booking_time DESC";

            ps = conn.prepareStatement(sql);
            ps.setString(1, userId);
            rs = ps.executeQuery();

            while (rs.next()) {
                Booking b = new Booking();
                b.setBookingId(rs.getInt("booking_id"));
                b.setUserId(rs.getString("user_id"));
                b.setSlotId(rs.getString("slot_id"));
                b.setVehicleNumber(rs.getString("vehicle_number"));
                b.setDurationHours(rs.getInt("duration_hours"));
                b.setTotalAmount(rs.getDouble("total_amount"));
                b.setStatus(rs.getString("status"));
                b.setBookingTime(rs.getTimestamp("booking_time"));
                b.setEntryTime(rs.getTimestamp("entry_time"));
                b.setExitTime(rs.getTimestamp("exit_time"));
                b.setExpiresAt(rs.getTimestamp("expires_at"));
                b.setScheduledArrivalTime(rs.getTimestamp("scheduled_arrival_time"));
                b.setCancellationReason(rs.getString("cancellation_reason"));
                b.setPaymentId(rs.getString("payment_id"));
                b.setZoneId(rs.getString("zone_id"));
                b.setHourlyRate(rs.getDouble("hourly_rate"));
                b.setFeedbackGiven(rs.getInt("feedback_count") > 0);
                list.add(b);
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch user bookings: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public List<Booking> getAllBookings() throws DatabaseException {
        List<Booking> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT b.booking_id, b.user_id, b.slot_id, b.vehicle_number, b.duration_hours, b.total_amount, " +
                    "b.status, b.booking_time, b.entry_time, b.exit_time, b.expires_at, b.payment_id, u.name AS user_name, u.email AS user_email, s.zone_id " +
                    "FROM bookings b " +
                    "JOIN users u ON b.user_id = u.user_id " +
                    "JOIN slots s ON b.slot_id = s.slot_id " +
                    "ORDER BY b.booking_id DESC";

            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                Booking b = new Booking();
                b.setBookingId(rs.getInt("booking_id"));
                b.setUserId(rs.getString("user_id"));
                b.setSlotId(rs.getString("slot_id"));
                b.setVehicleNumber(rs.getString("vehicle_number"));
                b.setDurationHours(rs.getInt("duration_hours"));
                b.setTotalAmount(rs.getDouble("total_amount"));
                b.setStatus(rs.getString("status"));
                b.setBookingTime(rs.getTimestamp("booking_time"));
                b.setEntryTime(rs.getTimestamp("entry_time"));
                b.setExitTime(rs.getTimestamp("exit_time"));
                b.setExpiresAt(rs.getTimestamp("expires_at"));
                b.setPaymentId(rs.getString("payment_id"));
                b.setUserName(rs.getString("user_name"));
                b.setUserEmail(rs.getString("user_email"));
                b.setZoneId(rs.getString("zone_id"));
                list.add(b);
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch all bookings", e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public Booking getBookingById(int bookingId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT b.booking_id, b.user_id, b.slot_id, b.vehicle_number, b.duration_hours, b.total_amount, " +
                    "b.status, b.booking_time, b.entry_time, b.exit_time, b.expires_at, b.scheduled_arrival_time, b.cancellation_reason, b.payment_id, u.name AS user_name, u.email AS user_email, s.zone_id, z.hourly_rate " +
                    "FROM bookings b " +
                    "JOIN users u ON b.user_id = u.user_id " +
                    "JOIN slots s ON b.slot_id = s.slot_id " +
                    "JOIN zones z ON s.zone_id = z.zone_id " +
                    "WHERE b.booking_id = ?";

            ps = conn.prepareStatement(sql);
            ps.setInt(1, bookingId);
            rs = ps.executeQuery();

            if (rs.next()) {
                Booking b = new Booking();
                b.setBookingId(rs.getInt("booking_id"));
                b.setUserId(rs.getString("user_id"));
                b.setSlotId(rs.getString("slot_id"));
                b.setVehicleNumber(rs.getString("vehicle_number"));
                b.setDurationHours(rs.getInt("duration_hours"));
                b.setTotalAmount(rs.getDouble("total_amount"));
                b.setStatus(rs.getString("status"));
                b.setBookingTime(rs.getTimestamp("booking_time"));
                b.setEntryTime(rs.getTimestamp("entry_time"));
                b.setExitTime(rs.getTimestamp("exit_time"));
                b.setExpiresAt(rs.getTimestamp("expires_at"));
                b.setScheduledArrivalTime(rs.getTimestamp("scheduled_arrival_time"));
                b.setCancellationReason(rs.getString("cancellation_reason"));
                b.setPaymentId(rs.getString("payment_id"));
                b.setUserName(rs.getString("user_name"));
                b.setUserEmail(rs.getString("user_email"));
                b.setZoneId(rs.getString("zone_id"));
                b.setHourlyRate(rs.getDouble("hourly_rate"));
                return b;
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch booking #" + bookingId, e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public Map<String, Object> getRevenueStats() throws DatabaseException {
        Map<String, Object> stats = new HashMap<>();
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            stmt = conn.createStatement();

            // Total collected revenue strictly from settled successful payments (excludes cancelled, unpaid, and active accruals)
            rs = stmt.executeQuery("SELECT COALESCE(SUM(amount), 0) AS total_revenue, COUNT(*) AS total_paid_txns FROM payments WHERE status = 'SUCCESS'");
            if (rs.next()) {
                stats.put("totalRevenue", rs.getDouble("total_revenue"));
                stats.put("totalPaidTransactions", rs.getInt("total_paid_txns"));
                stats.put("verifiedPaidSum", rs.getDouble("total_revenue"));
            }

            // Total confirmed/completed bookings count
            rs.close();
            rs = stmt.executeQuery("SELECT COUNT(*) AS total_count FROM bookings WHERE status IN ('CONFIRMED', 'COMPLETED')");
            if (rs.next()) {
                stats.put("totalConfirmedBookings", rs.getInt("total_count"));
            }

            // Today's collected revenue strictly from settled payments where payment_time is in current operating day
            rs.close();
            rs = stmt.executeQuery("SELECT COALESCE(SUM(amount), 0) AS today_revenue FROM payments WHERE status = 'SUCCESS' AND DATE(payment_time) = CURDATE()");
            if (rs.next()) {
                stats.put("todayRevenue", rs.getDouble("today_revenue"));
            }

            // Pending revenue: vehicles that departed bay but payment is awaiting completion
            rs.close();
            rs = stmt.executeQuery("SELECT COALESCE(SUM(total_amount), 0) AS pending_revenue, COUNT(*) AS pending_count FROM bookings WHERE status = 'PAYMENT_PENDING'");
            if (rs.next()) {
                stats.put("pendingRevenue", rs.getDouble("pending_revenue"));
                stats.put("pendingCount", rs.getInt("pending_count"));
            }

            // Cancelled bookings count (explicitly excluded from revenue accounting)
            rs.close();
            rs = stmt.executeQuery("SELECT COUNT(*) AS cancelled_count FROM bookings WHERE status = 'CANCELLED'");
            if (rs.next()) {
                stats.put("cancelledBookingsCount", rs.getInt("cancelled_count"));
            }

            return stats;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to calculate revenue stats", e);
        } finally {
            DBConnection.close(conn, stmt, rs);
        }
    }

    /**
     * Analytics: 24-Hour Occupancy Curve
     * Aggregates hourly vehicle check-ins and bookings across the 24 hours of the day (00:00 to 23:00).
    /**
     * Analytics: 24-Hour Occupancy Curve
     * Aggregates hourly vehicle check-ins and bookings across the 24 hours of the day (00:00 to 23:00).
     * Strictly reflects genuine database records; contains zero synthetic baseline values.
     */
    public int[] get24HourOccupancyCurve() throws DatabaseException {
        int[] hourlyData = new int[24];

        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            stmt = conn.createStatement();
            String sql = "SELECT HOUR(COALESCE(entry_time, booking_time)) AS hr, COUNT(*) AS cnt " +
                    "FROM bookings " +
                    "WHERE status IN ('ACTIVE', 'CONFIRMED', 'COMPLETED', 'PAYMENT_PENDING') " +
                    "GROUP BY hr";
            rs = stmt.executeQuery(sql);
            while (rs.next()) {
                int hr = rs.getInt("hr");
                int cnt = rs.getInt("cnt");
                if (hr >= 0 && hr < 24) {
                    hourlyData[hr] += cnt;
                }
            }
            return hourlyData;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch 24-hour occupancy curve: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, stmt, rs);
        }
    }

    /**
     * Analytics: Metropolitan Revenue Breakdown by City
     * Aggregates settled parking revenue strictly from successful payments joined to facilities.
     * Contains only cities with genuine settled revenue; no artificial placeholder bars.
     */
    public Map<String, Double> getRevenueByCityData() throws DatabaseException {
        Map<String, Double> cityRevenue = new LinkedHashMap<>();

        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            stmt = conn.createStatement();
            String sql = "SELECT " +
                    "CASE " +
                    "  WHEN z.zone_id IN ('A', 'MUM-2', 'MUM-3', 'MUM-4') OR z.name LIKE '%Mumbai%' THEN 'Mumbai' " +
                    "  WHEN z.zone_id IN ('B', 'BLR-2', 'BLR-3', 'BLR-4') OR z.name LIKE '%Bengaluru%' OR z.name LIKE '%Bangalore%' THEN 'Bengaluru' " +
                    "  WHEN z.zone_id IN ('C', 'DEL-2', 'DEL-3', 'DEL-4') OR z.name LIKE '%Delhi%' THEN 'New Delhi' " +
                    "  WHEN z.zone_id IN ('D', 'HYD-2', 'HYD-3', 'HYD-4') OR z.name LIKE '%Hyderabad%' THEN 'Hyderabad' " +
                    "  WHEN z.zone_id IN ('E', 'CHN-2', 'CHN-3', 'CHN-4') OR z.name LIKE '%Chennai%' THEN 'Chennai' " +
                    "  WHEN z.zone_id IN ('F', 'KOL-2', 'KOL-3', 'KOL-4') OR z.name LIKE '%Kolkata%' THEN 'Kolkata' " +
                    "  ELSE 'Other' " +
                    "END AS city_name, " +
                    "SUM(p.amount) AS rev " +
                    "FROM payments p " +
                    "JOIN bookings b ON p.booking_id = b.booking_id " +
                    "JOIN slots s ON b.slot_id = s.slot_id " +
                    "JOIN zones z ON s.zone_id = z.zone_id " +
                    "WHERE p.status = 'SUCCESS' " +
                    "GROUP BY city_name";
            rs = stmt.executeQuery(sql);
            while (rs.next()) {
                String c = rs.getString("city_name");
                double rev = rs.getDouble("rev");
                if (c != null && rev > 0.0) {
                    cityRevenue.put(c, cityRevenue.getOrDefault(c, 0.0) + rev);
                }
            }
            return cityRevenue;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch revenue by city: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, stmt, rs);
        }
    }

    /**
     * Analytics: Payment Method Distribution
     * Returns genuine transaction counts across payment channels from settled transactions.
     * Contains only payment methods present in verified successful payment records.
     */
    public Map<String, Integer> getPaymentMethodDistributionData() throws DatabaseException {
        Map<String, Integer> dist = new LinkedHashMap<>();

        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            stmt = conn.createStatement();
            String sql = "SELECT payment_method, COUNT(*) AS cnt FROM payments WHERE status = 'SUCCESS' GROUP BY payment_method";
            rs = stmt.executeQuery(sql);
            while (rs.next()) {
                String m = rs.getString("payment_method");
                int cnt = rs.getInt("cnt");
                if (m != null && cnt > 0) {
                    m = m.trim().toUpperCase();
                    dist.put(m, dist.getOrDefault(m, 0) + cnt);
                }
            }
            return dist;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch payment method distribution: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, stmt, rs);
        }
    }

    /**
     * Checks if a slot currently has an active user reservation or parking session.
     * Prevents administrative actions or IoT simulation from overwriting real user bookings.
     */
    public boolean hasActiveBookingForSlot(String slotId) throws DatabaseException {
        if (slotId == null || slotId.trim().isEmpty()) return false;
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT COUNT(*) FROM bookings WHERE slot_id = ? AND (" +
                         "status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') OR " +
                         "(status IN ('PENDING', 'CONFIRMED', 'RESERVED') AND (expires_at IS NULL OR expires_at > NOW())))";
            ps = conn.prepareStatement(sql);
            ps.setString(1, slotId.trim().toUpperCase());
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            return false;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to check active booking for slot: " + slotId, e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * Retrieves the latest active booking for a slot (if any) for authorized inspection.
     */
    public Booking getActiveBookingForSlot(String slotId) throws DatabaseException {
        if (slotId == null || slotId.trim().isEmpty()) return null;
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT booking_id, user_id, slot_id, vehicle_number, duration_hours, total_amount, status, " +
                         "booking_time, entry_time, exit_time, scheduled_arrival_time " +
                         "FROM bookings WHERE slot_id = ? AND (" +
                         "status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') OR " +
                         "(status IN ('PENDING', 'CONFIRMED', 'RESERVED') AND (expires_at IS NULL OR expires_at > NOW()))) " +
                         "ORDER BY booking_id DESC LIMIT 1";
            ps = conn.prepareStatement(sql);
            ps.setString(1, slotId.trim().toUpperCase());
            rs = ps.executeQuery();
            if (rs.next()) {
                Booking b = new Booking();
                b.setBookingId(rs.getInt("booking_id"));
                b.setUserId(rs.getString("user_id"));
                b.setSlotId(rs.getString("slot_id"));
                b.setVehicleNumber(rs.getString("vehicle_number"));
                b.setDurationHours(rs.getInt("duration_hours"));
                b.setTotalAmount(rs.getDouble("total_amount"));
                b.setStatus(rs.getString("status"));
                b.setBookingTime(rs.getTimestamp("booking_time"));
                b.setEntryTime(rs.getTimestamp("entry_time"));
                b.setExitTime(rs.getTimestamp("exit_time"));
                try {
                    b.setScheduledArrivalTime(rs.getTimestamp("scheduled_arrival_time"));
                } catch (Exception ignored) {}
                return b;
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to retrieve active booking for slot: " + slotId, e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * HYPERPARK ACTIVE PARKING SESSIONS:
     * Retrieves all vehicles currently parked in bays (status 'ACTIVE' or 'PAYMENT_PENDING').
     * Computes real-time dynamic tariff rates, elapsed seconds, and live accrued estimated charges.
     */
    public List<Booking> getActiveParkingSessions() throws DatabaseException {
        List<Booking> sessions = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT b.booking_id, b.user_id, b.slot_id, b.vehicle_number, b.duration_hours, b.total_amount, " +
                    "b.status, b.booking_time, b.entry_time, b.exit_time, b.expires_at, b.scheduled_arrival_time, b.cancellation_reason, b.payment_id, " +
                    "u.name AS user_name, u.email AS user_email, s.zone_id, z.name AS zone_name, z.hourly_rate " +
                    "FROM bookings b " +
                    "JOIN slots s ON b.slot_id = s.slot_id " +
                    "JOIN zones z ON s.zone_id = z.zone_id " +
                    "JOIN users u ON b.user_id = u.user_id " +
                    "WHERE b.status IN ('ACTIVE', 'PAYMENT_PENDING') AND b.entry_time IS NOT NULL " +
                    "ORDER BY b.entry_time DESC";

            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            ZoneDAO zoneDAO = new ZoneDAO();

            while (rs.next()) {
                Booking b = new Booking();
                b.setBookingId(rs.getInt("booking_id"));
                b.setUserId(rs.getString("user_id"));
                b.setSlotId(rs.getString("slot_id"));
                b.setVehicleNumber(rs.getString("vehicle_number"));
                b.setDurationHours(rs.getInt("duration_hours"));
                b.setTotalAmount(rs.getDouble("total_amount"));
                b.setStatus(rs.getString("status"));
                b.setBookingTime(rs.getTimestamp("booking_time"));
                b.setEntryTime(rs.getTimestamp("entry_time"));
                b.setExitTime(rs.getTimestamp("exit_time"));
                b.setExpiresAt(rs.getTimestamp("expires_at"));
                b.setScheduledArrivalTime(rs.getTimestamp("scheduled_arrival_time"));
                b.setCancellationReason(rs.getString("cancellation_reason"));
                b.setPaymentId(rs.getString("payment_id"));
                b.setUserName(rs.getString("user_name"));
                b.setUserEmail(rs.getString("user_email"));
                b.setZoneId(rs.getString("zone_id"));

                double baseRate = rs.getDouble("hourly_rate");
                if (baseRate <= 0) baseRate = 40.0;

                double effectiveRate = baseRate;
                try {
                    com.parkingsystem.model.Zone zone = zoneDAO.getZoneById(b.getZoneId());
                    if (zone != null) {
                        effectiveRate = zone.getEffectiveHourlyRate();
                    }
                } catch (Exception ignored) {}

                b.setHourlyRate(effectiveRate);
                sessions.add(b);
            }
            return sessions;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch active parking sessions: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * HYPERPARK GATE ACTIVITY LEDGER:
     * Chronological audit stream of simulated vehicle entry and exit movements across facilities.
     * All gate camera (ANPR) and sensor triggers are prototype simulations.
     */
    public List<GateActivityEvent> getRecentGateActivity(int limit) throws DatabaseException {
        if (limit <= 0) limit = 25;
        List<GateActivityEvent> events = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT * FROM (" +
                    "  SELECT b.booking_id, b.vehicle_number, b.user_id, u.name AS user_name, b.slot_id, s.zone_id, z.name AS zone_name, " +
                    "         'ENTRY' AS event_type, b.entry_time AS event_time, " +
                    "         'Simulated ANPR Camera' AS event_source, " +
                    "         'Admitted & Bay Occupied' AS event_result, " +
                    "         b.status AS booking_status, b.total_amount, " +
                    "         CASE WHEN b.status = 'COMPLETED' THEN 'COMPLETED' WHEN b.status = 'PAYMENT_PENDING' THEN 'PENDING' ELSE 'ESTIMATED' END AS payment_status, " +
                    "         COALESCE(p.payment_method, '-') AS payment_method, " +
                    "         COALESCE(b.payment_id, COALESCE(p.transaction_id, '-')) AS transaction_id, " +
                    "         b.booking_time, b.entry_time, b.exit_time " +
                    "  FROM bookings b " +
                    "  JOIN users u ON b.user_id = u.user_id " +
                    "  JOIN slots s ON b.slot_id = s.slot_id " +
                    "  JOIN zones z ON s.zone_id = z.zone_id " +
                    "  LEFT JOIN payments p ON b.booking_id = p.booking_id " +
                    "  WHERE b.entry_time IS NOT NULL " +
                    "  UNION ALL " +
                    "  SELECT b.booking_id, b.vehicle_number, b.user_id, u.name AS user_name, b.slot_id, s.zone_id, z.name AS zone_name, " +
                    "         'EXIT' AS event_type, b.exit_time AS event_time, " +
                    "         'Simulated Outgate Sensor' AS event_source, " +
                    "         CASE WHEN b.status = 'COMPLETED' THEN 'Departed • Bill Paid' ELSE 'Departed • Awaiting Payment' END AS event_result, " +
                    "         b.status AS booking_status, b.total_amount, " +
                    "         CASE WHEN b.status = 'COMPLETED' THEN 'COMPLETED' ELSE 'PENDING' END AS payment_status, " +
                    "         COALESCE(p.payment_method, '-') AS payment_method, " +
                    "         COALESCE(b.payment_id, COALESCE(p.transaction_id, '-')) AS transaction_id, " +
                    "         b.booking_time, b.entry_time, b.exit_time " +
                    "  FROM bookings b " +
                    "  JOIN users u ON b.user_id = u.user_id " +
                    "  JOIN slots s ON b.slot_id = s.slot_id " +
                    "  JOIN zones z ON s.zone_id = z.zone_id " +
                    "  LEFT JOIN payments p ON b.booking_id = p.booking_id " +
                    "  WHERE b.exit_time IS NOT NULL " +
                    ") combined_events " +
                    "ORDER BY event_time DESC LIMIT ?";

            ps = conn.prepareStatement(sql);
            ps.setInt(1, limit);
            rs = ps.executeQuery();

            while (rs.next()) {
                GateActivityEvent evt = new GateActivityEvent();
                evt.setBookingId(rs.getInt("booking_id"));
                evt.setVehicleNumber(rs.getString("vehicle_number"));
                evt.setUserId(rs.getString("user_id"));
                evt.setUserName(rs.getString("user_name"));
                evt.setSlotId(rs.getString("slot_id"));
                evt.setZoneId(rs.getString("zone_id"));
                evt.setZoneName(rs.getString("zone_name"));
                evt.setEventType(rs.getString("event_type"));
                evt.setEventTime(rs.getTimestamp("event_time"));
                evt.setEventSource(rs.getString("event_source"));
                evt.setEventResult(rs.getString("event_result"));
                evt.setBookingStatus(rs.getString("booking_status"));
                evt.setAmount(rs.getDouble("total_amount"));
                evt.setPaymentStatus(rs.getString("payment_status"));
                evt.setPaymentMethod(rs.getString("payment_method"));
                evt.setTransactionId(rs.getString("transaction_id"));
                evt.setBookingTime(rs.getTimestamp("booking_time"));
                evt.setEntryTime(rs.getTimestamp("entry_time"));
                evt.setExitTime(rs.getTimestamp("exit_time"));
                events.add(evt);
            }

            // Merge rejected gate events with recorded database movement events
            for (GateActivityEvent rej : REJECTED_GATE_EVENTS) {
                events.add(rej);
            }

            // Sort all events chronologically (newest first)
            events.sort((a, b) -> {
                if (a.getEventTime() == null && b.getEventTime() == null) return 0;
                if (a.getEventTime() == null) return 1;
                if (b.getEventTime() == null) return -1;
                return b.getEventTime().compareTo(a.getEventTime());
            });

            if (events.size() > limit) {
                return new ArrayList<>(events.subList(0, limit));
            }
            return events;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch gate activity: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    private static final int MAX_REJECTED_EVENTS = 100;
    private static final java.util.concurrent.ConcurrentLinkedDeque<GateActivityEvent> REJECTED_GATE_EVENTS = new java.util.concurrent.ConcurrentLinkedDeque<>();

    /**
     * Records an authorized or rejected gate access event into the audit ledger.
     */
    public static void recordRejectedGateAttempt(String vehicleNumber, String slotId, String userId, String reason, String source) {
        GateActivityEvent event = new GateActivityEvent();
        event.setBookingId(0);
        event.setVehicleNumber((vehicleNumber != null && !vehicleNumber.trim().isEmpty()) ? vehicleNumber.toUpperCase() : "UNKNOWN");
        event.setUserId((userId != null && !userId.trim().isEmpty()) ? userId : "--");
        event.setUserName((userId != null && !userId.trim().isEmpty()) ? userId : "Visitor / Unknown");
        event.setSlotId((slotId != null && !slotId.trim().isEmpty()) ? slotId : "--");
        event.setZoneId("--");
        event.setZoneName("Facility Gate");
        event.setEventType("REJECTED");
        event.setEventTime(new Timestamp(System.currentTimeMillis()));
        event.setEventSource((source != null && !source.trim().isEmpty()) ? source : "Simulated ANPR Camera");
        event.setEventResult(reason != null ? reason : "Access Denied");
        event.setBookingStatus("REJECTED");
        event.setAmount(0.0);
        event.setPaymentStatus("N/A");
        event.setPaymentMethod("-");
        event.setTransactionId("-");

        REJECTED_GATE_EVENTS.addFirst(event);
        while (REJECTED_GATE_EVENTS.size() > MAX_REJECTED_EVENTS) {
            REJECTED_GATE_EVENTS.pollLast();
        }
    }
}

