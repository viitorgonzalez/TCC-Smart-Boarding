package com.smartboarding.smartboarding_api.domain.route.port.in;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;

import java.time.LocalTime;
import java.util.UUID;

/// Horário de abertura e fechamento da lista da rota. Caminho separado do
/// update comum de propósito: mexer no horário muda o combinado com quem
/// depende do transporte, e o aviso à rota é parte da operação.
public interface UpdateRouteScheduleUseCase {

    /// [reason] é obrigatório e vira o corpo do aviso enviado à rota.
    Route execute(UUID routeId, LocalTime openTime, LocalTime closeTime, String reason);
}
