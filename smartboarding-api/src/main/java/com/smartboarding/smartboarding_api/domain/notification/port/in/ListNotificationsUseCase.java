package com.smartboarding.smartboarding_api.domain.notification.port.in;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;

import java.util.List;
import java.util.UUID;

public interface ListNotificationsUseCase {
    /// Aluno vê os gerais + os da rota da instituição dele, dentro da validade;
    /// admin vê tudo, inclusive expirados.
    List<Notification> listFor(UUID requesterId);
}
