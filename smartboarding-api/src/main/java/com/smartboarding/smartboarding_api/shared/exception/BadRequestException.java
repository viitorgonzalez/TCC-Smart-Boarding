package com.smartboarding.smartboarding_api.shared.exception;

import java.util.Map;

public class BadRequestException extends AppException {
    public BadRequestException(String code, String message) {
        super(code, message);
    }

    public BadRequestException(String code, String message, Map<String, Object> details) {
        super(code, message, details);
    }
}
