package com.parkingsystem.dao;

import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.exception.SlotUnavailableException;
import com.parkingsystem.model.Slot;
import com.parkingsystem.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class SlotDAO {

    public List<Slot> getSlotsByZone(String zoneId) throws DatabaseException {
        List<Slot> slots = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(
                    "SELECT slot_id, zone_id, slot_number, floor, type, status FROM slots WHERE zone_id = ? ORDER BY floor ASC, slot_number ASC"
            );
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
            ps = conn.prepareStatement(
                    "SELECT slot_id, zone_id, slot_number, floor, type, status FROM slots ORDER BY zone_id ASC, floor ASC, slot_number ASC"
            );
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
            ps = conn.prepareStatement(
                    "SELECT slot_id, zone_id, slot_number, floor, type, status FROM slots WHERE slot_id = ?"
            );
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
        PreparedStatement psUpdate = null;
        ResultSet rs = null;

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

            psUpdate = conn.prepareStatement("UPDATE slots SET status = 'RESERVED' WHERE slot_id = ?");
            psUpdate.setString(1, slotId);
            return psUpdate.executeUpdate() > 0;

        } finally {
            if (rs != null) rs.close();
            if (psLock != null) psLock.close();
            if (psUpdate != null) psUpdate.close();
        }
    }

    public boolean lockAndParkSlot(Connection conn, String slotId) throws SQLException, SlotUnavailableException {
        PreparedStatement psLock = null;
        PreparedStatement psUpdate = null;
        ResultSet rs = null;

        try {
            psLock = conn.prepareStatement("SELECT status FROM slots WHERE slot_id = ? FOR UPDATE");
            psLock.setString(1, slotId);
            rs = psLock.executeQuery();

            if (!rs.next()) {
                throw new SlotUnavailableException("Slot " + slotId + " does not exist.");
            }

            String currentStatus = rs.getString("status");
            if (!"AVAILABLE".equalsIgnoreCase(currentStatus)) {
                throw new SlotUnavailableException("Slot " + slotId + " is currently " + currentStatus + " and cannot be occupied.");
            }

            psUpdate = conn.prepareStatement("UPDATE slots SET status = 'BOOKED' WHERE slot_id = ?");
            psUpdate.setString(1, slotId);
            return psUpdate.executeUpdate() > 0;

        } finally {
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
            ps = conn.prepareStatement("UPDATE slots SET status = 'AVAILABLE' WHERE slot_id = ?");
            ps.setString(1, slotId);
            return ps.executeUpdate() > 0;
        } finally {
            if (ps != null) ps.close();
        }
    }

    public boolean releaseSlotStandalone(String slotId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement("UPDATE slots SET status = 'AVAILABLE' WHERE slot_id = ?");
            ps.setString(1, slotId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to release slot " + slotId, e);
        } finally {
            DBConnection.close(conn, ps);
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
}
