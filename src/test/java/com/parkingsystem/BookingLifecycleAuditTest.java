package com.parkingsystem;

import com.parkingsystem.dao.BookingDAO;
import com.parkingsystem.dao.SlotDAO;
import com.parkingsystem.dao.UserDAO;
import com.parkingsystem.exception.BookingException;
import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.exception.SlotUnavailableException;
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

/**
 * End-to-End Automated Verification of the Complete SmartParking Booking
 * and Parking-Session Lifecycle.
 *
 * Required Test Journey:
 * reserve -> wait without check-in -> verify timer has not started ->
 * ANPR check-in -> verify timer starts -> attempt another booking for the occupied bay ->
 * verify rejection -> checkout -> verify correct billing and bay release.
 */
public class BookingLifecycleAuditTest {

    private static final BookingDAO bookingDAO = new BookingDAO();
    private static final SlotDAO slotDAO = new SlotDAO();
    private static final UserDAO userDAO = new UserDAO();

    private static int passedTests = 0;
    private static int failedTests = 0;

    public static void main(String[] args) {
        System.out.println("==================================================================");
        System.out.println("  RUNNING SMARTPARKING BOOKING & PARKING-SESSION LIFECYCLE AUDIT  ");
        System.out.println("==================================================================");

        String testSlot = "B12";
        String driver1Id = "TST_DRV1";
        String driver2Id = "TST_DRV2";
        String plate1 = "KA05LC9991";
        String plate2 = "KA05LC9992";

        try {
            // Setup prerequisite test accounts
            ensureTestUser(driver1Id, "Lifecycle Driver 1", "driver1@lifecycle.local", "9123456781");
            ensureTestUser(driver2Id, "Lifecycle Driver 2", "driver2@lifecycle.local", "9123456782");

            // Clean state for test slot
            cleanupSlot(testSlot);

            System.out.println("\n--- STEP 1: RESERVE AN AVAILABLE BAY IN ADVANCE ---");
            Slot initialSlot = slotDAO.getSlotById(testSlot);
            assertCondition("Step 1.1: Initial bay status is AVAILABLE", "AVAILABLE".equalsIgnoreCase(initialSlot.getStatus()));

            Booking resBooking = new Booking();
            resBooking.setUserId(driver1Id);
            resBooking.setSlotId(testSlot);
            resBooking.setZoneId("B");
            resBooking.setVehicleNumber(plate1);
            resBooking.setHourlyRate(40.0);
            resBooking.setDurationHours(2);
            resBooking.setScheduledArrivalTime(new Timestamp(System.currentTimeMillis() + 600000L)); // +10 min
            int bookingId = bookingDAO.createScheduledReservation(resBooking);
            assertCondition("Step 1.2: Advance reservation created successfully (#" + bookingId + ")", bookingId > 0);

            Slot reservedSlot = slotDAO.getSlotById(testSlot);
            assertCondition("Step 1.3: Bay status updated to RESERVED", "RESERVED".equalsIgnoreCase(reservedSlot.getStatus()));

            Booking fetchedRes = bookingDAO.getBookingById(bookingId);
            assertCondition("Step 1.4: Booking status is RESERVED", "RESERVED".equalsIgnoreCase(fetchedRes.getStatus()));
            assertCondition("Step 1.5: Reservation booking_time is stamped", fetchedRes.getBookingTime() != null);
            assertCondition("Step 1.6: Actual entry_time is strictly NULL before arrival", fetchedRes.getEntryTime() == null);
            assertCondition("Step 1.7: Parking timer has not started (elapsed seconds = 0)", fetchedRes.getElapsedSeconds() == 0L);

            System.out.println("\n--- STEP 2: WAIT WITHOUT CHECK-IN ---");
            System.out.println("  Simulating driver in transit before arrival...");
            Thread.sleep(1200);

            Booking awaitedRes = bookingDAO.getBookingById(bookingId);
            assertCondition("Step 2.1: After waiting, entry_time remains NULL", awaitedRes.getEntryTime() == null);
            assertCondition("Step 2.2: After waiting, timer remains NOT started (elapsed = 0)", awaitedRes.getElapsedSeconds() == 0L);
            Slot awaitedSlot = slotDAO.getSlotById(testSlot);
            assertCondition("Step 2.3: Bay remains locked as RESERVED for driver", "RESERVED".equalsIgnoreCase(awaitedSlot.getStatus()));

            System.out.println("\n--- STEP 3: ANPR SCAN & CHECK-IN ---");
            Booking checkedIn = bookingDAO.checkInWithNumberPlate(plate1, testSlot, driver1Id);
            assertCondition("Step 3.1: ANPR plate matched and check-in succeeded", checkedIn != null);
            assertCondition("Step 3.2: Booking status transitioned to ACTIVE", "ACTIVE".equalsIgnoreCase(checkedIn.getStatus()));
            assertCondition("Step 3.3: Actual entry_time is now recorded", checkedIn.getEntryTime() != null);

            Slot occupiedSlot = slotDAO.getSlotById(testSlot);
            assertCondition("Step 3.4: Bay status transitioned to OCCUPIED", "OCCUPIED".equalsIgnoreCase(occupiedSlot.getStatus()) || "BOOKED".equalsIgnoreCase(occupiedSlot.getStatus()));

            // Verify live timer is now active
            long elapsedAfterCheckin = checkedIn.getElapsedSeconds();
            assertCondition("Step 3.5: Parking timer is now running (entry_time present, elapsed >= 0)", checkedIn.getEntryTime() != null && elapsedAfterCheckin >= 0L);

            System.out.println("\n--- STEP 4: BAY OCCUPANCY LOCK ---");
            // Simulate reservation cleanup pass - active sessions must NEVER be cancelled or released
            bookingDAO.cancelExpiredReservations(0);
            Slot persistentSlot = slotDAO.getSlotById(testSlot);
            assertCondition("Step 4.1: Bay remains OCCUPIED while parked (not cancelled by expiry cleaner)", "OCCUPIED".equalsIgnoreCase(persistentSlot.getStatus()) || "BOOKED".equalsIgnoreCase(persistentSlot.getStatus()));

            System.out.println("\n--- STEP 5: PREVENT ANOTHER DRIVER FROM RESERVING OCCUPIED BAY ---");
            boolean secondReservationBlocked = false;
            String rejectionReason = "";
            try {
                Booking driver2Booking = new Booking();
                driver2Booking.setUserId(driver2Id);
                driver2Booking.setSlotId(testSlot);
                driver2Booking.setZoneId("B");
                driver2Booking.setVehicleNumber(plate2);
                driver2Booking.setHourlyRate(40.0);
                driver2Booking.setScheduledArrivalTime(new Timestamp(System.currentTimeMillis() + 600000L));
                bookingDAO.createScheduledReservation(driver2Booking);
            } catch (SlotUnavailableException | DatabaseException e) {
                secondReservationBlocked = true;
                rejectionReason = e.getMessage();
            }

            assertCondition("Step 5.1: Second driver booking attempt on occupied bay REJECTED (" + rejectionReason + ")", secondReservationBlocked);
            Slot slotStillOccupied = slotDAO.getSlotById(testSlot);
            assertCondition("Step 5.2: Bay remains exclusively OCCUPIED by driver 1", "OCCUPIED".equalsIgnoreCase(slotStillOccupied.getStatus()) || "BOOKED".equalsIgnoreCase(slotStillOccupied.getStatus()));

            System.out.println("\n--- STEP 6: VEHICLE DEPARTS & CHECKOUT ---");
            Booking endedSession = bookingDAO.endParkingSession(bookingId, 40.0);
            assertCondition("Step 6.1: Parking session ended, status = PAYMENT_PENDING", "PAYMENT_PENDING".equalsIgnoreCase(endedSession.getStatus()));
            assertCondition("Step 6.2: Actual exit_time recorded", endedSession.getExitTime() != null);
            assertCondition("Step 6.3: Parking charge calculated using billing rules (min 1hr tariff: Rs " + endedSession.getTotalAmount() + ")", endedSession.getTotalAmount() >= 40.0);

            // Finalize payment
            Payment payment = new Payment();
            payment.setBookingId(bookingId);
            payment.setAmount(endedSession.getTotalAmount());
            payment.setPaymentMethod("UPI");
            payment.setTransactionId("TXN_LIFECYCLE_" + System.currentTimeMillis());
            payment.setStatus("SUCCESS");

            boolean paymentFinalized = bookingDAO.finalizeExitPayment(bookingId, payment);
            assertCondition("Step 6.4: Payment transaction processed and finalized", paymentFinalized);

            Booking completedBooking = bookingDAO.getBookingById(bookingId);
            assertCondition("Step 6.5: Booking status updated to COMPLETED", "COMPLETED".equalsIgnoreCase(completedBooking.getStatus()));

            System.out.println("\n--- STEP 7: BAY RELEASE VERIFICATION ---");
            Slot releasedSlot = slotDAO.getSlotById(testSlot);
            assertCondition("Step 7.1: Bay released back to AVAILABLE only after departure & payment", "AVAILABLE".equalsIgnoreCase(releasedSlot.getStatus()));

            // Now driver 2 can reserve the freed bay
            Booking driver2SuccessBooking = new Booking();
            driver2SuccessBooking.setUserId(driver2Id);
            driver2SuccessBooking.setSlotId(testSlot);
            driver2SuccessBooking.setZoneId("B");
            driver2SuccessBooking.setVehicleNumber(plate2);
            driver2SuccessBooking.setHourlyRate(40.0);
            driver2SuccessBooking.setScheduledArrivalTime(new Timestamp(System.currentTimeMillis() + 600000L));
            int driver2BookingId = bookingDAO.createScheduledReservation(driver2SuccessBooking);
            assertCondition("Step 7.2: Newly freed bay can now be reserved by driver 2 (#" + driver2BookingId + ")", driver2BookingId > 0);

            // Clean up driver 2 booking
            bookingDAO.cancelReservationByUser(driver2BookingId, driver2Id);
            Slot cleanedSlot = slotDAO.getSlotById(testSlot);
            assertCondition("Step 7.3: Test bay restored to AVAILABLE", "AVAILABLE".equalsIgnoreCase(cleanedSlot.getStatus()));

            System.out.println("\n--- STEP 8: TIMESTAMP & DURATION DISTINCTION ---");
            Booking auditBooking = bookingDAO.getBookingById(bookingId);
            assertCondition("Step 8.1: Reservation time exists", auditBooking.getBookingTime() != null);
            assertCondition("Step 8.2: Actual check-in time exists", auditBooking.getEntryTime() != null);
            assertCondition("Step 8.3: Actual checkout time exists", auditBooking.getExitTime() != null);
            assertCondition("Step 8.4: Chronological integrity: booking_time <= entry_time", !auditBooking.getBookingTime().after(auditBooking.getEntryTime()));
            assertCondition("Step 8.5: Chronological integrity: entry_time <= exit_time", !auditBooking.getEntryTime().after(auditBooking.getExitTime()));

            // Verify Gate Activity Log
            List<GateActivityEvent> gateEvents = bookingDAO.getRecentGateActivity(10);
            boolean foundEntry = false;
            boolean foundExit = false;
            for (GateActivityEvent evt : gateEvents) {
                if (evt.getBookingId() == bookingId) {
                    if (evt.isEntry()) foundEntry = true;
                    if (evt.isExit()) foundExit = true;
                }
            }
            assertCondition("Step 8.6: Gate Activity ledger contains ENTRY event for booking", foundEntry);
            assertCondition("Step 8.7: Gate Activity ledger contains EXIT event with duration for booking", foundExit);

        } catch (Exception e) {
            System.err.println("[UNEXPECTED EXCEPTION] " + e.getMessage());
            e.printStackTrace();
            failedTests++;
        } finally {
            cleanupSlot(testSlot);
        }

        System.out.println("------------------------------------------------------------------");
        System.out.printf("LIFECYCLE RESULTS: %d / %d Tests Passed (%s)\n",
                passedTests, (passedTests + failedTests),
                failedTests == 0 ? "100%" : (100 * passedTests / (passedTests + failedTests)) + "%");
        System.out.println("------------------------------------------------------------------");

        if (failedTests > 0) {
            System.exit(1);
        }
    }

    private static void assertCondition(String testName, boolean condition) {
        if (condition) {
            System.out.println("  [PASS] " + testName);
            passedTests++;
        } else {
            System.err.println("  [FAIL] " + testName);
            failedTests++;
        }
    }

    private static void ensureTestUser(String userId, String name, String email, String phone) throws DatabaseException {
        User u = userDAO.findById(userId);
        if (u == null) {
            User newUser = new User();
            newUser.setUserId(userId);
            newUser.setName(name);
            newUser.setEmail(email);
            newUser.setPhoneNumber(phone);
            newUser.setPassword("Pass1234!");
            newUser.setRole("USER");
            userDAO.register(newUser);
        }
    }

    private static void cleanupSlot(String slotId) {
        try (Connection conn = DBConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM payments WHERE transaction_id LIKE 'TXN_LIFECYCLE_%' OR transaction_id LIKE 'TXN_AUDIT_%' OR transaction_id LIKE 'TXN_RACE_%'")) {
                ps.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement("UPDATE bookings SET status = 'CANCELLED' WHERE slot_id = ? AND status IN ('RESERVED', 'ACTIVE', 'CONFIRMED', 'PAYMENT_PENDING')")) {
                ps.setString(1, slotId);
                ps.executeUpdate();
            }
            slotDAO.overrideSlotStatus(slotId, "AVAILABLE");
        } catch (Exception ignored) {}
    }
}
