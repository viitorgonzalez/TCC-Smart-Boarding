package com.smartboarding.smartboarding_api.domain.list.port.in;

import java.util.UUID;

public interface RemoveEntryUseCase {
    void remove(UUID userId, UUID listId);
}
