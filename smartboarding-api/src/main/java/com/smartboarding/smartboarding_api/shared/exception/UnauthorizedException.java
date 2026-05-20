package com.smartboarding.smartboarding_api.shared.exception;

public class UnauthorizedException extends AppException {
    public UnauthorizedException(String message) {
        super("UNAUTHORIZED", message);
    }
}
