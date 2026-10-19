package com.parkingsystem;

import com.parkingsystem.dao.BookingDAO;
import com.parkingsystem.dao.SlotDAO;
import com.parkingsystem.dao.UserDAO;
import com.parkingsystem.exception.BookingException;
import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.Booking;
import com.parkingsystem.model.GateActivityEvent;
import com.parkingsystem.model.Payment;
import com.parkingsystem.model.Slot;
import com.parkingsystem.model.User;
import com.parkingsystem.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Automated ANPR & Gate Access Workflow Verification Suite.
 * Covers:
 * 1. Valid plate + valid booking -> Entry authorized, bay OCCUPIED, timer started.
 * 2. Unknown plate -> Entry rejected, clear error, bay untouched, logged in ledger.
 * 3. Cancelled booking -> Entry rejected, clear error, bay untouched, logged in ledger.
 * 4. Expired booking -> Entry rejected, auto-released, logged in ledger.
 * 5. Wrong plate for booking -> Entry rejected, rightful booking preserved, logged in ledger.
 * 6. Wrong bay for vehicle -> Entry rejected, logged in ledger.
 * 7. Repeated scan on active session -> Duplicate entry blocked, logged in ledger.
 * 8. Checkout workflow -> Exit recorded, charge calculated, payment finalized, bay released.
 * 9. Gate Activity Ledger -> Verifies ENTRY, EXIT, and REJECTED events.
 * 10. Concurrency & locking -> Prevents race conditions and duplicate check-ins.
 */
public class ANPRGateWorkflowTest {

    private static final BookingDAO bookingDAO = new BookingDAO();
    private static final SlotDAO slotDAO = new SlotDAO();
    private static final UserDAO userDAO = new UserDAO();

    private static int totalPassed = 0;
    private static int totalFailed = 0;

    public static void main(String[] args) {
        System.out.println("==================================================");
        System.out.println("  RUNNING ANPR & GATE ACCESS WORKFLOW TEST SUITE  ");
        System.out.println("==================================================");

        try {
            ensureTestDriver();

            testScenario1_ValidPlateCheckIn();
            testScenario2_UnknownPlateRejected();
            testScenario3_CancelledBookingRejected();
            testScenario4_ExpiredBookingRejected();
            testScenario5_WrongPlateRejected();
            testScenario6_WrongBayRejected();
            testScenario7_RepeatedScanDuplicateBlocked();
            testScenario8_CheckoutAndBayRelease();
            testScenario9_GateActivityLedgerAuditing();
            testScenario10_ConcurrencyProtection();

        } catch (Exception e) {
            System.err.println("[SUITE ERROR] " + e.getMessage());
            e.printStackTrace();
            totalFailed++;
        } finally {
            cleanupSlot("B4");
            cleanupSlot("B5");
            cleanupSlot("B6");
            cleanupSlot("B7");
            cleanupSlot("B8");
            cleanupSlot("B9");
            cleanupSlot("B10");
        }

        System.out.println("--------------------------------------------------");
        System.out.printf("RESULTS: %d / %d Tests Passed (%s)\n",
                totalPassed, (totalPassed + totalFailed),
                totalFailed == 0 ? "100%" : (100 * totalPassed / (totalPassed + totalFailed)) + "%");
        System.out.println("--------------------------------------------------");

        if (totalFailed > 0) {
            System.exit(1);
        }
    }

    private static void pass(String testName) {
        System.out.println("  [PASS] " + testName);
        totalPassed++;
    }

    private static void fail(String testName, String reason) {
        System.err.println("  [FAIL] " + testName + " - " + reason);
        totalFailed++;
    }

    private static void ensureTestDriver() throws DatabaseException {
        User u = userDAO.findById("TST_DRV");
        if (u == null) {
            User newDriver = new User();
            newDriver.setUserId("TST_DRV");
            newDriver.setName("ANPR Audit Driver");
            newDriver.setEmail("anpr_driver@test.local");
            newDriver.setPhoneNumber("9988776655");
            newDriver.setPassword("DriverPass123!");
            newDriver.setRole("USER");
            userDAO.register(newDriver);
        }
    }

    private static void cleanupSlot(String slotId) {
        try (Connection conn = DBConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM payments WHERE transaction_id LIKE 'TXN_AUDIT_%' OR transaction_id LIKE 'TXN_RACE_%' OR transaction_id LIKE 'TXN_LIFECYCLE_%'")) {
                ps.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement("UPDATE bookings SET status = 'CANCELLED' WHERE slot_id = ? AND status IN ('RESERVED', 'ACTIVE', 'CONFIRMED', 'PAYMENT_PENDING')")) {
                ps.setString(1, slotId);
                ps.executeUpdate();
            }
            slotDAO.overrideSlotStatus(slotId, "AVAILABLE");
        } catch (Exception ignored) {}
    }

    /**
     * Scenario 1: Valid plate with a valid booking -> Entry authorized
     */
    private static void testScenario1_ValidPlateCheckIn() {
        String slotId = "B4";
        cleanupSlot(slotId);

        try {
            // Reserve bay B4
            Booking b = new Booking();
            b.setUserId("TST_DRV");
            b.setSlotId(slotId);
            b.setZoneId("B");
            b.setVehicleNumber("KA04OK1111");
            b.setHourlyRate(40.0);
            b.setScheduledArrivalTime(new Timestamp(System.currentTimeMillis() + 600000L));
            int bookingId = bookingDAO.createScheduledReservation(b);

            // Slot should be RESERVED
            Slot slotBefore = slotDAO.getSlotById(slotId);
            if (!"RESERVED".equalsIgnoreCase(slotBefore.getStatus())) {
                fail("Scenario 1: Slot RESERVED before scan", "Slot status was: " + slotBefore.getStatus());
                return;
            } else {
                pass("Scenario 1: Pre-scan slot locked as RESERVED");
            }

            // Perform ANPR check-in
            Booking checkedIn = bookingDAO.checkInWithNumberPlate("KA04OK1111", slotId, "TST_DRV");
            if (checkedIn != null && checkedIn.isActive() && checkedIn.getEntryTime() != null) {
                pass("Scenario 1: Entry authorized, status ACTIVE, entry_time recorded");
            } else {
                fail("Scenario 1: Entry authorization", "Check-in failed or missing entry_time");
            }

            Slot slotAfter = slotDAO.getSlotById(slotId);
            if ("OCCUPIED".equalsIgnoreCase(slotAfter.getStatus()) || "BOOKED".equalsIgnoreCase(slotAfter.getStatus())) {
                pass("Scenario 1: Bay status updated to OCCUPIED");
            } else {
                fail("Scenario 1: Bay OCCUPIED update", "Slot status was: " + slotAfter.getStatus());
            }

        } catch (Exception e) {
            fail("Scenario 1: Valid plate check-in exception", e.getMessage());
        }
    }

    /**
     * Scenario 2: Unknown plate -> Entry rejected
     */
    private static void testScenario2_UnknownPlateRejected() {
        String slotId = "B5";
        cleanupSlot(slotId);

        try {
            boolean rejected = false;
            String errorMsg = "";
            try {
                bookingDAO.checkInWithNumberPlate("DL99UNKNOWN", slotId, "TST_DRV");
            } catch (BookingException be) {
                rejected = true;
                errorMsg = be.getMessage();
            }

            if (rejected && errorMsg.contains("Unknown number plate")) {
                pass("Scenario 2: Unknown plate rejected with clear error: " + errorMsg);
            } else {
                fail("Scenario 2: Unknown plate rejection", "Did not reject or error mismatch: " + errorMsg);
            }

            Slot slot = slotDAO.getSlotById(slotId);
            if ("AVAILABLE".equalsIgnoreCase(slot.getStatus())) {
                pass("Scenario 2: Bay remains untouched as AVAILABLE");
            } else {
                fail("Scenario 2: Bay protection", "Slot status changed to: " + slot.getStatus());
            }

        } catch (Exception e) {
            fail("Scenario 2: Unknown plate test exception", e.getMessage());
        }
    }

    /**
     * Scenario 3: Cancelled booking -> Entry rejected
     */
    private static void testScenario3_CancelledBookingRejected() {
        String slotId = "B5";
        cleanupSlot(slotId);

        try {
            Booking b = new Booking();
            b.setUserId("TST_DRV");
            b.setSlotId(slotId);
            b.setZoneId("B");
            b.setVehicleNumber("KA04CANC99");
            b.setHourlyRate(40.0);
            b.setScheduledArrivalTime(new Timestamp(System.currentTimeMillis() + 600000L));
            int bookingId = bookingDAO.createScheduledReservation(b);

            // Cancel the booking
            bookingDAO.cancelReservationByUser(bookingId, "TST_DRV");

            boolean rejected = false;
            String errorMsg = "";
            try {
                bookingDAO.checkInWithNumberPlate("KA04CANC99", slotId, "TST_DRV");
            } catch (BookingException be) {
                rejected = true;
                errorMsg = be.getMessage();
            }

            if (rejected && errorMsg.toLowerCase().contains("cancelled")) {
                pass("Scenario 3: Cancelled booking rejected: " + errorMsg);
            } else {
                fail("Scenario 3: Cancelled booking rejection", "Did not reject or error mismatch: " + errorMsg);
            }

            Slot slot = slotDAO.getSlotById(slotId);
            if ("AVAILABLE".equalsIgnoreCase(slot.getStatus())) {
                pass("Scenario 3: Bay remains AVAILABLE after rejected scan");
            } else {
                fail("Scenario 3: Bay status after cancelled scan", "Status was: " + slot.getStatus());
            }

        } catch (Exception e) {
            fail("Scenario 3: Cancelled booking exception", e.getMessage());
        }
    }

    /**
     * Scenario 4: Expired booking -> Entry rejected
     */
    private static void testScenario4_ExpiredBookingRejected() {
        String slotId = "B6";
        cleanupSlot(slotId);

        try {
            Booking b = new Booking();
            b.setUserId("TST_DRV");
            b.setSlotId(slotId);
            b.setZoneId("B");
            b.setVehicleNumber("KA04EXP88");
            b.setHourlyRate(40.0);
            // Arrival time was 45 minutes ago
            Timestamp pastArrival = new Timestamp(System.currentTimeMillis() - 45 * 60 * 1000L);
            b.setScheduledArrivalTime(pastArrival);
            int bookingId = bookingDAO.createScheduledReservation(b);

            // Force expires_at in the past
            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement("UPDATE bookings SET expires_at = ? WHERE booking_id = ?")) {
                ps.setTimestamp(1, new Timestamp(System.currentTimeMillis() - 30 * 60 * 1000L));
                ps.setInt(2, bookingId);
                ps.executeUpdate();
            }

            boolean rejected = false;
            String errorMsg = "";
            try {
                bookingDAO.checkInWithNumberPlate("KA04EXP88", slotId, "TST_DRV");
            } catch (BookingException be) {
                rejected = true;
                errorMsg = be.getMessage();
            }

            if (rejected && (errorMsg.toLowerCase().contains("expired") || errorMsg.toLowerCase().contains("cancelled"))) {
                pass("Scenario 4: Expired arrival window rejected: " + errorMsg);
            } else {
                fail("Scenario 4: Expired arrival window", "Did not reject or error mismatch: " + errorMsg);
            }

            Slot slot = slotDAO.getSlotById(slotId);
            if ("AVAILABLE".equalsIgnoreCase(slot.getStatus())) {
                pass("Scenario 4: Bay released to AVAILABLE upon expired scan");
            } else {
                fail("Scenario 4: Expired bay release", "Status was: " + slot.getStatus());
            }

        } catch (Exception e) {
            fail("Scenario 4: Expired booking exception", e.getMessage());
        }
    }

    /**
     * Scenario 5: Wrong plate for a booking -> Entry rejected
     */
    private static void testScenario5_WrongPlateRejected() {
        String slotId = "B7";
        cleanupSlot(slotId);

        try {
            Booking b = new Booking();
            b.setUserId("TST_DRV");
            b.setSlotId(slotId);
            b.setZoneId("B");
            b.setVehicleNumber("KA04RIGHT01");
            b.setHourlyRate(40.0);
            b.setScheduledArrivalTime(new Timestamp(System.currentTimeMillis() + 600000L));
            int bookingId = bookingDAO.createScheduledReservation(b);

            // An intruder plate arrives at Bay B7
            boolean rejected = false;
            String errorMsg = "";
            try {
                bookingDAO.checkInWithNumberPlate("MH12WRONG02", slotId, null);
            } catch (BookingException be) {
                rejected = true;
                errorMsg = be.getMessage();
            }

            if (rejected && errorMsg.contains("does not match reserved vehicle")) {
                pass("Scenario 5: Wrong plate rejected: " + errorMsg);
            } else {
                fail("Scenario 5: Wrong plate rejection", "Did not reject or error mismatch: " + errorMsg);
            }

            // Rightful reservation must remain intact
            Slot slot = slotDAO.getSlotById(slotId);
            if ("RESERVED".equalsIgnoreCase(slot.getStatus())) {
                pass("Scenario 5: Bay remains RESERVED for the rightful booking");
            } else {
                fail("Scenario 5: Rightful bay reservation preservation", "Status was: " + slot.getStatus());
            }

            // Clean up reservation
            bookingDAO.cancelReservationByUser(bookingId, "TST_DRV");

        } catch (Exception e) {
            fail("Scenario 5: Wrong plate test exception", e.getMessage());
        }
    }

    /**
     * Scenario 6: Wrong bay for vehicle -> Entry rejected
     */
    private static void testScenario6_WrongBayRejected() {
        String slotId1 = "B8";
        String slotId2 = "B9";
        cleanupSlot(slotId1);
        cleanupSlot(slotId2);

        try {
            Booking b = new Booking();
            b.setUserId("TST_DRV");
            b.setSlotId(slotId1);
            b.setZoneId("B");
            b.setVehicleNumber("KA04CORRECT77");
            b.setHourlyRate(40.0);
            b.setScheduledArrivalTime(new Timestamp(System.currentTimeMillis() + 600000L));
            int bookingId = bookingDAO.createScheduledReservation(b);

            // Driver attempts check-in at slotId2 instead of slotId1
            boolean rejected = false;
            String errorMsg = "";
            try {
                bookingDAO.checkInWithNumberPlate("KA04CORRECT77", slotId2, null);
            } catch (BookingException be) {
                rejected = true;
                errorMsg = be.getMessage();
            }

            if (rejected && (errorMsg.contains("is reserved for Bay [B8]") || errorMsg.contains("not Bay [B9]"))) {
                pass("Scenario 6: Wrong bay scan rejected with target redirect: " + errorMsg);
            } else {
                fail("Scenario 6: Wrong bay rejection", "Did not reject or error mismatch: " + errorMsg);
            }

            // Clean up
            bookingDAO.cancelReservationByUser(bookingId, "TST_DRV");

        } catch (Exception e) {
            fail("Scenario 6: Wrong bay test exception", e.getMessage());
        }
    }

    /**
     * Scenario 7: Repeated scan after entry -> Duplicate entry blocked
     */
    private static void testScenario7_RepeatedScanDuplicateBlocked() {
        // Vehicle from Scenario 1 is actively parked in B4
        String slotId = "B4";
        String plate = "KA04OK1111";

        try {
            boolean rejected = false;
            String errorMsg = "";
            try {
                bookingDAO.checkInWithNumberPlate(plate, slotId, "TST_DRV");
            } catch (BookingException be) {
                rejected = true;
                errorMsg = be.getMessage();
            }

            if (rejected && (errorMsg.contains("Duplicate entry attempt") || errorMsg.contains("already checked in"))) {
                pass("Scenario 7: Repeated scan blocked: " + errorMsg);
            } else {
                fail("Scenario 7: Duplicate check-in guard", "Did not reject or message mismatch: " + errorMsg);
            }

        } catch (Exception e) {
            fail("Scenario 7: Repeated scan exception", e.getMessage());
        }
    }

    /**
     * Scenario 8: Checkout workflow -> Exit recorded, charge calculated, payment finalized, bay released
     */
    private static void testScenario8_CheckoutAndBayRelease() {
        String slotId = "B4";
        String plate = "KA04OK1111";

        try {
            Booking active = bookingDAO.getActiveBookingForSlot(slotId);
            if (active == null) {
                fail("Scenario 8: Pre-condition active session", "No active session in B4");
                return;
            }

            int bookingId = active.getBookingId();

            // 1. End parking session
            Booking ended = bookingDAO.endParkingSession(bookingId, 40.0);
            if (ended != null && "PAYMENT_PENDING".equalsIgnoreCase(ended.getStatus()) && ended.getExitTime() != null) {
                pass("Scenario 8: Parking session ended, exit_time stamped, status PAYMENT_PENDING");
            } else {
                fail("Scenario 8: End session", "Failed to end session or status was: " + (ended != null ? ended.getStatus() : "null"));
            }

            if (ended.getTotalAmount() >= 40.0) {
                pass("Scenario 8: Dynamic charge calculated successfully: Rs " + ended.getTotalAmount());
            } else {
                fail("Scenario 8: Bill calculation", "Amount too low: " + ended.getTotalAmount());
            }

            // 2. Finalize payment
            Payment payment = new Payment();
            payment.setBookingId(bookingId);
            payment.setAmount(ended.getTotalAmount());
            payment.setPaymentMethod("UPI");
            payment.setTransactionId("TXN_AUDIT_" + System.currentTimeMillis());
            payment.setStatus("SUCCESS");

            boolean finalized = bookingDAO.finalizeExitPayment(bookingId, payment);
            if (finalized) {
                pass("Scenario 8: Payment finalized with transaction ref: " + payment.getTransactionId());
            } else {
                fail("Scenario 8: Finalize payment", "finalizeExitPayment returned false");
            }

            Booking completed = bookingDAO.getBookingById(bookingId);
            if ("COMPLETED".equalsIgnoreCase(completed.getStatus())) {
                pass("Scenario 8: Booking status updated to COMPLETED");
            } else {
                fail("Scenario 8: Booking COMPLETED check", "Status: " + completed.getStatus());
            }

            Slot slot = slotDAO.getSlotById(slotId);
            if ("AVAILABLE".equalsIgnoreCase(slot.getStatus())) {
                pass("Scenario 8: Bay B4 released back to AVAILABLE in sensor network");
            } else {
                fail("Scenario 8: Bay release check", "Slot status: " + slot.getStatus());
            }

        } catch (Exception e) {
            fail("Scenario 8: Checkout workflow exception", e.getMessage());
        }
    }

    /**
     * Scenario 9: Gate Activity Ledger auditing
     */
    private static void testScenario9_GateActivityLedgerAuditing() {
        try {
            List<GateActivityEvent> events = bookingDAO.getRecentGateActivity(30);
            if (events == null || events.isEmpty()) {
                fail("Scenario 9: Ledger non-empty", "Gate activity ledger was empty");
                return;
            } else {
                pass("Scenario 9: Gate activity ledger populated (" + events.size() + " events retrieved)");
            }

            boolean hasEntry = false;
            boolean hasExit = false;
            boolean hasRejected = false;

            for (GateActivityEvent evt : events) {
                if (evt.isEntry()) hasEntry = true;
                if (evt.isExit()) hasExit = true;
                if (evt.isRejected()) hasRejected = true;
            }

            if (hasEntry) {
                pass("Scenario 9: Ledger records ENTRY movements (Admitted & Bay Occupied)");
            } else {
                fail("Scenario 9: Entry event audit", "Missing ENTRY movement in ledger");
            }

            if (hasExit) {
                pass("Scenario 9: Ledger records EXIT movements (Departed • Bill Paid)");
            } else {
                fail("Scenario 9: Exit event audit", "Missing EXIT movement in ledger");
            }

            if (hasRejected) {
                pass("Scenario 9: Ledger records REJECTED movements (Access Denied)");
            } else {
                fail("Scenario 9: Rejected event audit", "Missing REJECTED movement in ledger");
            }

        } catch (Exception e) {
            fail("Scenario 9: Ledger auditing exception", e.getMessage());
        }
    }

    /**
     * Scenario 10: Concurrency & race condition protection
     */
    private static void testScenario10_ConcurrencyProtection() {
        String slotId = "B10";
        cleanupSlot(slotId);

        try {
            Booking b = new Booking();
            b.setUserId("TST_DRV");
            b.setSlotId(slotId);
            b.setZoneId("B");
            b.setVehicleNumber("KA04RACE55");
            b.setHourlyRate(40.0);
            b.setScheduledArrivalTime(new Timestamp(System.currentTimeMillis() + 600000L));
            int bookingId = bookingDAO.createScheduledReservation(b);

            int threadCount = 2;
            CountDownLatch readyLatch = new CountDownLatch(threadCount);
            CountDownLatch startLatch = new CountDownLatch(1);
            CountDownLatch doneLatch = new CountDownLatch(threadCount);

            AtomicInteger successCount = new AtomicInteger(0);
            AtomicInteger rejectCount = new AtomicInteger(0);

            for (int i = 0; i < threadCount; i++) {
                new Thread(() -> {
                    readyLatch.countDown();
                    try {
                        startLatch.await();
                        Booking checkedIn = bookingDAO.checkInWithNumberPlate("KA04RACE55", slotId, "TST_DRV");
                        if (checkedIn != null && checkedIn.isActive()) {
                            successCount.incrementAndGet();
                        }
                    } catch (BookingException expected) {
                        rejectCount.incrementAndGet();
                    } catch (Exception ignored) {
                    } finally {
                        doneLatch.countDown();
                    }
                }).start();
            }

            readyLatch.await();
            startLatch.countDown();
            doneLatch.await();

            if (successCount.get() == 1 && rejectCount.get() == 1) {
                pass("Scenario 10: Concurrency safety verified: Exactly 1 check-in succeeded, 1 duplicate attempt safely rejected");
            } else {
                fail("Scenario 10: Race condition guard", "Success count: " + successCount.get() + ", Reject count: " + rejectCount.get());
            }

            // Cleanup
            bookingDAO.endParkingSession(bookingId, 40.0);
            Payment p = new Payment();
            p.setBookingId(bookingId);
            p.setAmount(40.0);
            p.setPaymentMethod("UPI");
            p.setTransactionId("TXN_RACE_" + System.currentTimeMillis());
            bookingDAO.finalizeExitPayment(bookingId, p);

        } catch (Exception e) {
            fail("Scenario 10: Concurrency test exception", e.getMessage());
        }
    }
}
