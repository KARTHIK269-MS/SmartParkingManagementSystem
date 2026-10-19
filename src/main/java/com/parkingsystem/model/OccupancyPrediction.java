package com.parkingsystem.model;

import java.io.Serializable;

/**
 * Occupancy Prediction Model
 * Encapsulates live occupancy vs predicted occupancy for a parking facility/zone,
 * including 1h, 3h, and 6h forecasts, peak arrival windows, and transparency metrics.
 */
public class OccupancyPrediction implements Serializable {
    private static final long serialVersionUID = 1L;

    private String zoneId;
    private String zoneName;
    private String city;
    private int totalBays;

    // Current live metrics
    private int currentOccupied;
    private int currentAvailable;
    private double currentOccupancyPercentage;

    // Forecast metrics (+1 Hour)
    private int predicted1hOccupied;
    private int predicted1hAvailable;
    private double predicted1hPercentage;

    // Forecast metrics (+3 Hours)
    private int predicted3hOccupied;
    private int predicted3hAvailable;
    private double predicted3hPercentage;

    // Forecast metrics (+6 Hours)
    private int predicted6hOccupied;
    private int predicted6hAvailable;
    private double predicted6hPercentage;

    // Insights & Transparency
    private String peakPeriodLabel;
    private int historicalObservationsCount;
    private boolean sufficientData;
    private String statusNotice;
    private String methodology;
    private String dataPeriod;

    // 24-Hour curve comparisons [0..23]
    private int[] currentHourlyOccupancy = new int[24];
    private int[] predictedHourlyOccupancy = new int[24];

    public OccupancyPrediction() {}

    public String getZoneId() { return zoneId; }
    public void setZoneId(String zoneId) { this.zoneId = zoneId; }

    public String getZoneName() { return zoneName; }
    public void setZoneName(String zoneName) { this.zoneName = zoneName; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public int getTotalBays() { return totalBays; }
    public void setTotalBays(int totalBays) { this.totalBays = totalBays; }

    public int getCurrentOccupied() { return currentOccupied; }
    public void setCurrentOccupied(int currentOccupied) { this.currentOccupied = currentOccupied; }

    public int getCurrentAvailable() { return currentAvailable; }
    public void setCurrentAvailable(int currentAvailable) { this.currentAvailable = currentAvailable; }

    public double getCurrentOccupancyPercentage() { return currentOccupancyPercentage; }
    public void setCurrentOccupancyPercentage(double currentOccupancyPercentage) { this.currentOccupancyPercentage = currentOccupancyPercentage; }

    public int getPredicted1hOccupied() { return predicted1hOccupied; }
    public void setPredicted1hOccupied(int predicted1hOccupied) { this.predicted1hOccupied = predicted1hOccupied; }

    public int getPredicted1hAvailable() { return predicted1hAvailable; }
    public void setPredicted1hAvailable(int predicted1hAvailable) { this.predicted1hAvailable = predicted1hAvailable; }

    public double getPredicted1hPercentage() { return predicted1hPercentage; }
    public void setPredicted1hPercentage(double predicted1hPercentage) { this.predicted1hPercentage = predicted1hPercentage; }

    public int getPredicted3hOccupied() { return predicted3hOccupied; }
    public void setPredicted3hOccupied(int predicted3hOccupied) { this.predicted3hOccupied = predicted3hOccupied; }

    public int getPredicted3hAvailable() { return predicted3hAvailable; }
    public void setPredicted3hAvailable(int predicted3hAvailable) { this.predicted3hAvailable = predicted3hAvailable; }

    public double getPredicted3hPercentage() { return predicted3hPercentage; }
    public void setPredicted3hPercentage(double predicted3hPercentage) { this.predicted3hPercentage = predicted3hPercentage; }

    public int getPredicted6hOccupied() { return predicted6hOccupied; }
    public void setPredicted6hOccupied(int predicted6hOccupied) { this.predicted6hOccupied = predicted6hOccupied; }

    public int getPredicted6hAvailable() { return predicted6hAvailable; }
    public void setPredicted6hAvailable(int predicted6hAvailable) { this.predicted6hAvailable = predicted6hAvailable; }

    public double getPredicted6hPercentage() { return predicted6hPercentage; }
    public void setPredicted6hPercentage(double predicted6hPercentage) { this.predicted6hPercentage = predicted6hPercentage; }

    public String getPeakPeriodLabel() { return peakPeriodLabel; }
    public void setPeakPeriodLabel(String peakPeriodLabel) { this.peakPeriodLabel = peakPeriodLabel; }

    public int getHistoricalObservationsCount() { return historicalObservationsCount; }
    public void setHistoricalObservationsCount(int historicalObservationsCount) { this.historicalObservationsCount = historicalObservationsCount; }

    public boolean isSufficientData() { return sufficientData; }
    public void setSufficientData(boolean sufficientData) { this.sufficientData = sufficientData; }

    public String getStatusNotice() { return statusNotice; }
    public void setStatusNotice(String statusNotice) { this.statusNotice = statusNotice; }

    public String getMethodology() { return methodology; }
    public void setMethodology(String methodology) { this.methodology = methodology; }

    public String getDataPeriod() { return dataPeriod; }
    public void setDataPeriod(String dataPeriod) { this.dataPeriod = dataPeriod; }

    public int[] getCurrentHourlyOccupancy() { return currentHourlyOccupancy; }
    public void setCurrentHourlyOccupancy(int[] currentHourlyOccupancy) { this.currentHourlyOccupancy = currentHourlyOccupancy; }

    public int[] getPredictedHourlyOccupancy() { return predictedHourlyOccupancy; }
    public void setPredictedHourlyOccupancy(int[] predictedHourlyOccupancy) { this.predictedHourlyOccupancy = predictedHourlyOccupancy; }

    // Convenience aliases
    public int getObservationsCount() { return historicalObservationsCount; }
    public double getLiveOccupancyPercent() { return currentOccupancyPercentage; }
    public int getLiveAvailableBays() { return currentAvailable; }
    public int getLiveOccupiedBays() { return currentOccupied; }
    public double getPredicted1hPercent() { return predicted1hPercentage; }
    public double getPredicted3hPercent() { return predicted3hPercentage; }
    public double getPredicted6hPercent() { return predicted6hPercentage; }

    public String getTrendDirection() {
        if (predicted1hPercentage > currentOccupancyPercentage + 5.0) return "UP";
        if (predicted1hPercentage < currentOccupancyPercentage - 5.0) return "DOWN";
        return "STEADY";
    }

    public String getCurrentHourlyJson() {
        StringBuilder sb = new StringBuilder("[");
        if (currentHourlyOccupancy != null) {
            for (int i = 0; i < currentHourlyOccupancy.length; i++) {
                if (i > 0) sb.append(",");
                sb.append(currentHourlyOccupancy[i]);
            }
        }
        sb.append("]");
        return sb.toString();
    }

    public String getPredictedHourlyJson() {
        StringBuilder sb = new StringBuilder("[");
        if (predictedHourlyOccupancy != null) {
            for (int i = 0; i < predictedHourlyOccupancy.length; i++) {
                if (i > 0) sb.append(",");
                sb.append(predictedHourlyOccupancy[i]);
            }
        }
        sb.append("]");
        return sb.toString();
    }
}
