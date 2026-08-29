package com.smartboarding.smartboarding_api.domain.notification.port.in;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;

import java.util.UUID;

public interface PublishNotificationUseCase {
    /// Grava o aviso e dispara o push. Todo aviso pertence a uma rota — quem
    /// recebe é quem pega aquela rota. `durationHours` nulo = sem prazo.
    Notification publish(String title, String body, UUID routeId, Integer durationHours, UUID authorId);

    void deleteAll(java.util.List<UUID> ids);
}
