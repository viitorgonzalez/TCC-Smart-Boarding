package com.smartboarding.smartboarding_api.domain.notification.port.in;

import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;

import java.util.List;
import java.util.UUID;

public interface ManageScheduledNotificationUseCase {
    List<ScheduledNotification> listByRoute(UUID routeId);
    ScheduledNotification save(ScheduledNotification notification);
    ScheduledNotification toggle(UUID id, boolean active);

    /// Usado pela checagem de alcance: a rota dona precisa vir do aviso
    /// guardado, não do pedido.
    ScheduledNotification findById(UUID id);
    void delete(UUID id);

    /// Dispara os que já venceram. Chamado pela varredura.
    int dispatchDue();
}
