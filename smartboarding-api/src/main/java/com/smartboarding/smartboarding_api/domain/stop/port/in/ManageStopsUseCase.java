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

    /// Igual ao acima, mais o vínculo com a instituição e a marcação de ponto
    /// principal.
    ///
    /// Sobrecarga em vez de um parâmetro a mais na assinatura única: os
    /// chamadores que só movem ou renomeiam não têm o que dizer sobre vínculo,
    /// e passar `null, false` ali desvincularia a instituição sem querer.
    Stop update(UUID stopId, String name, Double latitude, Double longitude,
                UUID institutionId, boolean mainPoint);

    void remove(UUID stopId);
}
