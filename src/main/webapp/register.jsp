<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String error = (String) request.getAttribute("errorMessage");
    String enteredName = (String) request.getAttribute("enteredName");
    String enteredEmail = (String) request.getAttribute("enteredEmail");
    String enteredPhone = (String) request.getAttribute("enteredPhone");
    if (enteredName == null) enteredName = "";
    if (enteredEmail == null) enteredEmail = "";
    if (enteredPhone == null) enteredPhone = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Driver Registration | Smart Parking Management System</title>
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
            <li><a href="<%= request.getContextPath() %>/login" class="nav-link">Sign In</a></li>
        </ul>
        <div class="nav-actions">
            <a href="<%= request.getContextPath() %>/login" class="btn btn-secondary btn-sm">Already Registered? Sign In</a>
        </div>
    </nav>

    <!-- Main Content -->
    <div class="container" style="max-width: 520px; margin-top: 32px; margin-bottom: 60px;">
        <div class="card" style="padding: 36px 32px;">
            <div style="text-align: center; margin-bottom: 24px;">
                <h2 style="font-size: 1.6rem; font-weight: 800; color: var(--color-primary);">Create Driver Account</h2>
                <p style="color: var(--text-muted); font-size: 0.9rem; margin-top: 4px;">Join the intelligent parking network for guaranteed bay reservation</p>
            </div>

            <% if (error != null && !error.isEmpty()) { %>
                <div class="alert alert-danger">
                    <span>⚠️</span>
                    <div><%= error %></div>
                </div>
            <% } %>

            <form id="registerForm" action="<%= request.getContextPath() %>/register" method="POST">
                <div class="form-group">
                    <label class="form-label" for="name">Full Name</label>
                    <input type="text" id="name" name="name" class="form-control" placeholder="e.g. Rahul Sharma" value="<%= enteredName %>" required>
                </div>

                <div class="form-group">
                    <label class="form-label" for="email">Email Address</label>
                    <input type="email" id="email" name="email" class="form-control" placeholder="rahul@example.com" value="<%= enteredEmail %>" required>
                </div>

                <div class="form-group">
                    <label class="form-label" for="phoneNumber">Mobile Number (10 digits)</label>
                    <input type="tel" id="phoneNumber" name="phoneNumber" class="form-control" placeholder="9876543210" value="<%= enteredPhone %>">
                </div>

                <div class="form-group">
                    <label class="form-label" for="password">Password (min. 6 characters)</label>
                    <input type="password" id="password" name="password" class="form-control" placeholder="••••••••" required>
                </div>

                <div class="form-group">
                    <label class="form-label" for="confirmPassword">Confirm Password</label>
                    <input type="password" id="confirmPassword" name="confirmPassword" class="form-control" placeholder="••••••••" required>
                </div>

                <button type="submit" class="btn btn-primary btn-block" style="margin-top: 14px; font-size: 1rem; padding: 14px;">
                    Complete Registration
                </button>
            </form>

            <div style="text-align: center; margin-top: 24px; font-size: 0.9rem; color: var(--text-muted);">
                Already have an account? 
                <a href="<%= request.getContextPath() %>/login" style="color: var(--color-accent); font-weight: 700;">Sign in here</a>
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
