package com.smartboarding.smartboarding_api.domain.stop.port.in;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;

import java.util.List;
import java.util.UUID;

public interface ManageStopsUseCase {
    List<Stop> listByRoute(UUID routeId);

    /// Sequência nula acrescenta no fim; preenchida insere naquela posição e
    /// empurra as seguintes.
    Stop add(Stop stop);

    /// Move ou renomeia. Campos nulos ficam como estão.
    Stop update(UUID stopId, String name, Double latitude, Double longitude);

    void remove(UUID stopId);
}
