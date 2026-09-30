package com.parkingsystem.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class DBConnection {

    private static final String URL = "jdbc:mysql://localhost:3306/parking_system?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata";
    private static final String USER = "root";
    private static final String PASSWORD = "karthik123";

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            System.err.println("MySQL JDBC Driver not found: " + e.getMessage());
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }

    public static void close(Connection conn, Statement stmt, ResultSet rs) {
        if (rs != null) {
            try {
                rs.close();
            } catch (SQLException ignored) {
            }
        }
        if (stmt != null) {
            try {
                stmt.close();
            } catch (SQLException ignored) {
            }
        }
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException ignored) {
            }
        }
    }

    public static void close(Connection conn, Statement stmt) {
        close(conn, stmt, null);
    }

    public static void rollback(Connection conn) {
        if (conn != null) {
            try {
                conn.rollback();
            } catch (SQLException ignored) {
            }
        }
    }
}
