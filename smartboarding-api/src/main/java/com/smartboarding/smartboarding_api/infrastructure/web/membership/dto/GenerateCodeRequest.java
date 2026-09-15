package com.smartboarding.smartboarding_api.infrastructure.web.membership.dto;

import java.time.LocalDateTime;
import java.util.UUID;

/// [expiresAt] nulo usa a validade padrão da configuração.
/// [institutionId] nulo deixa o código aberto a qualquer instituição.
public record GenerateCodeRequest(LocalDateTime expiresAt, UUID institutionId) {}
