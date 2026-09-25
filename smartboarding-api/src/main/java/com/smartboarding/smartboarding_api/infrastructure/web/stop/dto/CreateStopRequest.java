package com.smartboarding.smartboarding_api.infrastructure.web.stop.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

/// [institutionId] é o que torna a parada um ponto principal (RN23) -- é dela
/// que sai o "tempo até a sua instituição" de cada aluno.
///
/// [mainPoint] existe pra rodoviária, que é ponto principal sem ser
/// instituição nenhuma. Nulo conta como falso.
public record CreateStopRequest(
        @NotBlank(message = "name can't be empty") @Size(max = 150) String name,
        Double latitude,
        Double longitude,
        Integer sequence,
        UUID institutionId,
        Boolean mainPoint
) {
    public boolean isMainPoint() {
        return Boolean.TRUE.equals(mainPoint);
    }
}
