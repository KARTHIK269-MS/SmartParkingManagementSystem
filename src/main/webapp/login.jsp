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
    <meta name="description" content="Sign in to your SmartParking account to reserve bays, view active tickets, and manage bookings.">
    <title>SmartParking | Sign In</title>
    <link rel="icon" type="image/svg+xml" href="<%= request.getContextPath() %>/resources/images/favicon.svg">
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
            <a href="<%= request.getContextPath() %>/register" class="btn btn-primary btn-sm">Register</a>
        </div>
    </nav>

    <!-- Main Content -->
    <div class="container" style="max-width: 440px; margin-top: 36px; margin-bottom: 50px;">
        <div class="card" style="padding: 32px 28px;">
            <div style="text-align: center; margin-bottom: 24px;">
                <div class="brand-icon" style="margin: 0 auto 10px; width: 40px; height: 40px; font-size: 1.3rem;">P</div>
                <h2 style="font-size: 1.45rem; font-weight: 700; color: var(--color-primary);">Sign In</h2>
                <p style="color: var(--text-muted); font-size: 0.88rem; margin-top: 4px;">Access your parking reservations and passes</p>
            </div>

            <% if (error != null && !error.isEmpty()) { %>
                <div class="alert alert-danger">
                    <span>⚠️</span>
                    <div><%= com.parkingsystem.util.HtmlEscaper.escape(error) %></div>
                </div>
            <% } %>

            <% if ("logged_out".equals(msg)) { %>
                <div class="alert alert-success">
                    <span>✓</span>
                    <div>You have been signed out.</div>
                </div>
            <% } else if ("auth_required".equals(msg)) { %>
                <div class="alert alert-danger">
                    <span>ℹ️</span>
                    <div>Please sign in to proceed with your booking.</div>
                </div>
            <% } %>

            <form id="loginForm" action="<%= request.getContextPath() %>/login" method="POST">
                <input type="hidden" name="action" value="login">
                <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">

                <div class="form-group">
                    <label class="form-label" for="email">Email Address</label>
                    <input type="email" id="email" name="email" class="form-control" placeholder="name@example.com" value="<%= com.parkingsystem.util.HtmlEscaper.escape(enteredEmail) %>" required>
                </div>

                <div class="form-group">
                    <label class="form-label" for="password">Password</label>
                    <input type="password" id="password" name="password" class="form-control" placeholder="••••••••" required>
                </div>

                <button type="submit" class="btn btn-primary btn-block" style="margin-top: 10px; font-size: 0.95rem; padding: 12px;">
                    Sign In
                </button>
            </form>

            <div style="text-align: center; margin-top: 20px; font-size: 0.85rem; color: var(--text-muted);">
                Don't have an account? 
                <a href="<%= request.getContextPath() %>/register" style="color: var(--color-accent); font-weight: 600;">Register here</a>
            </div>
        </div>
    </div>

    <!-- Standardized Academic Footer -->
    <footer class="footer" role="contentinfo">
        <div class="footer-container">
            <div>
                <div class="footer-brand">SmartParking</div>
                <div class="footer-sub">Smart Parking Management System • Academic Mini Project</div>
                <div class="footer-sub" style="margin-top: 4px;">Developed with Java 17, JSP, Servlets, JDBC & MySQL</div>
            </div>
            <div style="text-align: right;">
                <div class="footer-links" style="margin-bottom: 6px; justify-content: flex-end;">
                    <a href="<%= request.getContextPath() %>/privacy.jsp">Privacy Policy</a>
                    <a href="<%= request.getContextPath() %>/terms.jsp">Terms &amp; Conditions</a>
                    <a href="<%= request.getContextPath() %>/cookies.jsp">Cookie Policy</a>
                    <a href="<%= request.getContextPath() %>/refund.jsp">Refund Policy</a>
                </div>
                <div class="footer-sub">&copy; 2026 SmartParking. For Academic Demonstration.</div>
            </div>
        </div>
    </footer>

    <script src="<%= request.getContextPath() %>/resources/js/validation.js"></script>
    <script src="<%= request.getContextPath() %>/resources/js/cookieConsent.js"></script>
</body>
</html>
