package com.smartboarding.smartboarding_api.domain.notification.port.out;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface NotificationRepositoryPort {
    Notification save(Notification notification);

    /// Avisos gerais + os da rota informada, ainda válidos na data dada.
    List<Notification> findVisible(UUID routeId, LocalDateTime now);

    List<Notification> findAll();
    void deleteAllById(List<UUID> ids);
}
