package com.smartboarding.smartboarding_api.infrastructure.persistence.emailchange;

import com.smartboarding.smartboarding_api.domain.emailchange.entity.EmailChangeRequest;
import com.smartboarding.smartboarding_api.domain.emailchange.port.out.EmailChangeRepositoryPort;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Component
public class EmailChangeRepositoryAdapter implements EmailChangeRepositoryPort {

    private final EmailChangeJpaRepository jpaRepository;

    public EmailChangeRepositoryAdapter(EmailChangeJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public EmailChangeRequest save(EmailChangeRequest request) {
        return jpaRepository.save(request);
    }

    @Override
    public Optional<EmailChangeRequest> findLatestOpenByUserId(UUID userId) {
        return jpaRepository.findTopByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(userId);
    }

    @Override
    @Transactional
    public void invalidateAllForUser(UUID userId, LocalDateTime at) {
        jpaRepository.invalidateAllForUser(userId, at);
    }
}
