package com.parkingsystem.util;

import com.parkingsystem.dao.BookingDAO;

public class ReservationCleanupService implements Runnable {

    private static volatile ReservationCleanupService instance;
    private static Thread workerThread;
    private volatile boolean running = false;
    private final BookingDAO bookingDAO = new BookingDAO();

    private ReservationCleanupService() {
    }

    public static synchronized ReservationCleanupService getInstance() {
        if (instance == null) {
            instance = new ReservationCleanupService();
        }
        return instance;
    }

    public synchronized void start() {
        if (running) return;
        running = true;
        workerThread = new Thread(this, "ReservationCleanupDaemon");
        workerThread.setDaemon(true);
        workerThread.start();
        System.out.println("[ReservationCleanupService] Background cleaner daemon started.");
    }

    public synchronized void stop() {
        if (!running) return;
        running = false;
        if (workerThread != null) {
            workerThread.interrupt();
        }
        System.out.println("[ReservationCleanupService] Background cleaner daemon stopped.");
    }

    public boolean isRunning() {
        return running;
    }

    public int triggerCheck() {
        try {
            return bookingDAO.cancelExpiredReservations(15);
        } catch (Exception e) {
            System.err.println("[ReservationCleanupService Error] " + e.getMessage());
            return 0;
        }
    }

    @Override
    public void run() {
        while (running) {
            try {
                Thread.sleep(15000L); // Check every 15 seconds
                if (!running) break;
                triggerCheck();
            } catch (InterruptedException e) {
                break;
            } catch (Exception e) {
                System.err.println("[ReservationCleanupService Loop] " + e.getMessage());
            }
        }
    }
}