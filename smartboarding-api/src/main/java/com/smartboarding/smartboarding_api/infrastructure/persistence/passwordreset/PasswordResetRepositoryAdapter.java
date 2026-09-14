package com.smartboarding.smartboarding_api.infrastructure.persistence.passwordreset;

import com.smartboarding.smartboarding_api.domain.passwordreset.entity.PasswordResetRequest;
import com.smartboarding.smartboarding_api.domain.passwordreset.port.out.PasswordResetRepositoryPort;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Component
public class PasswordResetRepositoryAdapter implements PasswordResetRepositoryPort {

    private final PasswordResetJpaRepository jpaRepository;

    public PasswordResetRepositoryAdapter(PasswordResetJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public PasswordResetRequest save(PasswordResetRequest request) {
        return jpaRepository.save(request);
    }

    @Override
    public Optional<PasswordResetRequest> findLatestOpenByUserId(UUID userId) {
        return jpaRepository.findTopByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(userId);
    }

    @Override
    // O reset() roda sem transacao de proposito, entao o update precisa abrir a
    // dele: @Modifying sem transacao por perto nao executa.
    @Transactional
    public void invalidateAllForUser(UUID userId, LocalDateTime at) {
        jpaRepository.invalidateAllForUser(userId, at);
    }
}
