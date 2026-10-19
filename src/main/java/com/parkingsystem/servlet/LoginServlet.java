package com.parkingsystem.servlet;

import com.parkingsystem.dao.UserDAO;
import com.parkingsystem.exception.DatabaseException;
import com.parkingsystem.model.User;
import com.parkingsystem.util.PasswordHasher;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        if (action == null) action = "view";

        switch (action) {
            case "logout":
                handleLogout(request, response);
                break;
            case "view":
            default:
                request.getRequestDispatcher("/login.jsp").forward(request, response);
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        if (action == null) action = "login";

        if ("login".equalsIgnoreCase(action)) {
            handleLogin(request, response);
        } else {
            doGet(request, response);
        }
    }

    private void handleLogin(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Basic CSRF check for security demonstration
        if (request.getParameter("csrfToken") != null && !com.parkingsystem.util.CsrfUtil.isValid(request)) {
            request.setAttribute("errorMessage", "Session expired or invalid security token. Please try again.");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || email.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            request.setAttribute("errorMessage", "Please provide both email address and password.");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        try {
            User user = userDAO.authenticate(email.trim(), password);

            if (user == null) {
                request.setAttribute("errorMessage", "Invalid email or password. Please try again.");
                request.setAttribute("enteredEmail", email);
                request.getRequestDispatcher("/login.jsp").forward(request, response);
                return;
            }

            HttpSession session = request.getSession();
            if (user.isAdmin()) {
                session.setAttribute("adminUser", user);
                // Set fallback "user" if no driver is currently logged in
                if (session.getAttribute("driverUser") == null) {
                    session.setAttribute("user", user);
                }
                response.sendRedirect(request.getContextPath() + "/admin?action=dashboard");
            } else {
                session.setAttribute("driverUser", user);
                session.setAttribute("user", user);
                response.sendRedirect(request.getContextPath() + "/zones");
            }

        } catch (DatabaseException e) {
            request.setAttribute("errorMessage", "System error during authentication: " + e.getMessage());
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        }
    }

    private void handleLogout(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession(false);
        if (session != null) {
            String role = request.getParameter("role");
            if ("admin".equalsIgnoreCase(role)) {
                session.removeAttribute("adminUser");
                User driverUser = (User) session.getAttribute("driverUser");
                if (driverUser != null) {
                    session.setAttribute("user", driverUser);
                } else {
                    session.removeAttribute("user");
                    session.invalidate();
                }
            } else if ("driver".equalsIgnoreCase(role)) {
                session.removeAttribute("driverUser");
                User adminUser = (User) session.getAttribute("adminUser");
                if (adminUser != null) {
                    session.setAttribute("user", adminUser);
                } else {
                    session.removeAttribute("user");
                    session.invalidate();
                }
            } else {
                // If no explicit role specified, check Referer
                String referer = request.getHeader("Referer");
                if (referer != null && referer.contains("/admin")) {
                    session.removeAttribute("adminUser");
                    User driverUser = (User) session.getAttribute("driverUser");
                    if (driverUser != null) {
                        session.setAttribute("user", driverUser);
                    } else {
                        session.removeAttribute("user");
                        session.invalidate();
                    }
                } else {
                    session.removeAttribute("driverUser");
                    User adminUser = (User) session.getAttribute("adminUser");
                    if (adminUser != null) {
                        session.setAttribute("user", adminUser);
                    } else {
                        session.removeAttribute("user");
                        session.invalidate();
                    }
                }
            }
        }
        response.sendRedirect(request.getContextPath() + "/login?msg=logged_out");
    }
}
