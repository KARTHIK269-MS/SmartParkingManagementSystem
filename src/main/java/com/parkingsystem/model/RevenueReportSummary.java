package com.parkingsystem.model;

import java.io.Serializable;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Summary metrics for the filtered Revenue Report.
 */
public class RevenueReportSummary implements Serializable {
    private static final long serialVersionUID = 1L;

    private double totalRevenue;
    private int transactionCount;
    private double averageTicket;
    private String topPaymentMethod = "N/A";
    private Map<String, Double> methodBreakdown = new LinkedHashMap<>();
    private Map<String, Integer> methodCountBreakdown = new LinkedHashMap<>();
    private Map<String, Double> cityRevenueBreakdown = new LinkedHashMap<>();
    private String filterZone;
    private String filterStartDate;
    private String filterEndDate;

    public RevenueReportSummary() {
    }

    public double getTotalRevenue() {
        return totalRevenue;
    }

    public void setTotalRevenue(double totalRevenue) {
        this.totalRevenue = totalRevenue;
    }

    public int getTransactionCount() {
        return transactionCount;
    }

    public void setTransactionCount(int transactionCount) {
        this.transactionCount = transactionCount;
    }

    public double getAverageTicket() {
        return averageTicket;
    }

    public void setAverageTicket(double averageTicket) {
        this.averageTicket = averageTicket;
    }

    public String getTopPaymentMethod() {
        if (topPaymentMethod == null || topPaymentMethod.trim().isEmpty() || "--".equals(topPaymentMethod.trim()) || "NONE".equalsIgnoreCase(topPaymentMethod.trim())) {
            return "N/A";
        }
        return topPaymentMethod;
    }

    public void setTopPaymentMethod(String topPaymentMethod) {
        this.topPaymentMethod = (topPaymentMethod == null || topPaymentMethod.trim().isEmpty() || "--".equals(topPaymentMethod.trim())) ? "N/A" : topPaymentMethod;
    }

    public Map<String, Double> getMethodBreakdown() {
        return methodBreakdown;
    }

    public void setMethodBreakdown(Map<String, Double> methodBreakdown) {
        this.methodBreakdown = methodBreakdown;
    }

    public Map<String, Integer> getMethodCountBreakdown() {
        return methodCountBreakdown;
    }

    public void setMethodCountBreakdown(Map<String, Integer> methodCountBreakdown) {
        this.methodCountBreakdown = methodCountBreakdown;
    }

    public Map<String, Double> getCityRevenueBreakdown() {
        return cityRevenueBreakdown;
    }

    public void setCityRevenueBreakdown(Map<String, Double> cityRevenueBreakdown) {
        this.cityRevenueBreakdown = cityRevenueBreakdown;
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

    // Convenient Alias
    public Map<String, Double> getCityBreakdown() {
        return cityRevenueBreakdown;
    }
}
