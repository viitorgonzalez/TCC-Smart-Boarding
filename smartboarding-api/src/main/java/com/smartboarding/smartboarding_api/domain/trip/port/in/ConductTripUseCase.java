package com.smartboarding.smartboarding_api.domain.trip.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;

import java.util.UUID;

/// Ações de trajeto são exclusivas do ADMIN (RN23) — não existe papel de
/// motorista separado. Valem com a lista OPEN ou CLOSED: o embarque físico
/// acontece depois do fechamento.
public interface ConductTripUseCase {
    DailyList start(UUID listId);

    DailyList checkpoint(UUID listId, UUID stopId);

    DailyList finish(UUID listId);
}
