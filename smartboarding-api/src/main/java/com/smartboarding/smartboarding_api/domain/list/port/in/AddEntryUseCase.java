package com.smartboarding.smartboarding_api.domain.list.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;

import java.util.UUID;

public interface AddEntryUseCase {
    ListEntry add(UUID userId, UUID listId);
}
