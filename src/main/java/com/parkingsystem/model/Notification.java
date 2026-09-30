package com.parkingsystem.model;

import java.io.Serializable;
import java.sql.Timestamp;

public class Notification implements Serializable {
    private static final long serialVersionUID = 1L;

    private int notificationId;
    private String userId;
    private Integer bookingId;
    private String title;
    private String message;
    private String type; // WARNING, INFO, SUCCESS, CANCELLATION
    private boolean isRead;
    private Timestamp createdAt;

    public Notification() {
    }

    public Notification(String userId, Integer bookingId, String title, String message, String type) {
        this.userId = userId;
        this.bookingId = bookingId;
        this.title = title;
        this.message = message;
        this.type = type;
        this.isRead = false;
        this.createdAt = new Timestamp(System.currentTimeMillis());
    }

    public int getNotificationId() {
        return notificationId;
    }

    public void setNotificationId(int notificationId) {
        this.notificationId = notificationId;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public Integer getBookingId() {
        return bookingId;
    }

    public void setBookingId(Integer bookingId) {
        this.bookingId = bookingId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public boolean isRead() {
        return isRead;
    }

    public void setRead(boolean read) {
        isRead = read;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
}
