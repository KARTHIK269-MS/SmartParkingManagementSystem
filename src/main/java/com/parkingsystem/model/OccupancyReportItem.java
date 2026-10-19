package com.parkingsystem.model;

import java.io.Serializable;

/**
 * Data Transfer Object representing an individual facility / zone line item
 * in the Real-Time Occupancy Report.
 */
public class OccupancyReportItem implements Serializable {
    private static final long serialVersionUID = 1L;

    private String zoneId;
    private String zoneName;
    private String city;
    private String location;
    private int totalSlots;
    private int availableSlots;
    private int occupiedSlots;
    private int reservedSlots;
    private int blockedSlots;
    private double occupancyRate; // Currently Parked %: occupied / total * 100
    private double activeRate;    // Total Active %: (occupied + reserved) / total * 100

    public OccupancyReportItem() {
    }

    public OccupancyReportItem(String zoneId, String zoneName, String city, String location,
                               int totalSlots, int availableSlots, int occupiedSlots,
                               int reservedSlots, int blockedSlots) {
        this.zoneId = zoneId;
        this.zoneName = zoneName;
        this.city = city;
        this.location = location;
        this.totalSlots = totalSlots;
        this.availableSlots = availableSlots;
        this.occupiedSlots = occupiedSlots;
        this.reservedSlots = reservedSlots;
        this.blockedSlots = blockedSlots;
        this.occupancyRate = totalSlots > 0 ? (occupiedSlots * 100.0) / totalSlots : 0.0;
        this.activeRate = totalSlots > 0 ? ((occupiedSlots + reservedSlots) * 100.0) / totalSlots : 0.0;
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

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public int getTotalSlots() {
        return totalSlots;
    }

    public void setTotalSlots(int totalSlots) {
        this.totalSlots = totalSlots;
    }

    public int getAvailableSlots() {
        return availableSlots;
    }

    public void setAvailableSlots(int availableSlots) {
        this.availableSlots = availableSlots;
    }

    public int getOccupiedSlots() {
        return occupiedSlots;
    }

    public void setOccupiedSlots(int occupiedSlots) {
        this.occupiedSlots = occupiedSlots;
    }

    public int getReservedSlots() {
        return reservedSlots;
    }

    public void setReservedSlots(int reservedSlots) {
        this.reservedSlots = reservedSlots;
    }

    public int getBlockedSlots() {
        return blockedSlots;
    }

    public void setBlockedSlots(int blockedSlots) {
        this.blockedSlots = blockedSlots;
    }

    public double getOccupancyRate() {
        return occupancyRate;
    }

    public void setOccupancyRate(double occupancyRate) {
        this.occupancyRate = occupancyRate;
    }

    public double getActiveRate() {
        return activeRate;
    }

    public void setActiveRate(double activeRate) {
        this.activeRate = activeRate;
    }

    // Convenient Aliases
    public String getCityName() { return city; }
    public int getTotalBays() { return totalSlots; }
    public int getAvailableBays() { return availableSlots; }
    public int getOccupiedBays() { return occupiedSlots; }
    public int getReservedBays() { return reservedSlots; }
    public int getBlockedBays() { return blockedSlots; }
}
