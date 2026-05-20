package com.smartboarding.smartboarding_api.shared.web;

import java.util.Map;

public record ApiResponse<T>(T data) {

    public static <T> ApiResponse<T> data(T body) {
        return new ApiResponse<>(body);
    }

    public static ApiResponse<Map<String, Boolean>> success() {
        return new ApiResponse<>(Map.of("success", true));
    }
}
