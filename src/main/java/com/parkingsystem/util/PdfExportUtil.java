package com.parkingsystem.util;

import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import com.parkingsystem.model.*;

import java.awt.Color;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

/**
 * Utility for streaming high-fidelity, printable PDF reports using OpenPDF.
 * Implements professional styling, consistent color palette, responsive table layouts,
 * KPI summary headers, running footers with page numbers, and IST timezone labeling.
 */
public class PdfExportUtil {

    private static final SimpleDateFormat TIMESTAMP_FORMAT = new SimpleDateFormat("dd-MM-yyyy HH:mm:ss");
    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("dd-MM-yyyy HH:mm");

    // Corporate Color Palette (Matching SmartParking Admin UI)
    private static final Color COLOR_PRIMARY = new Color(15, 23, 42);      // #0f172a (Deep Slate)
    private static final Color COLOR_ACCENT = new Color(37, 99, 235);      // #2563eb (Royal Blue)
    private static final Color COLOR_HEADER_BG = new Color(30, 41, 59);    // #1e293b (Header BG)
    private static final Color COLOR_ROW_ALT = new Color(248, 250, 252);   // #f8fafc (Zebra Stripe)
    private static final Color COLOR_BORDER = new Color(226, 232, 240);    // #e2e8f0 (Border)
    private static final Color COLOR_TEXT_MUTED = new Color(100, 116, 139);// #64748b (Slate Muted)
    private static final Color COLOR_GREEN = new Color(5, 150, 105);       // #059669 (Emerald)
    private static final Color COLOR_AMBER = new Color(217, 119, 6);       // #d97706 (Amber)

    // Standard Typography
    private static BaseFont UNICODE_BASE_FONT;
    static {
        try {
            File arial = new File("C:/Windows/Fonts/arial.ttf");
            if (arial.exists()) {
                UNICODE_BASE_FONT = BaseFont.createFont(arial.getAbsolutePath(), BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
            }
        } catch (Exception ignored) {}
    }

    private static Font getFont(float size, int style, Color color) {
        if (UNICODE_BASE_FONT != null) {
            return new Font(UNICODE_BASE_FONT, size, style, color);
        }
        return FontFactory.getFont(FontFactory.HELVETICA, size, style, color);
    }

    public static String formatCurrency(double amount) {
        return String.format(Locale.US, "₹%.2f", amount);
    }

    private static final Font FONT_TITLE = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 15, COLOR_PRIMARY);
    private static final Font FONT_SUBTITLE = FontFactory.getFont(FontFactory.HELVETICA, 8.5f, COLOR_TEXT_MUTED);
    private static final Font FONT_SECTION = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, COLOR_PRIMARY);
    private static final Font FONT_TH = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, Color.WHITE);
    private static final Font FONT_TD = FontFactory.getFont(FontFactory.HELVETICA, 8, Color.BLACK);
    private static final Font FONT_TD_BOLD = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, Color.BLACK);
    private static final Font FONT_FOOTER = FontFactory.getFont(FontFactory.HELVETICA, 7, COLOR_TEXT_MUTED);

    /**
     * Page Event Helper for running footer and page numbers.
     */
    private static class HeaderFooterPageEvent extends PdfPageEventHelper {
        private final String reportTitle;

        public HeaderFooterPageEvent(String reportTitle) {
            this.reportTitle = reportTitle;
        }

        @Override
        public void onEndPage(PdfWriter writer, Document document) {
            PdfPTable footer = new PdfPTable(2);
            footer.setTotalWidth(document.right() - document.left());
            footer.getDefaultCell().setBorder(Rectangle.NO_BORDER);

            PdfPCell cellLeft = new PdfPCell(new Phrase("SmartParking Console - " + reportTitle + " (Confidential)", FONT_FOOTER));
            cellLeft.setBorder(Rectangle.TOP);
            cellLeft.setBorderColor(COLOR_BORDER);
            cellLeft.setPaddingTop(4f);

            PdfPCell cellRight = new PdfPCell(new Phrase("Page " + writer.getPageNumber() + " | IST (UTC+05:30)", FONT_FOOTER));
            cellRight.setBorder(Rectangle.TOP);
            cellRight.setBorderColor(COLOR_BORDER);
            cellRight.setHorizontalAlignment(Element.ALIGN_RIGHT);
            cellRight.setPaddingTop(4f);

            footer.addCell(cellLeft);
            footer.addCell(cellRight);

            footer.writeSelectedRows(0, -1, document.left(), document.bottom() - 10, writer.getDirectContent());
        }
    }

    /**
     * Exports the Real-Time Occupancy Report to PDF (Landscape A4).
     */
    public static void exportOccupancyPdf(OutputStream out, List<OccupancyReportItem> items,
                                          OccupancyReportSummary summary, String filterZone) throws DocumentException, IOException {
        exportOccupancyPdf(out, items, summary, filterZone, null, null);
    }

    /**
     * Exports the Real-Time Occupancy Report to PDF with date range / reporting period.
     */
    public static void exportOccupancyPdf(OutputStream out, List<OccupancyReportItem> items,
                                          OccupancyReportSummary summary, String filterZone,
                                          String startDate, String endDate) throws DocumentException, IOException {
        Document document = new Document(PageSize.A4.rotate(), 30, 30, 35, 35);
        PdfWriter writer = PdfWriter.getInstance(document, out);
        writer.setPageEvent(new HeaderFooterPageEvent("Real-Time Occupancy Report"));
        document.open();

        String facFilter = (filterZone != null && !filterZone.isEmpty() && !"ALL".equalsIgnoreCase(filterZone)) ? ("Zone " + filterZone) : "All Facilities";
        String dateFilterDesc = ((startDate != null && !startDate.isEmpty()) ? startDate : "All Time") +
                " to " + ((endDate != null && !endDate.isEmpty()) ? endDate + " (Through 23:59:59 IST)" : "Present");

        // 1. Report Header
        addReportHeader(document, "Real-Time Facility Occupancy Report",
                "Monitored Physical Bays in MySQL (Real-Time Sensor Truth) — Live bay availability is never fabricated for past dates",
                "Facility: " + facFilter + "  |  Reporting Period: " + dateFilterDesc);

        // 2. KPI Summary Banner Box
        PdfPTable kpiTable = new PdfPTable(6);
        kpiTable.setWidthPercentage(100);
        kpiTable.setSpacingBefore(8f);
        kpiTable.setSpacingAfter(12f);

        addKpiCell(kpiTable, "Total Capacity", summary.getTotalBays() + " Bays", COLOR_PRIMARY);
        addKpiCell(kpiTable, "Available Bays", String.valueOf(summary.getAvailableBays()), COLOR_GREEN);
        addKpiCell(kpiTable, "Occupied Bays", String.valueOf(summary.getOccupiedBays()), COLOR_PRIMARY);
        addKpiCell(kpiTable, "Reserved (Grace)", String.valueOf(summary.getReservedBays()), COLOR_AMBER);
        addKpiCell(kpiTable, "Blocked / Maint", String.valueOf(summary.getBlockedBays()), COLOR_TEXT_MUTED);
        addKpiCell(kpiTable, "Parked Occupancy", String.format("%.1f%%", summary.getOverallOccupancyRate()), COLOR_ACCENT);

        document.add(kpiTable);

        // 3. Data Table
        float[] columnWidths = {6f, 22f, 12f, 24f, 8f, 8f, 8f, 8f, 8f, 10f, 10f};
        PdfPTable table = new PdfPTable(columnWidths);
        table.setWidthPercentage(100);
        table.setHeaderRows(1);

        String[] headers = {
                "Zone", "Facility Name", "City", "Location Address",
                "Total", "Avail", "Occ", "Res", "Blk", "Parked %", "Active %"
        };
        for (String h : headers) {
            PdfPCell cell = new PdfPCell(new Phrase(h, FONT_TH));
            cell.setBackgroundColor(COLOR_HEADER_BG);
            cell.setPadding(5f);
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setBorderColor(COLOR_BORDER);
            table.addCell(cell);
        }

        if (items != null && !items.isEmpty()) {
            boolean alt = false;
            for (OccupancyReportItem item : items) {
                Color rowBg = alt ? COLOR_ROW_ALT : Color.WHITE;
                alt = !alt;

                addCell(table, item.getZoneId(), FONT_TD_BOLD, rowBg, Element.ALIGN_CENTER);
                addCell(table, item.getZoneName(), FONT_TD, rowBg, Element.ALIGN_LEFT);
                addCell(table, item.getCity(), FONT_TD, rowBg, Element.ALIGN_LEFT);
                addCell(table, item.getLocation(), FONT_TD, rowBg, Element.ALIGN_LEFT);
                addCell(table, String.valueOf(item.getTotalSlots()), FONT_TD_BOLD, rowBg, Element.ALIGN_RIGHT);
                addCell(table, String.valueOf(item.getAvailableSlots()), FONT_TD, rowBg, Element.ALIGN_RIGHT);
                addCell(table, String.valueOf(item.getOccupiedSlots()), FONT_TD, rowBg, Element.ALIGN_RIGHT);
                addCell(table, String.valueOf(item.getReservedSlots()), FONT_TD, rowBg, Element.ALIGN_RIGHT);
                addCell(table, String.valueOf(item.getBlockedSlots()), FONT_TD, rowBg, Element.ALIGN_RIGHT);
                addCell(table, String.format("%.1f%%", item.getOccupancyRate()), FONT_TD_BOLD, rowBg, Element.ALIGN_RIGHT);
                addCell(table, String.format("%.1f%%", item.getActiveRate()), FONT_TD, rowBg, Element.ALIGN_RIGHT);
            }
        } else {
            PdfPCell emptyCell = new PdfPCell(new Phrase("No facility records found for the selected filter.", FONT_TD));
            emptyCell.setColspan(11);
            emptyCell.setPadding(12f);
            emptyCell.setHorizontalAlignment(Element.ALIGN_CENTER);
            table.addCell(emptyCell);
        }

        // Totals Footer Row
        Color totalsBg = new Color(241, 245, 249);
        addCell(table, "TOTAL", FONT_TD_BOLD, totalsBg, Element.ALIGN_CENTER);
        addCell(table, summary.getTotalFacilities() + " Facilities", FONT_TD_BOLD, totalsBg, Element.ALIGN_LEFT);
        addCell(table, "--", FONT_TD, totalsBg, Element.ALIGN_CENTER);
        addCell(table, "--", FONT_TD, totalsBg, Element.ALIGN_CENTER);
        addCell(table, String.valueOf(summary.getTotalBays()), FONT_TD_BOLD, totalsBg, Element.ALIGN_RIGHT);
        addCell(table, String.valueOf(summary.getAvailableBays()), FONT_TD_BOLD, totalsBg, Element.ALIGN_RIGHT);
        addCell(table, String.valueOf(summary.getOccupiedBays()), FONT_TD_BOLD, totalsBg, Element.ALIGN_RIGHT);
        addCell(table, String.valueOf(summary.getReservedBays()), FONT_TD_BOLD, totalsBg, Element.ALIGN_RIGHT);
        addCell(table, String.valueOf(summary.getBlockedBays()), FONT_TD_BOLD, totalsBg, Element.ALIGN_RIGHT);
        addCell(table, String.format("%.1f%%", summary.getOverallOccupancyRate()), FONT_TD_BOLD, totalsBg, Element.ALIGN_RIGHT);
        addCell(table, String.format("%.1f%%", summary.getOverallActiveRate()), FONT_TD_BOLD, totalsBg, Element.ALIGN_RIGHT);

        document.add(table);
        document.close();
    }

    /**
     * Exports the Booking Report to PDF (Landscape A4).
     * Supports both parameter orders: (..., startDate, endDate, filterStatus) and (..., filterStatus, startDate, endDate).
     */
    public static void exportBookingPdf(OutputStream out, List<BookingReportItem> items,
                                        BookingReportSummary summary, String filterZone,
                                        String arg5, String arg6, String arg7) throws DocumentException, IOException {
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

        Document document = new Document(PageSize.A4.rotate(), 25, 25, 35, 35);
        PdfWriter writer = PdfWriter.getInstance(document, out);
        writer.setPageEvent(new HeaderFooterPageEvent("Driver Bookings Ledger Report"));
        document.open();

        String facFilter = (filterZone != null && !filterZone.isEmpty() && !"ALL".equalsIgnoreCase(filterZone)) ? ("Zone " + filterZone) : "All Facilities";
        String dateFilterDesc = ((startDate != null && !startDate.isEmpty()) ? startDate : "All Time") +
                " to " + ((endDate != null && !endDate.isEmpty()) ? endDate + " (Through 23:59:59 IST)" : "Present");

        addReportHeader(document, "Driver Bookings Ledger & Sessions Report",
                "Historical & Active Parking Transactions from MySQL Database",
                "Facility: " + facFilter + "  |  Reporting Period: " + dateFilterDesc + "  |  Status: " + (summary != null ? summary.getFilterStatus() : (filterStatus != null ? filterStatus : "ALL")));

        // Summary KPI Box
        PdfPTable kpiTable = new PdfPTable(5);
        kpiTable.setWidthPercentage(100);
        kpiTable.setSpacingBefore(8f);
        kpiTable.setSpacingAfter(12f);

        addKpiCell(kpiTable, "Total Bookings", String.valueOf(summary.getTotalBookings()), COLOR_PRIMARY);
        addKpiCell(kpiTable, "Completed / Paid", String.valueOf(summary.getCompletedCount()), COLOR_GREEN);
        addKpiCell(kpiTable, "Active Sessions", String.valueOf(summary.getActiveCount()), COLOR_ACCENT);
        addKpiCell(kpiTable, "Cancelled", String.valueOf(summary.getCancelledCount()), COLOR_TEXT_MUTED);
        addKpiCell(kpiTable, "Total Billed Amount", String.format("INR %.2f", summary.getTotalAmount()), COLOR_PRIMARY);

        document.add(kpiTable);

        // Data Table
        float[] columnWidths = {8f, 15f, 13f, 18f, 8f, 8f, 11f, 11f, 12f, 10f, 14f};
        PdfPTable table = new PdfPTable(columnWidths);
        table.setWidthPercentage(100);
        table.setHeaderRows(1);

        String[] headers = {
                "Ref #", "Driver Name", "Vehicle VRN", "Facility & Zone",
                "Bay", "Hours", "Total (INR)", "Status", "Booking Time", "Entry Time", "Transaction ID"
        };
        for (String h : headers) {
            PdfPCell cell = new PdfPCell(new Phrase(h, FONT_TH));
            cell.setBackgroundColor(COLOR_HEADER_BG);
            cell.setPadding(5f);
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setBorderColor(COLOR_BORDER);
            table.addCell(cell);
        }

        if (items != null && !items.isEmpty()) {
            boolean alt = false;
            for (BookingReportItem b : items) {
                Color rowBg = alt ? COLOR_ROW_ALT : Color.WHITE;
                alt = !alt;

                addCell(table, "#" + b.getBookingId(), FONT_TD_BOLD, rowBg, Element.ALIGN_CENTER);
                addCell(table, b.getUserName() != null ? b.getUserName() : b.getUserId(), FONT_TD, rowBg, Element.ALIGN_LEFT);
                addCell(table, b.getVehicleNumber(), FONT_TD_BOLD, rowBg, Element.ALIGN_CENTER);
                addCell(table, "Zone " + b.getZoneId(), FONT_TD, rowBg, Element.ALIGN_LEFT);
                addCell(table, b.getSlotId(), FONT_TD_BOLD, rowBg, Element.ALIGN_CENTER);
                addCell(table, String.valueOf(b.getDurationHours()) + "h", FONT_TD, rowBg, Element.ALIGN_CENTER);
                addCell(table, String.format("%.2f", b.getTotalAmount()), FONT_TD_BOLD, rowBg, Element.ALIGN_RIGHT);
                addCell(table, b.getStatus(), FONT_TD, rowBg, Element.ALIGN_CENTER);
                addCell(table, b.getBookingTime() != null ? DATE_FORMAT.format(b.getBookingTime()) : "--", FONT_TD, rowBg, Element.ALIGN_CENTER);
                addCell(table, b.getEntryTime() != null ? DATE_FORMAT.format(b.getEntryTime()) : "--", FONT_TD, rowBg, Element.ALIGN_CENTER);
                addCell(table, b.getPaymentId() != null ? b.getPaymentId() : "--", FONT_TD, rowBg, Element.ALIGN_LEFT);
            }
        } else {
            PdfPCell emptyCell = new PdfPCell(new Phrase("No booking records found for the selected filters.", FONT_TD));
            emptyCell.setColspan(11);
            emptyCell.setPadding(12f);
            emptyCell.setHorizontalAlignment(Element.ALIGN_CENTER);
            table.addCell(emptyCell);
        }

        document.add(table);
        document.close();
    }

    /**
     * Exports the Settled Revenue Report to PDF (Landscape A4).
     */
    public static void exportRevenuePdf(OutputStream out, List<RevenueReportItem> items,
                                        RevenueReportSummary summary, String filterZone,
                                        String startDate, String endDate) throws DocumentException, IOException {
        Document document = new Document(PageSize.A4.rotate(), 28, 28, 28, 30);
        PdfWriter writer = PdfWriter.getInstance(document, out);
        writer.setPageEvent(new HeaderFooterPageEvent("Verified Settled Revenue Report"));
        document.open();

        String facFilter = (filterZone != null && !filterZone.isEmpty() && !"ALL".equalsIgnoreCase(filterZone)) ? ("Zone " + filterZone) : "All Facilities";
        String dateFilterDesc = ((startDate != null && !startDate.isEmpty()) ? startDate : "All Time") +
                " to " + ((endDate != null && !endDate.isEmpty()) ? endDate + " (Through 23:59:59 IST)" : "Present");

        // 1. Report Header with controlled spacing
        Paragraph pTitle = new Paragraph("Verified Settled Revenue & Collections Report", FONT_TITLE);
        pTitle.setSpacingAfter(2f);
        document.add(pTitle);

        Paragraph pSub = new Paragraph("Audited Successful Transactions Joined from MySQL Payments & Bookings Ledgers\nGenerated on: " + TIMESTAMP_FORMAT.format(new Date()) + " IST (UTC+05:30)", FONT_SUBTITLE);
        pSub.setSpacingAfter(6f);
        document.add(pSub);

        // 2. Structured Filter & Policy Grid (Wrapping without text clipping)
        PdfPTable filterBox = new PdfPTable(3);
        filterBox.setWidthPercentage(100);
        try {
            filterBox.setWidths(new float[]{32f, 40f, 28f});
        } catch (Exception ignored) {}
        filterBox.setSpacingAfter(8f);

        addFilterCardCell(filterBox, "Facility Filter", facFilter, Element.ALIGN_LEFT);
        addFilterCardCell(filterBox, "Reporting Period", dateFilterDesc, Element.ALIGN_CENTER);
        addFilterCardCell(filterBox, "Currency & Timezone", "INR (₹) | IST (UTC+05:30)", Element.ALIGN_RIGHT);

        PdfPCell policyCell = new PdfPCell();
        policyCell.setColspan(3);
        policyCell.setBackgroundColor(new Color(239, 246, 255));
        policyCell.setBorderColor(new Color(191, 219, 254));
        policyCell.setPadding(5f);

        Paragraph pPolicy = new Paragraph();
        pPolicy.setLeading(10.5f);
        Chunk pPrefix = new Chunk("Strict Revenue Recognition Policy: ", getFont(7.5f, Font.BOLD, new Color(30, 58, 138)));
        Chunk pBody = new Chunk("Revenue strictly comprises verified settled transactions (status = 'SUCCESS') in MySQL payments ledger. Pending, unbilled, and cancelled sessions are excluded.", getFont(7.5f, Font.NORMAL, new Color(30, 64, 175)));
        pPolicy.add(pPrefix);
        pPolicy.add(pBody);
        policyCell.addElement(pPolicy);

        filterBox.addCell(policyCell);
        document.add(filterBox);

        // 3. KPI Summary Box (4 cards)
        PdfPTable kpiTable = new PdfPTable(4);
        kpiTable.setWidthPercentage(100);
        try {
            kpiTable.setWidths(new float[]{25f, 25f, 25f, 25f});
        } catch (Exception ignored) {}
        kpiTable.setSpacingBefore(0f);
        kpiTable.setSpacingAfter(10f);

        double totalRevenue = summary != null ? summary.getTotalRevenue() : 0.0;
        int txnCount = summary != null ? summary.getTransactionCount() : 0;
        double avgTicket = summary != null ? summary.getAverageTicket() : 0.0;
        String topMethod = (summary != null && txnCount > 0 &&
                summary.getTopPaymentMethod() != null && !summary.getTopPaymentMethod().trim().isEmpty() &&
                !"--".equals(summary.getTopPaymentMethod().trim())) ? summary.getTopPaymentMethod().trim() : "N/A";

        addKpiCell(kpiTable, "Total Collected Revenue", formatCurrency(totalRevenue), COLOR_GREEN);
        addKpiCell(kpiTable, "Settled Transactions", String.valueOf(txnCount), COLOR_PRIMARY);
        addKpiCell(kpiTable, "Average Ticket Value", formatCurrency(avgTicket), COLOR_ACCENT);
        addKpiCell(kpiTable, "Top Payment Channel", topMethod, COLOR_PRIMARY);

        document.add(kpiTable);

        // 4. Data Table
        float[] columnWidths = {22f, 8f, 16f, 15f, 13f, 7f, 10f, 11f, 14f};
        PdfPTable table = new PdfPTable(columnWidths);
        table.setWidthPercentage(100);
        table.setHeaderRows(1);

        String[] headers = {
                "Transaction Reference", "Booking", "Driver Name", "Facility & Zone",
                "Metro City", "Bay", "Channel", "Amount (INR)", "Payment Time (IST)"
        };
        for (String h : headers) {
            PdfPCell cell = new PdfPCell(new Phrase(h, FONT_TH));
            cell.setBackgroundColor(COLOR_HEADER_BG);
            cell.setPadding(5f);
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setBorderColor(COLOR_BORDER);
            table.addCell(cell);
        }

        if (items != null && !items.isEmpty()) {
            boolean alt = false;
            for (RevenueReportItem r : items) {
                Color rowBg = alt ? COLOR_ROW_ALT : Color.WHITE;
                alt = !alt;

                addCell(table, r.getTransactionId(), FONT_TD_BOLD, rowBg, Element.ALIGN_LEFT);
                addCell(table, "#" + r.getBookingId(), FONT_TD, rowBg, Element.ALIGN_CENTER);
                addCell(table, r.getUserName(), FONT_TD, rowBg, Element.ALIGN_LEFT);
                addCell(table, "Zone " + r.getZoneId(), FONT_TD, rowBg, Element.ALIGN_LEFT);
                addCell(table, r.getCityName(), FONT_TD, rowBg, Element.ALIGN_LEFT);
                addCell(table, r.getSlotId(), FONT_TD_BOLD, rowBg, Element.ALIGN_CENTER);
                addCell(table, r.getPaymentMethod(), FONT_TD_BOLD, rowBg, Element.ALIGN_CENTER);
                addCell(table, String.format(Locale.US, "%.2f", r.getAmount()), FONT_TD_BOLD, rowBg, Element.ALIGN_RIGHT);
                addCell(table, r.getPaymentTime() != null ? DATE_FORMAT.format(r.getPaymentTime()) : "--", FONT_TD, rowBg, Element.ALIGN_CENTER);
            }

            // Clean Totals Footer Row (only when there are transactions, no placeholder-heavy '--')
            Color totalsBg = new Color(241, 245, 249);
            PdfPCell totLbl = new PdfPCell(new Phrase("TOTAL SETTLED REVENUE (" + txnCount + " Transactions)", FONT_TD_BOLD));
            totLbl.setColspan(7);
            totLbl.setHorizontalAlignment(Element.ALIGN_RIGHT);
            totLbl.setVerticalAlignment(Element.ALIGN_MIDDLE);
            totLbl.setBackgroundColor(totalsBg);
            totLbl.setBorderColor(COLOR_BORDER);
            totLbl.setPadding(5f);
            table.addCell(totLbl);

            PdfPCell totAmt = new PdfPCell(new Phrase(String.format(Locale.US, "%.2f", totalRevenue), FONT_TD_BOLD));
            totAmt.setHorizontalAlignment(Element.ALIGN_RIGHT);
            totAmt.setVerticalAlignment(Element.ALIGN_MIDDLE);
            totAmt.setBackgroundColor(totalsBg);
            totAmt.setBorderColor(COLOR_BORDER);
            totAmt.setPadding(5f);
            table.addCell(totAmt);

            PdfPCell totStatus = new PdfPCell(new Phrase("SUCCESS", FONT_TD_BOLD));
            totStatus.setHorizontalAlignment(Element.ALIGN_CENTER);
            totStatus.setVerticalAlignment(Element.ALIGN_MIDDLE);
            totStatus.setBackgroundColor(totalsBg);
            totStatus.setBorderColor(COLOR_BORDER);
            totStatus.setPadding(5f);
            table.addCell(totStatus);
        } else {
            // Unambiguous, elegant empty state without confusing '--' rows
            PdfPCell emptyCell = new PdfPCell();
            emptyCell.setColspan(9);
            emptyCell.setPadding(18f);
            emptyCell.setBackgroundColor(new Color(248, 250, 252));
            emptyCell.setBorderColor(COLOR_BORDER);
            emptyCell.setHorizontalAlignment(Element.ALIGN_CENTER);

            Paragraph emptyTitle = new Paragraph("No Settled Payment Records Found", getFont(10.5f, Font.BOLD, COLOR_PRIMARY));
            emptyTitle.setAlignment(Element.ALIGN_CENTER);
            emptyTitle.setSpacingAfter(4f);
            emptyCell.addElement(emptyTitle);

            Paragraph emptyBody = new Paragraph("No successful transactions match the selected filter criteria.\nTotal collected revenue is " + formatCurrency(0.0) + " across 0 transactions in the database ledger.", getFont(8f, Font.NORMAL, COLOR_TEXT_MUTED));
            emptyBody.setAlignment(Element.ALIGN_CENTER);
            emptyCell.addElement(emptyBody);

            table.addCell(emptyCell);
        }

        document.add(table);
        document.close();
    }

    private static void addFilterCardCell(PdfPTable table, String label, String value, int alignment) {
        PdfPCell cell = new PdfPCell();
        cell.setBackgroundColor(new Color(241, 245, 249));
        cell.setBorderColor(COLOR_BORDER);
        cell.setPadding(5f);
        cell.setHorizontalAlignment(alignment);

        Paragraph p = new Paragraph();
        p.setAlignment(alignment);
        Chunk cLbl = new Chunk(label + ": ", getFont(7.5f, Font.BOLD, COLOR_PRIMARY));
        Chunk cVal = new Chunk(value != null ? value : "--", getFont(7.5f, Font.NORMAL, COLOR_PRIMARY));
        p.add(cLbl);
        p.add(cVal);
        cell.addElement(p);

        table.addCell(cell);
    }

    private static void addReportHeader(Document document, String title, String subtitle, String filterLine) throws DocumentException {
        Paragraph pTitle = new Paragraph(title, FONT_TITLE);
        pTitle.setSpacingAfter(2f);
        document.add(pTitle);

        Paragraph pSub = new Paragraph(subtitle + "\nGenerated on: " + TIMESTAMP_FORMAT.format(new Date()) + " IST (UTC+05:30)", FONT_SUBTITLE);
        pSub.setSpacingAfter(5f);
        document.add(pSub);

        PdfPTable filterBox = new PdfPTable(1);
        filterBox.setWidthPercentage(100);
        PdfPCell fCell = new PdfPCell(new Phrase("Filter Scope: " + filterLine, FONT_TD_BOLD));
        fCell.setBackgroundColor(new Color(241, 245, 249));
        fCell.setBorderColor(COLOR_BORDER);
        fCell.setPadding(5f);
        filterBox.addCell(fCell);
        document.add(filterBox);
    }

    private static void addKpiCell(PdfPTable table, String label, String value, Color valColor) {
        PdfPCell cell = new PdfPCell();
        cell.setBackgroundColor(new Color(248, 250, 252));
        cell.setBorderColor(COLOR_BORDER);
        cell.setPadding(6f);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);

        Paragraph pVal = new Paragraph(value, getFont(12.5f, Font.BOLD, valColor));
        pVal.setAlignment(Element.ALIGN_CENTER);
        cell.addElement(pVal);

        Paragraph pLbl = new Paragraph(label, getFont(7.5f, Font.NORMAL, COLOR_TEXT_MUTED));
        pLbl.setAlignment(Element.ALIGN_CENTER);
        cell.addElement(pLbl);

        table.addCell(cell);
    }

    private static void addCell(PdfPTable table, String text, Font font, Color bgColor, int alignment) {
        PdfPCell cell = new PdfPCell(new Phrase(text != null ? text : "--", font));
        cell.setBackgroundColor(bgColor);
        cell.setHorizontalAlignment(alignment);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(4.5f);
        cell.setBorderColor(COLOR_BORDER);
        table.addCell(cell);
    }
}
