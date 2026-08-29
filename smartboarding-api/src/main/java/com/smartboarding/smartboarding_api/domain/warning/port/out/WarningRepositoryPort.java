package com.smartboarding.smartboarding_api.domain.warning.port.out;

import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;

import java.util.List;
import java.util.UUID;

public interface WarningRepositoryPort {
    Warning save(Warning warning);

    List<Warning> findAllByUserId(UUID userId);

    List<Warning> findAll();

    void deleteById(UUID id);
}
