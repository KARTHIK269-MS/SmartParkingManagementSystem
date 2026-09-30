package com.parkingsystem.model;

import java.io.Serializable;
import java.sql.Timestamp;

public class Feedback implements Serializable {
    private static final long serialVersionUID = 1L;

    private int feedbackId;
    private int bookingId;
    private String userId;
    private int rating;
    private String comment;
    private Timestamp createdAt;

    // Display fields
    private String userName;
    private String slotId;
    private String vehicleNumber;

    public Feedback() {
    }

    public Feedback(int feedbackId, int bookingId, String userId, int rating, String comment) {
        this.feedbackId = feedbackId;
        this.bookingId = bookingId;
        this.userId = userId;
        this.rating = rating;
        this.comment = comment;
    }

    public int getFeedbackId() {
        return feedbackId;
    }

    public void setFeedbackId(int feedbackId) {
        this.feedbackId = feedbackId;
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

    public int getRating() {
        return rating;
    }

    public void setRating(int rating) {
        this.rating = rating;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
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

    public String getVehicleNumber() {
        return vehicleNumber;
    }

    public void setVehicleNumber(String vehicleNumber) {
        this.vehicleNumber = vehicleNumber;
    }
}
