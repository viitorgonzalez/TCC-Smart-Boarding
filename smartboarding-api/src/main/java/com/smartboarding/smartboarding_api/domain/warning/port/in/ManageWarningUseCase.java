package com.smartboarding.smartboarding_api.domain.warning.port.in;

import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.UUID;

public interface ManageWarningUseCase {

    /// Advertências de um aluno; [userId] nulo traz todas (visão do admin).
    List<Warning> list(UUID userId);

    /// Usada pela tela, que carrega conforme o admin rola.
    Page<Warning> listPage(UUID userId, Pageable pageable);

    void delete(UUID id);
}
