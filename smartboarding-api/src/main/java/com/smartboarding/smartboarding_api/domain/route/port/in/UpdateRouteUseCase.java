package com.smartboarding.smartboarding_api.domain.route.port.in;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;

import java.util.UUID;

public interface UpdateRouteUseCase {
    /// [isActive] nulo mantém o estado atual — o PATCH é parcial.
    /// [isActive] e [admitsNoInstitution] nulos mantêm o que está gravado: a
    /// tela que edita os dados da rota não conhece as duas chaves, e mandar
    /// nulo dali não pode desligá-las sem querer.
    Route execute(UUID id, Route route, Boolean isActive, Boolean admitsNoInstitution);
}
