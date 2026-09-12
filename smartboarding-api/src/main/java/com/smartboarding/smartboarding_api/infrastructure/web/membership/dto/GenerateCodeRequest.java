package com.smartboarding.smartboarding_api.infrastructure.web.membership.dto;

import java.time.LocalDateTime;

/// Nulo usa a validade padrão da configuração.
public record GenerateCodeRequest(LocalDateTime expiresAt) {}
