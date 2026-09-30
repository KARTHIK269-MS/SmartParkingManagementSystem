package com.parkingsystem.dao;

import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.Payment;
import com.parkingsystem.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class PaymentDAO {

    public Payment getPaymentByBookingId(int bookingId) throws DatabaseException {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(
                    "SELECT payment_id, booking_id, amount, payment_method, transaction_id, status, payment_time " +
                            "FROM payments WHERE booking_id = ? ORDER BY payment_id DESC LIMIT 1"
            );
            ps.setInt(1, bookingId);
            rs = ps.executeQuery();

            if (rs.next()) {
                Payment p = new Payment();
                p.setPaymentId(rs.getInt("payment_id"));
                p.setBookingId(rs.getInt("booking_id"));
                p.setAmount(rs.getDouble("amount"));
                p.setPaymentMethod(rs.getString("payment_method"));
                p.setTransactionId(rs.getString("transaction_id"));
                p.setStatus(rs.getString("status"));
                p.setPaymentTime(rs.getTimestamp("payment_time"));
                return p;
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch payment for booking " + bookingId, e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }

    public List<Payment> getAllPayments() throws DatabaseException {
        List<Payment> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            ps = conn.prepareStatement(
                    "SELECT payment_id, booking_id, amount, payment_method, transaction_id, status, payment_time " +
                            "FROM payments ORDER BY payment_id DESC"
            );
            rs = ps.executeQuery();

            while (rs.next()) {
                Payment p = new Payment();
                p.setPaymentId(rs.getInt("payment_id"));
                p.setBookingId(rs.getInt("booking_id"));
                p.setAmount(rs.getDouble("amount"));
                p.setPaymentMethod(rs.getString("payment_method"));
                p.setTransactionId(rs.getString("transaction_id"));
                p.setStatus(rs.getString("status"));
                p.setPaymentTime(rs.getTimestamp("payment_time"));
                list.add(p);
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Failed to fetch all payments", e);
        } finally {
            DBConnection.close(conn, ps, rs);
        }
    }
}
