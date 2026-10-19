package com.parkingsystem.dao;

import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.User;
import com.parkingsystem.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class UserDAO {

    public synchronized String generateNextUserId() throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement("SELECT user_id FROM users WHERE user_id LIKE 'U%' ORDER BY LENGTH(user_id) DESC, user_id DESC LIMIT 1");
            rs = ps.executeQuery();
            if (rs.next()) {
                String lastId = rs.getString("user_id");
                try {
                    int num = Integer.parseInt(lastId.substring(1));
                    return String.format("U%03d", num + 1);
                } catch (NumberFormatException ignored) {
                }
            }
            return "U001";
        } catch (SQLException e) {
            throw new DatabaseException("Failed to generate user ID", e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public boolean register(User user) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(
                    "INSERT INTO users (user_id, name, email, password, phone_number, role) VALUES (?, ?, ?, ?, ?, ?)"
            );
            ps.setString(1, user.getUserId());
            ps.setString(2, user.getName());
            ps.setString(3, user.getEmail());
            ps.setString(4, user.getPassword());
            ps.setString(5, user.getPhoneNumber());
            ps.setString(6, user.getRole() != null ? user.getRole() : "USER");

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DatabaseException("Error registering user: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps);
        }
    }

    public User authenticate(String email, String passwordHash) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(
                    "SELECT user_id, name, email, password, phone_number, role, created_at FROM users WHERE email = ?"
            );
            ps.setString(1, email);
            rs = ps.executeQuery();

            if (rs.next()) {
                String storedHash = rs.getString("password");
                if (com.parkingsystem.util.PasswordHasher.verify(passwordHash, storedHash)) {
                    User user = new User();
                    user.setUserId(rs.getString("user_id"));
                    user.setName(rs.getString("name"));
                    user.setEmail(rs.getString("email"));
                    user.setPhoneNumber(rs.getString("phone_number"));
                    user.setRole(rs.getString("role"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                    return user;
                }
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Authentication error: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public User findByEmail(String email) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(
                    "SELECT user_id, name, email, phone_number, role, created_at FROM users WHERE email = ?"
            );
            ps.setString(1, email);
            rs = ps.executeQuery();
            if (rs.next()) {
                User user = new User();
                user.setUserId(rs.getString("user_id"));
                user.setName(rs.getString("name"));
                user.setEmail(rs.getString("email"));
                user.setPhoneNumber(rs.getString("phone_number"));
                user.setRole(rs.getString("role"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
                return user;
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Error finding user by email: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public User findById(String userId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(
                    "SELECT user_id, name, email, phone_number, role, created_at FROM users WHERE user_id = ?"
            );
            ps.setString(1, userId);
            rs = ps.executeQuery();
            if (rs.next()) {
                User user = new User();
                user.setUserId(rs.getString("user_id"));
                user.setName(rs.getString("name"));
                user.setEmail(rs.getString("email"));
                user.setPhoneNumber(rs.getString("phone_number"));
                user.setRole(rs.getString("role"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
                return user;
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Error finding user by ID: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * Retrieves all registered users in the application.
     */
    public List<User> getAllUsers() throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        List<User> list = new ArrayList<>();
        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(
                    "SELECT user_id, name, email, phone_number, role, created_at FROM users ORDER BY created_at DESC, user_id ASC"
            );
            rs = ps.executeQuery();
            while (rs.next()) {
                User user = new User();
                user.setUserId(rs.getString("user_id"));
                user.setName(rs.getString("name"));
                user.setEmail(rs.getString("email"));
                user.setPhoneNumber(rs.getString("phone_number"));
                user.setRole(rs.getString("role"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
                list.add(user);
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Error retrieving all users: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    /**
     * Returns a map of user_id -> count of bookings placed by that user.
     */
    public Map<String, Integer> getUserBookingCounts() throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Map<String, Integer> counts = new HashMap<>();
        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(
                    "SELECT user_id, COUNT(*) AS booking_count FROM bookings GROUP BY user_id"
            );
            rs = ps.executeQuery();
            while (rs.next()) {
                counts.put(rs.getString("user_id"), rs.getInt("booking_count"));
            }
            return counts;
        } catch (SQLException e) {
            throw new DatabaseException("Error retrieving user booking counts: " + e.getMessage(), e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }
}
