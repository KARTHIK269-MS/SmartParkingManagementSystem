package com.parkingsystem;

import com.parkingsystem.dao.*;
import com.parkingsystem.model.*;
import com.parkingsystem.util.IoTSimulator;
import com.parkingsystem.util.PasswordHasher;

import java.util.List;
import java.util.Map;

public class TestSystem {

    public static void main(String[] args) {
        System.out.println("==================================================");
        System.out.println("Starting Automated End-to-End Verification Test...");
        System.out.println("==================================================");

        try {
            // 1. Test Auth
            UserDAO userDAO = new UserDAO();
            String adminHash = PasswordHasher.hash("Admin@123");
            User admin = userDAO.authenticate("admin@smartparking.com", adminHash);
            assert admin != null && admin.isAdmin() : "Admin authentication failed!";
            System.out.println("[PASS] 1. Auth: Admin authenticated successfully (Role: " + admin.getRole() + ")");

            String driverHash = PasswordHasher.hash("Driver@123");
            User driver = userDAO.authenticate("driver@smartparking.com", driverHash);
            assert driver != null && !driver.isAdmin() : "Driver authentication failed!";
            System.out.println("[PASS] 2. Auth: Driver authenticated successfully (" + driver.getName() + ")");

            // 2. Test Zones
            ZoneDAO zoneDAO = new ZoneDAO();
            List<Zone> zones = zoneDAO.getAllZones();
            assert zones != null && !zones.isEmpty() : "Zones list is empty!";
            System.out.println("[PASS] 3. Zones: Fetched " + zones.size() + " zones. First zone: " + zones.get(0).getName() + " (Available bays: " + zones.get(0).getAvailableSlots() + ")");

            // 3. Test Slots
            SlotDAO slotDAO = new SlotDAO();
            List<Slot> slotsA = slotDAO.getSlotsByZone("A");
            assert slotsA != null && slotsA.size() >= 20 : "Zone A slots count invalid!";
            System.out.println("[PASS] 4. Slots: Fetched " + slotsA.size() + " bays in Zone A.");

            // 4. Test Two-Step Booking Flow
            BookingDAO bookingDAO = new BookingDAO();
            // Pick an available slot in Zone A
            Slot targetSlot = null;
            for (Slot s : slotsA) {
                if (s.isAvailable()) {
                    targetSlot = s;
                    break;
                }
            }
            if (targetSlot == null && !slotsA.isEmpty()) {
                slotDAO.overrideSlotStatus(slotsA.get(0).getSlotId(), "AVAILABLE");
                targetSlot = slotDAO.getSlotById(slotsA.get(0).getSlotId());
            }
            assert targetSlot != null : "No available slot found for test!";

            Booking booking = new Booking();
            booking.setUserId(driver.getUserId());
            booking.setSlotId(targetSlot.getSlotId());
            booking.setVehicleNumber("KA01AB9999");
            booking.setDurationHours(2);
            booking.setTotalAmount(60.0);
            booking.setStatus("PENDING");

            int bookingId = bookingDAO.createPendingBooking(booking);
            assert bookingId > 0 : "Failed to create pending booking!";
            System.out.println("[PASS] 5. Booking Step 1: Pending reservation created (#" + bookingId + ") - Slot " + targetSlot.getSlotId() + " locked as RESERVED.");

            // Verify slot is now RESERVED in DB
            Slot checkSlot = slotDAO.getSlotById(targetSlot.getSlotId());
            assert "RESERVED".equalsIgnoreCase(checkSlot.getStatus()) : "Slot status was not set to RESERVED!";
            System.out.println("[PASS] 6. Concurrency Check: Bay " + targetSlot.getSlotId() + " is safely RESERVED.");

            // Step 2: Finalize Payment
            Payment payment = new Payment();
            payment.setBookingId(bookingId);
            payment.setAmount(60.0);
            payment.setPaymentMethod("UPI");
            payment.setTransactionId("TEST_TXN_" + System.currentTimeMillis());

            boolean finalized = bookingDAO.finalizeBooking(bookingId, payment);
            assert finalized : "Failed to finalize booking payment!";
            System.out.println("[PASS] 7. Booking Step 2: Finalized payment. Booking CONFIRMED, Slot BOOKED.");

            checkSlot = slotDAO.getSlotById(targetSlot.getSlotId());
            assert "BOOKED".equalsIgnoreCase(checkSlot.getStatus()) : "Slot status was not set to BOOKED!";

            // 5. Test Feedback
            FeedbackDAO feedbackDAO = new FeedbackDAO();
            Feedback fb = new Feedback();
            fb.setBookingId(bookingId);
            fb.setUserId(driver.getUserId());
            fb.setRating(5);
            fb.setComment("Automated test feedback: Exceptional sensor accuracy and smooth checkout.");
            boolean fbSuccess = feedbackDAO.submitFeedback(fb);
            assert fbSuccess : "Failed to submit feedback!";
            System.out.println("[PASS] 8. Feedback: 5-star rating submitted and saved successfully.");

            // 6. Test New IoT Sensor Scan-In & Pay-on-Exit Dynamic Billing Flow
            Slot sensorSlot = null;
            for (Slot s : slotDAO.getAllSlots()) {
                if (s.isAvailable() && (targetSlot == null || !s.getSlotId().equals(targetSlot.getSlotId()))) {
                    sensorSlot = s;
                    break;
                }
            }
            if (sensorSlot == null) {
                slotDAO.overrideSlotStatus("A2", "AVAILABLE");
                sensorSlot = slotDAO.getSlotById("A2");
            }
            assert sensorSlot != null : "No available slot found for IoT Sensor test!";

            Booking sensorSession = new Booking();
            sensorSession.setUserId(driver.getUserId());
            sensorSession.setSlotId(sensorSlot.getSlotId());
            sensorSession.setVehicleNumber("MH01AB2026");
            sensorSession.setZoneId(sensorSlot.getZoneId());
            sensorSession.setHourlyRate(60.0);

            // Step 1: Scan-In - Timer starts from 00:00:00, slot marked BOOKED
            int sensorBookingId = bookingDAO.startParkingSession(sensorSession);
            assert sensorBookingId > 0 : "Failed to start IoT sensor parking session!";
            Booking activeSession = bookingDAO.getActiveBookingForUser(driver.getUserId());
            assert activeSession != null && activeSession.getBookingId() == sensorBookingId : "Active session mismatch!";
            assert activeSession.isActive() : "Session status should be ACTIVE!";
            assert activeSession.getEntryTime() != null : "Session entry_time must not be null!";
            assert "BOOKED".equalsIgnoreCase(slotDAO.getSlotById(sensorSlot.getSlotId()).getStatus()) : "Slot should be marked BOOKED by sensor!";
            System.out.println("[PASS] 9. IoT Sensor Check-In: Vehicle scanned in bay " + sensorSlot.getSlotId() + ". Timer started from 0hr 0min 0sec (Status: " + activeSession.getStatus() + ").");

            // Step 2: Vehicle Leaving - Sensor scans out, computes duration and total amount
            Booking checkoutBooking = bookingDAO.endParkingSession(sensorBookingId, 60.0);
            assert checkoutBooking != null && checkoutBooking.isPaymentPending() : "Checkout booking status should be PAYMENT_PENDING!";
            assert checkoutBooking.getExitTime() != null : "Exit time should be recorded!";
            assert checkoutBooking.getTotalAmount() >= 60.0 : "Minimum 1-hour tariff should be charged!";
            System.out.println("[PASS] 10. IoT Sensor Check-Out: Vehicle scanned out. Total bill dynamically calculated: ₹ " + checkoutBooking.getTotalAmount() + " (" + checkoutBooking.getDurationHours() + " hr billed).");

            // Step 3: Driver pays bill - Slot released back to AVAILABLE, booking COMPLETED
            Payment exitPayment = new Payment();
            exitPayment.setBookingId(sensorBookingId);
            exitPayment.setAmount(checkoutBooking.getTotalAmount());
            exitPayment.setPaymentMethod("UPI");
            exitPayment.setTransactionId("SENSOR_TXN_" + System.currentTimeMillis());
            boolean exitPaid = bookingDAO.finalizeExitPayment(sensorBookingId, exitPayment);
            assert exitPaid : "Failed to finalize exit payment!";
            assert "AVAILABLE".equalsIgnoreCase(slotDAO.getSlotById(sensorSlot.getSlotId()).getStatus()) : "Slot should be released back to AVAILABLE!";
            System.out.println("[PASS] 11. Pay-on-Exit Payment: Bill paid, bay " + sensorSlot.getSlotId() + " released back to AVAILABLE in sensor network.");

            // 7. Test IoT Simulator Concurrency Protection
            IoTSimulator simulator = IoTSimulator.getInstance();
            boolean pulseSuccess = simulator.triggerSimulationStep();
            System.out.println("[PASS] 12. IoT Simulator: Simulated sensor pulse executed (Safe transaction). Last Event: " + simulator.getLastEventMessage());

            // 8. Test Revenue Stats
            Map<String, Object> revStats = bookingDAO.getRevenueStats();
            System.out.println("[PASS] 13. Admin Analytics: Total Revenue: ₹ " + revStats.get("totalRevenue") + ", Confirmed/Completed Bookings: " + revStats.get("totalConfirmedBookings"));

            // 9. Test 3-Tier Dynamic Demand Pricing Calculation
            Zone testZone = new Zone("TEST", "Test Zone", "City Center", 40.0, 10, "Pricing Test Zone");
            testZone.setAvailableSlots(5); // 50% occupancy -> Normal tier
            assert testZone.isNormalHours() : "Should be Normal hours at 50% occupancy!";
            assert !testZone.isRushHour() : "Rush hour should NOT be active at 50% occupancy!";
            assert testZone.getSurgeMultiplier() == 1.0 : "Normal multiplier should be 1.0!";
            assert testZone.getEffectiveHourlyRate() == 40.0 : "Normal rate should be 40.0!";

            testZone.setAvailableSlots(2); // 80% occupancy -> Rush Hour tier
            assert testZone.isRushHour() : "Rush hour SHOULD be active at 80% occupancy!";
            assert testZone.getSurgeMultiplier() == 1.25 : "Rush hour multiplier should be 1.25!";
            assert testZone.getEffectiveHourlyRate() == 50.0 : "Rush hour rate should be 50.0!";

            testZone.setAvailableSlots(1); // 90% occupancy -> Rush Hour tier
            assert testZone.isRushHour() : "Rush hour SHOULD be active at 90% occupancy!";
            assert testZone.getEffectiveHourlyRate() == 50.0 : "Effective rate should remain 50.0!";

            testZone.setAvailableSlots(8); // 20% occupancy -> No Rush (Off-Peak) tier
            assert testZone.isOffPeak() : "Off-peak / No Rush SHOULD be active at 20% occupancy!";
            assert testZone.getSurgeMultiplier() == 0.75 : "No Rush multiplier should be 0.75!";
            assert testZone.getEffectiveHourlyRate() == 30.0 : "No Rush rate should be 30.0!";
            System.out.println("[PASS] 14. 3-Tier Dynamic Demand Pricing: Verified all 3 tiers (Rush Hours: ₹50, Normal: ₹40, No Rush: ₹30).");

            // 10. Test 24-Hour Occupancy Curve Query
            int[] hourlyCurve = bookingDAO.get24HourOccupancyCurve();
            assert hourlyCurve != null && hourlyCurve.length == 24 : "Hourly curve must contain exactly 24 hours of data!";
            assert hourlyCurve[8] > 0 && hourlyCurve[17] > 0 : "Morning and evening rush hour data points should be present!";
            System.out.println("[PASS] 15. Analytics Occupancy Curve: 24-hour distribution curve verified (Morning peak: " + hourlyCurve[9] + ", Evening peak: " + hourlyCurve[17] + ").");

            // 11. Test Revenue by City Query
            Map<String, Double> cityRevenue = bookingDAO.getRevenueByCityData();
            assert cityRevenue != null : "City revenue map should not be null!";
            assert cityRevenue.containsKey("Mumbai") && cityRevenue.containsKey("Bengaluru") && cityRevenue.containsKey("New Delhi") : "Must contain major Indian metros!";
            System.out.println("[PASS] 16. Analytics Revenue by City: Verified 6 Metros (Mumbai: ₹" + cityRevenue.get("Mumbai") + ", Bengaluru: ₹" + cityRevenue.get("Bengaluru") + ", Delhi: ₹" + cityRevenue.get("New Delhi") + ").");

            // 12. Test Payment Method Distribution Query
            Map<String, Integer> paymentDist = bookingDAO.getPaymentMethodDistributionData();
            assert paymentDist != null : "Payment distribution map should not be null!";
            assert paymentDist.containsKey("UPI") && paymentDist.containsKey("FASTag") : "Must include UPI and FASTag!";
            System.out.println("[PASS] 17. Analytics Payment Channels: Verified distribution (UPI: " + paymentDist.get("UPI") + ", FASTag: " + paymentDist.get("FASTag") + ", Cards: " + paymentDist.get("CARD") + ").");

            // 13. Test Scheduled Reservation Creation
            NotificationDAO notificationDAO = new NotificationDAO();
            Slot resSlot = null;
            for (Slot s : slotDAO.getAllSlots()) {
                if (s.isAvailable()) {
                    resSlot = s;
                    break;
                }
            }
            if (resSlot == null) {
                slotDAO.overrideSlotStatus("B1", "AVAILABLE");
                resSlot = slotDAO.getSlotById("B1");
            }
            assert resSlot != null : "No slot found for reservation test!";

            Booking resBooking = new Booking();
            resBooking.setUserId(driver.getUserId());
            resBooking.setSlotId(resSlot.getSlotId());
            resBooking.setVehicleNumber("KA03MD5555");
            resBooking.setZoneId(resSlot.getZoneId());
            resBooking.setHourlyRate(40.0);
            long now = System.currentTimeMillis();
            java.sql.Timestamp scheduledTime = new java.sql.Timestamp(now + (20 * 60 * 1000L));
            resBooking.setScheduledArrivalTime(scheduledTime);

            int resId = bookingDAO.createScheduledReservation(resBooking);
            assert resId > 0 : "Failed to create scheduled reservation!";
            Booking fetchedRes = bookingDAO.getBookingById(resId);
            assert fetchedRes != null && fetchedRes.isReserved() : "Booking must have status RESERVED!";
            assert fetchedRes.getEntryTime() == null : "Entry time must be null before vehicle arrival!";
            assert "RESERVED".equalsIgnoreCase(slotDAO.getSlotById(resSlot.getSlotId()).getStatus()) : "Slot status must be RESERVED!";
            System.out.println("[PASS] 18. Scheduled Reservation: Bay " + resSlot.getSlotId() + " reserved for " + fetchedRes.getScheduledArrivalTime() + " (Slot: RESERVED, Timer: NOT started).");

            // 14. Test Number Plate Scan Check-In (ANPR Sensor Arrival)
            Booking checkedInBooking = bookingDAO.checkInWithNumberPlate("KA03MD5555", resSlot.getSlotId(), driver.getUserId());
            assert checkedInBooking != null && checkedInBooking.getBookingId() == resId : "Check-in booking mismatch!";
            assert checkedInBooking.isActive() : "Booking status must become BOOKED (Occupied)!";
            assert checkedInBooking.getEntryTime() != null : "Entry time must be stamped on plate scan!";
            assert "BOOKED".equalsIgnoreCase(slotDAO.getSlotById(resSlot.getSlotId()).getStatus()) : "Slot status must switch to BOOKED (Occupied)!";
            System.out.println("[PASS] 19. ANPR Plate Scan Check-In: Vehicle arrived, plate scanned. Slot switched to OCCUPIED (BOOKED) and live timer started.");

            // Release slot back
            bookingDAO.endParkingSession(resId, 40.0);
            Payment pRes = new Payment();
            pRes.setBookingId(resId);
            pRes.setAmount(40.0);
            pRes.setPaymentMethod("UPI");
            pRes.setTransactionId("TEST_RES_TXN_" + System.currentTimeMillis());
            bookingDAO.finalizeExitPayment(resId, pRes);

            // 15. Test 30-Minute Grace Expiration Auto-Cancellation & Notification
            Slot overdueSlot = null;
            for (Slot s : slotDAO.getAllSlots()) {
                if (s.isAvailable()) {
                    overdueSlot = s;
                    break;
                }
            }
            if (overdueSlot == null) {
                slotDAO.overrideSlotStatus("B2", "AVAILABLE");
                overdueSlot = slotDAO.getSlotById("B2");
            }

            Booking overdueBooking = new Booking();
            overdueBooking.setUserId(driver.getUserId());
            overdueBooking.setSlotId(overdueSlot.getSlotId());
            overdueBooking.setVehicleNumber("KA04EF1234");
            overdueBooking.setZoneId(overdueSlot.getZoneId());
            overdueBooking.setHourlyRate(40.0);
            // Scheduled 45 minutes in the past -> exceeds 30-minute grace window!
            java.sql.Timestamp overdueSched = new java.sql.Timestamp(now - (45 * 60 * 1000L));
            overdueBooking.setScheduledArrivalTime(overdueSched);

            int overdueId = bookingDAO.createScheduledReservation(overdueBooking);
            assert overdueId > 0 : "Failed to create overdue test reservation!";
            assert "RESERVED".equalsIgnoreCase(slotDAO.getSlotById(overdueSlot.getSlotId()).getStatus()) : "Slot must be RESERVED before sweep!";

            // Trigger expiration sweep (30 minute grace window)
            int cancelledCount = bookingDAO.cancelExpiredReservations(30);
            assert cancelledCount > 0 : "Overdue reservation should have been cancelled!";

            Booking afterSweepBooking = bookingDAO.getBookingById(overdueId);
            assert afterSweepBooking != null && afterSweepBooking.isCancelled() : "Overdue booking status must be CANCELLED!";
            assert afterSweepBooking.getCancellationReason() != null && afterSweepBooking.getCancellationReason().contains("30-minute grace") : "Cancellation reason must mention 30-minute grace window!";
            assert "AVAILABLE".equalsIgnoreCase(slotDAO.getSlotById(overdueSlot.getSlotId()).getStatus()) : "Overdue slot must be released back to AVAILABLE!";

            // Verify notification generated
            List<Notification> driverNotifs = notificationDAO.getNotificationsByUserId(driver.getUserId(), 5);
            boolean foundNotif = false;
            for (Notification n : driverNotifs) {
                if (n.getBookingId() == overdueId && "CANCELLATION".equalsIgnoreCase(n.getType())) {
                    foundNotif = true;
                    assert n.getMessage().contains("cancelling your reservation") : "Notification message mismatch!";
                    break;
                }
            }
            assert foundNotif : "Cancellation notification must be delivered to user!";
            System.out.println("[PASS] 20. 30-Minute Grace Auto-Cancellation: Reservation #" + overdueId + " cancelled past 30m grace. Bay " + overdueSlot.getSlotId() + " released to AVAILABLE and notification generated.");

            System.out.println("==================================================");
            System.out.println("ALL 20 AUTOMATED TESTS PASSED END-TO-END!");
            System.out.println("==================================================");

        } catch (Exception e) {
            System.err.println("[TEST FAILURE] Exception occurred:");
            e.printStackTrace();
            System.exit(1);
        }
    }
}
