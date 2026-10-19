package com.parkingsystem.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Password Hashing Utility using BCrypt.
 * Hashes passwords with salt rounds and provides verification against both
 * modern BCrypt hashes and legacy SHA-256 hashes for smooth academic demonstration.
 */
public class PasswordHasher {

    /**
     * Hashes a plaintext password using BCrypt with salt rounds = 10.
     */
    public static String hash(String password) {
        if (password == null) {
            return null;
        }
        return BCrypt.hashpw(password, BCrypt.gensalt(10));
    }

    /**
     * Legacy SHA-256 hash helper for backward compatibility with seeded test accounts.
     */
    public static String hashSha256(String password) {
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

    /**
     * Verifies an input password against a stored hash.
     * Supports BCrypt hashes ($2a$, $2b$, $2y$) and legacy SHA-256 hashes.
     */
    public static boolean verify(String inputPassword, String storedHash) {
        if (inputPassword == null || storedHash == null) {
            return false;
        }

        // Direct match if pre-hashed or identical
        if (inputPassword.equalsIgnoreCase(storedHash)) {
            return true;
        }

        // BCrypt verification
        if (storedHash.startsWith("$2a$") || storedHash.startsWith("$2b$") || storedHash.startsWith("$2y$")) {
            return BCrypt.checkpw(inputPassword, storedHash);
        }

        // Legacy SHA-256 verification
        String sha256 = hashSha256(inputPassword);
        return sha256.equalsIgnoreCase(storedHash);
    }
}
