package com.smartboarding.smartboarding_api.infrastructure.web.trip.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/// Estado do trajeto pra tela desenhar o stepper sem fazer várias chamadas.
public record TripStatusResponse(
        UUID listId,
        String routeName,
        LocalDateTime startedAt,
        /// Quando a ida acabou. Nulo = ainda na ida.
        LocalDateTime outboundFinishedAt,
        LocalDateTime finishedAt,
        /// OUTBOUND ou RETURN -- o app usa pra inverter a ordem das paradas e
        /// rotular a tela.
        String leg,
        List<TripStopStatus> stops
) {
    /// Só ponto principal entra aqui — parada comum não vira passo (RN23).
    public record TripStopStatus(UUID stopId, String name, int sequence, LocalDateTime reachedAt) {}
}
