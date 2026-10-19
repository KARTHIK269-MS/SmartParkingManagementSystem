package com.parkingsystem.util;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import java.util.UUID;

/**
 * Basic CSRF (Cross-Site Request Forgery) protection helper.
 * Designed for a student college project to demonstrate web form security.
 * Generates and validates a session-bound token for POST form submissions.
 */
public class CsrfUtil {

    public static final String CSRF_PARAM = "csrfToken";
    public static final String CSRF_SESSION_ATTR = "csrfToken";

    /**
     * Gets existing CSRF token from session or generates a new one.
     */
    public static String getToken(HttpServletRequest request) {
        if (request == null) return "";
        HttpSession session = request.getSession(true);
        String token = (String) session.getAttribute(CSRF_SESSION_ATTR);
        if (token == null) {
            token = UUID.randomUUID().toString();
            session.setAttribute(CSRF_SESSION_ATTR, token);
        }
        return token;
    }

    /**
     * Checks if the CSRF token in the request matches the session token.
     * Returns true if valid, false otherwise.
     */
    public static boolean isValid(HttpServletRequest request) {
        if (request == null) return false;
        HttpSession session = request.getSession(false);
        if (session == null) return false;
        String sessionToken = (String) session.getAttribute(CSRF_SESSION_ATTR);
        if (sessionToken == null) return false;
        String requestToken = request.getParameter(CSRF_PARAM);
        if (requestToken == null || requestToken.trim().isEmpty()) {
            requestToken = request.getHeader("X-CSRF-TOKEN");
        }
        return sessionToken.equals(requestToken);
    }
}
