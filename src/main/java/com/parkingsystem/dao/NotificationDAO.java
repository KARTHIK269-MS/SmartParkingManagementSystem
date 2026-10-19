package com.parkingsystem.dao;

import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.Notification;
import com.parkingsystem.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class NotificationDAO {

    public int createNotification(Notification n) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "INSERT INTO notifications (user_id, booking_id, title, message, type, is_read, created_at) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?)";
            ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, n.getUserId());
            if (n.getBookingId() != null) {
                ps.setInt(2, n.getBookingId());
            } else {
                ps.setNull(2, java.sql.Types.INTEGER);
            }
            ps.setString(3, n.getTitle());
            ps.setString(4, n.getMessage());
            ps.setString(5, n.getType() != null ? n.getType() : "WARNING");
            ps.setBoolean(6, n.isRead());
            ps.setTimestamp(7, n.getCreatedAt() != null ? n.getCreatedAt() : new java.sql.Timestamp(System.currentTimeMillis()));

            ps.executeUpdate();
            rs = ps.getGeneratedKeys();
            if (rs.next()) {
                return rs.getInt(1);
            }
            return 0;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to create notification: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public List<Notification> getNotificationsByUserId(String userId, int limit) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<Notification> list = new ArrayList<>();

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT notification_id, user_id, booking_id, title, message, type, is_read, created_at " +
                    "FROM notifications WHERE user_id = ? ORDER BY notification_id DESC LIMIT ?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, userId);
            ps.setInt(2, limit > 0 ? limit : 20);
            rs = ps.executeQuery();

            while (rs.next()) {
                Notification n = new Notification();
                n.setNotificationId(rs.getInt("notification_id"));
                n.setUserId(rs.getString("user_id"));
                int bId = rs.getInt("booking_id");
                if (!rs.wasNull()) {
                    n.setBookingId(bId);
                }
                n.setTitle(rs.getString("title"));
                n.setMessage(rs.getString("message"));
                n.setType(rs.getString("type"));
                n.setRead(rs.getBoolean("is_read"));
                n.setCreatedAt(rs.getTimestamp("created_at"));
                list.add(n);
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch notifications: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public int getUnreadCount(String userId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = FALSE";
            ps = conn.prepareStatement(sql);
            ps.setString(1, userId);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
            return 0;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to get unread notification count: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public boolean markAsRead(int notificationId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "UPDATE notifications SET is_read = TRUE WHERE notification_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, notificationId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to mark notification as read: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, null);
        }
    }

    public boolean markAsReadForUser(int notificationId, String userId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "UPDATE notifications SET is_read = TRUE WHERE notification_id = ? AND user_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, notificationId);
            ps.setString(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to mark notification as read: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, null);
        }
    }

    public boolean markAllAsRead(String userId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;

        try {
            conn = DBConnection.getConnection();
            String sql = "UPDATE notifications SET is_read = TRUE WHERE user_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to mark all notifications as read: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, null);
        }
    }
}
