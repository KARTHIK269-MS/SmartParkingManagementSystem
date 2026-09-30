package com.parkingsystem.dao;

import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.Feedback;
import com.parkingsystem.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class FeedbackDAO {

    public boolean submitFeedback(Feedback feedback) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "INSERT INTO feedback (booking_id, user_id, rating, comment) VALUES (?, ?, ?, ?)";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, feedback.getBookingId());
            ps.setString(2, feedback.getUserId());
            ps.setInt(3, feedback.getRating());
            ps.setString(4, feedback.getComment());

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to submit feedback: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps);
        }
    }

    public Feedback getFeedbackByBookingId(int bookingId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT feedback_id, booking_id, user_id, rating, comment, created_at FROM feedback WHERE booking_id = ? LIMIT 1";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, bookingId);
            rs = ps.executeQuery();

            if (rs.next()) {
                Feedback f = new Feedback();
                f.setFeedbackId(rs.getInt("feedback_id"));
                f.setBookingId(rs.getInt("booking_id"));
                f.setUserId(rs.getString("user_id"));
                f.setRating(rs.getInt("rating"));
                f.setComment(rs.getString("comment"));
                f.setCreatedAt(rs.getTimestamp("created_at"));
                return f;
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch feedback for booking " + bookingId, e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public List<Feedback> getAllFeedback() throws DatabaseException {
        List<Feedback> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT f.feedback_id, f.booking_id, f.user_id, f.rating, f.comment, f.created_at, " +
                    "u.name AS user_name, b.slot_id, b.vehicle_number " +
                    "FROM feedback f " +
                    "JOIN users u ON f.user_id = u.user_id " +
                    "JOIN bookings b ON f.booking_id = b.booking_id " +
                    "ORDER BY f.feedback_id DESC";
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();

            while (rs.next()) {
                Feedback f = new Feedback();
                f.setFeedbackId(rs.getInt("feedback_id"));
                f.setBookingId(rs.getInt("booking_id"));
                f.setUserId(rs.getString("user_id"));
                f.setRating(rs.getInt("rating"));
                f.setComment(rs.getString("comment"));
                f.setCreatedAt(rs.getTimestamp("created_at"));
                f.setUserName(rs.getString("user_name"));
                f.setSlotId(rs.getString("slot_id"));
                f.setVehicleNumber(rs.getString("vehicle_number"));
                list.add(f);
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch all feedback", e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public double getAverageRating() throws DatabaseException {
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            stmt = conn.createStatement();
            rs = stmt.executeQuery("SELECT COALESCE(AVG(rating), 0) AS avg_rating FROM feedback");
            if (rs.next()) {
                return Math.round(rs.getDouble("avg_rating") * 10.0) / 10.0;
            }
            return 0.0;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to calculate average rating", e);
        } finally {
            DBConnection.close(conn, stmt, rs);
        }
    }
}
