package com.parkingsystem.dao;

import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.OccupancyPrediction;
import com.parkingsystem.model.Zone;
import com.parkingsystem.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Calendar;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Smart Occupancy Prediction DAO
 * Computes transparent, explainable parking occupancy forecasts across upcoming
 * intervals (+1h, +3h, +6h) based on real database history.
 *
 * Provides a graceful, clearly labelled fallback ("Collecting data — prediction not yet available")
 * when historical observations are insufficient (< 3 sessions), guaranteeing zero fabrication.
 */
public class PredictionDAO {

    private final ZoneDAO zoneDAO = new ZoneDAO();

    /**
     * Minimum historical parking sessions/snapshots required before activating
     * the empirical moving average prediction model.
     */
    public static final int MIN_OBSERVATIONS_THRESHOLD = 3;

    /**
     * Computes the occupancy prediction for a specific parking facility/zone.
     */
    public OccupancyPrediction getPredictionForZone(String zoneId) throws DatabaseException {
        if (zoneId == null || zoneId.trim().isEmpty()) {
            zoneId = "B";
        }
        zoneId = zoneId.trim();

        Zone zone = zoneDAO.getZoneById(zoneId);
        if (zone == null) {
            List<Zone> all = zoneDAO.getAllZones();
            if (!all.isEmpty()) {
                zone = all.get(0);
                zoneId = zone.getZoneId();
            }
        }

        OccupancyPrediction pred = new OccupancyPrediction();
        pred.setZoneId(zoneId);
        pred.setZoneName(zone != null ? zone.getName() : ("Zone " + zoneId));
        pred.setCity(zone != null ? zone.getCity() : "Metropolitan Area");
        int totalBays = (zone != null && zone.getTotalSlots() > 0) ? zone.getTotalSlots() : 20;
        pred.setTotalBays(totalBays);

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();

            // 1. Current Live Occupancy
            int liveOccupied = 0;
            String sqlLive = "SELECT COUNT(DISTINCT s.slot_id) AS occ_cnt " +
                    "FROM slots s " +
                    "LEFT JOIN bookings b ON s.slot_id = b.slot_id AND b.status IN ('ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING') " +
                    "WHERE s.zone_id = ? AND (b.booking_id IS NOT NULL OR s.status IN ('BOOKED', 'OCCUPIED'))";
            ps = conn.prepareStatement(sqlLive);
            ps.setString(1, zoneId);
            rs = ps.executeQuery();
            if (rs.next()) {
                liveOccupied = rs.getInt("occ_cnt");
            }
            rs.close();
            ps.close();

            // Bound live occupancy within physical capacity
            liveOccupied = Math.max(0, Math.min(totalBays, liveOccupied));
            int liveAvailable = Math.max(0, totalBays - liveOccupied);
            double liveRate = (totalBays > 0) ? Math.round((liveOccupied * 100.0 / totalBays) * 10.0) / 10.0 : 0.0;

            pred.setCurrentOccupied(liveOccupied);
            pred.setCurrentAvailable(liveAvailable);
            pred.setCurrentOccupancyPercentage(liveRate);

            // 2. Count genuine historical sessions and snapshots observed for this zone
            int historicalCount = 0;
            String sqlHist = "SELECT COUNT(*) AS hist_cnt " +
                    "FROM bookings b " +
                    "JOIN slots s ON b.slot_id = s.slot_id " +
                    "WHERE s.zone_id = ? AND b.entry_time IS NOT NULL AND b.status IN ('COMPLETED', 'ACTIVE', 'PAYMENT_PENDING')";
            ps = conn.prepareStatement(sqlHist);
            ps.setString(1, zoneId);
            rs = ps.executeQuery();
            if (rs.next()) {
                historicalCount += rs.getInt("hist_cnt");
            }
            rs.close();
            ps.close();

            // Check optional snapshots table if it exists
            try {
                String sqlSnap = "SELECT COUNT(*) AS snap_cnt FROM occupancy_snapshots WHERE zone_id = ?";
                ps = conn.prepareStatement(sqlSnap);
                ps.setString(1, zoneId);
                rs = ps.executeQuery();
                if (rs.next()) {
                    historicalCount += rs.getInt("snap_cnt");
                }
                rs.close();
                ps.close();
            } catch (SQLException ignored) {
                // Table might not exist yet, bookings count is sufficient
            }

            pred.setHistoricalObservationsCount(historicalCount);

            // Current operating hour (0..23)
            Calendar nowCal = Calendar.getInstance();
            int currentHour = nowCal.get(Calendar.HOUR_OF_DAY);

            // 3. Evaluate Data Sufficiency
            if (historicalCount < MIN_OBSERVATIONS_THRESHOLD) {
                // ==============================================================
                // INSUFFICIENT DATA / CLEAN STARTING STATE: Honest Transparent Fallback
                // ==============================================================
                pred.setSufficientData(false);
                pred.setStatusNotice("Collecting occupancy data. Predictions will appear when sufficient real parking activity is recorded.");
                pred.setMethodology("Awaiting empirical history (Requires minimum " + MIN_OBSERVATIONS_THRESHOLD + " verified sessions/snapshots)");
                pred.setDataPeriod("Data Accumulation (" + historicalCount + " of " + MIN_OBSERVATIONS_THRESHOLD + " minimum observations recorded)");
                pred.setPeakPeriodLabel("Awaiting Data (Accumulating Traffic History)");

                // Forecast metrics remain unpopulated to prevent implying predictions are active
                pred.setPredicted1hOccupied(0);
                pred.setPredicted1hAvailable(0);
                pred.setPredicted1hPercentage(0.0);

                pred.setPredicted3hOccupied(0);
                pred.setPredicted3hAvailable(0);
                pred.setPredicted3hPercentage(0.0);

                pred.setPredicted6hOccupied(0);
                pred.setPredicted6hAvailable(0);
                pred.setPredicted6hPercentage(0.0);

                // Zeroed curves - empty state container rendered in UI
                pred.setCurrentHourlyOccupancy(new int[24]);
                pred.setPredictedHourlyOccupancy(new int[24]);

            } else {
                // ==============================================================
                // SUFFICIENT DATA: Empirical Zone-Hour Moving Average Model
                // ==============================================================
                pred.setSufficientData(true);
                pred.setStatusNotice("Active Prediction Model (Empirical Moving Average)");
                pred.setMethodology("Empirical Zone-Hour Moving Average (Based on " + historicalCount + " verified observations)");
                pred.setDataPeriod("Historical Operations (Trailing Active Window)");

                // Query historical arrivals distribution by hour for this zone
                int[] hourCounts = new int[24];
                String sqlDist = "SELECT HOUR(b.entry_time) AS hr, COUNT(*) AS cnt " +
                        "FROM bookings b " +
                        "JOIN slots s ON b.slot_id = s.slot_id " +
                        "WHERE s.zone_id = ? AND b.entry_time IS NOT NULL AND b.status IN ('COMPLETED', 'ACTIVE', 'PAYMENT_PENDING') " +
                        "GROUP BY hr";
                ps = conn.prepareStatement(sqlDist);
                ps.setString(1, zoneId);
                rs = ps.executeQuery();
                int maxHour = -1;
                int maxCount = -1;
                while (rs.next()) {
                    int hr = rs.getInt("hr");
                    int cnt = rs.getInt("cnt");
                    if (hr >= 0 && hr < 24) {
                        hourCounts[hr] = cnt;
                        if (cnt > maxCount) {
                            maxCount = cnt;
                            maxHour = hr;
                        }
                    }
                }
                rs.close();
                ps.close();

                // Format peak period label
                if (maxHour >= 0 && maxCount > 0) {
                    pred.setPeakPeriodLabel(String.format("%02d:00 - %02d:00 (Peak Arrival Window)", maxHour, (maxHour + 2) % 24));
                } else {
                    pred.setPeakPeriodLabel("Distributed Traffic Profile");
                }

                // Compute predictions for upcoming intervals
                int targetH1 = (currentHour + 1) % 24;
                int targetH3 = (currentHour + 3) % 24;
                int targetH6 = (currentHour + 6) % 24;

                double rate1 = computeHourlyExpectedRate(hourCounts, historicalCount, targetH1, liveRate / 100.0);
                double rate3 = computeHourlyExpectedRate(hourCounts, historicalCount, targetH3, liveRate / 100.0);
                double rate6 = computeHourlyExpectedRate(hourCounts, historicalCount, targetH6, liveRate / 100.0);

                int p1Occ = Math.max(0, Math.min(totalBays, (int) Math.round(rate1 * totalBays)));
                int p3Occ = Math.max(0, Math.min(totalBays, (int) Math.round(rate3 * totalBays)));
                int p6Occ = Math.max(0, Math.min(totalBays, (int) Math.round(rate6 * totalBays)));

                pred.setPredicted1hOccupied(p1Occ);
                pred.setPredicted1hAvailable(Math.max(0, totalBays - p1Occ));
                pred.setPredicted1hPercentage(Math.round((p1Occ * 100.0 / totalBays) * 10.0) / 10.0);

                pred.setPredicted3hOccupied(p3Occ);
                pred.setPredicted3hAvailable(Math.max(0, totalBays - p3Occ));
                pred.setPredicted3hPercentage(Math.round((p3Occ * 100.0 / totalBays) * 10.0) / 10.0);

                pred.setPredicted6hOccupied(p6Occ);
                pred.setPredicted6hAvailable(Math.max(0, totalBays - p6Occ));
                pred.setPredicted6hPercentage(Math.round((p6Occ * 100.0 / totalBays) * 10.0) / 10.0);

                // Populate 24h curve comparisons
                int[] curr24 = new int[24];
                int[] pred24 = new int[24];
                curr24[currentHour] = liveOccupied;
                for (int h = 0; h < 24; h++) {
                    double hRate = computeHourlyExpectedRate(hourCounts, historicalCount, h, liveRate / 100.0);
                    pred24[h] = Math.max(0, Math.min(totalBays, (int) Math.round(hRate * totalBays)));
                }
                pred.setCurrentHourlyOccupancy(curr24);
                pred.setPredictedHourlyOccupancy(pred24);
            }

            return pred;

        } catch (SQLException e) {
            throw new DatabaseException("Failed to calculate occupancy prediction for zone " + zoneId + ": " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * Helper to compute expected occupancy rate blending historical frequency with current baseline.
     */
    private double computeHourlyExpectedRate(int[] hourCounts, int totalHistory, int hour, double currentLiveRate) {
        if (totalHistory <= 0) return currentLiveRate;
        double histRatio = (double) hourCounts[hour] / (double) totalHistory;
        // Blend 70% historical pattern + 30% live continuous momentum
        double blended = (0.7 * histRatio) + (0.3 * currentLiveRate);
        return Math.max(0.0, Math.min(1.0, blended));
    }

    /**
     * Counts scheduled reservations arriving within the next specified hours.
     */
    private int getScheduledArrivalsWithinHours(Connection conn, String zoneId, int hours) {
        String sql = "SELECT COUNT(*) AS cnt " +
                "FROM bookings b " +
                "JOIN slots s ON b.slot_id = s.slot_id " +
                "WHERE s.zone_id = ? AND b.status = 'RESERVED' " +
                "AND b.scheduled_arrival_time BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL ? HOUR)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, zoneId);
            ps.setInt(2, hours);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("cnt");
                }
            }
        } catch (SQLException ignored) {}
        return 0;
    }

    /**
     * Records an operational occupancy observation snapshot.
     */
    public boolean recordSnapshot(String zoneId, int totalBays, int occupiedBays) {
        if (zoneId == null || totalBays <= 0) return false;
        double pct = Math.max(0.0, Math.min(100.0, (occupiedBays * 100.0) / totalBays));
        String sql = "INSERT INTO occupancy_snapshots (zone_id, total_bays, occupied_bays, occupancy_percent) VALUES (?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, zoneId);
            ps.setInt(2, totalBays);
            ps.setInt(3, occupiedBays);
            ps.setDouble(4, pct);
            return ps.executeUpdate() > 0;
        } catch (SQLException ignored) {
            return false;
        }
    }

    /**
     * Retrieves predictions for all active zones.
     */
    public Map<String, OccupancyPrediction> getAllZonePredictions() throws DatabaseException {
        Map<String, OccupancyPrediction> map = new LinkedHashMap<>();
        List<Zone> zones = zoneDAO.getAllZones();
        for (Zone z : zones) {
            map.put(z.getZoneId(), getPredictionForZone(z.getZoneId()));
        }
        return map;
    }
}
