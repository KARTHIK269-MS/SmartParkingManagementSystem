package com.parkingsystem.model;

import java.io.Serializable;
import java.sql.Timestamp;

public class Booking implements Serializable {
    private static final long serialVersionUID = 1L;

    private int bookingId;
    private String userId;
    private String slotId;
    private String vehicleNumber;
    private int durationHours;
    private double totalAmount;
    private String status; // "PENDING", "CONFIRMED", "COMPLETED", "CANCELLED"
    private Timestamp bookingTime;
    private Timestamp entryTime;
    private Timestamp exitTime;
    private Timestamp expiresAt;
    private String paymentId;
    private Timestamp scheduledArrivalTime;
    private String cancellationReason;

    // Supplementary display fields
    private String userName;
    private String userEmail;
    private String zoneId;
    private double hourlyRate;
    private boolean feedbackGiven;

    public Booking() {
    }

    public Booking(int bookingId, String userId, String slotId, String vehicleNumber, int durationHours, double totalAmount, String status) {
        this.bookingId = bookingId;
        this.userId = userId;
        this.slotId = slotId;
        this.vehicleNumber = vehicleNumber;
        this.durationHours = durationHours;
        this.totalAmount = totalAmount;
        this.status = status;
    }

    public int getBookingId() {
        return bookingId;
    }

    public void setBookingId(int bookingId) {
        this.bookingId = bookingId;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getSlotId() {
        return slotId;
    }

    public void setSlotId(String slotId) {
        this.slotId = slotId;
    }

    public String getVehicleNumber() {
        return vehicleNumber;
    }

    public void setVehicleNumber(String vehicleNumber) {
        this.vehicleNumber = vehicleNumber;
    }

    public int getDurationHours() {
        return durationHours;
    }

    public void setDurationHours(int durationHours) {
        this.durationHours = durationHours;
    }

    public double getTotalAmount() {
        return totalAmount;
    }

    public void setTotalAmount(double totalAmount) {
        this.totalAmount = totalAmount;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Timestamp getBookingTime() {
        return bookingTime;
    }

    public void setBookingTime(Timestamp bookingTime) {
        this.bookingTime = bookingTime;
    }

    public Timestamp getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(Timestamp expiresAt) {
        this.expiresAt = expiresAt;
    }

    public String getPaymentId() {
        return paymentId;
    }

    public void setPaymentId(String paymentId) {
        this.paymentId = paymentId;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public String getZoneId() {
        return zoneId;
    }

    public void setZoneId(String zoneId) {
        this.zoneId = zoneId;
    }

    public double getHourlyRate() {
        return hourlyRate;
    }

    public void setHourlyRate(double hourlyRate) {
        this.hourlyRate = hourlyRate;
    }

    public boolean isFeedbackGiven() {
        return feedbackGiven;
    }

    public void setFeedbackGiven(boolean feedbackGiven) {
        this.feedbackGiven = feedbackGiven;
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

    public Timestamp getScheduledArrivalTime() {
        return scheduledArrivalTime;
    }

    public void setScheduledArrivalTime(Timestamp scheduledArrivalTime) {
        this.scheduledArrivalTime = scheduledArrivalTime;
    }

    public String getCancellationReason() {
        return cancellationReason;
    }

    public void setCancellationReason(String cancellationReason) {
        this.cancellationReason = cancellationReason;
    }

    public boolean isReserved() {
        return "RESERVED".equalsIgnoreCase(this.status);
    }

    public boolean isConfirmed() {
        return "CONFIRMED".equalsIgnoreCase(this.status);
    }

    public boolean isPending() {
        return "PENDING".equalsIgnoreCase(this.status);
    }

    public boolean isActive() {
        return "ACTIVE".equalsIgnoreCase(this.status) || "PARKED".equalsIgnoreCase(this.status);
    }

    public boolean isPaymentPending() {
        return "PAYMENT_PENDING".equalsIgnoreCase(this.status);
    }

    public boolean isCancelled() {
        return "CANCELLED".equalsIgnoreCase(this.status);
    }

    public boolean isCompleted() {
        return "COMPLETED".equalsIgnoreCase(this.status);
    }

    public long getElapsedSeconds() {
        if (entryTime == null) return 0L;
        long end = (exitTime != null) ? exitTime.getTime() : System.currentTimeMillis();
        long diff = (end - entryTime.getTime()) / 1000L;
        return Math.max(0L, diff);
    }

    public String getFormattedElapsed() {
        long totalSec = getElapsedSeconds();
        long hrs = totalSec / 3600;
        long mins = (totalSec % 3600) / 60;
        long secs = totalSec % 60;
        return String.format("%dhr %dmin %dsec", hrs, mins, secs);
    }

    public double getLiveEstimatedAmount(double rate) {
        if (rate <= 0) rate = (this.hourlyRate > 0) ? this.hourlyRate : 40.0;
        long totalSec = getElapsedSeconds();
        if (totalSec <= 0) return rate; // Minimum 1-hour base rate
        double hours = Math.ceil(totalSec / 3600.0);
        return Math.max(rate, hours * rate);
    }

    public long getGracePeriodRemainingSeconds() {
        if (!isReserved()) return 0L;
        Timestamp target = (expiresAt != null) ? expiresAt :
                (scheduledArrivalTime != null ? new Timestamp(scheduledArrivalTime.getTime() + (30 * 60 * 1000L)) : null);
        if (target == null) return 0L;
        long diffSec = (target.getTime() - System.currentTimeMillis()) / 1000L;
        return Math.max(0L, diffSec);
    }
}
