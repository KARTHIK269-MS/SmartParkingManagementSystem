<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ page import="com.parkingsystem.model.User" %>
<%
    response.setStatus(HttpServletResponse.SC_NOT_FOUND);
    User currentUser = (User) session.getAttribute("driverUser");
    if (currentUser == null) currentUser = (User) session.getAttribute("adminUser");
    if (currentUser == null) currentUser = (User) session.getAttribute("user");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="The page you are looking for could not be found - Smart Parking Management System.">
    <title>SmartParking | Page Not Found (404)</title>
    <link rel="icon" type="image/svg+xml" href="<%= request.getContextPath() %>/resources/images/favicon.svg">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <style>
        .error-hero {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 80px 20px;
            min-height: calc(100vh - 240px);
        }
        .error-code {
            font-size: 6rem;
            font-weight: 900;
            line-height: 1;
            color: var(--color-primary);
            letter-spacing: -2px;
            margin-bottom: 12px;
        }
        .error-badge {
            display: inline-block;
            font-size: 0.85rem;
            font-weight: 700;
            padding: 4px 12px;
            border-radius: var(--border-radius-full);
            background: rgba(239, 68, 68, 0.1);
            color: #dc2626;
            border: 1px solid rgba(239, 68, 68, 0.2);
            margin-bottom: 16px;
        }
        .error-title {
            font-size: 1.5rem;
            font-weight: 800;
            color: var(--text-color);
            margin-bottom: 12px;
        }
        .error-desc {
            font-size: 0.95rem;
            color: var(--text-muted);
            max-width: 480px;
            margin: 0 auto 28px;
            line-height: 1.6;
        }
        .error-actions {
            display: flex;
            gap: 12px;
            justify-content: center;
            flex-wrap: wrap;
        }
    </style>
</head>
<body>

    <!-- Navigation Bar -->
    <nav class="navbar" role="navigation">
        <a href="<%= request.getContextPath() %>/zones" class="navbar-brand">
            <div class="brand-icon">P</div>
            <span>SmartParking<span class="brand-tag">SYSTEM</span></span>
        </a>
        <ul class="nav-links">
            <li><a href="<%= request.getContextPath() %>/zones" class="nav-link">Parking Zones</a></li>
            <% if (currentUser != null) { %>
                <li><a href="<%= request.getContextPath() %>/booking?action=myBookings" class="nav-link">My Bookings</a></li>
                <% if (currentUser.isAdmin()) { %>
                    <li><a href="<%= request.getContextPath() %>/admin?action=dashboard" class="nav-link" style="color: var(--color-cyan);">Admin Console</a></li>
                <% } %>
            <% } else { %>
                <li><a href="<%= request.getContextPath() %>/login" class="nav-link">Sign In</a></li>
            <% } %>
        </ul>
        <div class="nav-actions">
            <% if (currentUser != null) { %>
                <span class="user-greeting">Hi, <%= currentUser.getName().split(" ")[0] %></span>
                <a href="<%= request.getContextPath() %>/logout" class="btn btn-outline btn-sm">Sign Out</a>
            <% } else { %>
                <a href="<%= request.getContextPath() %>/login" class="btn btn-primary btn-sm">Sign In</a>
            <% } %>
        </div>
    </nav>

    <!-- Main 404 Container -->
    <main class="container">
        <div class="error-hero">
            <div class="error-badge">HTTP Error 404</div>
            <div class="error-code">404</div>
            <h1 class="error-title">Page Not Found</h1>
            <p class="error-desc">
                The page you're looking for doesn't exist, has been relocated, or is temporarily unavailable in this session.
            </p>
            <div class="error-actions">
                <a href="<%= request.getContextPath() %>/zones" class="btn btn-primary">
                    Return to Parking Zones
                </a>
                <% if (currentUser != null) { %>
                    <a href="<%= request.getContextPath() %>/booking?action=myBookings" class="btn btn-secondary">
                        View My Bookings
                    </a>
                <% } else { %>
                    <a href="<%= request.getContextPath() %>/login" class="btn btn-secondary">
                        Driver Sign In
                    </a>
                <% } %>
            </div>
        </div>
    </main>

    <!-- Academic Footer -->
    <footer class="footer" role="contentinfo">
        <div class="footer-container">
            <div>
                <div class="footer-brand">SmartParking</div>
                <div class="footer-sub">Smart Parking Management System • Academic Mini Project</div>
                <div class="footer-sub" style="margin-top: 4px;">Developed with Java 17, JSP, Servlets, JDBC &amp; MySQL</div>
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

    <script src="<%= request.getContextPath() %>/resources/js/cookieConsent.js"></script>
</body>
</html>
