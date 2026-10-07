package com.smartboarding.smartboarding_api.shared.exception;

public class ForbiddenException extends AppException {
    public ForbiddenException(String code, String message) {
        super(code, message);
    }
}
