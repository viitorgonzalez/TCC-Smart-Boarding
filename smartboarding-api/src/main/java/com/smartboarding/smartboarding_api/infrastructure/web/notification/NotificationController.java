package com.smartboarding.smartboarding_api.infrastructure.web.notification;

import com.smartboarding.smartboarding_api.domain.notification.port.in.SendBroadcastUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.notification.dto.BroadcastRequest;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final SendBroadcastUseCase sendBroadcastUseCase;

    public NotificationController(SendBroadcastUseCase sendBroadcastUseCase) {
        this.sendBroadcastUseCase = sendBroadcastUseCase;
    }

    @PostMapping("/broadcast")
    public ResponseEntity<ApiResponse<?>> broadcast(@RequestBody @Valid BroadcastRequest request) {
        sendBroadcastUseCase.execute(request.title(), request.body());
        return ResponseEntity.ok(ApiResponse.success());
    }
}
