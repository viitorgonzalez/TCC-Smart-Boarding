package com.smartboarding.smartboarding_api.infrastructure.persistence.warning;

import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;
import com.smartboarding.smartboarding_api.domain.warning.port.out.WarningRepositoryPort;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
public class WarningRepositoryAdapter implements WarningRepositoryPort {

    private final WarningJpaRepository jpaRepository;

    public WarningRepositoryAdapter(WarningJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public Warning save(Warning warning) {
        return jpaRepository.save(warning);
    }

    @Override
    public List<Warning> findAllByUserId(UUID userId) {
        return jpaRepository.findAllByUserIdOrderByCreatedAtDesc(userId);
    }

    @Override
    public List<Warning> findAll() {
        return jpaRepository.findAllByOrderByCreatedAtDesc();
    }

    @Override
    public void deleteById(UUID id) {
        jpaRepository.deleteById(id);
    }
}
