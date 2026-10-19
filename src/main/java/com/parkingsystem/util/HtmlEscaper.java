package com.parkingsystem.util;

/**
 * Basic HTML escaping utility to prevent Cross-Site Scripting (XSS).
 * Simple and easy to understand for student project demonstration.
 */
public class HtmlEscaper {

    public static String escape(String input) {
        if (input == null) {
            return "";
        }
        return input.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#x27;");
    }
}
