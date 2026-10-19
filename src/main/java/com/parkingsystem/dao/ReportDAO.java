package com.parkingsystem.dao;

import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.*;
import com.parkingsystem.util.DBConnection;

import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * Data Access Object for Administrative Reports & Export generation.
 * Queries actual database records for Real-Time Occupancy, Bookings, and Settled Revenue.
 * Uses prepared statements with dynamic parameterization and robust date validation.
 */
public class ReportDAO {

    public static final TimeZone APP_TIMEZONE = TimeZone.getTimeZone("Asia/Kolkata");
    private final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");

    public ReportDAO() {
        dateFormat.setLenient(false);
        dateFormat.setTimeZone(APP_TIMEZONE);
    }

    /**
     * Checks if a non-null, non-empty date string strictly conforms to yyyy-MM-dd.
     */
    public boolean isValidDateFormat(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) return true;
        String s = dateStr.trim();
        if (!s.matches("^\\d{4}-\\d{2}-\\d{2}$")) return false;
        try {
            java.util.Date parsed = dateFormat.parse(s);
            return parsed != null;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Validates date range. Returns an error message if invalid, or null if valid.
     */
    public String validateDateRange(String startDateStr, String endDateStr) {
        boolean hasStart = startDateStr != null && !startDateStr.trim().isEmpty();
        boolean hasEnd = endDateStr != null && !endDateStr.trim().isEmpty();

        if (hasStart && !isValidDateFormat(startDateStr)) {
            return "Invalid Start Date format (" + startDateStr + "). Please use YYYY-MM-DD.";
        }
        if (hasEnd && !isValidDateFormat(endDateStr)) {
            return "Invalid End Date format (" + endDateStr + "). Please use YYYY-MM-DD.";
        }
        if (hasStart && hasEnd) {
            Timestamp startTs = parseStartDate(startDateStr);
            Timestamp endTs = parseEndDate(endDateStr);
            if (startTs != null && endTs != null && startTs.after(endTs)) {
                return "Start date cannot be after end date. Please adjust the date filter.";
            }
        }
        return null;
    }

    /**
     * Retrieves the Real-Time Occupancy Report computed strictly from physical bay statuses
     * in the MySQL slots and zones tables.
     */
    public List<OccupancyReportItem> getOccupancyReport(String zoneFilter) throws DatabaseException {
        List<OccupancyReportItem> items = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        boolean filterByZone = (zoneFilter != null && !zoneFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(zoneFilter.trim()));

        StringBuilder sql = new StringBuilder(
                "SELECT z.zone_id, z.name AS zone_name, z.location, z.total_slots, " +
                "       COUNT(s.slot_id) AS bays_count, " +
                "       SUM(CASE WHEN s.status = 'AVAILABLE' THEN 1 ELSE 0 END) AS available_count, " +
                "       SUM(CASE WHEN s.status = 'BOOKED' THEN 1 ELSE 0 END) AS occupied_count, " +
                "       SUM(CASE WHEN s.status = 'RESERVED' THEN 1 ELSE 0 END) AS reserved_count, " +
                "       SUM(CASE WHEN s.status IN ('BLOCKED', 'MAINTENANCE') THEN 1 ELSE 0 END) AS blocked_count " +
                "FROM zones z " +
                "LEFT JOIN slots s ON z.zone_id = s.zone_id "
        );

        if (filterByZone) {
            sql.append("WHERE z.zone_id = ? ");
        }

        sql.append("GROUP BY z.zone_id, z.name, z.location, z.total_slots ");
        sql.append("ORDER BY z.zone_id ASC");

        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(sql.toString());
            if (filterByZone) {
                ps.setString(1, zoneFilter.trim().toUpperCase());
            }
            rs = ps.executeQuery();

            Zone tempZone = new Zone();
            while (rs.next()) {
                String zId = rs.getString("zone_id");
                String zName = rs.getString("zone_name");
                String zLoc = rs.getString("location");
                int totalBays = rs.getInt("bays_count");
                if (totalBays == 0) {
                    totalBays = rs.getInt("total_slots");
                }
                int avail = rs.getInt("available_count");
                int occ = rs.getInt("occupied_count");
                int res = rs.getInt("reserved_count");
                int blk = rs.getInt("blocked_count");

                tempZone.setName(zName);
                tempZone.setLocation(zLoc);
                String city = tempZone.getCityName();

                OccupancyReportItem item = new OccupancyReportItem(
                        zId, zName, city, zLoc, totalBays, avail, occ, res, blk
                );
                items.add(item);
            }
            return items;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to generate Occupancy Report: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * Calculates summary metrics across an Occupancy Report dataset.
     */
    /**
     * Calculates summary metrics across an Occupancy Report dataset.
     */
    public OccupancyReportSummary buildOccupancySummary(List<OccupancyReportItem> items, String filterZoneLabel) {
        return buildOccupancySummary(items, filterZoneLabel, null, null);
    }

    /**
     * Calculates summary metrics across an Occupancy Report dataset with reporting period.
     */
    public OccupancyReportSummary buildOccupancySummary(List<OccupancyReportItem> items, String filterZoneLabel,
                                                        String startDate, String endDate) {
        int totalFac = items.size();
        int totalBays = 0;
        int availBays = 0;
        int occBays = 0;
        int resBays = 0;
        int blkBays = 0;

        for (OccupancyReportItem item : items) {
            totalBays += item.getTotalSlots();
            availBays += item.getAvailableSlots();
            occBays += item.getOccupiedSlots();
            resBays += item.getReservedSlots();
            blkBays += item.getBlockedSlots();
        }

        OccupancyReportSummary summary = new OccupancyReportSummary(
                totalFac, totalBays, availBays, occBays, resBays, blkBays,
                (filterZoneLabel != null && !filterZoneLabel.isEmpty()) ? filterZoneLabel : "All Facilities"
        );
        summary.setFilterStartDate(startDate);
        summary.setFilterEndDate(endDate);
        return summary;
    }

    /**
     * Retrieves recent historical telemetry snapshots for the Occupancy Report
     * to clearly contrast historical snapshots with real-time occupancy.
     */
    public List<Map<String, Object>> getHistoricalOccupancySnapshots(String zoneFilter, int limit) throws DatabaseException {
        return getHistoricalOccupancySnapshots(zoneFilter, null, null, limit);
    }

    /**
     * Retrieves historical telemetry snapshots filtered by zone and date range.
     */
    public List<Map<String, Object>> getHistoricalOccupancySnapshots(String zoneFilter, String startDateStr,
                                                                   String endDateStr, int limit) throws DatabaseException {
        List<Map<String, Object>> snapshots = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        boolean filterByZone = (zoneFilter != null && !zoneFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(zoneFilter.trim()));
        Timestamp startTs = parseStartDate(startDateStr);
        Timestamp endTs = parseEndDate(endDateStr);

        StringBuilder sql = new StringBuilder(
                "SELECT os.snapshot_id, os.zone_id, z.name AS zone_name, os.total_bays, " +
                "       os.occupied_bays, os.occupancy_percent, os.recorded_at " +
                "FROM occupancy_snapshots os " +
                "LEFT JOIN zones z ON os.zone_id = z.zone_id " +
                "WHERE 1=1 "
        );

        List<Object> params = new ArrayList<>();

        if (filterByZone) {
            sql.append("AND os.zone_id = ? ");
            params.add(zoneFilter.trim().toUpperCase());
        }

        if (startTs != null) {
            sql.append("AND os.recorded_at >= ? ");
            params.add(startTs);
        }

        if (endTs != null) {
            sql.append("AND os.recorded_at <= ? ");
            params.add(endTs);
        }

        sql.append("ORDER BY os.recorded_at DESC, os.snapshot_id DESC LIMIT ?");
        params.add(limit > 0 ? limit : 50);

        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                Object p = params.get(i);
                if (p instanceof Timestamp) {
                    ps.setTimestamp(i + 1, (Timestamp) p);
                } else if (p instanceof String) {
                    ps.setString(i + 1, (String) p);
                } else if (p instanceof Integer) {
                    ps.setInt(i + 1, (Integer) p);
                }
            }
            rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, Object> map = new HashMap<>();
                map.put("snapshotId", rs.getInt("snapshot_id"));
                map.put("zoneId", rs.getString("zone_id"));
                map.put("zoneName", rs.getString("zone_name"));
                map.put("totalBays", rs.getInt("total_bays"));
                map.put("occupiedBays", rs.getInt("occupied_bays"));
                map.put("occupancyPercent", rs.getDouble("occupancy_percent"));
                map.put("recordedAt", rs.getTimestamp("recorded_at"));
                snapshots.add(map);
            }
            return snapshots;
        } catch (SQLException e) {
            // If occupancy_snapshots table is empty or missing, fail gracefully
            return Collections.emptyList();
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * Generates the Booking Report with parameterized filtering by facility/zone,
     * status, and date range.
     */
    public List<BookingReportItem> getBookingReport(String zoneFilter, String startDateStr,
                                                   String endDateStr, String statusFilter) throws DatabaseException {
        List<BookingReportItem> items = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        boolean filterByZone = (zoneFilter != null && !zoneFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(zoneFilter.trim()));
        boolean filterByStatus = (statusFilter != null && !statusFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(statusFilter.trim()));

        Timestamp startTs = parseStartDate(startDateStr);
        Timestamp endTs = parseEndDate(endDateStr);

        StringBuilder sql = new StringBuilder(
                "SELECT b.booking_id, b.user_id, u.name AS user_name, u.email AS user_email, " +
                "       b.slot_id, s.zone_id, z.name AS zone_name, b.vehicle_number, " +
                "       b.duration_hours, b.total_amount, b.status, b.booking_time, " +
                "       b.entry_time, b.exit_time, b.scheduled_arrival_time, b.payment_id " +
                "FROM bookings b " +
                "JOIN slots s ON b.slot_id = s.slot_id " +
                "JOIN zones z ON s.zone_id = z.zone_id " +
                "JOIN users u ON b.user_id = u.user_id " +
                "WHERE 1=1 "
        );

        List<Object> params = new ArrayList<>();

        if (filterByZone) {
            sql.append("AND s.zone_id = ? ");
            params.add(zoneFilter.trim().toUpperCase());
        }

        if (filterByStatus) {
            sql.append("AND b.status = ? ");
            params.add(statusFilter.trim().toUpperCase());
        }

        if (startTs != null) {
            sql.append("AND b.booking_time >= ? ");
            params.add(startTs);
        }

        if (endTs != null) {
            sql.append("AND b.booking_time <= ? ");
            params.add(endTs);
        }

        sql.append("ORDER BY b.booking_time DESC, b.booking_id DESC");

        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                Object p = params.get(i);
                if (p instanceof Timestamp) {
                    ps.setTimestamp(i + 1, (Timestamp) p);
                } else if (p instanceof String) {
                    ps.setString(i + 1, (String) p);
                }
            }

            rs = ps.executeQuery();
            while (rs.next()) {
                BookingReportItem item = new BookingReportItem();
                item.setBookingId(rs.getInt("booking_id"));
                item.setUserId(rs.getString("user_id"));
                item.setUserName(rs.getString("user_name"));
                item.setUserEmail(rs.getString("user_email"));
                item.setSlotId(rs.getString("slot_id"));
                item.setZoneId(rs.getString("zone_id"));
                item.setZoneName(rs.getString("zone_name"));
                item.setVehicleNumber(rs.getString("vehicle_number"));
                item.setDurationHours(rs.getInt("duration_hours"));
                item.setTotalAmount(rs.getDouble("total_amount"));
                item.setStatus(rs.getString("status"));
                item.setBookingTime(rs.getTimestamp("booking_time"));
                item.setEntryTime(rs.getTimestamp("entry_time"));
                item.setExitTime(rs.getTimestamp("exit_time"));
                item.setScheduledArrivalTime(rs.getTimestamp("scheduled_arrival_time"));
                item.setPaymentId(rs.getString("payment_id"));
                items.add(item);
            }
            return items;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to generate Booking Report: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * Calculates summary metrics across a Booking Report dataset.
     * Flexibly accepts either (items, zone, startDate, endDate, status) or (items, zone, status, startDate, endDate).
     */
    public BookingReportSummary buildBookingSummary(List<BookingReportItem> items, String zone,
                                                   String arg3, String arg4, String arg5) {
        String status;
        String start;
        String end;

        // If arg3 is formatted as a date and arg5 is not a date, then arg3=start, arg4=end, arg5=status
        if (isValidDateFormat(arg3) && !isValidDateFormat(arg5)) {
            start = arg3;
            end = arg4;
            status = arg5;
        } else {
            // Otherwise, arg3=status, arg4=start, arg5=end
            status = arg3;
            start = arg4;
            end = arg5;
        }

        BookingReportSummary summary = new BookingReportSummary();
        summary.setTotalBookings(items.size());
        summary.setFilterZone((zone != null && !zone.isEmpty()) ? zone : "All Facilities");
        summary.setFilterStartDate(start);
        summary.setFilterEndDate(end);
        summary.setFilterStatus((status != null && !status.isEmpty()) ? status : "ALL");

        int completed = 0;
        int active = 0;
        int reserved = 0;
        int confirmed = 0;
        int cancelled = 0;
        int pending = 0;
        double totalAmt = 0.0;

        for (BookingReportItem item : items) {
            String st = item.getStatus() != null ? item.getStatus().toUpperCase() : "";
            totalAmt += item.getTotalAmount();
            switch (st) {
                case "COMPLETED":
                    completed++;
                    break;
                case "ACTIVE":
                    active++;
                    break;
                case "RESERVED":
                    reserved++;
                    break;
                case "CONFIRMED":
                    confirmed++;
                    break;
                case "CANCELLED":
                    cancelled++;
                    break;
                case "PENDING":
                case "PAYMENT_PENDING":
                    pending++;
                    break;
                default:
                    break;
            }
        }

        summary.setCompletedCount(completed);
        summary.setActiveCount(active);
        summary.setReservedCount(reserved);
        summary.setConfirmedCount(confirmed);
        summary.setCancelledCount(cancelled);
        summary.setPendingCount(pending);
        summary.setTotalAmount(totalAmt);

        return summary;
    }

    /**
     * Generates the Settled Revenue Report with parameterized filtering by facility/zone
     * and date range. Strictly queries successful transactions (p.status = 'SUCCESS').
     * Pending, unbilled, and cancelled sessions are strictly excluded.
     */
    public List<RevenueReportItem> getRevenueReport(String zoneFilter, String startDateStr,
                                                   String endDateStr) throws DatabaseException {
        List<RevenueReportItem> items = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        boolean filterByZone = (zoneFilter != null && !zoneFilter.trim().isEmpty() && !"ALL".equalsIgnoreCase(zoneFilter.trim()));

        Timestamp startTs = parseStartDate(startDateStr);
        Timestamp endTs = parseEndDate(endDateStr);

        StringBuilder sql = new StringBuilder(
                "SELECT p.payment_id, p.transaction_id, p.booking_id, p.amount, " +
                "       p.payment_method, p.status, p.payment_time, " +
                "       b.user_id, u.name AS user_name, b.slot_id, s.zone_id, " +
                "       z.name AS zone_name, z.location " +
                "FROM payments p " +
                "JOIN bookings b ON p.booking_id = b.booking_id " +
                "JOIN slots s ON b.slot_id = s.slot_id " +
                "JOIN zones z ON s.zone_id = z.zone_id " +
                "JOIN users u ON b.user_id = u.user_id " +
                "WHERE p.status = 'SUCCESS' "
        );

        List<Object> params = new ArrayList<>();

        if (filterByZone) {
            sql.append("AND s.zone_id = ? ");
            params.add(zoneFilter.trim().toUpperCase());
        }

        if (startTs != null) {
            sql.append("AND p.payment_time >= ? ");
            params.add(startTs);
        }

        if (endTs != null) {
            sql.append("AND p.payment_time <= ? ");
            params.add(endTs);
        }

        sql.append("ORDER BY p.payment_time DESC, p.payment_id DESC");

        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                Object p = params.get(i);
                if (p instanceof Timestamp) {
                    ps.setTimestamp(i + 1, (Timestamp) p);
                } else if (p instanceof String) {
                    ps.setString(i + 1, (String) p);
                }
            }

            rs = ps.executeQuery();
            Zone tempZone = new Zone();
            while (rs.next()) {
                RevenueReportItem item = new RevenueReportItem();
                item.setPaymentId(rs.getInt("payment_id"));
                item.setTransactionId(rs.getString("transaction_id"));
                item.setBookingId(rs.getInt("booking_id"));
                item.setAmount(rs.getDouble("amount"));
                item.setPaymentMethod(rs.getString("payment_method"));
                item.setStatus(rs.getString("status"));
                item.setPaymentTime(rs.getTimestamp("payment_time"));
                item.setUserId(rs.getString("user_id"));
                item.setUserName(rs.getString("user_name"));
                item.setSlotId(rs.getString("slot_id"));
                item.setZoneId(rs.getString("zone_id"));
                String zName = rs.getString("zone_name");
                String zLoc = rs.getString("location");
                item.setZoneName(zName);

                tempZone.setName(zName);
                tempZone.setLocation(zLoc);
                item.setCityName(tempZone.getCityName());

                items.add(item);
            }
            return items;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to generate Revenue Report: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * Calculates summary metrics across a Revenue Report dataset.
     */
    public RevenueReportSummary buildRevenueSummary(List<RevenueReportItem> items, String zone,
                                                    String start, String end) {
        RevenueReportSummary summary = new RevenueReportSummary();
        summary.setTransactionCount(items.size());
        summary.setFilterZone((zone != null && !zone.isEmpty()) ? zone : "All Facilities");
        summary.setFilterStartDate(start);
        summary.setFilterEndDate(end);

        double totalRev = 0.0;
        Map<String, Double> methodTotals = new LinkedHashMap<>();
        Map<String, Integer> methodCounts = new LinkedHashMap<>();
        Map<String, Double> cityTotals = new LinkedHashMap<>();

        for (RevenueReportItem item : items) {
            double amt = item.getAmount();
            totalRev += amt;

            String method = item.getPaymentMethod() != null ? item.getPaymentMethod().toUpperCase() : "OTHER";
            methodTotals.put(method, methodTotals.getOrDefault(method, 0.0) + amt);
            methodCounts.put(method, methodCounts.getOrDefault(method, 0) + 1);

            String city = item.getCityName() != null ? item.getCityName() : "Other";
            cityTotals.put(city, cityTotals.getOrDefault(city, 0.0) + amt);
        }

        summary.setTotalRevenue(totalRev);
        summary.setAverageTicket(items.size() > 0 ? totalRev / items.size() : 0.0);
        summary.setMethodBreakdown(methodTotals);
        summary.setMethodCountBreakdown(methodCounts);
        summary.setCityRevenueBreakdown(cityTotals);

        // Top payment method (defaults to N/A when no transactions exist)
        String topMethod = "N/A";
        int maxMethodCount = 0;
        for (Map.Entry<String, Integer> entry : methodCounts.entrySet()) {
            if (entry.getValue() > maxMethodCount) {
                maxMethodCount = entry.getValue();
                topMethod = entry.getKey();
            }
        }
        summary.setTopPaymentMethod(topMethod);

        return summary;
    }

    public Timestamp parseStartDate(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) return null;
        try {
            java.util.Date parsed = dateFormat.parse(dateStr.trim());
            Calendar cal = Calendar.getInstance(APP_TIMEZONE);
            cal.setTime(parsed);
            cal.set(Calendar.HOUR_OF_DAY, 0);
            cal.set(Calendar.MINUTE, 0);
            cal.set(Calendar.SECOND, 0);
            cal.set(Calendar.MILLISECOND, 0);
            return new Timestamp(cal.getTimeInMillis());
        } catch (Exception e) {
            return null;
        }
    }

    public Timestamp parseEndDate(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) return null;
        try {
            java.util.Date parsed = dateFormat.parse(dateStr.trim());
            Calendar cal = Calendar.getInstance(APP_TIMEZONE);
            cal.setTime(parsed);
            cal.set(Calendar.HOUR_OF_DAY, 23);
            cal.set(Calendar.MINUTE, 59);
            cal.set(Calendar.SECOND, 59);
            cal.set(Calendar.MILLISECOND, 999);
            return new Timestamp(cal.getTimeInMillis());
        } catch (Exception e) {
            return null;
        }
    }
}
