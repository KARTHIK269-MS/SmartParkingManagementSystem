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
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || email.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            request.setAttribute("errorMessage", "Please provide both email address and password.");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        try {
            String passwordHash = PasswordHasher.hash(password);
            User user = userDAO.authenticate(email.trim(), passwordHash);

            if (user == null) {
                request.setAttribute("errorMessage", "Invalid email or password. Please try again.");
                request.setAttribute("enteredEmail", email);
                request.getRequestDispatcher("/login.jsp").forward(request, response);
                return;
            }

            HttpSession session = request.getSession();
            session.setAttribute("user", user);

            if (user.isAdmin()) {
                response.sendRedirect(request.getContextPath() + "/admin?action=dashboard");
            } else {
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
            session.invalidate();
        }
        response.sendRedirect(request.getContextPath() + "/login?msg=logged_out");
    }
}
