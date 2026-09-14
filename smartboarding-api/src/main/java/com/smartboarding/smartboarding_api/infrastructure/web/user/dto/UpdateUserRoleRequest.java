package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import jakarta.validation.constraints.NotNull;

/// Papel fora do enum e recusado pela desserializacao, antes de chegar na regra.
public record UpdateUserRoleRequest(@NotNull Role role) {}
