package com.parkingsystem.model;

import java.io.Serializable;

public class Zone implements Serializable {
    private static final long serialVersionUID = 1L;

    private String zoneId;
    private String name;
    private String location;
    private double hourlyRate;
    private int totalSlots;
    private String description;

    // Transient runtime metrics
    private int availableSlots;
    private int occupiedSlots;

    public Zone() {
    }

    public Zone(String zoneId, String name, String location, double hourlyRate, int totalSlots, String description) {
        this.zoneId = zoneId;
        this.name = name;
        this.location = location;
        this.hourlyRate = hourlyRate;
        this.totalSlots = totalSlots;
        this.description = description;
    }

    public String getZoneId() {
        return zoneId;
    }

    public void setZoneId(String zoneId) {
        this.zoneId = zoneId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public double getHourlyRate() {
        return hourlyRate;
    }

    public void setHourlyRate(double hourlyRate) {
        this.hourlyRate = hourlyRate;
    }

    public int getTotalSlots() {
        return totalSlots;
    }

    public void setTotalSlots(int totalSlots) {
        this.totalSlots = totalSlots;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
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

    public int getOccupancyPercentage() {
        if (totalSlots <= 0) return 0;
        int occupied = totalSlots - availableSlots;
        if (occupied < 0) occupied = 0;
        return (int) Math.round(((double) occupied / totalSlots) * 100);
    }

    /**
     * 3-Tier Dynamic Demand Pricing:
     * - Rush Hours (High Demand / Occupancy >= 75%): ₹50 / hr (1.25x)
     * - Normal Hours (Moderate Demand / Occupancy 40% - 74%): ₹40 / hr (1.0x)
     * - No Rush Hours (Low Demand / Off-Peak / Occupancy < 40%): ₹30 / hr (0.75x)
     */
    public boolean isRushHour() {
        return getOccupancyPercentage() >= 75;
    }

    public boolean isSurgeActive() {
        return isRushHour();
    }

    public boolean isOffPeak() {
        return getOccupancyPercentage() < 40;
    }

    public boolean isNoRush() {
        return isOffPeak();
    }

    public boolean isNormalHours() {
        return !isRushHour() && !isOffPeak();
    }

    public double getSurgeMultiplier() {
        if (isRushHour()) return 1.25;
        if (isOffPeak()) return 0.75;
        return 1.0;
    }

    public double getEffectiveHourlyRate() {
        if (isRushHour()) {
            return 50.0;
        } else if (isOffPeak()) {
            return 30.0;
        } else {
            return 40.0;
        }
    }

    public double getBaseHourlyRate() {
        return 40.0;
    }

    public String getPricingTierName() {
        if (isRushHour()) return "Rush Hour";
        if (isOffPeak()) return "No Rush";
        return "Normal";
    }

    public String getPricingTierBadge() {
        if (isRushHour()) return "⚡ RUSH HOUR (₹50)";
        if (isOffPeak()) return "🏷️ NO RUSH (₹30)";
        return "⚖️ NORMAL (₹40)";
    }

    public String getCityName() {
        if (name != null) {
            if (name.contains("Mumbai")) return "Mumbai";
            if (name.contains("Bengaluru") || name.contains("Bangalore")) return "Bengaluru";
            if (name.contains("New Delhi") || name.contains("Delhi")) return "New Delhi";
            if (name.contains("Hyderabad")) return "Hyderabad";
            if (name.contains("Chennai")) return "Chennai";
            if (name.contains("Kolkata")) return "Kolkata";
        }
        if (location != null) {
            if (location.contains("Mumbai")) return "Mumbai";
            if (location.contains("Bengaluru") || location.contains("Bangalore")) return "Bengaluru";
            if (location.contains("Delhi")) return "New Delhi";
            if (location.contains("Hyderabad")) return "Hyderabad";
            if (location.contains("Chennai")) return "Chennai";
            if (location.contains("Kolkata")) return "Kolkata";
        }
        return "Other";
    }

    public String getCity() {
        return getCityName();
    }

    public String getFacilityName() {
        if (name == null) return "Zone " + zoneId;
        int hyphenIdx = name.indexOf(" - ");
        if (hyphenIdx != -1) {
            return name.substring(hyphenIdx + 3).trim();
        }
        return name;
    }
}
