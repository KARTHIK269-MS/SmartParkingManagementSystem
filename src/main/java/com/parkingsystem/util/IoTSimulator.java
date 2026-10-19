package com.parkingsystem.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class IoTSimulator implements Runnable {

    private static volatile IoTSimulator instance;
    private static Thread workerThread;

    private volatile boolean running = false;
    private volatile int intervalSeconds = 10;
    private final Random random = new Random();
    private String lastEventMessage = "Simulator initialized. Ready.";

    private IoTSimulator() {
    }

    public static synchronized IoTSimulator getInstance() {
        if (instance == null) {
            instance = new IoTSimulator();
        }
        return instance;
    }

    public synchronized void start() {
        if (running) return;
        running = true;
        workerThread = new Thread(this, "IoTSensorSimulatorThread");
        workerThread.setDaemon(true);
        workerThread.start();
        lastEventMessage = "IoT Sensor Simulation started (Interval: " + intervalSeconds + "s)";
        System.out.println("[IoT Simulator] Started background thread.");
    }

    public synchronized void stop() {
        if (!running) return;
        running = false;
        if (workerThread != null) {
            workerThread.interrupt();
        }
        lastEventMessage = "IoT Sensor Simulation paused.";
        System.out.println("[IoT Simulator] Stopped background thread.");
    }

    public boolean isRunning() {
        return running;
    }

    public int getIntervalSeconds() {
        return intervalSeconds;
    }

    public void setIntervalSeconds(int intervalSeconds) {
        this.intervalSeconds = Math.max(3, intervalSeconds);
    }

    public String getLastEventMessage() {
        return lastEventMessage;
    }

    @Override
    public void run() {
        while (running) {
            try {
                Thread.sleep(intervalSeconds * 1000L);
                if (!running) break;
                triggerSimulationStep();
            } catch (InterruptedException e) {
                // Thread stopped or awakened
                break;
            } catch (Exception e) {
                System.err.println("[IoT Simulator Error] " + e.getMessage());
            }
        }
    }

    /**
     * Executes a transaction-safe simulated vehicle sensor event.
     * Guarantees that active driver reservations or bookings are never overwritten.
     */
    public synchronized boolean triggerSimulationStep() {
        Connection conn = null;
        PreparedStatement psFind = null;
        PreparedStatement psLock = null;
        PreparedStatement psCheck = null;
        PreparedStatement psUpdate = null;
        ResultSet rsFind = null;
        ResultSet rsLock = null;
        ResultSet rsCheck = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false); // Transactional isolation

            // 1. Find all candidate slots that are unblocked
            psFind = conn.prepareStatement("SELECT slot_id, status FROM slots WHERE status IN ('AVAILABLE', 'BOOKED') ORDER BY RAND() LIMIT 1");
            rsFind = psFind.executeQuery();

            if (!rsFind.next()) {
                conn.rollback();
                return false;
            }

            String candidateSlotId = rsFind.getString("slot_id");
            String currentStatus = rsFind.getString("status");

            // 2. Lock candidate slot record using SELECT FOR UPDATE
            psLock = conn.prepareStatement("SELECT status FROM slots WHERE slot_id = ? FOR UPDATE");
            psLock.setString(1, candidateSlotId);
            rsLock = psLock.executeQuery();

            if (!rsLock.next()) {
                conn.rollback();
                return false;
            }

            // 3. Concurrency Safety Check: Is there an active driver booking or pending reservation?
            psCheck = conn.prepareStatement("SELECT COUNT(*) FROM bookings WHERE slot_id = ? AND status IN ('PENDING', 'CONFIRMED', 'RESERVED', 'ACTIVE', 'OCCUPIED', 'PAYMENT_PENDING')");
            psCheck.setString(1, candidateSlotId);
            rsCheck = psCheck.executeQuery();

            int activeBookings = 0;
            if (rsCheck.next()) {
                activeBookings = rsCheck.getInt(1);
            }

            // If an active user booking exists, do NOT alter this slot!
            if (activeBookings > 0) {
                conn.rollback();
                lastEventMessage = "Sensor checked bay " + candidateSlotId + " [Driver Reservation Active - Protected]";
                return false;
            }

            // 4. Safely toggle between AVAILABLE and BOOKED to simulate transient drive-in vehicle
            String newStatus = "AVAILABLE".equalsIgnoreCase(currentStatus) ? "BOOKED" : "AVAILABLE";

            psUpdate = conn.prepareStatement("UPDATE slots SET status = ? WHERE slot_id = ?");
            psUpdate.setString(1, newStatus);
            psUpdate.setString(2, candidateSlotId);
            psUpdate.executeUpdate();

            conn.commit();

            if ("BOOKED".equalsIgnoreCase(newStatus)) {
                lastEventMessage = "Sensor detected vehicle arrival at Bay " + candidateSlotId + " -> Marked BOOKED";
            } else {
                lastEventMessage = "Sensor detected vehicle departure at Bay " + candidateSlotId + " -> Restored AVAILABLE";
            }
            System.out.println("[IoT Simulator] " + lastEventMessage);
            return true;

        } catch (SQLException e) {
            DBConnection.rollback(conn);
            System.err.println("[IoT Simulator] Transaction rollback due to: " + e.getMessage());
            return false;
        } finally {
            DBConnection.close(null, psFind, rsFind);
            DBConnection.close(null, psLock, rsLock);
            DBConnection.close(null, psCheck, rsCheck);
            DBConnection.close(null, psUpdate, null);
            DBConnection.close(conn, null, null);
        }
    }
}
