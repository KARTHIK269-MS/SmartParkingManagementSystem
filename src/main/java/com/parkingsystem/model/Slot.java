package com.parkingsystem.model;

import java.io.Serializable;

public class Slot implements Serializable {
    private static final long serialVersionUID = 1L;

    private String slotId;
    private String zoneId;
    private int slotNumber;
    private int floor;
    private String type; // "STANDARD", "EV", "ACCESSIBLE"
    private String status; // "AVAILABLE", "BOOKED", "RESERVED", "BLOCKED"

    public Slot() {
    }

    public Slot(String slotId, String zoneId, int slotNumber, int floor, String type, String status) {
        this.slotId = slotId;
        this.zoneId = zoneId;
        this.slotNumber = slotNumber;
        this.floor = floor;
        this.type = type;
        this.status = status;
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

    public int getSlotNumber() {
        return slotNumber;
    }

    public void setSlotNumber(int slotNumber) {
        this.slotNumber = slotNumber;
    }

    public int getFloor() {
        return floor;
    }

    public void setFloor(int floor) {
        this.floor = floor;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public boolean isAvailable() {
        return "AVAILABLE".equalsIgnoreCase(this.status);
    }

    public boolean isBooked() {
        return "BOOKED".equalsIgnoreCase(this.status);
    }

    public boolean isReserved() {
        return "RESERVED".equalsIgnoreCase(this.status);
    }

    public boolean isBlocked() {
        return "BLOCKED".equalsIgnoreCase(this.status);
    }

    @Override
    public String toString() {
        return "Slot{" +
                "slotId='" + slotId + '\'' +
                ", zoneId='" + zoneId + '\'' +
                ", floor=" + floor +
                ", type='" + type + '\'' +
                ", status='" + status + '\'' +
                '}';
    }
}
