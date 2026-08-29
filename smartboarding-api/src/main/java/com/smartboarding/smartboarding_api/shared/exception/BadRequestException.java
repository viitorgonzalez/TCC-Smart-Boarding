package com.smartboarding.smartboarding_api.shared.exception;

public class BadRequestException extends AppException {
    public BadRequestException(String code, String message) {
        super(code, message);
    }
}
