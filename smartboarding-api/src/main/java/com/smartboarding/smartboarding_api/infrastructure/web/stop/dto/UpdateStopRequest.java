package com.smartboarding.smartboarding_api.infrastructure.web.stop.dto;

import jakarta.validation.constraints.Size;

import java.util.UUID;

/// Campos nulos ficam como estão — mover manda só as coordenadas, renomear só
/// o nome.
public record UpdateStopRequest(
        @Size(max = 150) String name,
        Double latitude,
        Double longitude,
        UUID institutionId,
        Boolean mainPoint
) {
    /// Distingue "mover a parada" de "mexer no vínculo". Sem isso, arrastar um
    /// pino no mapa mandaria institutionId nulo junto e desvincularia a
    /// instituição sem ninguém pedir.
    public boolean mexeNoVinculo() {
        return institutionId != null || mainPoint != null;
    }

    public boolean isMainPoint() {
        return Boolean.TRUE.equals(mainPoint);
    }
}
