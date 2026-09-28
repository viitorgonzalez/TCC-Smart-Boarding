package com.smartboarding.smartboarding_api.domain.warning.port.out;

import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.UUID;

public interface WarningRepositoryPort {
    Warning save(Warning warning);

    List<Warning> findAllByUserId(UUID userId);

    List<Warning> findAll();

    Page<Warning> findPage(Pageable pageable);

    Page<Warning> findPageByUserId(UUID userId, Pageable pageable);

    void deleteById(UUID id);
}
