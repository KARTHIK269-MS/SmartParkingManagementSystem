package com.parkingsystem.dao;

import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.exception.SlotUnavailableException;
import com.parkingsystem.model.Slot;
import com.parkingsystem.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class SlotDAO {

    public int syncSlotStatuses() throws DatabaseException {
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            return syncSlotStatuses(conn);
        } catch (SQLException e) {
            throw new DatabaseException("Failed to synchronize slot statuses with bookings: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, null, null);
        }
    }

    public int syncSlotStatuses(Connection conn) throws SQLException {
        int updated = 0;
        try (Statement st = conn.createStatement()) {
            // 1. Mark slots with active vehicle sessions as OCCUPIED
            updated += st.executeUpdate(
                "UPDATE slots s SET s.status = 'OCCUPIED' " +
                "WHERE UPPER(s.status) NOT IN ('MAINTENANCE', 'BLOCKED') " +
                "AND EXISTS (SELECT 1 FROM bookings b WHERE b.slot_id = s.slot_id AND b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING'))"
            );
            // 2. Mark slots with CONFIRMED bookings as BOOKED
            updated += st.executeUpdate(
                "UPDATE slots s SET s.status = 'BOOKED' " +
                "WHERE UPPER(s.status) NOT IN ('MAINTENANCE', 'BLOCKED') " +
                "AND NOT EXISTS (SELECT 1 FROM bookings b WHERE b.slot_id = s.slot_id AND b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING')) " +
                "AND EXISTS (SELECT 1 FROM bookings b WHERE b.slot_id = s.slot_id AND b.status = 'CONFIRMED')"
            );
            // 3. Mark slots with active unexpired reservations as RESERVED
            updated += st.executeUpdate(
                "UPDATE slots s SET s.status = 'RESERVED' " +
                "WHERE UPPER(s.status) NOT IN ('MAINTENANCE', 'BLOCKED') " +
                "AND NOT EXISTS (SELECT 1 FROM bookings b WHERE b.slot_id = s.slot_id AND b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING', 'CONFIRMED')) " +
                "AND EXISTS (SELECT 1 FROM bookings b WHERE b.slot_id = s.slot_id AND b.status IN ('RESERVED', 'PENDING') AND (b.expires_at IS NULL OR b.expires_at > NOW()))"
            );
            // 4. Mark slots without active sessions or reservations as AVAILABLE
            updated += st.executeUpdate(
                "UPDATE slots s SET s.status = 'AVAILABLE' " +
                "WHERE UPPER(s.status) NOT IN ('MAINTENANCE', 'BLOCKED') " +
                "AND NOT EXISTS (SELECT 1 FROM bookings b WHERE b.slot_id = s.slot_id AND (" +
                "   b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING', 'CONFIRMED') OR " +
                "   (b.status IN ('RESERVED', 'PENDING') AND (b.expires_at IS NULL OR b.expires_at > NOW()))" +
                "))"
            );
        }
        return updated;
    }

    public List<Slot> getSlotsByZone(String zoneId) throws DatabaseException {
        List<Slot> slots = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT s.slot_id, s.zone_id, s.slot_number, s.floor, s.type, " +
                    "CASE " +
                    "    WHEN UPPER(s.status) IN ('MAINTENANCE', 'BLOCKED') THEN s.status " +
                    "    WHEN EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') " +
                    "    ) THEN 'OCCUPIED' " +
                    "    WHEN EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND b.status = 'CONFIRMED' " +
                    "    ) THEN 'BOOKED' " +
                    "    WHEN EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND b.status IN ('RESERVED', 'PENDING') " +
                    "        AND (b.expires_at IS NULL OR b.expires_at > NOW()) " +
                    "    ) THEN 'RESERVED' " +
                    "    ELSE s.status " +
                    "END AS status " +
                    "FROM slots s WHERE s.zone_id = ? ORDER BY s.floor ASC, s.slot_number ASC";
            ps = conn.prepareStatement(sql);
            ps.setString(1, zoneId);
            rs = ps.executeQuery();

            while (rs.next()) {
                Slot slot = new Slot();
                slot.setSlotId(rs.getString("slot_id"));
                slot.setZoneId(rs.getString("zone_id"));
                slot.setSlotNumber(rs.getInt("slot_number"));
                slot.setFloor(rs.getInt("floor"));
                slot.setType(rs.getString("type"));
                slot.setStatus(rs.getString("status"));
                slots.add(slot);
            }
            return slots;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch slots for zone " + zoneId, e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public List<Slot> getAllSlots() throws DatabaseException {
        List<Slot> slots = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT s.slot_id, s.zone_id, s.slot_number, s.floor, s.type, " +
                    "CASE " +
                    "    WHEN UPPER(s.status) IN ('MAINTENANCE', 'BLOCKED') THEN s.status " +
                    "    WHEN EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') " +
                    "    ) THEN 'OCCUPIED' " +
                    "    WHEN EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND b.status = 'CONFIRMED' " +
                    "    ) THEN 'BOOKED' " +
                    "    WHEN EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND b.status IN ('RESERVED', 'PENDING') " +
                    "        AND (b.expires_at IS NULL OR b.expires_at > NOW()) " +
                    "    ) THEN 'RESERVED' " +
                    "    ELSE s.status " +
                    "END AS status " +
                    "FROM slots s ORDER BY s.zone_id ASC, s.floor ASC, s.slot_number ASC";
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                Slot slot = new Slot();
                slot.setSlotId(rs.getString("slot_id"));
                slot.setZoneId(rs.getString("zone_id"));
                slot.setSlotNumber(rs.getInt("slot_number"));
                slot.setFloor(rs.getInt("floor"));
                slot.setType(rs.getString("type"));
                slot.setStatus(rs.getString("status"));
                slots.add(slot);
            }
            return slots;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch all slots", e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public Slot getSlotById(String slotId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT s.slot_id, s.zone_id, s.slot_number, s.floor, s.type, " +
                    "CASE " +
                    "    WHEN UPPER(s.status) IN ('MAINTENANCE', 'BLOCKED') THEN s.status " +
                    "    WHEN EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') " +
                    "    ) THEN 'OCCUPIED' " +
                    "    WHEN EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND b.status = 'CONFIRMED' " +
                    "    ) THEN 'BOOKED' " +
                    "    WHEN EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND b.status IN ('RESERVED', 'PENDING') " +
                    "        AND (b.expires_at IS NULL OR b.expires_at > NOW()) " +
                    "    ) THEN 'RESERVED' " +
                    "    ELSE s.status " +
                    "END AS status " +
                    "FROM slots s WHERE s.slot_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, slotId);
            rs = ps.executeQuery();

            if (rs.next()) {
                Slot slot = new Slot();
                slot.setSlotId(rs.getString("slot_id"));
                slot.setZoneId(rs.getString("zone_id"));
                slot.setSlotNumber(rs.getInt("slot_number"));
                slot.setFloor(rs.getInt("floor"));
                slot.setType(rs.getString("type"));
                slot.setStatus(rs.getString("status"));
                return slot;
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch slot by ID: " + slotId, e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * Transactional Lock & Reserve
     * Acquires exclusive row lock and verifies slot is AVAILABLE before setting to RESERVED.
     */
    public boolean lockAndReserveSlot(Connection conn, String slotId) throws SQLException, SlotUnavailableException {
        PreparedStatement psLock = null;
        PreparedStatement psCheck = null;
        PreparedStatement psUpdate = null;
        ResultSet rs = null;
        ResultSet rsCheck = null;

        try {
            psLock = conn.prepareStatement("SELECT status FROM slots WHERE slot_id = ? FOR UPDATE");
            psLock.setString(1, slotId);
            rs = psLock.executeQuery();

            if (!rs.next()) {
                throw new SlotUnavailableException("Slot " + slotId + " does not exist.");
            }

            String currentStatus = rs.getString("status");
            if (!"AVAILABLE".equalsIgnoreCase(currentStatus)) {
                throw new SlotUnavailableException("Slot " + slotId + " is currently " + currentStatus + " and cannot be reserved.");
            }

            // Concurrency guard: verify no active or unexpired reservation exists in bookings
            psCheck = conn.prepareStatement(
                    "SELECT COUNT(*) FROM bookings WHERE slot_id = ? AND (" +
                    "status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') OR " +
                    "(status IN ('RESERVED', 'PENDING', 'CONFIRMED') AND (expires_at IS NULL OR expires_at > NOW()))) FOR UPDATE"
            );
            psCheck.setString(1, slotId);
            rsCheck = psCheck.executeQuery();
            if (rsCheck.next() && rsCheck.getInt(1) > 0) {
                throw new SlotUnavailableException("Slot " + slotId + " already has an active reservation or parking session.");
            }

            psUpdate = conn.prepareStatement("UPDATE slots SET status = 'RESERVED' WHERE slot_id = ?");
            psUpdate.setString(1, slotId);
            return psUpdate.executeUpdate() > 0;

        } finally {
            if (rsCheck != null) rsCheck.close();
            if (psCheck != null) psCheck.close();
            if (rs != null) rs.close();
            if (psLock != null) psLock.close();
            if (psUpdate != null) psUpdate.close();
        }
    }

    public boolean lockAndParkSlot(Connection conn, String slotId) throws SQLException, SlotUnavailableException {
        PreparedStatement psLock = null;
        PreparedStatement psCheck = null;
        PreparedStatement psUpdate = null;
        ResultSet rs = null;
        ResultSet rsCheck = null;

        try {
            psLock = conn.prepareStatement("SELECT status FROM slots WHERE slot_id = ? FOR UPDATE");
            psLock.setString(1, slotId);
            rs = psLock.executeQuery();

            if (!rs.next()) {
                throw new SlotUnavailableException("Slot " + slotId + " does not exist.");
            }

            String currentStatus = rs.getString("status");
            if (!"AVAILABLE".equalsIgnoreCase(currentStatus) && !"RESERVED".equalsIgnoreCase(currentStatus)) {
                throw new SlotUnavailableException("Slot " + slotId + " is currently " + currentStatus + " and cannot be occupied.");
            }

            // Concurrency guard: verify no vehicle is already actively parked in this bay
            psCheck = conn.prepareStatement(
                    "SELECT COUNT(*) FROM bookings WHERE slot_id = ? AND status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') FOR UPDATE"
            );
            psCheck.setString(1, slotId);
            rsCheck = psCheck.executeQuery();
            if (rsCheck.next() && rsCheck.getInt(1) > 0) {
                throw new SlotUnavailableException("Slot " + slotId + " is already occupied by an active parking session.");
            }

            psUpdate = conn.prepareStatement("UPDATE slots SET status = 'OCCUPIED' WHERE slot_id = ?");
            psUpdate.setString(1, slotId);
            return psUpdate.executeUpdate() > 0;

        } finally {
            if (rsCheck != null) rsCheck.close();
            if (psCheck != null) psCheck.close();
            if (rs != null) rs.close();
            if (psLock != null) psLock.close();
            if (psUpdate != null) psUpdate.close();
        }
    }

    public boolean confirmSlot(Connection conn, String slotId) throws SQLException {
        PreparedStatement ps = null;
        try {
            ps = conn.prepareStatement("UPDATE slots SET status = 'BOOKED' WHERE slot_id = ?");
            ps.setString(1, slotId);
            return ps.executeUpdate() > 0;
        } finally {
            if (ps != null) ps.close();
        }
    }

    public boolean releaseSlot(Connection conn, String slotId) throws SQLException {
        PreparedStatement ps = null;
        try {
            String sql = "UPDATE slots SET status = CASE " +
                    "  WHEN UPPER(status) IN ('MAINTENANCE', 'BLOCKED') THEN status " +
                    "  WHEN EXISTS (SELECT 1 FROM bookings WHERE slot_id = ? AND status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING')) THEN 'OCCUPIED' " +
                    "  WHEN EXISTS (SELECT 1 FROM bookings WHERE slot_id = ? AND status IN ('RESERVED', 'PENDING', 'CONFIRMED') AND (expires_at IS NULL OR expires_at > NOW())) THEN 'RESERVED' " +
                    "  ELSE 'AVAILABLE' " +
                    "END WHERE slot_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, slotId);
            ps.setString(2, slotId);
            ps.setString(3, slotId);
            return ps.executeUpdate() > 0;
        } finally {
            if (ps != null) ps.close();
        }
    }

    public boolean releaseSlotStandalone(String slotId) throws DatabaseException {
        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            return releaseSlot(conn, slotId);
        } catch (SQLException e) {
            throw new DatabaseException("Failed to release slot " + slotId, e);
        } finally {
            DBConnection.close(conn, null, null);
        }
    }

    public boolean overrideSlotStatus(String slotId, String newStatus) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement("UPDATE slots SET status = ? WHERE slot_id = ?");
            ps.setString(1, newStatus.toUpperCase());
            ps.setString(2, slotId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to override slot status: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps);
        }
    }

    /**
     * Safely overrides a parking bay status with pessimistic concurrency locking.
     * Prevents making a bay AVAILABLE or BLOCKED if an active user reservation
     * or occupied vehicle is currently assigned to it.
     */
    public boolean safeOverrideSlotStatus(String slotId, String newStatus) throws DatabaseException, com.parkingsystem.exception.BookingException {
        if (slotId == null || newStatus == null) return false;
        String normalizedStatus = newStatus.trim().toUpperCase();

        Connection conn = null;
        PreparedStatement psLock = null;
        PreparedStatement psCheck = null;
        PreparedStatement psUpdate = null;
        ResultSet rsLock = null;
        ResultSet rsCheck = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            // 1. Pessimistic row lock on slot
            psLock = conn.prepareStatement("SELECT status FROM slots WHERE slot_id = ? FOR UPDATE");
            psLock.setString(1, slotId);
            rsLock = psLock.executeQuery();
            if (!rsLock.next()) {
                throw new com.parkingsystem.exception.BookingException("Slot " + slotId + " does not exist.");
            }

            // 2. Prevent setting AVAILABLE or BLOCKED if an active booking / occupied vehicle exists
            if ("AVAILABLE".equalsIgnoreCase(normalizedStatus) || "BLOCKED".equalsIgnoreCase(normalizedStatus)) {
                String checkSql = "SELECT COUNT(*) FROM bookings WHERE slot_id = ? AND (" +
                        "status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') OR " +
                        "(status IN ('PENDING', 'CONFIRMED', 'RESERVED') AND (expires_at IS NULL OR expires_at > NOW()))) FOR UPDATE";
                psCheck = conn.prepareStatement(checkSql);
                psCheck.setString(1, slotId);
                rsCheck = psCheck.executeQuery();
                if (rsCheck.next() && rsCheck.getInt(1) > 0) {
                    conn.rollback();
                    throw new com.parkingsystem.exception.BookingException("Cannot set " + slotId + " to " + normalizedStatus + ": An active booking or parked vehicle currently occupies this bay.");
                }
            }

            // 3. Perform update
            psUpdate = conn.prepareStatement("UPDATE slots SET status = ? WHERE slot_id = ?");
            psUpdate.setString(1, normalizedStatus);
            psUpdate.setString(2, slotId);
            boolean updated = psUpdate.executeUpdate() > 0;

            conn.commit();
            return updated;

        } catch (SQLException e) {
            DBConnection.rollback(conn);
            throw new DatabaseException("Failed to safely override slot status: " + e.getMessage(), e);
        } catch (com.parkingsystem.exception.BookingException be) {
            DBConnection.rollback(conn);
            throw be;
        } finally {
            DBConnection.close(null, psCheck, rsCheck);
            DBConnection.close(null, psLock, rsLock);
            DBConnection.close(null, psUpdate, null);
            DBConnection.close(conn, null, null);
        }
    }
}

