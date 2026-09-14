package com.smartboarding.smartboarding_api.domain.notification.port.out;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface NotificationRepositoryPort {
    Notification save(Notification notification);

    /// Avisos gerais + os da rota informada, ainda válidos na data dada.
    /// [routeIds] vazio devolve so os avisos gerais.
    List<Notification> findVisible(java.util.Collection<UUID> routeIds, LocalDateTime now);

    List<Notification> findAll();
    void deleteAllById(List<UUID> ids);
}
