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

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/register.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String phone = request.getParameter("phoneNumber");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");

        // Basic CSRF check for security demonstration
        if (request.getParameter("csrfToken") != null && !com.parkingsystem.util.CsrfUtil.isValid(request)) {
            request.setAttribute("errorMessage", "Session expired or invalid security token. Please try again.");
            forwardWithInputs(request, response, name, email, phone);
            return;
        }

        // Basic server-side validation
        if (name == null || name.trim().isEmpty() ||
            email == null || email.trim().isEmpty() ||
            password == null || password.trim().isEmpty()) {
            request.setAttribute("errorMessage", "All required fields must be filled.");
            forwardWithInputs(request, response, name, email, phone);
            return;
        }

        if (!password.equals(confirmPassword)) {
            request.setAttribute("errorMessage", "Passwords do not match.");
            forwardWithInputs(request, response, name, email, phone);
            return;
        }

        if (password.length() < 6) {
            request.setAttribute("errorMessage", "Password must be at least 6 characters in length.");
            forwardWithInputs(request, response, name, email, phone);
            return;
        }

        String termsConsent = request.getParameter("termsConsent");
        if (termsConsent == null || termsConsent.trim().isEmpty()) {
            request.setAttribute("errorMessage", "You must agree to the Terms of Service, Privacy Policy (DPDP Act), and Cookie Policy to register.");
            forwardWithInputs(request, response, name, email, phone);
            return;
        }

        try {
            User existing = userDAO.findByEmail(email.trim());
            if (existing != null) {
                request.setAttribute("errorMessage", "An account with email " + email + " already exists.");
                forwardWithInputs(request, response, name, email, phone);
                return;
            }

            String userId = userDAO.generateNextUserId();
            String passwordHash = PasswordHasher.hash(password);

            User newUser = new User(userId, name.trim(), email.trim().toLowerCase(), passwordHash, phone != null ? phone.trim() : "", "USER");
            boolean success = userDAO.register(newUser);

            if (success) {
                HttpSession session = request.getSession();
                session.setAttribute("driverUser", newUser);
                session.setAttribute("user", newUser);
                response.sendRedirect(request.getContextPath() + "/zones?msg=welcome");
            } else {
                request.setAttribute("errorMessage", "Registration failed. Please try again.");
                forwardWithInputs(request, response, name, email, phone);
            }

        } catch (DatabaseException e) {
            request.setAttribute("errorMessage", "Database error: " + e.getMessage());
            forwardWithInputs(request, response, name, email, phone);
        }
    }

    private void forwardWithInputs(HttpServletRequest request, HttpServletResponse response,
                                   String name, String email, String phone) throws ServletException, IOException {
        request.setAttribute("enteredName", name);
        request.setAttribute("enteredEmail", email);
        request.setAttribute("enteredPhone", phone);
        request.getRequestDispatcher("/register.jsp").forward(request, response);
    }
}
