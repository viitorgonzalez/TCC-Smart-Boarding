package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

import java.util.List;
import java.util.UUID;

public interface FindUserUseCase {
    List<User> findAll();

    /// Usuários cuja instituição é atendida pela rota (RN15). A base cresce sem
    /// teto — listar tudo não escala nem ajuda o admin.
    List<User> findByRoute(UUID routeId);
    User findById(UUID id);
}
