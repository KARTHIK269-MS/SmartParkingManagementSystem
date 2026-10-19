package com.parkingsystem;

import com.parkingsystem.dao.BookingDAO;
import com.parkingsystem.dao.NotificationDAO;
import com.parkingsystem.dao.SlotDAO;
import com.parkingsystem.dao.UserDAO;
import com.parkingsystem.exception.SlotUnavailableException;
import com.parkingsystem.model.Booking;
import com.parkingsystem.model.Notification;
import com.parkingsystem.model.Slot;
import com.parkingsystem.model.User;
import com.parkingsystem.util.PasswordHasher;

import java.util.List;
import java.util.Map;

/**
 * Realistic College Mini-Project Unit Test Suite
 * Tests core project modules:
 * 1. User registration & BCrypt password hashing
 * 2. Login authentication & credential verification
 * 3. Slot reservation & grace period calculation
 * 4. Double-booking concurrency prevention
 * 5. Booking cancellation & slot release
 * 6. User ownership & data isolation checks
 * 7. Active booking protection against overrides
 */
public class MiniProjectUnitTest {

    private static int testsPassed = 0;
    private static int testsFailed = 0;

    public static void main(String[] args) {
        System.out.println("==================================================");
        System.out.println(" Smart Parking System - Mini-Project Unit Tests  ");
        System.out.println("==================================================");

        setupTestUser();
        try {
            runTest("1. User Registration with BCrypt Hashing", MiniProjectUnitTest::testUserRegistrationWithBCrypt);
            runTest("2. Login Authentication & Invalid Credentials", MiniProjectUnitTest::testLoginAuthentication);
            runTest("3. Slot Reservation & 15-Minute Grace Period", MiniProjectUnitTest::testSlotReservationAndGracePeriod);
            runTest("4. Concurrency: Double-Booking Prevention", MiniProjectUnitTest::testDoubleBookingPrevention);
            runTest("5. Booking Cancellation & Bay Release", MiniProjectUnitTest::testBookingCancellationAndSlotRelease);
            runTest("6. Ownership Check & Cross-User Data Isolation", MiniProjectUnitTest::testOwnershipChecks);
            runTest("7. Active Booking Protection Against Overwrite", MiniProjectUnitTest::testActiveBookingProtection);
            runTest("8. Safe Admin Bay Override & Active Occupancy Protection", MiniProjectUnitTest::testSafeAdminOverrideProtection);
            runTest("9. Active Booking Lookup & Authorized Vehicle Inspection", MiniProjectUnitTest::testActiveBookingLookupForInspector);
            runTest("10. HyperPark Lifecycle, Gate Activity & Revenue Audit", MiniProjectUnitTest::testHyperParkLifecycleAndRevenueAudit);
            runTest("11. Check-In & Checkout Validation and Repeated Actions", MiniProjectUnitTest::testInvalidCheckInAndCheckoutEdgeCases);
            runTest("12. Payment & Cancellation Validation and Repeated Actions", MiniProjectUnitTest::testInvalidPaymentAndCancellationEdgeCases);
            runTest("13. Step-by-Step State Consistency & Revenue Isolation Audit", MiniProjectUnitTest::testStepByStepConsistencyAndRevenueExclusions);
        } finally {
            teardownTestUser();
        }

        System.out.println("==================================================");
        System.out.println(" Test Results Summary: " + testsPassed + " Passed, " + testsFailed + " Failed");
        System.out.println("==================================================");

        if (testsFailed > 0) {
            System.exit(1);
        }
    }

    private static void setupTestUser() {
        try {
            teardownTestUser();
            UserDAO userDAO = new UserDAO();
            User u = new User("TST_DRV", "Unit Test Driver", "unittest@smartparking.com", PasswordHasher.hash("Pass@123"), "9998887776", "USER");
            userDAO.register(u);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void teardownTestUser() {
        try (java.sql.Connection conn = com.parkingsystem.util.DBConnection.getConnection();
             java.sql.Statement stmt = conn.createStatement()) {
            stmt.executeUpdate("DELETE FROM notifications WHERE user_id = 'TST_DRV'");
            stmt.executeUpdate("DELETE FROM bookings WHERE user_id = 'TST_DRV'");
            stmt.executeUpdate("DELETE FROM users WHERE user_id = 'TST_DRV'");
        } catch (Exception ignored) {}
    }

    private static void runTest(String testName, TestCase testCase) {
        System.out.print("[RUNNING] " + testName + " ... ");
        try {
            testCase.execute();
            testsPassed++;
            System.out.println("PASSED");
        } catch (Throwable t) {
            testsFailed++;
            System.out.println("FAILED: " + t.getMessage());
            t.printStackTrace(System.out);
        }
    }

    @FunctionalInterface
    interface TestCase {
        void execute() throws Exception;
    }

    private static void assertTrue(boolean condition, String message) {
        if (!condition) {
            throw new AssertionError("Assertion Failed: " + message);
        }
    }

    private static void assertEquals(Object expected, Object actual, String message) {
        if (expected == null && actual == null) return;
        if (expected != null && expected.equals(actual)) return;
        throw new AssertionError("Assertion Failed: " + message + " (Expected: " + expected + ", Actual: " + actual + ")");
    }

    /**
     * TEST 1: User registration and BCrypt password hashing
     */
    private static void testUserRegistrationWithBCrypt() throws Exception {
        UserDAO userDAO = new UserDAO();
        String testEmail = "testuser_" + System.currentTimeMillis() + "@smartparking.com";
        String rawPassword = "SecurePassword@123";

        // Hash using BCrypt
        String bcryptHash = PasswordHasher.hash(rawPassword);
        assertTrue(bcryptHash != null && bcryptHash.startsWith("$2a$"), "Password must be hashed with BCrypt ($2a$)");

        User newUser = new User();
        newUser.setUserId("TST" + (System.currentTimeMillis() % 100000));
        newUser.setName("Test Student");
        newUser.setEmail(testEmail);
        newUser.setPassword(bcryptHash);
        String testPhone = "9" + String.format("%09d", Math.abs(System.currentTimeMillis() % 1000000000L));
        newUser.setPhoneNumber(testPhone);
        newUser.setRole("USER");

        boolean registered = userDAO.register(newUser);
        assertTrue(registered, "User registration must succeed in database");

        User fetched = userDAO.findByEmail(testEmail);
        assertTrue(fetched != null, "Registered user must be queryable by email");
        assertEquals("Test Student", fetched.getName(), "User name should match registered name");

        // Authenticate the newly registered user using BCrypt verification
        User authenticated = userDAO.authenticate(testEmail, rawPassword);
        assertTrue(authenticated != null, "Newly registered user must authenticate successfully with original password via BCrypt");

        // Clean up temporary test user so database remains clean
        try (java.sql.Connection conn = com.parkingsystem.util.DBConnection.getConnection();
             java.sql.Statement stmt = conn.createStatement()) {
            stmt.executeUpdate("DELETE FROM users WHERE user_id = '" + newUser.getUserId() + "'");
        }
    }

    /**
     * TEST 2: Login authentication (valid and invalid passwords)
     */
    private static void testLoginAuthentication() throws Exception {
        UserDAO userDAO = new UserDAO();
        String email = "admin@smartparking.com";

        // Successful authentication
        User validUser = userDAO.authenticate(email, "Admin@123");
        assertTrue(validUser != null, "Valid credentials must authenticate successfully");
        assertEquals("ADMIN", validUser.getRole(), "Admin role must match");

        // Failed authentication: wrong password
        User wrongPwUser = userDAO.authenticate(email, "WrongPassword@999");
        assertTrue(wrongPwUser == null, "Incorrect password must fail authentication and return null");

        // Failed authentication: non-existent email
        User ghostUser = userDAO.authenticate("ghost_user_nonexistent@smartparking.com", "anyPassword");
        assertTrue(ghostUser == null, "Non-existent user must return null");
    }

    /**
     * TEST 3: Slot reservation and grace period
     */
    private static void testSlotReservationAndGracePeriod() throws Exception {
        SlotDAO slotDAO = new SlotDAO();
        BookingDAO bookingDAO = new BookingDAO();

        // Find or reset an available slot in Zone B
        List<Slot> slotsB = slotDAO.getSlotsByZone("B");
        assertTrue(slotsB != null && !slotsB.isEmpty(), "Zone B must have slots available");

        Slot target = null;
        for (Slot s : slotsB) {
            if (s.isAvailable()) {
                target = s;
                break;
            }
        }
        if (target == null) {
            target = slotsB.get(0);
            slotDAO.overrideSlotStatus(target.getSlotId(), "AVAILABLE");
        }

        Booking booking = new Booking();
        booking.setUserId("TST_DRV");
        booking.setSlotId(target.getSlotId());
        booking.setVehicleNumber("KA05CD1122");
        booking.setDurationHours(1);
        booking.setTotalAmount(40.0);
        booking.setStatus("PENDING");

        int bookingId = bookingDAO.createPendingBooking(booking);
        assertTrue(bookingId > 0, "createPendingBooking must return valid generated booking ID");

        // Slot status in database must be RESERVED
        Slot reservedSlot = slotDAO.getSlotById(target.getSlotId());
        assertEquals("RESERVED", reservedSlot.getStatus().toUpperCase(), "Slot must transition to RESERVED upon pending booking");

        // Clean up
        bookingDAO.cancelPendingBooking(bookingId);
    }

    /**
     * TEST 4: Double-booking concurrency prevention
     */
    private static void testDoubleBookingPrevention() throws Exception {
        SlotDAO slotDAO = new SlotDAO();
        BookingDAO bookingDAO = new BookingDAO();

        // Prepare slot B1
        String testSlotId = "B1";
        slotDAO.overrideSlotStatus(testSlotId, "AVAILABLE");

        Booking firstBooking = new Booking();
        firstBooking.setUserId("TST_DRV");
        firstBooking.setSlotId(testSlotId);
        firstBooking.setVehicleNumber("KA01AA1111");
        firstBooking.setDurationHours(1);
        firstBooking.setTotalAmount(40.0);

        int firstId = bookingDAO.createPendingBooking(firstBooking);
        assertTrue(firstId > 0, "First booking must succeed");

        // Second booking attempts to book the same slot concurrently
        Booking secondBooking = new Booking();
        secondBooking.setUserId("TST001");
        secondBooking.setSlotId(testSlotId);
        secondBooking.setVehicleNumber("KA02BB2222");
        secondBooking.setDurationHours(2);
        secondBooking.setTotalAmount(80.0);

        boolean exceptionCaught = false;
        try {
            bookingDAO.createPendingBooking(secondBooking);
        } catch (SlotUnavailableException sue) {
            exceptionCaught = true;
        }

        assertTrue(exceptionCaught, "Double booking must throw SlotUnavailableException to protect slot concurrency");

        // Clean up first booking
        bookingDAO.cancelPendingBooking(firstId);
    }

    /**
     * TEST 5: Booking cancellation and slot release
     */
    private static void testBookingCancellationAndSlotRelease() throws Exception {
        SlotDAO slotDAO = new SlotDAO();
        BookingDAO bookingDAO = new BookingDAO();

        String slotId = "B2";
        slotDAO.overrideSlotStatus(slotId, "AVAILABLE");

        Booking b = new Booking();
        b.setUserId("TST_DRV");
        b.setSlotId(slotId);
        b.setVehicleNumber("KA03CC3333");
        b.setDurationHours(2);
        b.setTotalAmount(80.0);

        int bookingId = bookingDAO.createPendingBooking(b);
        assertTrue(bookingId > 0, "Booking must be created");

        // Cancel
        boolean cancelled = bookingDAO.cancelPendingBooking(bookingId);
        assertTrue(cancelled, "cancelPendingBooking must return true");

        // Verify slot is AVAILABLE again
        Slot slotAfterCancel = slotDAO.getSlotById(slotId);
        assertEquals("AVAILABLE", slotAfterCancel.getStatus().toUpperCase(), "Slot must be restored to AVAILABLE after cancellation");
    }

    /**
     * TEST 6: User ownership and isolation checks
     */
    private static void testOwnershipChecks() throws Exception {
        NotificationDAO notificationDAO = new NotificationDAO();
        BookingDAO bookingDAO = new BookingDAO();

        // 1. Notifications isolation
        Notification n = new Notification();
        n.setUserId("TST_DRV");
        n.setTitle("Test Privacy Notification");
        n.setMessage("Private message for TST_DRV");
        n.setType("INFO");
        n.setRead(false);
        int notifId = notificationDAO.createNotification(n);
        assertTrue(notifId > 0, "Notification must be created");

        // Another user (e.g., ADM001 or ATTACKER) tries to mark it as read
        boolean attackerMarked = notificationDAO.markAsReadForUser(notifId, "ATTACKER_USER_ID");
        assertTrue(!attackerMarked, "Attacker cannot mark another user's notification as read");

        // Legitimate user marks it as read
        boolean ownerMarked = notificationDAO.markAsReadForUser(notifId, "TST_DRV");
        assertTrue(ownerMarked, "Legitimate owner must be able to mark their notification as read");

        // 2. Bookings isolation
        List<Booking> drvBookings = bookingDAO.getBookingsByUser("TST_DRV");
        for (Booking b : drvBookings) {
            assertEquals("TST_DRV", b.getUserId(), "Every returned booking must strictly belong to TST_DRV");
        }
    }

    /**
     * TEST 7: Active booking protection from admin resets or IoT overwrites
     */
    private static void testActiveBookingProtection() throws Exception {
        SlotDAO slotDAO = new SlotDAO();
        BookingDAO bookingDAO = new BookingDAO();

        String slotId = "B3";
        slotDAO.overrideSlotStatus(slotId, "AVAILABLE");

        Booking b = new Booking();
        b.setUserId("TST_DRV");
        b.setSlotId(slotId);
        b.setVehicleNumber("KA04DD4444");
        b.setDurationHours(1);
        b.setTotalAmount(40.0);

        int bookingId = bookingDAO.createPendingBooking(b);
        assertTrue(bookingId > 0, "Booking created");

        // Verify hasActiveBookingForSlot returns true
        boolean hasActive = bookingDAO.hasActiveBookingForSlot(slotId);
        assertTrue(hasActive, "Active booking guard must return true for locked slot");

        // Clean up
        bookingDAO.cancelPendingBooking(bookingId);

        // After cancel, hasActiveBookingForSlot should return false
        boolean hasActiveAfterCancel = bookingDAO.hasActiveBookingForSlot(slotId);
        assertTrue(!hasActiveAfterCancel, "Active booking guard must return false after cancellation");
    }

    /**
     * TEST 8: Safe Admin Bay Override & Active Occupancy Protection (Requirement 8)
     * Verifies that safeOverrideSlotStatus rejects overrides if an active booking is in progress,
     * but succeeds cleanly when the bay is unoccupied.
     */
    private static void testSafeAdminOverrideProtection() throws Exception {
        SlotDAO slotDAO = new SlotDAO();
        BookingDAO bookingDAO = new BookingDAO();

        String slotId = "B4";
        slotDAO.overrideSlotStatus(slotId, "AVAILABLE");

        Booking b = new Booking();
        b.setUserId("TST_DRV");
        b.setSlotId(slotId);
        b.setVehicleNumber("KA04DD7777");
        b.setDurationHours(2);
        b.setTotalAmount(80.0);

        int bookingId = bookingDAO.createPendingBooking(b);
        assertTrue(bookingId > 0, "Booking created for test slot B4");

        // 1. Attempting to override to AVAILABLE must throw BookingException
        boolean blockedAvailable = false;
        try {
            slotDAO.safeOverrideSlotStatus(slotId, "AVAILABLE");
        } catch (com.parkingsystem.exception.BookingException be) {
            blockedAvailable = true;
            assertTrue(be.getMessage().contains("active booking") || be.getMessage().contains("occupies"),
                    "Exception message must explain active booking conflict");
        }
        assertTrue(blockedAvailable, "safeOverrideSlotStatus must reject AVAILABLE override when active booking exists");

        // 2. Attempting to override to BLOCKED must also throw BookingException
        boolean blockedBlocked = false;
        try {
            slotDAO.safeOverrideSlotStatus(slotId, "BLOCKED");
        } catch (com.parkingsystem.exception.BookingException be) {
            blockedBlocked = true;
        }
        assertTrue(blockedBlocked, "safeOverrideSlotStatus must reject BLOCKED override when active vehicle occupies bay");

        // 3. Cancel booking and verify override now succeeds
        bookingDAO.cancelPendingBooking(bookingId);

        boolean overriddenToBlocked = slotDAO.safeOverrideSlotStatus(slotId, "BLOCKED");
        assertTrue(overriddenToBlocked, "Override to BLOCKED should succeed when slot is clear");
        assertEquals("BLOCKED", slotDAO.getSlotById(slotId).getStatus(), "Slot status must be BLOCKED");

        boolean overriddenToAvail = slotDAO.safeOverrideSlotStatus(slotId, "AVAILABLE");
        assertTrue(overriddenToAvail, "Override to AVAILABLE should succeed when slot is clear");
        assertEquals("AVAILABLE", slotDAO.getSlotById(slotId).getStatus(), "Slot status must be restored to AVAILABLE");
    }

    /**
     * TEST 9: Active Booking Lookup & Authorized Vehicle Inspection (Requirement 5)
     */
    private static void testActiveBookingLookupForInspector() throws Exception {
        SlotDAO slotDAO = new SlotDAO();
        BookingDAO bookingDAO = new BookingDAO();

        String slotId = "B5";
        slotDAO.overrideSlotStatus(slotId, "AVAILABLE");

        // 1. When no active booking, getActiveBookingForSlot returns null
        Booking emptyCheck = bookingDAO.getActiveBookingForSlot(slotId);
        assertTrue(emptyCheck == null, "Empty bay must return null active booking");

        // 2. Create active booking and verify details returned
        Booking b = new Booking();
        b.setUserId("TST_DRV");
        b.setSlotId(slotId);
        b.setVehicleNumber("KA05XY9999");
        b.setDurationHours(1);
        b.setTotalAmount(40.0);

        int bookingId = bookingDAO.createPendingBooking(b);
        assertTrue(bookingId > 0, "Booking created for slot B5");

        Booking activeB = bookingDAO.getActiveBookingForSlot(slotId);
        assertTrue(activeB != null, "Active booking must be retrieved for slot B5");
        assertEquals(bookingId, activeB.getBookingId(), "Booking ID must match");
        assertEquals("KA05XY9999", activeB.getVehicleNumber(), "Vehicle number must match for authorized inspector");
        assertEquals("TST_DRV", activeB.getUserId(), "User ID must match");

        // 3. Clean up
        bookingDAO.cancelPendingBooking(bookingId);
        Booking afterCancel = bookingDAO.getActiveBookingForSlot(slotId);
        assertTrue(afterCancel == null, "Cancelled booking must not be returned as active");
        slotDAO.overrideSlotStatus(slotId, "AVAILABLE");
    }

    /**
     * TEST 10: HyperPark End-to-End Parking Session Lifecycle, Gate Activity & Revenue Tracking
     * Verifies:
     * 1. Reservation creation (status = 'RESERVED', entry_time = null)
     * 2. Simulated ANPR check-in (status = 'ACTIVE', bay marked 'BOOKED', entry_time recorded)
     * 3. Concurrency guard: Duplicate check-in rejected
     * 4. Active parking sessions query: Session tracked with live elapsed stopwatch & calculated charge
     * 5. Vehicle checkout (status = 'PAYMENT_PENDING', exit_time recorded, total bill calculated)
     * 6. Concurrency guard: Duplicate checkout handled idempotently
     * 7. Gate Activity Ledger: Both ENTRY and EXIT events chronologically tracked with simulated sources
     * 8. Finalize payment (status = 'COMPLETED', payments record created, bay released to AVAILABLE)
     * 9. Revenue accounting: Total revenue increases by payment, cancelled and unpaid excluded
     * 10. Concurrency guard: Duplicate payment finalization rejected
     */
    private static void testHyperParkLifecycleAndRevenueAudit() throws Exception {
        SlotDAO slotDAO = new SlotDAO();
        BookingDAO bookingDAO = new BookingDAO();

        String slotId = "B4";
        slotDAO.overrideSlotStatus(slotId, "AVAILABLE");

        // Baseline revenue before test
        java.util.Map<String, Object> baselineRev = bookingDAO.getRevenueStats();
        double initialTotalRev = (Double) baselineRev.getOrDefault("totalRevenue", 0.0);

        // 1. Create scheduled reservation
        Booking b = new Booking();
        b.setUserId("TST_DRV");
        b.setSlotId(slotId);
        b.setVehicleNumber("KA03HP7777");
        b.setZoneId("B");
        b.setHourlyRate(40.0);
        b.setScheduledArrivalTime(new java.sql.Timestamp(System.currentTimeMillis() + 600000L));

        int bookingId = bookingDAO.createScheduledReservation(b);
        assertTrue(bookingId > 0, "Scheduled reservation created successfully");
        Slot s1 = slotDAO.getSlotById(slotId);
        assertEquals("RESERVED", s1.getStatus(), "Bay status must be RESERVED");

        // 2. Simulated ANPR Plate Scan Check-In
        Booking checkedIn = bookingDAO.checkInWithNumberPlate("KA03HP7777", slotId, "TST_DRV");
        assertTrue(checkedIn != null, "Vehicle check-in must succeed");
        assertEquals("ACTIVE", checkedIn.getStatus(), "Booking status must transition to ACTIVE");
        assertTrue(checkedIn.getEntryTime() != null, "Entry timestamp must be set");
        Slot s2 = slotDAO.getSlotById(slotId);
        assertTrue("OCCUPIED".equalsIgnoreCase(s2.getStatus()) || "BOOKED".equalsIgnoreCase(s2.getStatus()), "Bay status must transition to OCCUPIED");

        // 3. Concurrency check: Duplicate check-in must be rejected
        boolean dupCheckInCaught = false;
        try {
            bookingDAO.checkInWithNumberPlate("KA03HP7777", slotId, "TST_DRV");
        } catch (com.parkingsystem.exception.BookingException be) {
            dupCheckInCaught = true;
        }
        assertTrue(dupCheckInCaught, "Duplicate check-in on already active vehicle must throw BookingException");

        // 4. Verify Active Parking Sessions Query
        List<Booking> activeSessions = bookingDAO.getActiveParkingSessions();
        boolean foundInActive = false;
        double sessRate = 30.0;
        for (Booking sess : activeSessions) {
            if (sess.getBookingId() == bookingId) {
                foundInActive = true;
                assertEquals("KA03HP7777", sess.getVehicleNumber(), "Active session vehicle plate must match");
                assertTrue(sess.getElapsedSeconds() >= 0L, "Elapsed seconds must be >= 0");
                sessRate = sess.getHourlyRate() > 0 ? sess.getHourlyRate() : 30.0;
                double estCharge = sess.getLiveEstimatedAmount(sessRate);
                assertTrue(estCharge >= sessRate, "Live estimated charge must reflect hourly tariff");
                break;
            }
        }
        assertTrue(foundInActive, "Booking #" + bookingId + " must be present in active parking sessions view");

        // 5. Vehicle Checkout / Departure
        Booking checkedOut = bookingDAO.endParkingSession(bookingId, sessRate);
        assertTrue(checkedOut != null, "Vehicle checkout must succeed");
        assertEquals("PAYMENT_PENDING", checkedOut.getStatus(), "Booking status must transition to PAYMENT_PENDING");
        assertTrue(checkedOut.getExitTime() != null, "Exit timestamp must be recorded");
        assertTrue(checkedOut.getTotalAmount() >= sessRate, "Total amount must be calculated from duration and tariff");

        // 6. Concurrency check: Duplicate checkout must be idempotent
        Booking dupExit = bookingDAO.endParkingSession(bookingId, sessRate);
        assertEquals(checkedOut.getBookingId(), dupExit.getBookingId(), "Idempotent checkout must return current booking");
        assertEquals("PAYMENT_PENDING", dupExit.getStatus(), "Status must remain PAYMENT_PENDING");

        // 7. Verify Gate Activity Ledger
        List<com.parkingsystem.model.GateActivityEvent> gateEvents = bookingDAO.getRecentGateActivity(20);
        boolean hasEntryEvent = false;
        boolean hasExitEvent = false;
        for (com.parkingsystem.model.GateActivityEvent evt : gateEvents) {
            if (evt.getBookingId() == bookingId) {
                if (evt.isEntry()) {
                    hasEntryEvent = true;
                    assertEquals("Simulated ANPR Camera", evt.getEventSource(), "Entry event source must be simulated ANPR");
                } else if (evt.isExit()) {
                    hasExitEvent = true;
                    assertEquals("Simulated Outgate Sensor", evt.getEventSource(), "Exit event source must be simulated sensor");
                }
            }
        }
        assertTrue(hasEntryEvent, "Gate activity ledger must log ENTRY event for booking #" + bookingId);
        assertTrue(hasExitEvent, "Gate activity ledger must log EXIT event for booking #" + bookingId);

        // 8. Finalize Payment & Bay Release
        String txnId = "TXN_HP_" + System.currentTimeMillis();
        com.parkingsystem.model.Payment payment = new com.parkingsystem.model.Payment();
        payment.setBookingId(bookingId);
        payment.setAmount(checkedOut.getTotalAmount());
        payment.setPaymentMethod("UPI");
        payment.setTransactionId(txnId);
        payment.setStatus("SUCCESS");

        boolean paid = bookingDAO.finalizeExitPayment(bookingId, payment);
        assertTrue(paid, "Finalizing exit payment must succeed");

        Booking completedB = bookingDAO.getBookingById(bookingId);
        assertEquals("COMPLETED", completedB.getStatus(), "Booking status must be COMPLETED");
        Slot s3 = slotDAO.getSlotById(slotId);
        assertEquals("AVAILABLE", s3.getStatus(), "Bay must be released back to AVAILABLE");

        // 9. Verify Revenue Accounting: Revenue increases by verified payment amount
        java.util.Map<String, Object> updatedRev = bookingDAO.getRevenueStats();
        double newTotalRev = (Double) updatedRev.getOrDefault("totalRevenue", 0.0);
        assertEquals(initialTotalRev + checkedOut.getTotalAmount(), newTotalRev, "Total collected revenue must increase by paid amount");

        // 10. Concurrency check: Duplicate payment finalization must be rejected
        boolean dupPayCaught = false;
        try {
            bookingDAO.finalizeExitPayment(bookingId, payment);
        } catch (com.parkingsystem.exception.BookingException be) {
            dupPayCaught = true;
        }
        assertTrue(dupPayCaught, "Duplicate payment finalization on COMPLETED booking must be rejected");

        // Cleanup slot to AVAILABLE
        slotDAO.overrideSlotStatus(slotId, "AVAILABLE");
    }

    private static void testInvalidCheckInAndCheckoutEdgeCases() throws Exception {
        BookingDAO bookingDAO = new BookingDAO();
        SlotDAO slotDAO = new SlotDAO();

        String slotId1 = "B13";
        String slotId2 = "B14";
        slotDAO.overrideSlotStatus(slotId1, "AVAILABLE");
        slotDAO.overrideSlotStatus(slotId2, "AVAILABLE");

        // 1. Invalid Check-in: No active reservation exists
        boolean caughtNoRes = false;
        try {
            bookingDAO.checkInWithNumberPlate("KA99ZZ9999", slotId1, "TST_DRV");
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtNoRes = true;
        }
        assertTrue(caughtNoRes, "Check-in without active reservation must throw BookingException");

        // 2. Invalid Check-in: Slot is under MAINTENANCE
        slotDAO.overrideSlotStatus(slotId1, "MAINTENANCE");
        boolean caughtMaint = false;
        try {
            bookingDAO.checkInWithNumberPlate("KA03INV01", slotId1, "TST_DRV");
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtMaint = true;
        }
        assertTrue(caughtMaint, "Check-in to a bay under MAINTENANCE must throw BookingException");
        slotDAO.overrideSlotStatus(slotId1, "AVAILABLE");

        // 3. Valid Check-in: Create reservation and check in
        Booking b1 = new Booking();
        b1.setUserId("TST_DRV");
        b1.setSlotId(slotId1);
        b1.setVehicleNumber("KA03INV01");
        b1.setZoneId("B");
        b1.setHourlyRate(40.0);
        b1.setScheduledArrivalTime(new java.sql.Timestamp(System.currentTimeMillis() + 600000L));
        int bId1 = bookingDAO.createScheduledReservation(b1);
        assertTrue(bId1 > 0, "Valid reservation #1 must be created");

        Booking active1 = bookingDAO.checkInWithNumberPlate("KA03INV01", slotId1, "TST_DRV");
        assertEquals("ACTIVE", active1.getStatus(), "Booking #1 must become ACTIVE");

        // 4. Invalid Check-in: Attempt to reserve already occupied bay B13
        Booking b2 = new Booking();
        b2.setUserId("TST_DRV");
        b2.setSlotId(slotId1);
        b2.setVehicleNumber("KA03INV02");
        b2.setZoneId("B");
        b2.setHourlyRate(40.0);
        b2.setScheduledArrivalTime(new java.sql.Timestamp(System.currentTimeMillis() + 600000L));
        boolean caughtSlotUnavailable = false;
        try {
            bookingDAO.createScheduledReservation(b2);
        } catch (com.parkingsystem.exception.SlotUnavailableException sue) {
            caughtSlotUnavailable = true;
        }
        assertTrue(caughtSlotUnavailable, "Reserving already occupied bay B13 must throw SlotUnavailableException");

        // 5. Invalid Check-in: Already active vehicle KA03INV01 attempting check-in into another bay B14
        Booking b3 = new Booking();
        b3.setUserId("TST_DRV");
        b3.setSlotId(slotId2);
        b3.setVehicleNumber("KA03INV01");
        b3.setZoneId("B");
        b3.setHourlyRate(40.0);
        b3.setScheduledArrivalTime(new java.sql.Timestamp(System.currentTimeMillis() + 600000L));
        int bId3 = bookingDAO.createScheduledReservation(b3);
        assertTrue(bId3 > 0, "Reservation on B14 created");

        boolean caughtDupVeh = false;
        try {
            bookingDAO.checkInWithNumberPlate("KA03INV01", slotId2, "TST_DRV");
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtDupVeh = true;
        }
        assertTrue(caughtDupVeh, "Active vehicle checking in to second bay must throw BookingException");

        // 6. Invalid Checkout: Non-existent booking ID
        boolean caughtNonExistentCheckout = false;
        try {
            bookingDAO.endParkingSession(999999, 40.0);
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtNonExistentCheckout = true;
        }
        assertTrue(caughtNonExistentCheckout, "Checking out non-existent booking must throw BookingException");

        // 7. Invalid Checkout: Unparked reservation (entry_time is null)
        boolean caughtUnparkedCheckout = false;
        try {
            bookingDAO.endParkingSession(bId3, 40.0);
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtUnparkedCheckout = true;
        }
        assertTrue(caughtUnparkedCheckout, "Checking out unparked reservation must throw BookingException");

        // 8. Invalid Checkout: Cancelled booking
        bookingDAO.cancelReservationByUser(bId3, "TST_DRV");
        boolean caughtCancelledCheckout = false;
        try {
            bookingDAO.endParkingSession(bId3, 40.0);
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtCancelledCheckout = true;
        }
        assertTrue(caughtCancelledCheckout, "Checking out cancelled booking must throw BookingException");

        // 9. Repeated Checkout: Idempotent behavior on active1
        Booking checkout1 = bookingDAO.endParkingSession(bId1, 40.0);
        assertEquals("PAYMENT_PENDING", checkout1.getStatus(), "Status must be PAYMENT_PENDING");
        java.sql.Timestamp exitTime1 = checkout1.getExitTime();
        assertTrue(exitTime1 != null, "Exit time must be recorded");

        Booking repeatedCheckout = bookingDAO.endParkingSession(bId1, 40.0);
        assertEquals("PAYMENT_PENDING", repeatedCheckout.getStatus(), "Status must remain PAYMENT_PENDING");
        assertEquals(exitTime1.getTime(), repeatedCheckout.getExitTime().getTime(), "Exit timestamp must remain unchanged on repeated checkout");

        // Cleanup: finalize payment for bId1
        com.parkingsystem.model.Payment pay = new com.parkingsystem.model.Payment();
        pay.setBookingId(bId1);
        pay.setAmount(checkout1.getTotalAmount());
        pay.setPaymentMethod("UPI");
        pay.setTransactionId("TXN_CLEAN_" + System.currentTimeMillis());
        bookingDAO.finalizeExitPayment(bId1, pay);

        slotDAO.overrideSlotStatus(slotId1, "AVAILABLE");
        slotDAO.overrideSlotStatus(slotId2, "AVAILABLE");
    }

    private static void testInvalidPaymentAndCancellationEdgeCases() throws Exception {
        BookingDAO bookingDAO = new BookingDAO();
        SlotDAO slotDAO = new SlotDAO();

        String slotId = "B15";
        slotDAO.overrideSlotStatus(slotId, "AVAILABLE");

        // Create reservation, check in and checkout -> PAYMENT_PENDING
        Booking b = new Booking();
        b.setUserId("TST_DRV");
        b.setSlotId(slotId);
        b.setVehicleNumber("KA03PAY01");
        b.setZoneId("B");
        b.setHourlyRate(40.0);
        b.setScheduledArrivalTime(new java.sql.Timestamp(System.currentTimeMillis() + 600000L));
        int bId = bookingDAO.createScheduledReservation(b);
        bookingDAO.checkInWithNumberPlate("KA03PAY01", slotId, "TST_DRV");
        Booking checkedOut = bookingDAO.endParkingSession(bId, 40.0);
        assertEquals("PAYMENT_PENDING", checkedOut.getStatus(), "Status must be PAYMENT_PENDING");

        // 1. Invalid Payment: Zero amount
        com.parkingsystem.model.Payment zeroPay = new com.parkingsystem.model.Payment();
        zeroPay.setBookingId(bId);
        zeroPay.setAmount(0.0);
        zeroPay.setPaymentMethod("UPI");
        zeroPay.setTransactionId("TXN_ZERO");
        boolean caughtZeroPay = false;
        try {
            bookingDAO.finalizeExitPayment(bId, zeroPay);
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtZeroPay = true;
        }
        assertTrue(caughtZeroPay, "Payment with zero amount must throw BookingException");

        // 2. Invalid Payment: Negative amount
        com.parkingsystem.model.Payment negPay = new com.parkingsystem.model.Payment();
        negPay.setBookingId(bId);
        negPay.setAmount(-50.0);
        negPay.setPaymentMethod("UPI");
        negPay.setTransactionId("TXN_NEG");
        boolean caughtNegPay = false;
        try {
            bookingDAO.finalizeExitPayment(bId, negPay);
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtNegPay = true;
        }
        assertTrue(caughtNegPay, "Payment with negative amount must throw BookingException");

        // 3. Invalid Cancellation: Attempt to cancel PAYMENT_PENDING booking
        boolean caughtCancelPending = false;
        try {
            bookingDAO.cancelReservationByUser(bId, "TST_DRV");
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtCancelPending = true;
        }
        assertTrue(caughtCancelPending, "Cancelling departed PAYMENT_PENDING booking must throw BookingException");

        // 4. Valid Payment: Finalize exit payment successfully
        com.parkingsystem.model.Payment validPay = new com.parkingsystem.model.Payment();
        validPay.setBookingId(bId);
        validPay.setAmount(checkedOut.getTotalAmount());
        validPay.setPaymentMethod("UPI");
        validPay.setTransactionId("TXN_VAL_" + System.currentTimeMillis());
        boolean paySuccess = bookingDAO.finalizeExitPayment(bId, validPay);
        assertTrue(paySuccess, "Valid payment finalization must succeed");

        Booking completedB = bookingDAO.getBookingById(bId);
        assertEquals("COMPLETED", completedB.getStatus(), "Booking status must be COMPLETED");
        assertEquals("AVAILABLE", slotDAO.getSlotById(slotId).getStatus(), "Slot must be released to AVAILABLE");

        // 5. Repeated Payment: Already COMPLETED booking
        boolean caughtRepeatedPay = false;
        try {
            bookingDAO.finalizeExitPayment(bId, validPay);
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtRepeatedPay = true;
        }
        assertTrue(caughtRepeatedPay, "Repeated payment on COMPLETED booking must throw BookingException");

        // 6. Invalid Cancellation: Attempt to cancel COMPLETED booking
        boolean caughtCancelCompleted = false;
        try {
            bookingDAO.cancelReservationByUser(bId, "TST_DRV");
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtCancelCompleted = true;
        }
        assertTrue(caughtCancelCompleted, "Cancelling COMPLETED booking must throw BookingException");

        // 7. Cancellation Lifecycle & Payment on CANCELLED booking
        Booking bCancel = new Booking();
        bCancel.setUserId("TST_DRV");
        bCancel.setSlotId(slotId);
        bCancel.setVehicleNumber("KA03PAY02");
        bCancel.setZoneId("B");
        bCancel.setHourlyRate(40.0);
        bCancel.setScheduledArrivalTime(new java.sql.Timestamp(System.currentTimeMillis() + 600000L));
        int bIdCancel = bookingDAO.createScheduledReservation(bCancel);
        bookingDAO.cancelReservationByUser(bIdCancel, "TST_DRV");
        assertEquals("CANCELLED", bookingDAO.getBookingById(bIdCancel).getStatus(), "Booking status must be CANCELLED");

        boolean caughtPayOnCancelled = false;
        try {
            bookingDAO.finalizeExitPayment(bIdCancel, validPay);
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtPayOnCancelled = true;
        }
        assertTrue(caughtPayOnCancelled, "Processing payment for CANCELLED booking must throw BookingException");

        // 8. Repeated Cancellation on already CANCELLED booking
        boolean caughtRepeatedCancel = false;
        try {
            bookingDAO.cancelReservationByUser(bIdCancel, "TST_DRV");
        } catch (com.parkingsystem.exception.BookingException be) {
            caughtRepeatedCancel = true;
        }
        assertTrue(caughtRepeatedCancel, "Repeated cancellation on CANCELLED booking must throw BookingException");

        slotDAO.overrideSlotStatus(slotId, "AVAILABLE");
    }

    private static void testStepByStepConsistencyAndRevenueExclusions() throws Exception {
        BookingDAO bookingDAO = new BookingDAO();
        SlotDAO slotDAO = new SlotDAO();

        String slotId1 = "B16";
        String slotId2 = "B17";
        slotDAO.overrideSlotStatus(slotId1, "AVAILABLE");
        slotDAO.overrideSlotStatus(slotId2, "AVAILABLE");

        // Baseline financial metrics
        Map<String, Object> baselineRev = bookingDAO.getRevenueStats();
        double baseTotalRev = (Double) baselineRev.getOrDefault("totalRevenue", 0.0);
        double baseTodayRev = (Double) baselineRev.getOrDefault("todayRevenue", 0.0);
        int basePendingCount = (Integer) baselineRev.getOrDefault("pendingCount", 0);
        double basePendingRev = (Double) baselineRev.getOrDefault("pendingRevenue", 0.0);
        int baseCancelledCount = (Integer) baselineRev.getOrDefault("cancelledBookingsCount", 0);

        // STEP 1: Scheduled Reservation Created
        Booking b = new Booking();
        b.setUserId("TST_DRV");
        b.setSlotId(slotId1);
        b.setVehicleNumber("KA03AUDIT1");
        b.setZoneId("B");
        b.setHourlyRate(40.0);
        b.setScheduledArrivalTime(new java.sql.Timestamp(System.currentTimeMillis() + 600000L));
        int bId = bookingDAO.createScheduledReservation(b);

        // Verify Step 1 database state & revenue exclusion
        Booking s1Booking = bookingDAO.getBookingById(bId);
        assertEquals("RESERVED", s1Booking.getStatus(), "Step 1: Booking status must be RESERVED");
        assertEquals("RESERVED", slotDAO.getSlotById(slotId1).getStatus(), "Step 1: Slot status must be RESERVED");

        Map<String, Object> revAfterRes = bookingDAO.getRevenueStats();
        assertEquals(baseTotalRev, (Double) revAfterRes.get("totalRevenue"), "Step 1: Total collected revenue must NOT include reserved unpaid booking");
        assertEquals(basePendingCount, (Integer) revAfterRes.get("pendingCount"), "Step 1: Pending count must NOT increase on reservation");

        // STEP 2: Vehicle Check-In (ANPR scan) -> ACTIVE
        Booking checkedIn = bookingDAO.checkInWithNumberPlate("KA03AUDIT1", slotId1, "TST_DRV");
        assertEquals("ACTIVE", checkedIn.getStatus(), "Step 2: Booking status must be ACTIVE");
        assertTrue("OCCUPIED".equalsIgnoreCase(slotDAO.getSlotById(slotId1).getStatus()) || "BOOKED".equalsIgnoreCase(slotDAO.getSlotById(slotId1).getStatus()), "Step 2: Slot status must be OCCUPIED");

        // Verify Step 2: Active sessions count increases, but collected revenue remains UNTOUCHED
        List<Booking> activeSess = bookingDAO.getActiveParkingSessions();
        boolean foundInActive = false;
        double sessRate = 30.0;
        for (Booking as : activeSess) {
            if (as.getBookingId() == bId) {
                foundInActive = true;
                sessRate = as.getHourlyRate() > 0 ? as.getHourlyRate() : 30.0;
                break;
            }
        }
        assertTrue(foundInActive, "Step 2: Active parking sessions must list booking #" + bId);

        Map<String, Object> revAfterCheckIn = bookingDAO.getRevenueStats();
        assertEquals(baseTotalRev, (Double) revAfterCheckIn.get("totalRevenue"), "Step 2: Estimated active accrual must NOT be counted in collected revenue");

        // STEP 3: Vehicle Checkout (Sensor scan-out) -> PAYMENT_PENDING
        Booking checkedOut = bookingDAO.endParkingSession(bId, sessRate);
        assertEquals("PAYMENT_PENDING", checkedOut.getStatus(), "Step 3: Booking status must transition to PAYMENT_PENDING");
        assertTrue(checkedOut.getExitTime() != null, "Step 3: Exit timestamp must be stamped");
        assertTrue("OCCUPIED".equalsIgnoreCase(slotDAO.getSlotById(slotId1).getStatus()) || "BOOKED".equalsIgnoreCase(slotDAO.getSlotById(slotId1).getStatus()), "Step 3: Slot must remain OCCUPIED/BOOKED (held until settled)");

        // Verify Step 3: Collected revenue still untouched, pending revenue increases
        Map<String, Object> revAfterExit = bookingDAO.getRevenueStats();
        assertEquals(baseTotalRev, (Double) revAfterExit.get("totalRevenue"), "Step 3: Collected revenue must NOT include unpaid departed vehicle");
        assertEquals(basePendingCount + 1, (Integer) revAfterExit.get("pendingCount"), "Step 3: Pending collections count must increase by 1");
        assertEquals(basePendingRev + checkedOut.getTotalAmount(), (Double) revAfterExit.get("pendingRevenue"), "Step 3: Pending collections sum must increase by exact bill");

        // STEP 4: Finalize Payment -> COMPLETED & Slot Released
        com.parkingsystem.model.Payment pay = new com.parkingsystem.model.Payment();
        pay.setBookingId(bId);
        pay.setAmount(checkedOut.getTotalAmount());
        pay.setPaymentMethod("UPI");
        pay.setTransactionId("TXN_AUDIT_" + System.currentTimeMillis());
        boolean payDone = bookingDAO.finalizeExitPayment(bId, pay);
        assertTrue(payDone, "Step 4: Exit payment finalization must succeed");

        Booking completedB = bookingDAO.getBookingById(bId);
        assertEquals("COMPLETED", completedB.getStatus(), "Step 4: Booking status must transition to COMPLETED");
        assertEquals("AVAILABLE", slotDAO.getSlotById(slotId1).getStatus(), "Step 4: Slot must be released back to AVAILABLE");

        // Verify Step 4: Collected revenue increases by paid amount, pending returns to baseline
        Map<String, Object> revAfterPay = bookingDAO.getRevenueStats();
        assertEquals(baseTotalRev + checkedOut.getTotalAmount(), (Double) revAfterPay.get("totalRevenue"), "Step 4: Total revenue must increase by exact paid amount");
        assertEquals(baseTodayRev + checkedOut.getTotalAmount(), (Double) revAfterPay.get("todayRevenue"), "Step 4: Today's revenue must include settled payment");
        assertEquals(basePendingCount, (Integer) revAfterPay.get("pendingCount"), "Step 4: Pending count must return to baseline after payment");

        // STEP 5: Cancellation & Revenue Exclusion
        Booking bCancel = new Booking();
        bCancel.setUserId("TST_DRV");
        bCancel.setSlotId(slotId2);
        bCancel.setVehicleNumber("KA03AUDIT2");
        bCancel.setZoneId("B");
        bCancel.setHourlyRate(40.0);
        bCancel.setScheduledArrivalTime(new java.sql.Timestamp(System.currentTimeMillis() + 600000L));
        int bIdCancel = bookingDAO.createScheduledReservation(bCancel);

        bookingDAO.cancelReservationByUser(bIdCancel, "TST_DRV");
        Booking cancelledB = bookingDAO.getBookingById(bIdCancel);
        assertEquals("CANCELLED", cancelledB.getStatus(), "Step 5: Booking status must be CANCELLED");
        assertEquals("AVAILABLE", slotDAO.getSlotById(slotId2).getStatus(), "Step 5: Slot must be restored to AVAILABLE");

        Map<String, Object> revAfterCancel = bookingDAO.getRevenueStats();
        assertEquals(baseTotalRev + checkedOut.getTotalAmount(), (Double) revAfterCancel.get("totalRevenue"), "Step 5: Total collected revenue must NOT be affected by cancelled booking");
        assertEquals(baseCancelledCount + 1, (Integer) revAfterCancel.get("cancelledBookingsCount"), "Step 5: Cancelled count must increase by 1");

        // Cleanup
        slotDAO.overrideSlotStatus(slotId1, "AVAILABLE");
        slotDAO.overrideSlotStatus(slotId2, "AVAILABLE");
    }
}
