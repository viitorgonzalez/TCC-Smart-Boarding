package com.smartboarding.smartboarding_api.infrastructure.route;

import com.smartboarding.smartboarding_api.domain.route.port.out.GeoPoint;
import com.smartboarding.smartboarding_api.domain.route.port.out.RoutePlannerPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Component
public class OsrmRoutePlannerAdapter implements RoutePlannerPort {

    private final RestClient restClient;

    public OsrmRoutePlannerAdapter(@Qualifier("osrmRestClient") RestClient restClient) {
        this.restClient = restClient;
    }

    @Override
    @SuppressWarnings("unchecked")
    public Optional<List<Double>> legDurationsSeconds(List<GeoPoint> points) {
        if (points == null || points.size() < 2) return Optional.empty();

        String coords = points.stream()
                .map(p -> p.longitude() + "," + p.latitude())
                .collect(Collectors.joining(";"));

        try {
            Map<String, Object> corpo = restClient.get()
                    .uri(uri -> uri.path("/route/v1/driving/" + coords)
                            .queryParam("overview", "false")
                            .build())
                    .retrieve()
                    .body(Map.class);

            List<Map<String, Object>> rotas = corpo == null ? null
                    : (List<Map<String, Object>>) corpo.get("routes");
            if (rotas == null || rotas.isEmpty()) return Optional.empty();

            List<Map<String, Object>> legs =
                    (List<Map<String, Object>>) rotas.getFirst().get("legs");
            if (legs == null || legs.isEmpty()) return Optional.empty();

            List<Double> duracoes = new ArrayList<>(legs.size());
            for (Map<String, Object> leg : legs) {
                duracoes.add(((Number) leg.get("duration")).doubleValue());
            }
            return Optional.of(duracoes);
        } catch (Exception e) {
            log.warn("OSRM não respondeu ao calcular o trajeto: {}", e.getMessage());
            return Optional.empty();
        }
    }
}
