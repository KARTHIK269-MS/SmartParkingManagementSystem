package com.parkingsystem.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

/**
 * Database Connection Utility
 * Manages JDBC connections to MySQL with dynamic credential resolution.
 * Credentials are read from:
 * 1. System Properties (-Ddb.url, -Ddb.user, -Ddb.password)
 * 2. Environment Variables (DB_URL, DB_USER, DB_PASSWORD)
 * 3. Local properties file (db.properties in classpath or project root)
 * 4. Safe generic defaults
 */
public class DBConnection {

    private static final String DEFAULT_URL = "jdbc:mysql://localhost:3306/parking_system?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata";
    private static final String DEFAULT_USER = "root";
    private static final String DEFAULT_PASSWORD = "";

    private static String url;
    private static String user;
    private static String password;

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            System.err.println("MySQL JDBC Driver not found: " + e.getMessage());
        }

        loadConfiguration();
    }

    private static synchronized void loadConfiguration() {
        Properties props = new Properties();

        // 1. Check classpath for db.properties or application.properties
        try (InputStream is = DBConnection.class.getClassLoader().getResourceAsStream("db.properties")) {
            if (is != null) {
                props.load(is);
            }
        } catch (Exception ignored) {
        }
        if (props.isEmpty()) {
            try (InputStream is = DBConnection.class.getClassLoader().getResourceAsStream("application.properties")) {
                if (is != null) {
                    props.load(is);
                }
            } catch (Exception ignored) {
            }
        }

        // 2. Fallback to local working directory files if classpath didn't find it
        if (props.isEmpty()) {
            String[] candidateFiles = {
                "db.properties",
                "config/application.properties",
                "config/db.properties"
            };
            for (String candidatePath : candidateFiles) {
                File localFile = new File(candidatePath);
                if (localFile.exists()) {
                    try (InputStream fis = new FileInputStream(localFile)) {
                        props.load(fis);
                        if (!props.isEmpty()) {
                            break;
                        }
                    } catch (Exception ignored) {
                    }
                }
            }
        }

        // 3. Resolve Database URL
        url = System.getProperty("db.url");
        if (url == null || url.trim().isEmpty()) {
            url = System.getenv("DB_URL");
        }
        if (url == null || url.trim().isEmpty()) {
            url = props.getProperty("db.url", DEFAULT_URL);
        }

        // 4. Resolve Database User
        user = System.getProperty("db.user");
        if (user == null || user.trim().isEmpty()) {
            user = System.getenv("DB_USER");
        }
        if (user == null || user.trim().isEmpty()) {
            user = props.getProperty("db.user", DEFAULT_USER);
        }

        // 5. Resolve Database Password
        password = System.getProperty("db.password");
        if (password == null) {
            password = System.getenv("DB_PASSWORD");
        }
        if (password == null) {
            password = props.getProperty("db.password", DEFAULT_PASSWORD);
        }
    }

    public static Connection getConnection() throws SQLException {
        if (url == null || user == null) {
            loadConfiguration();
        }
        return DriverManager.getConnection(url, user, password);
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
