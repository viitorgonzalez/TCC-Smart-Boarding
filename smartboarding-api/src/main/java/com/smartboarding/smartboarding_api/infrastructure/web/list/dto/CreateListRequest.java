package com.smartboarding.smartboarding_api.infrastructure.web.list.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.UUID;

public record CreateListRequest(@NotNull UUID routeId, @NotNull LocalDate date) {}
