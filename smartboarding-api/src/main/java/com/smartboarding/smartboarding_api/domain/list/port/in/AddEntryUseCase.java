package com.smartboarding.smartboarding_api.domain.list.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;

import java.util.UUID;

public interface AddEntryUseCase {
    /**
     * Inscreve o usuário na lista com a direção informada. É idempotente:
     * se já estiver inscrito e ativo, apenas atualiza a direção (editável
     * enquanto a lista estiver aberta).
     */
    ListEntry add(UUID userId, UUID listId, TripType tripType);
}
