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

    /// Quantos admins existem hoje. É o que a ficha do usuário precisa pra saber
    /// se está olhando a última conta administrativa — sem isso o app baixaria a
    /// tabela inteira, com o contato de toda a base, só pra chegar num número.
    long countAdmins();
}
