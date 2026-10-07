package com.smartboarding.smartboarding_api.infrastructure.web.list.dto;

import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import jakarta.validation.constraints.NotNull;

public record UpdateListStatusRequest(
        @NotNull ListStatus status,
        @jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Size(max = 500)
        String reason
) {}
