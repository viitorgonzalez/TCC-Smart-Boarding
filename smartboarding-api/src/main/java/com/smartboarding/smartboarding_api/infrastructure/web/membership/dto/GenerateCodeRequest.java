package com.smartboarding.smartboarding_api.infrastructure.web.membership.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record GenerateCodeRequest(LocalDateTime expiresAt, UUID institutionId) {}
