package com.parkingsystem;

import com.parkingsystem.dao.ReportDAO;
import com.parkingsystem.model.*;
import com.parkingsystem.util.CsvExportUtil;
import com.parkingsystem.util.PdfExportUtil;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.util.Calendar;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;

/**
 * Test suite for Smart Parking Reports & Data Export.
 * Validates:
 * 1. Occupancy report queries and live bay calculations.
 * 2. Bookings report parameterized filtering and date range coverage.
 * 3. Revenue report strict settlement verification (status = 'SUCCESS').
 * 4. Server-side date validation and IST timezone completeness.
 * 5. CSV formatting, UTF-8 BOM, and CWE-1236 Formula Injection mitigation.
 * 6. PDF generation and layout streaming via OpenPDF.
 */
public class AdminReportsTest {

    private static int testsRun = 0;
    private static int testsPassed = 0;

    public static void main(String[] args) {
        System.out.println("==================================================");
        System.out.println("  RUNNING ADMIN REPORTS & EXPORT TEST SUITE       ");
        System.out.println("==================================================");

        try {
            testOccupancyReportQueries();
            testOccupancyReportSummaryCalculation();
            testOccupancyReportFiltering();
            testBookingReportQueries();
            testBookingReportDateValidation();
            testServerSideDateValidation();
            testTimezoneAndEndOfDayBounds();
            testHistoricalSnapshotsDateRangeFiltering();
            testRevenueReportStrictSettlementPolicy();
            testRevenueExportEmptyScenario();
            testRevenueExportNonEmptyScenario();
            testCsvFormulaInjectionMitigation();
            testCsvExportGeneration();
            testReportsDateRangeExports();
            testPdfExportGeneration();

            System.out.println("\n--------------------------------------------------");
            System.out.printf("RESULTS: %d / %d Tests Passed (100%%)\n", testsPassed, testsRun);
            System.out.println("--------------------------------------------------");
        } catch (Throwable t) {
            System.err.println("\n[FATAL ERROR] Test suite aborted with unexpected exception:");
            t.printStackTrace();
            System.exit(1);
        }
    }

    private static void assertTrue(String testName, boolean condition, String message) {
        testsRun++;
        if (condition) {
            testsPassed++;
            System.out.printf("  [PASS] %s\n", testName);
        } else {
            System.err.printf("  [FAIL] %s: %s\n", testName, message);
            throw new AssertionError(testName + " failed: " + message);
        }
    }

    private static void testOccupancyReportQueries() throws Exception {
        ReportDAO dao = new ReportDAO();
        List<OccupancyReportItem> items = dao.getOccupancyReport(null);

        assertTrue("Occupancy Report Query (All Zones)", items != null && !items.isEmpty(),
                "Expected non-empty list of facilities");
        assertTrue("Occupancy Report Zone Count", items.size() == 12,
                "Expected 12 facilities across 3 metro corridors, got " + items.size());

        int totalSlotsAcrossFacilities = 0;
        for (OccupancyReportItem item : items) {
            totalSlotsAcrossFacilities += item.getTotalSlots();
            assertTrue("Item Bay Accounting (" + item.getZoneId() + ")",
                    (item.getAvailableSlots() + item.getOccupiedSlots() + item.getReservedSlots() + item.getBlockedSlots()) == item.getTotalSlots(),
                    "Sum of bays should match total capacity for " + item.getZoneId());
        }

        assertTrue("Total System Capacity", totalSlotsAcrossFacilities == 150,
                "Expected exactly 150 bays across the system, got " + totalSlotsAcrossFacilities);
    }

    private static void testOccupancyReportSummaryCalculation() throws Exception {
        ReportDAO dao = new ReportDAO();
        List<OccupancyReportItem> items = dao.getOccupancyReport("ALL");
        OccupancyReportSummary summary = dao.buildOccupancySummary(items, "All Facilities");

        assertTrue("Summary Not Null", summary != null, "Summary object should not be null");
        assertTrue("Summary Facility Count", summary.getTotalFacilities() == 12, "Expected 12 facilities");
        assertTrue("Summary Total Capacity", summary.getTotalSlots() == 150, "Expected 150 bays");
        assertTrue("Summary Bay Sum Consistency",
                (summary.getAvailableSlots() + summary.getOccupiedSlots() + summary.getReservedSlots() + summary.getBlockedSlots()) == summary.getTotalSlots(),
                "Summary bay breakdown must equal total bays");
        assertTrue("Summary Occupancy Rate Range", summary.getOccupancyRate() >= 0.0 && summary.getOccupancyRate() <= 100.0,
                "Occupancy rate should be between 0% and 100%");
    }

    private static void testOccupancyReportFiltering() throws Exception {
        ReportDAO dao = new ReportDAO();
        List<OccupancyReportItem> items = dao.getOccupancyReport("BLR-2");

        assertTrue("Zone Filter Count", items.size() == 1, "Filtering by BLR-2 should return exactly 1 item");
        OccupancyReportItem item = items.get(0);
        assertTrue("Zone Filter ID", "BLR-2".equalsIgnoreCase(item.getZoneId()), "Returned item must be BLR-2");
        assertTrue("Zone Filter City", "Bengaluru".equalsIgnoreCase(item.getCityName()), "BLR-2 must be Bengaluru");
        assertTrue("Zone Filter Bay Count", item.getTotalSlots() > 0, "BLR-2 should have bays");
    }

    private static void testBookingReportQueries() throws Exception {
        ReportDAO dao = new ReportDAO();
        List<BookingReportItem> items = dao.getBookingReport("ALL", null, null, "ALL");
        assertTrue("Booking Report Execution", items != null, "Booking report must return a non-null list");

        BookingReportSummary summary = dao.buildBookingSummary(items, "ALL", "ALL", null, null);
        assertTrue("Booking Report Summary", summary != null, "Summary must be constructed");
        assertTrue("Booking Summary Count Match", summary.getTotalBookings() == items.size(),
                "Summary count must match items size");
    }

    private static void testBookingReportDateValidation() throws Exception {
        ReportDAO dao = new ReportDAO();
        // Test with specific date formats
        List<BookingReportItem> items = dao.getBookingReport(null, "2026-01-01", "2026-12-31", null);
        assertTrue("Booking Date Filtering", items != null, "Booking date filter should execute cleanly");
    }

    private static void testServerSideDateValidation() {
        ReportDAO dao = new ReportDAO();

        // 1. Valid date formats and ranges
        assertTrue("Date Validation: Null Dates", dao.validateDateRange(null, null) == null,
                "Null dates should be valid (all-time)");
        assertTrue("Date Validation: Empty Strings", dao.validateDateRange("", "  ") == null,
                "Empty strings should be valid (all-time)");
        assertTrue("Date Validation: Valid Range", dao.validateDateRange("2026-10-01", "2026-10-15") == null,
                "Valid YYYY-MM-DD range should pass validation");
        assertTrue("Date Validation: Single-Day Range", dao.validateDateRange("2026-10-11", "2026-10-11") == null,
                "Single-day range (start == end) should pass validation");

        // 2. Format rejections
        String badStart = dao.validateDateRange("2026/10/11", "2026-10-15");
        assertTrue("Date Validation: Reject Slash Format", badStart != null && badStart.contains("Invalid Start Date"),
                "Should reject 2026/10/11 slash format");

        String badEnd = dao.validateDateRange("2026-10-01", "2026-02-31");
        assertTrue("Date Validation: Reject Invalid Calendar Date", badEnd != null && badEnd.contains("Invalid End Date"),
                "Should reject invalid calendar date 2026-02-31");

        // 3. Start > End rejection
        String inverted = dao.validateDateRange("2026-10-20", "2026-10-10");
        assertTrue("Date Validation: Reject Start After End", inverted != null && inverted.contains("cannot be after"),
                "Should reject start date after end date");
    }

    private static void testTimezoneAndEndOfDayBounds() {
        ReportDAO dao = new ReportDAO();

        Timestamp startTs = dao.parseStartDate("2026-10-11");
        Timestamp endTs = dao.parseEndDate("2026-10-11");

        assertTrue("Start Timestamp Not Null", startTs != null, "Start timestamp must parse");
        assertTrue("End Timestamp Not Null", endTs != null, "End timestamp must parse");

        Calendar calStart = Calendar.getInstance(ReportDAO.APP_TIMEZONE);
        calStart.setTimeInMillis(startTs.getTime());
        assertTrue("Start Time Hour 00:00:00",
                calStart.get(Calendar.HOUR_OF_DAY) == 0 && calStart.get(Calendar.MINUTE) == 0 &&
                calStart.get(Calendar.SECOND) == 0 && calStart.get(Calendar.MILLISECOND) == 0,
                "Start timestamp must be 00:00:00.000 in IST");

        Calendar calEnd = Calendar.getInstance(ReportDAO.APP_TIMEZONE);
        calEnd.setTimeInMillis(endTs.getTime());
        assertTrue("End Time Completeness 23:59:59.999",
                calEnd.get(Calendar.HOUR_OF_DAY) == 23 && calEnd.get(Calendar.MINUTE) == 59 &&
                calEnd.get(Calendar.SECOND) == 59 && calEnd.get(Calendar.MILLISECOND) == 999,
                "End timestamp must be 23:59:59.999 in IST to cover the complete selected end date");

        long diff = endTs.getTime() - startTs.getTime();
        assertTrue("24-Hour Range Completeness", diff == 86399999L,
                "Difference between start and end of day must be exactly 86,399,999 ms (24 hours minus 1 ms)");
    }

    private static void testHistoricalSnapshotsDateRangeFiltering() throws Exception {
        ReportDAO dao = new ReportDAO();

        // 1. All-time query
        List<Map<String, Object>> snapsAll = dao.getHistoricalOccupancySnapshots(null, 10);
        assertTrue("Historical Snapshots Query", snapsAll != null, "Snapshots query should execute without error");

        // 2. Future date range query with no matching records
        List<Map<String, Object>> snapsFuture = dao.getHistoricalOccupancySnapshots(null, "2099-01-01", "2099-01-02", 10);
        assertTrue("Future Snapshots Empty (No Fabrication)", snapsFuture != null && snapsFuture.isEmpty(),
                "Query for dates with no snapshots must return empty list without fabricating records");

        // 3. Summary object with date range
        List<OccupancyReportItem> items = dao.getOccupancyReport("ALL");
        OccupancyReportSummary summary = dao.buildOccupancySummary(items, "ALL", "2026-10-01", "2026-10-11");
        assertTrue("Summary Start Date Preserved", "2026-10-01".equals(summary.getFilterStartDate()),
                "Summary must retain filter start date");
        assertTrue("Summary End Date Preserved", "2026-10-11".equals(summary.getFilterEndDate()),
                "Summary must retain filter end date");
    }

    private static void testRevenueReportStrictSettlementPolicy() throws Exception {
        ReportDAO dao = new ReportDAO();
        List<RevenueReportItem> items = dao.getRevenueReport("ALL", null, null);
        assertTrue("Revenue Report Query", items != null, "Revenue report must return a list");

        for (RevenueReportItem r : items) {
            assertTrue("Strict Revenue Settlement (" + r.getPaymentId() + ")",
                    "SUCCESS".equalsIgnoreCase(r.getStatus()),
                    "Revenue report items MUST strictly have status SUCCESS; found: " + r.getStatus());
            assertTrue("Positive Amount", r.getAmount() > 0.0, "Revenue amount must be positive");
        }

        RevenueReportSummary summary = dao.buildRevenueSummary(items, "ALL", null, null);
        assertTrue("Revenue Summary", summary != null, "Summary must not be null");
        assertTrue("Revenue Transaction Count", summary.getTransactionCount() == items.size(),
                "Summary transaction count must match list size");
    }

    private static void testCsvFormulaInjectionMitigation() {
        // CWE-1236 mitigation check:
        // Any cell beginning with =, +, -, @, \t, or \r should be escaped by prefixing a single quote (')
        String evilFormula1 = "=SUM(A1:A10)";
        String escaped1 = CsvExportUtil.escapeCsv(evilFormula1);
        assertTrue("Formula Injection Mitigation (=)", escaped1.startsWith("'="),
                "Formula '=SUM(A1:A10)' must be escaped with leading quote; got: " + escaped1);

        String evilFormula2 = "+12345";
        String escaped2 = CsvExportUtil.escapeCsv(evilFormula2);
        assertTrue("Formula Injection Mitigation (+)", escaped2.startsWith("'+"),
                "'+12345' must be escaped with leading quote; got: " + escaped2);

        String evilFormula3 = "-2+3";
        String escaped3 = CsvExportUtil.escapeCsv(evilFormula3);
        assertTrue("Formula Injection Mitigation (-)", escaped3.startsWith("'-"),
                "'-2+3' must be escaped with leading quote; got: " + escaped3);

        String evilFormula4 = "@CMD";
        String escaped4 = CsvExportUtil.escapeCsv(evilFormula4);
        assertTrue("Formula Injection Mitigation (@)", escaped4.startsWith("'@"),
                "'@CMD' must be escaped with leading quote; got: " + escaped4);

        // Standard RFC 4180 commas and quotes
        String regularWithComma = "Bengaluru, Karnataka";
        String escapedComma = CsvExportUtil.escapeCsv(regularWithComma);
        assertTrue("RFC 4180 Comma Escaping", escapedComma.equals("\"Bengaluru, Karnataka\""),
                "Values with commas must be wrapped in quotes; got: " + escapedComma);

        String regularWithQuote = "Bay \"A1\"";
        String escapedQuote = CsvExportUtil.escapeCsv(regularWithQuote);
        assertTrue("RFC 4180 Quote Escaping", escapedQuote.equals("\"Bay \"\"A1\"\"\""),
                "Quotes must be escaped with double quotes; got: " + escapedQuote);
    }

    private static void testCsvExportGeneration() throws Exception {
        ReportDAO dao = new ReportDAO();
        List<OccupancyReportItem> items = dao.getOccupancyReport("ALL");
        OccupancyReportSummary summary = dao.buildOccupancySummary(items, "All Facilities");

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        CsvExportUtil.exportOccupancyCsv(out, items, summary, "ALL");
        byte[] bytes = out.toByteArray();

        assertTrue("CSV Non-Empty", bytes.length > 100, "CSV bytes must be greater than 100");
        // Check UTF-8 BOM
        assertTrue("CSV UTF-8 BOM Present",
                (bytes[0] == (byte) 0xEF && bytes[1] == (byte) 0xBB && bytes[2] == (byte) 0xBF),
                "CSV must begin with UTF-8 BOM (0xEF, 0xBB, 0xBF)");

        String csvString = new String(bytes, StandardCharsets.UTF_8);
        assertTrue("CSV Header Present", csvString.contains("Real-Time Facility Occupancy Report"),
                "CSV must contain title header");
        assertTrue("CSV Contains Zone Data", csvString.contains("BLR-2"),
                "CSV must contain facility data");
    }

    private static void testReportsDateRangeExports() throws Exception {
        ReportDAO dao = new ReportDAO();
        List<OccupancyReportItem> items = dao.getOccupancyReport("ALL");
        OccupancyReportSummary summary = dao.buildOccupancySummary(items, "ALL", "2026-10-01", "2026-10-11");

        // 1. Occupancy CSV with date range
        ByteArrayOutputStream outCsv = new ByteArrayOutputStream();
        CsvExportUtil.exportOccupancyCsv(outCsv, items, summary, "ALL", "2026-10-01", "2026-10-11");
        String csvContent = new String(outCsv.toByteArray(), StandardCharsets.UTF_8);
        assertTrue("Occupancy CSV Date Range Header",
                csvContent.contains("Reporting Period: 2026-10-01 to 2026-10-11 (Through 23:59:59 IST)"),
                "CSV must state reporting period including end date through 23:59:59 IST");
        assertTrue("Occupancy CSV Ground Truth Disclaimer",
                csvContent.contains("Current bay capacity and physical availability reflect live sensor state"),
                "CSV must note that live availability reflects real-time truth");

        // 2. Booking CSV with date range
        ByteArrayOutputStream outBookCsv = new ByteArrayOutputStream();
        List<BookingReportItem> bookItems = dao.getBookingReport("ALL", "2026-10-01", "2026-10-11", "ALL");
        BookingReportSummary bookSummary = dao.buildBookingSummary(bookItems, "ALL", "ALL", "2026-10-01", "2026-10-11");
        CsvExportUtil.exportBookingCsv(outBookCsv, bookItems, bookSummary, "ALL", "2026-10-01", "2026-10-11", "ALL");
        String bookCsvContent = new String(outBookCsv.toByteArray(), StandardCharsets.UTF_8);
        assertTrue("Booking CSV Date Range Header",
                bookCsvContent.contains("Reporting Period: 2026-10-01 to 2026-10-11 (Through 23:59:59 IST)"),
                "Booking CSV must include full date range");

        // 3. Revenue CSV with date range
        ByteArrayOutputStream outRevCsv = new ByteArrayOutputStream();
        List<RevenueReportItem> revItems = dao.getRevenueReport("ALL", "2026-10-01", "2026-10-11");
        RevenueReportSummary revSummary = dao.buildRevenueSummary(revItems, "ALL", "2026-10-01", "2026-10-11");
        CsvExportUtil.exportRevenueCsv(outRevCsv, revItems, revSummary, "ALL", "2026-10-01", "2026-10-11");
        String revCsvContent = new String(outRevCsv.toByteArray(), StandardCharsets.UTF_8);
        assertTrue("Revenue CSV Date Range Header",
                revCsvContent.contains("Reporting Period: 2026-10-01 to 2026-10-11 (Through 23:59:59 IST)"),
                "Revenue CSV must include full date range");

        // 4. Occupancy PDF with date range
        ByteArrayOutputStream outPdf = new ByteArrayOutputStream();
        PdfExportUtil.exportOccupancyPdf(outPdf, items, summary, "ALL", "2026-10-01", "2026-10-11");
        byte[] pdfBytes = outPdf.toByteArray();
        assertTrue("Occupancy PDF with Date Range", pdfBytes.length > 2000,
                "PDF generated with date range must be valid");
    }

    private static void testPdfExportGeneration() throws Exception {
        ReportDAO dao = new ReportDAO();
        List<OccupancyReportItem> items = dao.getOccupancyReport("ALL");
        OccupancyReportSummary summary = dao.buildOccupancySummary(items, "All Facilities");

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        PdfExportUtil.exportOccupancyPdf(out, items, summary, "ALL");
        byte[] pdfBytes = out.toByteArray();

        assertTrue("PDF Bytes Generated", pdfBytes.length > 2000,
                "PDF output should be substantial (> 2KB), got " + pdfBytes.length);

        // Check PDF magic header %PDF-
        String magic = new String(pdfBytes, 0, 5, StandardCharsets.US_ASCII);
        assertTrue("PDF Magic Header", "%PDF-".equals(magic),
                "PDF byte stream must start with %PDF- header, got: " + magic);
    }

    private static void testRevenueExportEmptyScenario() throws Exception {
        ReportDAO dao = new ReportDAO();
        List<RevenueReportItem> revItems = dao.getRevenueReport("ALL", null, null);
        RevenueReportSummary summary = dao.buildRevenueSummary(revItems, "ALL", null, null);

        assertTrue("Empty Revenue Items List", revItems != null && revItems.isEmpty(),
                "Real database should currently contain 0 settled revenue transactions");
        assertTrue("Empty Revenue Summary Total", summary.getTotalRevenue() == 0.0,
                "Empty revenue summary total must be 0.0");
        assertTrue("Empty Revenue Transaction Count", summary.getTransactionCount() == 0,
                "Empty revenue summary transaction count must be 0");
        assertTrue("Empty Revenue Top Payment Method", "N/A".equals(summary.getTopPaymentMethod()),
                "Top payment method must be N/A when no transactions exist; got: " + summary.getTopPaymentMethod());

        // CSV Export Validation
        ByteArrayOutputStream outCsv = new ByteArrayOutputStream();
        CsvExportUtil.exportRevenueCsv(outCsv, revItems, summary, "ALL", null, null);
        byte[] csvBytes = outCsv.toByteArray();
        assertTrue("CSV BOM Present",
                (csvBytes[0] == (byte) 0xEF && csvBytes[1] == (byte) 0xBB && csvBytes[2] == (byte) 0xBF),
                "CSV must begin with UTF-8 BOM");
        String csv = new String(csvBytes, StandardCharsets.UTF_8);

        assertTrue("CSV Total Revenue Metric", csv.contains("Total Collected Revenue,₹0.00"),
                "CSV must show Total Collected Revenue,₹0.00");
        assertTrue("CSV Transaction Count Metric", csv.contains("Settled Transactions Count,0"),
                "CSV must show Settled Transactions Count,0");
        assertTrue("CSV Top Channel Metric", csv.contains("Top Payment Channel,N/A"),
                "CSV must show Top Payment Channel,N/A");
        assertTrue("CSV Ledger Status Section", csv.contains("TRANSACTION LEDGER STATUS"),
                "CSV must have separate status section outside transaction table");
        assertTrue("CSV Status Notice", csv.contains("Status,No settled payment records found matching the filter criteria."),
                "CSV must contain clear empty status notice");
        assertTrue("CSV Table Header", csv.contains("Transaction Ref,Payment ID,Booking ID,Driver Name"),
                "CSV must preserve consistent table header row");
        assertTrue("CSV No Fake Row", !csv.contains("Payment Timestamp (IST)\nNo settled payment records"),
                "CSV must not write empty message directly under header as a transaction row");
        assertTrue("CSV No Placeholder Total", !csv.contains("TOTAL COLLECTED,'--") && !csv.contains("TOTAL,0 Transactions"),
                "CSV must not have confusing placeholder total row when empty");

        // PDF Export Validation
        ByteArrayOutputStream outPdf = new ByteArrayOutputStream();
        PdfExportUtil.exportRevenuePdf(outPdf, revItems, summary, "ALL", null, null);
        byte[] pdfBytes = outPdf.toByteArray();
        assertTrue("PDF Magic Header (Empty State)", "%PDF-".equals(new String(pdfBytes, 0, 5, StandardCharsets.US_ASCII)),
                "PDF byte stream must start with %PDF- header");
        assertTrue("PDF Size Non-Trivial (Empty State)", pdfBytes.length > 2000,
                "PDF size should be greater than 2000 bytes");
    }

    private static void testRevenueExportNonEmptyScenario() throws Exception {
        ReportDAO dao = new ReportDAO();
        java.util.List<RevenueReportItem> mockItems = new java.util.ArrayList<>();

        RevenueReportItem r1 = new RevenueReportItem();
        r1.setPaymentId(9001);
        r1.setTransactionId("TXN_TEST_001");
        r1.setBookingId(8001);
        r1.setUserName("Karthik Driver");
        r1.setUserId("karthik");
        r1.setZoneId("BLR-2");
        r1.setZoneName("Electronic City");
        r1.setCityName("Bengaluru");
        r1.setSlotId("B-04");
        r1.setPaymentMethod("FASTAG");
        r1.setAmount(150.00);
        r1.setStatus("SUCCESS");
        r1.setPaymentTime(new java.sql.Timestamp(System.currentTimeMillis()));
        mockItems.add(r1);

        RevenueReportItem r2 = new RevenueReportItem();
        r2.setPaymentId(9002);
        r2.setTransactionId("TXN_TEST_002");
        r2.setBookingId(8002);
        r2.setUserName("Sarah Driver");
        r2.setUserId("sarah");
        r2.setZoneId("HYD-2");
        r2.setZoneName("Hitec City");
        r2.setCityName("Hyderabad");
        r2.setSlotId("H-08");
        r2.setPaymentMethod("UPI");
        r2.setAmount(250.00);
        r2.setStatus("SUCCESS");
        r2.setPaymentTime(new java.sql.Timestamp(System.currentTimeMillis()));
        mockItems.add(r2);

        RevenueReportItem r3 = new RevenueReportItem();
        r3.setPaymentId(9003);
        r3.setTransactionId("TXN_TEST_003");
        r3.setBookingId(8003);
        r3.setUserName("Amit Driver");
        r3.setUserId("amit");
        r3.setZoneId("BLR-2");
        r3.setZoneName("Electronic City");
        r3.setCityName("Bengaluru");
        r3.setSlotId("B-12");
        r3.setPaymentMethod("FASTAG");
        r3.setAmount(100.00);
        r3.setStatus("SUCCESS");
        r3.setPaymentTime(new java.sql.Timestamp(System.currentTimeMillis()));
        mockItems.add(r3);

        RevenueReportSummary summary = dao.buildRevenueSummary(mockItems, "ALL", "2026-10-01", "2026-10-11");
        assertTrue("Populated Total Revenue", Math.abs(summary.getTotalRevenue() - 500.00) < 0.001,
                "Total revenue must be 500.00; got: " + summary.getTotalRevenue());
        assertTrue("Populated Transaction Count", summary.getTransactionCount() == 3,
                "Transaction count must be 3; got: " + summary.getTransactionCount());
        assertTrue("Populated Top Payment Channel", "FASTAG".equalsIgnoreCase(summary.getTopPaymentMethod()),
                "Top payment channel must be FASTAG (2 txns vs 1 UPI); got: " + summary.getTopPaymentMethod());
        assertTrue("Populated Average Ticket", Math.abs(summary.getAverageTicket() - (500.0 / 3.0)) < 0.01,
                "Average ticket must match 500/3");

        // CSV Export Validation
        ByteArrayOutputStream outCsv = new ByteArrayOutputStream();
        CsvExportUtil.exportRevenueCsv(outCsv, mockItems, summary, "ALL", "2026-10-01", "2026-10-11");
        String csv = new String(outCsv.toByteArray(), StandardCharsets.UTF_8);

        assertTrue("Populated CSV Total Revenue", csv.contains("Total Collected Revenue,₹500.00"),
                "CSV must show Total Collected Revenue,₹500.00");
        assertTrue("Populated CSV Transaction Count", csv.contains("Settled Transactions Count,3"),
                "CSV must show Settled Transactions Count,3");
        assertTrue("Populated CSV Top Channel", csv.contains("Top Payment Channel,FASTAG"),
                "CSV must show Top Payment Channel,FASTAG");
        assertTrue("Populated CSV Channel Breakdown", csv.contains("PAYMENT CHANNEL BREAKDOWN"),
                "CSV must show channel breakdown when transactions exist");
        assertTrue("Populated CSV Data Row 1", csv.contains("TXN_TEST_001") && csv.contains("FASTAG"),
                "CSV must contain first transaction row");
        assertTrue("Populated CSV Data Row 2", csv.contains("TXN_TEST_002") && csv.contains("UPI"),
                "CSV must contain second transaction row");
        assertTrue("Populated CSV Clean Total Row", csv.contains("TOTAL,3 Transactions,,,,,,,,500.00,SUCCESS,"),
                "CSV must contain clean totals row matching schema without '--' placeholders");
        assertTrue("Populated CSV No Empty Notice", !csv.contains("TRANSACTION LEDGER STATUS"),
                "CSV must not display empty status notice when transactions exist");

        // PDF Export Validation
        ByteArrayOutputStream outPdf = new ByteArrayOutputStream();
        PdfExportUtil.exportRevenuePdf(outPdf, mockItems, summary, "ALL", "2026-10-01", "2026-10-11");
        byte[] pdfBytes = outPdf.toByteArray();
        assertTrue("Populated PDF Magic Header", "%PDF-".equals(new String(pdfBytes, 0, 5, StandardCharsets.US_ASCII)),
                "Populated PDF must begin with %PDF-");
        assertTrue("Populated PDF Non-Trivial", pdfBytes.length > 2500,
                "Populated PDF size must be greater than 2500 bytes");

        // Persist populated PDF for visual inspection
        java.io.File popPdf = new java.io.File("scratch_populated_rev.pdf");
        try (java.io.FileOutputStream fos = new java.io.FileOutputStream(popPdf)) {
            fos.write(pdfBytes);
        }
    }
}
