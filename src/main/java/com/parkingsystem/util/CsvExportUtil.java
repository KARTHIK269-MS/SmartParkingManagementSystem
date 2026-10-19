package com.parkingsystem.util;

import com.parkingsystem.model.*;

import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Utility for streaming clean, standards-compliant CSV reports.
 * Implements RFC 4180 escaping, UTF-8 BOM encoding for Excel,
 * and comprehensive CSV Formula Injection Prevention (CWE-1236).
 */
public class CsvExportUtil {

    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("dd-MM-yyyy HH:mm:ss");

    /**
     * Sanitizes and escapes a CSV cell value:
     * 1. Formula Injection Mitigation: If cell begins with =, +, -, @, \t, or \r, prepend a single quote (').
     * 2. RFC 4180 Escaping: If cell contains comma, quote, or newline, wrap in quotes and escape internal quotes.
     */
    public static String escapeCsv(String value) {
        if (value == null) {
            return "";
        }
        String clean = value.trim();
        if (!clean.isEmpty()) {
            char first = clean.charAt(0);
            if (first == '=' || first == '+' || first == '-' || first == '@' || first == '\t' || first == '\r') {
                clean = "'" + clean;
            }
        }
        if (clean.contains(",") || clean.contains("\"") || clean.contains("\n") || clean.contains("\r")) {
            return "\"" + clean.replace("\"", "\"\"") + "\"";
        }
        return clean;
    }

    /**
     * Exports the Real-Time Occupancy Report to CSV.
     */
    public static void exportOccupancyCsv(OutputStream out, List<OccupancyReportItem> items,
                                          OccupancyReportSummary summary, String filterZone) throws IOException {
        exportOccupancyCsv(out, items, summary, filterZone, null, null);
    }

    /**
     * Exports the Real-Time Occupancy Report to CSV with date range / reporting period.
     */
    public static void exportOccupancyCsv(OutputStream out, List<OccupancyReportItem> items,
                                          OccupancyReportSummary summary, String filterZone,
                                          String startDate, String endDate) throws IOException {
        // Write UTF-8 BOM (\uFEFF)
        out.write(0xEF);
        out.write(0xBB);
        out.write(0xBF);

        PrintWriter writer = new PrintWriter(new OutputStreamWriter(out, StandardCharsets.UTF_8));
        String genTime = DATE_FORMAT.format(new Date()) + " IST (UTC+05:30)";

        String facFilter = (filterZone != null && !filterZone.isEmpty() && !"ALL".equalsIgnoreCase(filterZone)) ? ("Zone " + filterZone) : "All Facilities";
        String dateFilterDesc = ((startDate != null && !startDate.isEmpty()) ? startDate : "All Time") +
                " to " + ((endDate != null && !endDate.isEmpty()) ? endDate + " (Through 23:59:59 IST)" : "Present");

        // Metadata Header
        writer.println(escapeCsv("SmartParking Management System — Real-Time Facility Occupancy Report"));
        writer.println(escapeCsv("Generated At: " + genTime) + "," + escapeCsv("Scope: Administrative Supervisory Ledger"));
        writer.println(escapeCsv("Facility Filter: " + facFilter));
        writer.println(escapeCsv("Reporting Period: " + dateFilterDesc));
        writer.println(escapeCsv("Data Source: Monitored Physical Bays in MySQL (Real-Time Sensor Truth)"));
        writer.println(escapeCsv("Note: Current bay capacity and physical availability reflect live sensor state; historical records are logged separately."));
        writer.println();

        // Summary KPI Metrics
        writer.println(escapeCsv("EXECUTIVE SUMMARY METRICS"));
        writer.println(escapeCsv("Monitored Facilities") + "," + summary.getTotalFacilities());
        writer.println(escapeCsv("Total Parking Capacity") + "," + summary.getTotalBays() + " Bays");
        writer.println(escapeCsv("Currently Available Bays") + "," + summary.getAvailableBays());
        writer.println(escapeCsv("Currently Occupied Bays") + "," + summary.getOccupiedBays());
        writer.println(escapeCsv("Reserved Bays (Awaiting Arrival)") + "," + summary.getReservedBays());
        writer.println(escapeCsv("Blocked / Maintenance Bays") + "," + summary.getBlockedBays());
        writer.println(escapeCsv("Overall Parked Occupancy %") + "," + String.format("%.2f%%", summary.getOverallOccupancyRate()));
        writer.println(escapeCsv("Overall Active Demand % (Parked + Reserved)") + "," + String.format("%.2f%%", summary.getOverallActiveRate()));
        writer.println();

        // Data Table Headers
        writer.println(String.join(",",
                escapeCsv("Zone ID"),
                escapeCsv("Facility Name"),
                escapeCsv("Metro Corridor"),
                escapeCsv("Location"),
                escapeCsv("Total Bays"),
                escapeCsv("Available Bays"),
                escapeCsv("Occupied Bays"),
                escapeCsv("Reserved Bays"),
                escapeCsv("Blocked / Maint"),
                escapeCsv("Parked Occupancy %"),
                escapeCsv("Active Demand %")
        ));

        // Data Rows
        if (items != null && !items.isEmpty()) {
            for (OccupancyReportItem item : items) {
                writer.println(String.join(",",
                        escapeCsv(item.getZoneId()),
                        escapeCsv(item.getZoneName()),
                        escapeCsv(item.getCity()),
                        escapeCsv(item.getLocation()),
                        String.valueOf(item.getTotalSlots()),
                        String.valueOf(item.getAvailableSlots()),
                        String.valueOf(item.getOccupiedSlots()),
                        String.valueOf(item.getReservedSlots()),
                        String.valueOf(item.getBlockedSlots()),
                        String.format("%.2f%%", item.getOccupancyRate()),
                        String.format("%.2f%%", item.getActiveRate())
                ));
            }
        } else {
            writer.println(escapeCsv("No facility records found matching the filter criteria."));
        }

        // Table Totals
        writer.println();
        writer.println(String.join(",",
                escapeCsv("TOTAL"),
                escapeCsv("All Selected Facilities"),
                escapeCsv("--"),
                escapeCsv("--"),
                String.valueOf(summary.getTotalBays()),
                String.valueOf(summary.getAvailableBays()),
                String.valueOf(summary.getOccupiedBays()),
                String.valueOf(summary.getReservedBays()),
                String.valueOf(summary.getBlockedBays()),
                String.format("%.2f%%", summary.getOverallOccupancyRate()),
                String.format("%.2f%%", summary.getOverallActiveRate())
        ));

        writer.flush();
    }

    /**
     * Exports the Booking Report to CSV.
     */
    /**
     * Exports the Booking Report to CSV.
     * Supports both parameter orders: (..., startDate, endDate, filterStatus) and (..., filterStatus, startDate, endDate).
     */
    public static void exportBookingCsv(OutputStream out, List<BookingReportItem> items,
                                        BookingReportSummary summary, String filterZone,
                                        String arg5, String arg6, String arg7) throws IOException {
        String startDate;
        String endDate;
        String filterStatus;
        if (arg5 != null && arg5.matches("^\\d{4}-\\d{2}-\\d{2}$")) {
            startDate = arg5;
            endDate = arg6;
            filterStatus = arg7;
        } else if (arg7 != null && arg7.matches("^\\d{4}-\\d{2}-\\d{2}$")) {
            filterStatus = arg5;
            startDate = arg6;
            endDate = arg7;
        } else {
            startDate = arg5;
            endDate = arg6;
            filterStatus = arg7;
        }

        out.write(0xEF);
        out.write(0xBB);
        out.write(0xBF);

        PrintWriter writer = new PrintWriter(new OutputStreamWriter(out, StandardCharsets.UTF_8));
        String genTime = DATE_FORMAT.format(new Date()) + " IST (UTC+05:30)";

        String facFilter = (filterZone != null && !filterZone.isEmpty() && !"ALL".equalsIgnoreCase(filterZone)) ? ("Zone " + filterZone) : "All Facilities";
        String dateFilterDesc = ((startDate != null && !startDate.isEmpty()) ? startDate : "All Time") +
                " to " + ((endDate != null && !endDate.isEmpty()) ? endDate + " (Through 23:59:59 IST)" : "Present");

        // Metadata Header
        writer.println(escapeCsv("SmartParking Management System — Driver Bookings Ledger Report"));
        writer.println(escapeCsv("Generated At: " + genTime) + "," + escapeCsv("Timezone: IST (Asia/Kolkata)"));
        writer.println(escapeCsv("Facility Filter: " + facFilter));
        writer.println(escapeCsv("Reporting Period: " + dateFilterDesc));
        writer.println(escapeCsv("Status Filter: " + (summary != null ? summary.getFilterStatus() : (filterStatus != null ? filterStatus : "ALL"))));
        writer.println();

        // Summary KPI Metrics
        writer.println(escapeCsv("BOOKINGS SUMMARY METRICS"));
        writer.println(escapeCsv("Total Matching Records") + "," + summary.getTotalBookings());
        writer.println(escapeCsv("Completed Bookings") + "," + summary.getCompletedCount());
        writer.println(escapeCsv("Active Parking Sessions") + "," + summary.getActiveCount());
        writer.println(escapeCsv("Reserved (Awaiting Arrival)") + "," + summary.getReservedCount());
        writer.println(escapeCsv("Confirmed Bookings") + "," + summary.getConfirmedCount());
        writer.println(escapeCsv("Cancelled Bookings") + "," + summary.getCancelledCount());
        writer.println(escapeCsv("Pending Settlements") + "," + summary.getPendingCount());
        writer.println(escapeCsv("Total Billed Amount") + "," + String.format("INR %.2f", summary.getTotalAmount()));
        writer.println();

        // Data Table Headers
        writer.println(String.join(",",
                escapeCsv("Booking ID"),
                escapeCsv("Driver Name"),
                escapeCsv("User ID"),
                escapeCsv("Driver Email"),
                escapeCsv("Vehicle VRN"),
                escapeCsv("Facility & Zone"),
                escapeCsv("Allocated Bay"),
                escapeCsv("Duration (Hrs)"),
                escapeCsv("Total Amount (INR)"),
                escapeCsv("Status"),
                escapeCsv("Booking Date & Time (IST)"),
                escapeCsv("Check-in Time (IST)"),
                escapeCsv("Checkout Time (IST)"),
                escapeCsv("Transaction ID")
        ));

        // Data Rows
        SimpleDateFormat rowDf = new SimpleDateFormat("dd-MM-yyyy HH:mm");
        if (items != null && !items.isEmpty()) {
            for (BookingReportItem b : items) {
                writer.println(String.join(",",
                        "#" + b.getBookingId(),
                        escapeCsv(b.getUserName()),
                        escapeCsv(b.getUserId()),
                        escapeCsv(b.getUserEmail()),
                        escapeCsv(b.getVehicleNumber()),
                        escapeCsv("Zone " + b.getZoneId() + " - " + b.getZoneName()),
                        escapeCsv(b.getSlotId()),
                        String.valueOf(b.getDurationHours()),
                        String.format("%.2f", b.getTotalAmount()),
                        escapeCsv(b.getStatus()),
                        b.getBookingTime() != null ? escapeCsv(rowDf.format(b.getBookingTime())) : "--",
                        b.getEntryTime() != null ? escapeCsv(rowDf.format(b.getEntryTime())) : "--",
                        b.getExitTime() != null ? escapeCsv(rowDf.format(b.getExitTime())) : "--",
                        escapeCsv(b.getPaymentId() != null ? b.getPaymentId() : "--")
                ));
            }
        } else {
            writer.println(escapeCsv("No booking records found matching the filter criteria."));
        }

        // Totals Footer
        writer.println();
        writer.println(String.join(",",
                escapeCsv("TOTAL"),
                escapeCsv(summary.getTotalBookings() + " Bookings"),
                escapeCsv("--"),
                escapeCsv("--"),
                escapeCsv("--"),
                escapeCsv("--"),
                escapeCsv("--"),
                escapeCsv("--"),
                String.format("%.2f", summary.getTotalAmount()),
                escapeCsv("--"),
                escapeCsv("--"),
                escapeCsv("--"),
                escapeCsv("--"),
                escapeCsv("--")
        ));

        writer.flush();
    }

    /**
     * Exports the Settled Revenue Report to CSV.
     */
    public static void exportRevenueCsv(OutputStream out, List<RevenueReportItem> items,
                                        RevenueReportSummary summary, String filterZone,
                                        String startDate, String endDate) throws IOException {
        out.write(0xEF);
        out.write(0xBB);
        out.write(0xBF);

        PrintWriter writer = new PrintWriter(new OutputStreamWriter(out, StandardCharsets.UTF_8));
        String genTime = DATE_FORMAT.format(new Date()) + " IST (UTC+05:30)";

        String facFilter = (filterZone != null && !filterZone.isEmpty() && !"ALL".equalsIgnoreCase(filterZone)) ? ("Zone " + filterZone) : "All Facilities";
        String dateFilterDesc = ((startDate != null && !startDate.isEmpty()) ? startDate : "All Time") +
                " to " + ((endDate != null && !endDate.isEmpty()) ? endDate + " (Through 23:59:59 IST)" : "Present");

        double totalRevenue = summary != null ? summary.getTotalRevenue() : 0.0;
        int txnCount = summary != null ? summary.getTransactionCount() : 0;
        double avgTicket = summary != null ? summary.getAverageTicket() : 0.0;
        String topMethod = (summary != null && txnCount > 0 &&
                summary.getTopPaymentMethod() != null && !summary.getTopPaymentMethod().trim().isEmpty() &&
                !"--".equals(summary.getTopPaymentMethod().trim())) ? summary.getTopPaymentMethod().trim() : "N/A";

        // Section 1: Report Metadata & Parameters (Clean Key-Value Layout for Excel)
        writer.println(escapeCsv("SmartParking Management System - Verified Settled Revenue Report"));
        writer.println(escapeCsv("Generated At: " + genTime) + "," + escapeCsv("Currency: INR (₹)"));
        writer.println(escapeCsv("Facility Filter: " + facFilter));
        writer.println(escapeCsv("Reporting Period: " + dateFilterDesc));
        writer.println(escapeCsv("Revenue Definition: Strictly comprises verified settled transactions (status = 'SUCCESS') in MySQL payments ledger. Pending, unbilled, and cancelled sessions are strictly excluded."));
        writer.println();

        // Section 2: Executive Summary Metrics (Clear Separation)
        writer.println(escapeCsv("EXECUTIVE REVENUE METRICS"));
        writer.println(escapeCsv("Total Collected Revenue") + "," + String.format(Locale.US, "₹%.2f", totalRevenue));
        writer.println(escapeCsv("Settled Transactions Count") + "," + txnCount);
        writer.println(escapeCsv("Average Ticket Value") + "," + String.format(Locale.US, "₹%.2f", avgTicket));
        writer.println(escapeCsv("Top Payment Channel") + "," + escapeCsv(topMethod));
        writer.println();

        // Section 3: Payment Channel Breakdown (only when genuine transactions exist)
        if (summary != null && summary.getMethodBreakdown() != null && !summary.getMethodBreakdown().isEmpty() && txnCount > 0) {
            writer.println(escapeCsv("PAYMENT CHANNEL BREAKDOWN"));
            writer.println(escapeCsv("Channel") + "," + escapeCsv("Transaction Count") + "," + escapeCsv("Settled Revenue (INR)"));
            for (Map.Entry<String, Double> e : summary.getMethodBreakdown().entrySet()) {
                int cnt = summary.getMethodCountBreakdown().getOrDefault(e.getKey(), 0);
                writer.println(escapeCsv(e.getKey()) + "," + cnt + "," + String.format(Locale.US, "%.2f", e.getValue()));
            }
            writer.println();
        }

        // Section 4: Empty-State Status Notice (outside transaction data table)
        if (items == null || items.isEmpty()) {
            writer.println(escapeCsv("TRANSACTION LEDGER STATUS"));
            writer.println(escapeCsv("Status") + "," + escapeCsv("No settled payment records found matching the filter criteria."));
            writer.println(escapeCsv("Audited Total") + "," + escapeCsv("Total collected revenue is ₹0.00 across 0 transactions."));
            writer.println();
        }

        // Section 5: Consistent Transaction Table Headers
        writer.println(String.join(",",
                escapeCsv("Transaction Ref"),
                escapeCsv("Payment ID"),
                escapeCsv("Booking ID"),
                escapeCsv("Driver Name"),
                escapeCsv("User ID"),
                escapeCsv("Facility & Zone"),
                escapeCsv("Metro City"),
                escapeCsv("Allocated Bay"),
                escapeCsv("Payment Channel"),
                escapeCsv("Settled Amount (INR)"),
                escapeCsv("Status"),
                escapeCsv("Payment Timestamp (IST)")
        ));

        // Section 6: Data Rows (Only genuine transaction rows when present)
        SimpleDateFormat rowDf = new SimpleDateFormat("dd-MM-yyyy HH:mm");
        if (items != null && !items.isEmpty()) {
            for (RevenueReportItem r : items) {
                writer.println(String.join(",",
                        escapeCsv(r.getTransactionId()),
                        String.valueOf(r.getPaymentId()),
                        "#" + r.getBookingId(),
                        escapeCsv(r.getUserName()),
                        escapeCsv(r.getUserId()),
                        escapeCsv("Zone " + r.getZoneId() + " - " + r.getZoneName()),
                        escapeCsv(r.getCityName()),
                        escapeCsv(r.getSlotId()),
                        escapeCsv(r.getPaymentMethod()),
                        String.format(Locale.US, "%.2f", r.getAmount()),
                        escapeCsv(r.getStatus()),
                        r.getPaymentTime() != null ? escapeCsv(rowDf.format(r.getPaymentTime())) : "--"
                ));
            }

            // Clean Totals Footer Row (no confusing '--' placeholders)
            writer.println();
            writer.println(String.join(",",
                    escapeCsv("TOTAL"),
                    escapeCsv(txnCount + " Transactions"),
                    "", "", "", "", "", "", "",
                    String.format(Locale.US, "%.2f", totalRevenue),
                    escapeCsv("SUCCESS"),
                    ""
            ));
        }

        writer.flush();
    }
}
