package com.smartboarding.smartboarding_api.infrastructure.web.trip.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record TripStatusResponse(
        UUID listId,
        String routeName,
        LocalDateTime startedAt,
        LocalDateTime outboundFinishedAt,
        LocalDateTime finishedAt,
        String leg,
        List<TripStopStatus> stops,
        MyStop myStop
) {
    /// latitude/longitude vêm nulos quando a parada não foi posicionada no mapa:
    /// o app desenha só as que têm ponto, em vez de esconder o mapa inteiro.
    public record TripStopStatus(UUID stopId, String name, int sequence,
                                 LocalDateTime reachedAt,
                                 Double latitude, Double longitude) {}

    public record MyStop(UUID stopId, String stopName, boolean fallback,
                         boolean alreadyReached, Integer etaMinutes) {}
}
