package com.parkingsystem.model;

import java.io.Serializable;

/**
 * Summary metrics for the filtered Occupancy Report.
 */
public class OccupancyReportSummary implements Serializable {
    private static final long serialVersionUID = 1L;

    private int totalFacilities;
    private int totalBays;
    private int availableBays;
    private int occupiedBays;
    private int reservedBays;
    private int blockedBays;
    private double overallOccupancyRate;
    private double overallActiveRate;
    private String filterZone;
    private String filterStartDate;
    private String filterEndDate;

    public OccupancyReportSummary() {
    }

    public OccupancyReportSummary(int totalFacilities, int totalBays, int availableBays,
                                  int occupiedBays, int reservedBays, int blockedBays,
                                  String filterZone) {
        this.totalFacilities = totalFacilities;
        this.totalBays = totalBays;
        this.availableBays = availableBays;
        this.occupiedBays = occupiedBays;
        this.reservedBays = reservedBays;
        this.blockedBays = blockedBays;
        this.filterZone = filterZone;
        this.overallOccupancyRate = totalBays > 0 ? (occupiedBays * 100.0) / totalBays : 0.0;
        this.overallActiveRate = totalBays > 0 ? ((occupiedBays + reservedBays) * 100.0) / totalBays : 0.0;
    }

    public int getTotalFacilities() {
        return totalFacilities;
    }

    public void setTotalFacilities(int totalFacilities) {
        this.totalFacilities = totalFacilities;
    }

    public int getTotalBays() {
        return totalBays;
    }

    public void setTotalBays(int totalBays) {
        this.totalBays = totalBays;
    }

    public int getAvailableBays() {
        return availableBays;
    }

    public void setAvailableBays(int availableBays) {
        this.availableBays = availableBays;
    }

    public int getOccupiedBays() {
        return occupiedBays;
    }

    public void setOccupiedBays(int occupiedBays) {
        this.occupiedBays = occupiedBays;
    }

    public int getReservedBays() {
        return reservedBays;
    }

    public void setReservedBays(int reservedBays) {
        this.reservedBays = reservedBays;
    }

    public int getBlockedBays() {
        return blockedBays;
    }

    public void setBlockedBays(int blockedBays) {
        this.blockedBays = blockedBays;
    }

    public double getOverallOccupancyRate() {
        return overallOccupancyRate;
    }

    public void setOverallOccupancyRate(double overallOccupancyRate) {
        this.overallOccupancyRate = overallOccupancyRate;
    }

    public double getOverallActiveRate() {
        return overallActiveRate;
    }

    public void setOverallActiveRate(double overallActiveRate) {
        this.overallActiveRate = overallActiveRate;
    }

    public String getFilterZone() {
        return filterZone;
    }

    public void setFilterZone(String filterZone) {
        this.filterZone = filterZone;
    }

    public String getFilterStartDate() {
        return filterStartDate;
    }

    public void setFilterStartDate(String filterStartDate) {
        this.filterStartDate = filterStartDate;
    }

    public String getFilterEndDate() {
        return filterEndDate;
    }

    public void setFilterEndDate(String filterEndDate) {
        this.filterEndDate = filterEndDate;
    }

    // Convenient Aliases
    public int getTotalSlots() { return totalBays; }
    public int getAvailableSlots() { return availableBays; }
    public int getOccupiedSlots() { return occupiedBays; }
    public int getReservedSlots() { return reservedBays; }
    public int getBlockedSlots() { return blockedBays; }
    public double getOccupancyRate() { return overallOccupancyRate; }
}
