package com.parkingsystem.exception;

public class SlotUnavailableException extends Exception {
    private static final long serialVersionUID = 1L;

    public SlotUnavailableException(String message) {
        super(message);
    }

    public SlotUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }
}
