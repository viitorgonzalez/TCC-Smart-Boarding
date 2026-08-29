package com.smartboarding.smartboarding_api.infrastructure.web.notification;

import com.smartboarding.smartboarding_api.domain.notification.port.in.ListNotificationsUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.notification.dto.BroadcastRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.notification.dto.NotificationResponse;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final PublishNotificationUseCase publishNotificationUseCase;
    private final ListNotificationsUseCase listNotificationsUseCase;
    private final UserRepositoryPort userRepository;
    private final Clock clock;

    public NotificationController(PublishNotificationUseCase publishNotificationUseCase,
                                  ListNotificationsUseCase listNotificationsUseCase,
                                  UserRepositoryPort userRepository,
                                  Clock clock) {
        this.publishNotificationUseCase = publishNotificationUseCase;
        this.listNotificationsUseCase = listNotificationsUseCase;
        this.userRepository = userRepository;
        this.clock = clock;
    }

    @PostMapping("/broadcast")
    public ResponseEntity<ApiResponse<NotificationResponse>> broadcast(
            @RequestBody @Valid BroadcastRequest request, Authentication auth) {
        var saved = publishNotificationUseCase.publish(
                request.title(), request.body(), request.routeId(),
                request.durationHours(), userId(auth));
        return ResponseEntity.ok(ApiResponse.data(
                NotificationResponse.from(saved, LocalDateTime.now(clock))));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> list(Authentication auth) {
        LocalDateTime now = LocalDateTime.now(clock);
        List<NotificationResponse> items = listNotificationsUseCase.listFor(userId(auth)).stream()
                .map(n -> NotificationResponse.from(n, now))
                .toList();
        return ResponseEntity.ok(ApiResponse.data(items));
    }

    /// Em lote: apagar vários avisos velhos um a um seria N requisições e N
    /// recargas da tela.
    @DeleteMapping
    public ResponseEntity<ApiResponse<?>> delete(@RequestBody List<UUID> ids) {
        publishNotificationUseCase.deleteAll(ids);
        return ResponseEntity.ok(ApiResponse.success());
    }

    private UUID userId(Authentication auth) {
        return userRepository.findByEmail(auth.getName())
                .map(u -> u.getId())
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado: " + auth.getName()));
    }
}
