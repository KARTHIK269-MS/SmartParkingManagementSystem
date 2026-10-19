package com.parkingsystem.model;

import java.io.Serializable;
import java.sql.Timestamp;

/**
 * HyperPark-inspired Gate Movement and Telemetry Model.
 * Represents an individual vehicle entry or exit event at a facility gate.
 * All gate camera and sensor triggers are prototype simulations.
 */
public class GateActivityEvent implements Serializable {
    private static final long serialVersionUID = 1L;

    private int bookingId;
    private String vehicleNumber;
    private String userId;
    private String userName;
    private String slotId;
    private String zoneId;
    private String zoneName;
    private String eventType;      // "ENTRY" or "EXIT"
    private Timestamp eventTime;
    private String eventSource;    // "Simulated ANPR Camera", "Simulated Bay Sensor", etc.
    private String eventResult;    // "Admitted & Bay Occupied", "Departed • Payment Pending", "Departed • Paid"
    private String bookingStatus;  // "ACTIVE", "PAYMENT_PENDING", "COMPLETED"
    private double amount;
    private String paymentStatus;  // "ESTIMATED", "PENDING", "COMPLETED"
    private String paymentMethod;
    private String transactionId;
    private Timestamp bookingTime;
    private Timestamp entryTime;
    private Timestamp exitTime;
    private String durationFormatted;

    public GateActivityEvent() {
    }

    public int getBookingId() {
        return bookingId;
    }

    public void setBookingId(int bookingId) {
        this.bookingId = bookingId;
    }

    public String getVehicleNumber() {
        return vehicleNumber;
    }

    public void setVehicleNumber(String vehicleNumber) {
        this.vehicleNumber = vehicleNumber;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getSlotId() {
        return slotId;
    }

    public void setSlotId(String slotId) {
        this.slotId = slotId;
    }

    public String getZoneId() {
        return zoneId;
    }

    public void setZoneId(String zoneId) {
        this.zoneId = zoneId;
    }

    public String getZoneName() {
        return zoneName;
    }

    public void setZoneName(String zoneName) {
        this.zoneName = zoneName;
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public Timestamp getEventTime() {
        return eventTime;
    }

    public void setEventTime(Timestamp eventTime) {
        this.eventTime = eventTime;
    }

    public String getEventSource() {
        return eventSource;
    }

    public void setEventSource(String eventSource) {
        this.eventSource = eventSource;
    }

    public String getEventResult() {
        return eventResult;
    }

    public void setEventResult(String eventResult) {
        this.eventResult = eventResult;
    }

    public String getBookingStatus() {
        return bookingStatus;
    }

    public void setBookingStatus(String bookingStatus) {
        this.bookingStatus = bookingStatus;
    }

    public double getAmount() {
        return amount;
    }

    public void setAmount(double amount) {
        this.amount = amount;
    }

    public String getPaymentStatus() {
        return paymentStatus;
    }

    public void setPaymentStatus(String paymentStatus) {
        this.paymentStatus = paymentStatus;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public String getTransactionId() {
        return transactionId;
    }

    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }

    public boolean isEntry() {
        return "ENTRY".equalsIgnoreCase(this.eventType);
    }

    public boolean isExit() {
        return "EXIT".equalsIgnoreCase(this.eventType);
    }

    public boolean isRejected() {
        return "REJECTED".equalsIgnoreCase(this.eventType) || "ACCESS_DENIED".equalsIgnoreCase(this.eventType);
    }

    public Timestamp getBookingTime() {
        return bookingTime;
    }

    public void setBookingTime(Timestamp bookingTime) {
        this.bookingTime = bookingTime;
    }

    public Timestamp getEntryTime() {
        return entryTime;
    }

    public void setEntryTime(Timestamp entryTime) {
        this.entryTime = entryTime;
    }

    public Timestamp getExitTime() {
        return exitTime;
    }

    public void setExitTime(Timestamp exitTime) {
        this.exitTime = exitTime;
    }

    public void setDurationFormatted(String durationFormatted) {
        this.durationFormatted = durationFormatted;
    }

    public String getDurationFormatted() {
        if (durationFormatted != null && !durationFormatted.isEmpty()) {
            return durationFormatted;
        }
        if (entryTime != null && exitTime != null) {
            long diffSec = Math.max(0L, (exitTime.getTime() - entryTime.getTime()) / 1000L);
            long hrs = diffSec / 3600;
            long mins = (diffSec % 3600) / 60;
            long secs = diffSec % 60;
            if (hrs > 0) return hrs + "h " + (mins < 10 ? "0" + mins : mins) + "m";
            if (mins > 0) return mins + "m " + (secs < 10 ? "0" + secs : secs) + "s";
            return Math.max(1, secs) + "s";
        } else if (entryTime != null && isEntry()) {
            return "Session Started";
        }
        return "--";
    }
}
