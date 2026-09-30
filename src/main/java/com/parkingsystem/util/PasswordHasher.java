package com.parkingsystem.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class PasswordHasher {

    public static String hash(String password) {
        if (password == null) {
            return null;
        }
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = md.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hashBytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Error initializing SHA-256 hasher", e);
        }
    }

    public static boolean verify(String inputPassword, String storedHash) {
        if (inputPassword == null || storedHash == null) {
            return false;
        }
        String hashedInput = hash(inputPassword);
        return hashedInput.equalsIgnoreCase(storedHash);
    }
}
