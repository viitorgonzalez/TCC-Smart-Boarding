package com.smartboarding.smartboarding_api.infrastructure.web.common;

import com.smartboarding.smartboarding_api.shared.exception.AppException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.Map;

@Slf4j
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(NotFoundException ex) {
        return ResponseEntity.status(404).body(errorBody(ex));
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<Map<String, String>> handleConflict(ConflictException ex) {
        return ResponseEntity.status(409).body(errorBody(ex));
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, String>> handleUnauthorized(UnauthorizedException ex) {
        return ResponseEntity.status(401).body(errorBody(ex));
    }

    @ExceptionHandler(com.smartboarding.smartboarding_api.shared.exception.BadRequestException.class)
    public ResponseEntity<Map<String, String>> handleBadRequest(
            com.smartboarding.smartboarding_api.shared.exception.BadRequestException ex) {
        return ResponseEntity.status(400).body(errorBody(ex));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
        String msg = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getField() + ": " + e.getDefaultMessage())
                .findFirst()
                .orElse("Dados inválidos");
        return ResponseEntity.status(400).body(Map.of("code", "VALIDATION_ERROR", "error", msg));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneric(Exception ex) {
        log.error("Erro não tratado", ex);
        return ResponseEntity.status(500).body(Map.of("code", "INTERNAL_SERVER_ERROR", "error", "Erro interno no servidor"));
    }

    private Map<String, String> errorBody(AppException ex) {
        return Map.of("code", ex.getCode(), "error", ex.getMessage());
    }
}
