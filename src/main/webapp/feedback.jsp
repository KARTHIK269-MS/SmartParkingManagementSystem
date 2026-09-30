<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%@ page import="com.parkingsystem.model.Booking" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login?msg=auth_required");
        return;
    }
    Booking booking = (Booking) request.getAttribute("booking");
    if (booking == null) {
        response.sendRedirect(request.getContextPath() + "/booking?action=myBookings");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Feedback & Rating | Smart Parking System</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <style>
        .star-item {
            font-size: 2.2rem;
            cursor: pointer;
            color: #cbd5e1;
            transition: color 0.2s ease;
        }
        .star-item.active, .star-item:hover, .star-item.hovered {
            color: #f59e0b;
        }
        .tag-pill {
            display: inline-block;
            background: var(--bg-card-alt);
            border: 1px solid var(--border-color);
            padding: 6px 14px;
            border-radius: var(--border-radius-full);
            font-size: 0.82rem;
            color: var(--text-muted);
            cursor: pointer;
            user-select: none;
            transition: var(--transition);
        }
        .tag-pill.selected {
            background: var(--color-status-available-bg);
            border-color: var(--color-status-available);
            color: #065f46;
            font-weight: 600;
        }
    </style>
</head>
<body>

    <!-- Navigation Bar -->
    <nav class="navbar">
        <a href="<%= request.getContextPath() %>/zones" class="navbar-brand">
            <div class="brand-icon">P</div>
            <span>SmartParking<span class="brand-tag">SYSTEM</span></span>
        </a>
        <ul class="nav-links">
            <li><a href="<%= request.getContextPath() %>/zones" class="nav-link">Zones</a></li>
            <li><a href="<%= request.getContextPath() %>/booking?action=myBookings" class="nav-link">My Bookings</a></li>
        </ul>
        <div class="nav-actions">
            <div class="user-badge">
                <div class="user-avatar"><%= currentUser.getName().substring(0, 1).toUpperCase() %></div>
                <span><%= currentUser.getName() %></span>
            </div>
            <a href="<%= request.getContextPath() %>/login?action=logout" class="btn btn-secondary btn-sm">Sign Out</a>
        </div>
    </nav>

    <!-- Main Container -->
    <main class="container" style="max-width: 600px;">
        <div class="card" style="padding: 36px 32px;">
            <div style="margin-bottom: 24px; text-align: center;">
                <div style="font-size: 2.5rem; margin-bottom: 8px;">🌟</div>
                <h2 style="font-size: 1.6rem; font-weight: 800; color: var(--color-primary);">How Was Your Parking Experience?</h2>
                <p style="color: var(--text-muted); font-size: 0.9rem; margin-top: 4px;">
                    Reservation #<%= booking.getBookingId() %> &bull; Bay <%= booking.getSlotId() %> (<%= booking.getVehicleNumber() %>)
                </p>
            </div>

            <form action="<%= request.getContextPath() %>/booking" method="POST">
                <input type="hidden" name="action" value="submitFeedback">
                <input type="hidden" name="bookingId" value="<%= booking.getBookingId() %>">
                <input type="hidden" id="ratingInput" name="rating" value="5">

                <!-- Interactive Star Rating -->
                <div style="text-align: center; margin-bottom: 24px;">
                    <div style="display: inline-flex; gap: 8px;" id="starContainer">
                        <span class="star-item active" data-value="1">★</span>
                        <span class="star-item active" data-value="2">★</span>
                        <span class="star-item active" data-value="3">★</span>
                        <span class="star-item active" data-value="4">★</span>
                        <span class="star-item active" data-value="5">★</span>
                    </div>
                    <div style="font-size: 0.9rem; font-weight: 700; color: var(--color-primary); margin-top: 6px;" id="ratingLabel">
                        5 Stars &bull; Excellent Experience
                    </div>
                </div>

                <!-- Quick Tags -->
                <div class="form-group">
                    <label class="form-label" style="font-size: 0.85rem;">What did you like the most?</label>
                    <div style="display: flex; flex-wrap: wrap; gap: 8px;" id="tagsContainer">
                        <span class="tag-pill selected" onclick="toggleTag(this, 'Accurate Sensor Detection')">Accurate Sensors</span>
                        <span class="tag-pill selected" onclick="toggleTag(this, 'Seamless Contactless Entry')">Seamless Entry</span>
                        <span class="tag-pill" onclick="toggleTag(this, 'Clean & Well Lit Bay')">Well Lit & Clean</span>
                        <span class="tag-pill" onclick="toggleTag(this, 'Clear Multi-Floor Signage')">Clear Signage</span>
                        <span class="tag-pill" onclick="toggleTag(this, 'Quick Digital Checkout')">Fast Checkout</span>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label" for="comment">Additional Comments / Suggestions</label>
                    <textarea id="comment" name="comment" class="form-control" rows="4" 
                              placeholder="Share your experience to help us improve urban parking operations..."></textarea>
                </div>

                <button type="submit" class="btn btn-primary btn-block" style="font-size: 1rem; padding: 14px;">
                    Submit Parking Review &rarr;
                </button>
            </form>
        </div>
    </main>

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

    <script>
        const ratingInput = document.getElementById('ratingInput');
        const stars = document.querySelectorAll('.star-item');
        const label = document.getElementById('ratingLabel');
        const commentBox = document.getElementById('comment');

        const labels = {
            1: '1 Star • Poor',
            2: '2 Stars • Fair',
            3: '3 Stars • Good',
            4: '4 Stars • Very Good',
            5: '5 Stars • Excellent Experience'
        };

        stars.forEach(star => {
            star.addEventListener('click', function () {
                const val = parseInt(this.dataset.value);
                ratingInput.value = val;
                label.textContent = labels[val];
                stars.forEach((s, idx) => {
                    if (idx < val) s.classList.add('active');
                    else s.classList.remove('active');
                });
            });
        });

        function toggleTag(el, tagText) {
            el.classList.toggle('selected');
            let current = commentBox.value.trim();
            if (el.classList.contains('selected')) {
                if (current.length > 0 && !current.includes(tagText)) {
                    commentBox.value = current + ', ' + tagText;
                } else if (current.length === 0) {
                    commentBox.value = tagText;
                }
            }
        }
    </script>
</body>
</html>
