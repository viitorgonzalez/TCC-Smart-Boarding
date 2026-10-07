package com.smartboarding.smartboarding_api.domain.notification.port.in;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;

import java.util.List;
import java.util.UUID;

public interface ListNotificationsUseCase {
    List<Notification> listFor(UUID requesterId);
}
