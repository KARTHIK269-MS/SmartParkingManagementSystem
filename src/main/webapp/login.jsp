<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser != null) {
        if (currentUser.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/admin?action=dashboard");
        } else {
            response.sendRedirect(request.getContextPath() + "/zones");
        }
        return;
    }
    String error = (String) request.getAttribute("errorMessage");
    String enteredEmail = (String) request.getAttribute("enteredEmail");
    if (enteredEmail == null) enteredEmail = "";
    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign In | Smart Parking Management System</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
</head>
<body>

    <!-- Navigation Bar -->
    <nav class="navbar">
        <a href="<%= request.getContextPath() %>/zones" class="navbar-brand">
            <div class="brand-icon">P</div>
            <span>SmartParking<span class="brand-tag">SYSTEM</span></span>
        </a>
        <ul class="nav-links">
            <li><a href="<%= request.getContextPath() %>/zones" class="nav-link">Parking Zones</a></li>
            <li><a href="<%= request.getContextPath() %>/register" class="nav-link">Create Account</a></li>
        </ul>
        <div class="nav-actions">
            <a href="<%= request.getContextPath() %>/register" class="btn btn-primary btn-sm">Register as Driver</a>
        </div>
    </nav>

    <!-- Main Content -->
    <div class="container" style="max-width: 480px; margin-top: 40px; margin-bottom: 60px;">
        <div class="card" style="padding: 36px 32px;">
            <div style="text-align: center; margin-bottom: 28px;">
                <div class="brand-icon" style="margin: 0 auto 12px; width: 46px; height: 46px; font-size: 1.5rem;">P</div>
                <h2 style="font-size: 1.6rem; font-weight: 800; color: var(--color-primary);">Sign In to Smart Parking</h2>
                <p style="color: var(--text-muted); font-size: 0.9rem; margin-top: 4px;">Access real-time bay reservations, digital passes & parking ledger</p>
            </div>

            <% if (error != null && !error.isEmpty()) { %>
                <div class="alert alert-danger">
                    <span>⚠️</span>
                    <div><%= error %></div>
                </div>
            <% } %>

            <% if ("logged_out".equals(msg)) { %>
                <div class="alert alert-success">
                    <span>✓</span>
                    <div>You have been safely signed out.</div>
                </div>
            <% } else if ("auth_required".equals(msg)) { %>
                <div class="alert alert-danger">
                    <span>ℹ️</span>
                    <div>Please sign in to proceed with your parking reservation.</div>
                </div>
            <% } %>

            <form id="loginForm" action="<%= request.getContextPath() %>/login" method="POST">
                <input type="hidden" name="action" value="login">

                <div class="form-group">
                    <label class="form-label" for="email">Email Address</label>
                    <input type="email" id="email" name="email" class="form-control" placeholder="driver@smartparking.com" value="<%= enteredEmail %>" required>
                </div>

                <div class="form-group">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <label class="form-label" for="password">Password</label>
                    </div>
                    <input type="password" id="password" name="password" class="form-control" placeholder="••••••••" required>
                </div>

                <button type="submit" class="btn btn-primary btn-block" style="margin-top: 10px; font-size: 1rem; padding: 14px;">
                    Sign In Securely
                </button>
            </form>

            <!-- Quick Demo Credentials Box -->
            <div style="margin-top: 28px; padding: 14px; background: var(--bg-card-alt); border-radius: var(--border-radius-md); font-size: 0.8rem; border: 1px dashed var(--border-color);">
                <div style="font-weight: 700; color: var(--color-primary); margin-bottom: 6px; display: flex; align-items: center; gap: 6px;">
                    <span>⚡</span> <span>Demo Accounts (Instant Testing):</span>
                </div>
                <div style="display: flex; flex-direction: column; gap: 4px; color: var(--text-muted);">
                    <div><strong>Driver:</strong> <code>driver@smartparking.com</code> / <code>Driver@123</code></div>
                    <div><strong>Admin:</strong> <code>admin@smartparking.com</code> / <code>Admin@123</code></div>
                </div>
            </div>

            <div style="text-align: center; margin-top: 24px; font-size: 0.9rem; color: var(--text-muted);">
                Don't have an account? 
                <a href="<%= request.getContextPath() %>/register" style="color: var(--color-accent); font-weight: 700;">Register here</a>
            </div>
        </div>
    </div>

    <!-- Footer -->
    <footer class="footer">
        <div class="footer-container">
            <div>
                <strong>Smart Parking Management System</strong>
                <div style="font-size: 0.82rem; margin-top: 4px;">Dynamic Web Application powered by Java 17 & Apache Tomcat 9</div>
            </div>
            <div class="footer-sdg">
                <span>🌱</span> Real-Time Smart Urban Mobility
            </div>
        </div>
    </footer>

    <script src="<%= request.getContextPath() %>/resources/js/validation.js"></script>
</body>
</html>
