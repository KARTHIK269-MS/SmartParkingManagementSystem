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
    <meta name="description" content="Create a new SmartParking account to reserve parking bays across urban facilities.">
    <title>SmartParking | Create Account</title>
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
            <li><a href="<%= request.getContextPath() %>/login" class="nav-link">Sign In</a></li>
        </ul>
        <div class="nav-actions">
            <a href="<%= request.getContextPath() %>/login" class="btn btn-secondary btn-sm">Sign In</a>
        </div>
    </nav>

    <!-- Main Content -->
    <div class="container" style="max-width: 480px; margin-top: 32px; margin-bottom: 50px;">
        <div class="card" style="padding: 32px 28px;">
            <div style="text-align: center; margin-bottom: 22px;">
                <h2 style="font-size: 1.45rem; font-weight: 700; color: var(--color-primary);">Create Driver Account</h2>
                <p style="color: var(--text-muted); font-size: 0.88rem; margin-top: 4px;">Register to reserve parking bays and manage your permits</p>
            </div>

            <% if (error != null && !error.isEmpty()) { %>
                <div class="alert alert-danger">
                    <span>⚠️</span>
                    <div><%= com.parkingsystem.util.HtmlEscaper.escape(error) %></div>
                </div>
            <% } %>

            <form id="registerForm" action="<%= request.getContextPath() %>/register" method="POST">
                <input type="hidden" name="csrfToken" value="<%= com.parkingsystem.util.CsrfUtil.getToken(request) %>">

                <div class="form-group">
                    <label class="form-label" for="name">Full Name</label>
                    <input type="text" id="name" name="name" class="form-control" placeholder="e.g. Rahul Sharma" value="<%= com.parkingsystem.util.HtmlEscaper.escape(enteredName) %>" required>
                </div>

                <div class="form-group">
                    <label class="form-label" for="email">Email Address</label>
                    <input type="email" id="email" name="email" class="form-control" placeholder="rahul@example.com" value="<%= com.parkingsystem.util.HtmlEscaper.escape(enteredEmail) %>" required>
                </div>

                <div class="form-group">
                    <label class="form-label" for="phoneNumber">Mobile Number (10 digits)</label>
                    <input type="tel" id="phoneNumber" name="phoneNumber" class="form-control" placeholder="9876543210" value="<%= com.parkingsystem.util.HtmlEscaper.escape(enteredPhone) %>">
                </div>

                <div class="form-group">
                    <label class="form-label" for="password">Password (min. 6 characters)</label>
                    <input type="password" id="password" name="password" class="form-control" placeholder="••••••••" required>
                </div>

                <div class="form-group">
                    <label class="form-label" for="confirmPassword">Confirm Password</label>
                    <input type="password" id="confirmPassword" name="confirmPassword" class="form-control" placeholder="••••••••" required>
                </div>

                <div class="form-consent-group">
                    <input type="checkbox" id="termsConsent" name="termsConsent" required>
                    <label for="termsConsent">
                        I agree to the 
                        <a href="<%= request.getContextPath() %>/terms.jsp" target="_blank">Terms &amp; Conditions</a>, 
                        <a href="<%= request.getContextPath() %>/privacy.jsp" target="_blank">Privacy Policy</a>, and 
                        <a href="<%= request.getContextPath() %>/cookies.jsp" target="_blank">Cookie Policy</a>.
                    </label>
                </div>

                <button type="submit" class="btn btn-primary btn-block" style="margin-top: 12px; font-size: 0.95rem; padding: 12px;">
                    Register
                </button>
            </form>

            <div style="text-align: center; margin-top: 20px; font-size: 0.85rem; color: var(--text-muted);">
                Already have an account? 
                <a href="<%= request.getContextPath() %>/login" style="color: var(--color-accent); font-weight: 600;">Sign in here</a>
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
