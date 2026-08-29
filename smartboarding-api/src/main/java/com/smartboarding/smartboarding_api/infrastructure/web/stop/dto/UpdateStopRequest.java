package com.smartboarding.smartboarding_api.infrastructure.web.stop.dto;

import jakarta.validation.constraints.Size;

/// Campos nulos ficam como estão — mover manda só as coordenadas, renomear só
/// o nome.
public record UpdateStopRequest(
        @Size(max = 150) String name,
        Double latitude,
        Double longitude
) {}
