package com.smartboarding.smartboarding_api.shared.exception;

public class ConflictException extends AppException {
    public ConflictException(String code, String message) {
        super(code, message);
    }
}
