package com.smartboarding.smartboarding_api.infrastructure.web.notification;

import com.smartboarding.smartboarding_api.infrastructure.web.common.AdminGuard;
import org.springframework.security.core.Authentication;

import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;
import com.smartboarding.smartboarding_api.domain.notification.port.in.ManageScheduledNotificationUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.notification.dto.ScheduledNotificationRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.notification.dto.ScheduledNotificationResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/notifications/scheduled")
public class ScheduledNotificationController {

    private final ManageScheduledNotificationUseCase useCase;
    private final AdminGuard guard;

    public ScheduledNotificationController(ManageScheduledNotificationUseCase useCase,
                                            AdminGuard guard) {
        this.useCase = useCase;
        this.guard = guard;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ScheduledNotificationResponse>>> list(
            @RequestParam UUID routeId, Authentication auth) {
        guard.ownsRoute(auth, routeId);
        List<ScheduledNotificationResponse> items = useCase.listByRoute(routeId).stream()
                .map(ScheduledNotificationResponse::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.data(items));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ScheduledNotificationResponse>> create(
            @RequestBody @Valid ScheduledNotificationRequest request, Authentication auth) {
        guard.ownsRoute(auth, request.routeId());
        ScheduledNotification saved = useCase.save(ScheduledNotification.builder()
                .routeId(request.routeId())
                .title(request.title())
                .body(request.body())
                .frequency(request.frequency())
                .sendAt(request.sendAt())
                .dayOfWeek(request.dayOfWeek())
                .durationHours(request.durationHours())
                .active(true)
                .build());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.data(ScheduledNotificationResponse.from(saved)));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<ScheduledNotificationResponse>> toggle(
            @PathVariable UUID id, @RequestBody Map<String, Boolean> body,
            Authentication auth) {
        guard.ownsRoute(auth, useCase.findById(id).getRouteId());
        boolean active = Boolean.TRUE.equals(body.get("active"));
        return ResponseEntity.ok(ApiResponse.data(
                ScheduledNotificationResponse.from(useCase.toggle(id, active))));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> delete(@PathVariable UUID id, Authentication auth) {
        guard.ownsRoute(auth, useCase.findById(id).getRouteId());
        useCase.delete(id);
        return ResponseEntity.ok(ApiResponse.success());
    }
}
