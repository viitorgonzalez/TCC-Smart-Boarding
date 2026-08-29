package com.smartboarding.smartboarding_api.domain.warning.port.in;

import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;

import java.util.List;
import java.util.UUID;

public interface ManageWarningUseCase {

    /// Advertências de um aluno; [userId] nulo traz todas (visão do admin).
    List<Warning> list(UUID userId);

    void delete(UUID id);
}
