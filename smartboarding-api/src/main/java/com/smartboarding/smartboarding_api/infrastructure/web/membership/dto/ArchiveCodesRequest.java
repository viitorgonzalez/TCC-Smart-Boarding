package com.smartboarding.smartboarding_api.infrastructure.web.membership.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public record ArchiveCodesRequest(
        @NotEmpty(message = "informe ao menos um código")
        @Size(max = 200, message = "no máximo 200 códigos por vez")
        List<UUID> codeIds
) {}
