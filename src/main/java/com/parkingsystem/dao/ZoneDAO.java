package com.parkingsystem.dao;

import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.Zone;
import com.parkingsystem.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class ZoneDAO {

    public List<Zone> getAllZones() throws DatabaseException {
        List<Zone> zones = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT z.zone_id, z.name, z.location, z.hourly_rate, z.total_slots, z.description, " +
                    "SUM(CASE WHEN ( " +
                    "    UPPER(s.status) = 'AVAILABLE' " +
                    "    AND NOT EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND ( " +
                    "            b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') " +
                    "            OR (b.status IN ('RESERVED', 'PENDING', 'CONFIRMED') AND (b.expires_at IS NULL OR b.expires_at > NOW())) " +
                    "        ) " +
                    "    ) " +
                    ") THEN 1 ELSE 0 END) AS available_slots, " +
                    "SUM(CASE WHEN NOT ( " +
                    "    UPPER(s.status) = 'AVAILABLE' " +
                    "    AND NOT EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND ( " +
                    "            b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') " +
                    "            OR (b.status IN ('RESERVED', 'PENDING', 'CONFIRMED') AND (b.expires_at IS NULL OR b.expires_at > NOW())) " +
                    "        ) " +
                    "    ) " +
                    ") THEN 1 ELSE 0 END) AS occupied_slots " +
                    "FROM zones z " +
                    "LEFT JOIN slots s ON z.zone_id = s.zone_id " +
                    "GROUP BY z.zone_id, z.name, z.location, z.hourly_rate, z.total_slots, z.description " +
                    "ORDER BY z.zone_id ASC";

            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                Zone zone = new Zone();
                zone.setZoneId(rs.getString("zone_id"));
                zone.setName(rs.getString("name"));
                zone.setLocation(rs.getString("location"));
                zone.setHourlyRate(rs.getDouble("hourly_rate"));
                zone.setTotalSlots(rs.getInt("total_slots"));
                zone.setDescription(rs.getString("description"));
                zone.setAvailableSlots(rs.getInt("available_slots"));
                zone.setOccupiedSlots(rs.getInt("occupied_slots"));
                zones.add(zone);
            }
            return zones;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch zones: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public Zone getZoneById(String zoneId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT z.zone_id, z.name, z.location, z.hourly_rate, z.total_slots, z.description, " +
                    "SUM(CASE WHEN ( " +
                    "    UPPER(s.status) = 'AVAILABLE' " +
                    "    AND NOT EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND ( " +
                    "            b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') " +
                    "            OR (b.status IN ('RESERVED', 'PENDING', 'CONFIRMED') AND (b.expires_at IS NULL OR b.expires_at > NOW())) " +
                    "        ) " +
                    "    ) " +
                    ") THEN 1 ELSE 0 END) AS available_slots, " +
                    "SUM(CASE WHEN NOT ( " +
                    "    UPPER(s.status) = 'AVAILABLE' " +
                    "    AND NOT EXISTS ( " +
                    "        SELECT 1 FROM bookings b " +
                    "        WHERE b.slot_id = s.slot_id " +
                    "        AND ( " +
                    "            b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') " +
                    "            OR (b.status IN ('RESERVED', 'PENDING', 'CONFIRMED') AND (b.expires_at IS NULL OR b.expires_at > NOW())) " +
                    "        ) " +
                    "    ) " +
                    ") THEN 1 ELSE 0 END) AS occupied_slots " +
                    "FROM zones z " +
                    "LEFT JOIN slots s ON z.zone_id = s.zone_id " +
                    "WHERE z.zone_id = ? " +
                    "GROUP BY z.zone_id, z.name, z.location, z.hourly_rate, z.total_slots, z.description";

            ps = conn.prepareStatement(sql);
            ps.setString(1, zoneId);
            rs = ps.executeQuery();

            if (rs.next()) {
                Zone zone = new Zone();
                zone.setZoneId(rs.getString("zone_id"));
                zone.setName(rs.getString("name"));
                zone.setLocation(rs.getString("location"));
                zone.setHourlyRate(rs.getDouble("hourly_rate"));
                zone.setTotalSlots(rs.getInt("total_slots"));
                zone.setDescription(rs.getString("description"));
                zone.setAvailableSlots(rs.getInt("available_slots"));
                zone.setOccupiedSlots(rs.getInt("occupied_slots"));
                return zone;
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch zone details: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }
}
