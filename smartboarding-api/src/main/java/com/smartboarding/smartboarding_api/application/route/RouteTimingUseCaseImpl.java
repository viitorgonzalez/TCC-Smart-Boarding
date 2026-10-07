package com.smartboarding.smartboarding_api.application.route;

import com.smartboarding.smartboarding_api.domain.route.port.in.RouteTimingUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.out.GeoPoint;
import com.smartboarding.smartboarding_api.domain.route.port.out.RoutePlannerPort;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
public class RouteTimingUseCaseImpl implements RouteTimingUseCase {

    private static final int BOARDING_MINUTES_PER_STOP = 1;

    private final StopRepositoryPort stopRepository;
    private final RoutePlannerPort planner;

    public RouteTimingUseCaseImpl(StopRepositoryPort stopRepository,
                                  RoutePlannerPort planner) {
        this.stopRepository = stopRepository;
        this.planner = planner;
    }

    @Override
    @Transactional
    public void recalculateIfMissing(UUID routeId) {
        boolean jaTem = stopRepository.findAllByRouteIdOrderBySequenceAsc(routeId).stream()
                .anyMatch(s -> s.getAvgMinutesFromStart() != null);
        if (jaTem) return;
        recalculate(routeId);
    }

    @Override
    @Transactional
    public void recalculate(UUID routeId) {
        List<Stop> todas = stopRepository.findAllByRouteIdOrderBySequenceAsc(routeId);

        List<Stop> comCoordenada = todas.stream()
                .filter(s -> s.getLatitude() != null && s.getLongitude() != null)
                .toList();

        if (comCoordenada.size() < 2) {
            limpar(todas);
            return;
        }

        List<GeoPoint> pontos = comCoordenada.stream()
                .map(s -> new GeoPoint(s.getLatitude(), s.getLongitude()))
                .toList();

        Optional<List<Double>> trechos = planner.legDurationsSeconds(pontos);
        if (trechos.isEmpty() || trechos.get().size() != comCoordenada.size() - 1) {
            limpar(todas);
            return;
        }

        List<Double> duracoes = trechos.get();
        double acumulado = 0;
        List<Stop> alteradas = new ArrayList<>(todas.size());

        for (int i = 0; i < comCoordenada.size(); i++) {
            if (i > 0) acumulado += duracoes.get(i - 1);
            Stop stop = comCoordenada.get(i);
            int embarques = (i + 1) * BOARDING_MINUTES_PER_STOP;
            stop.setAvgMinutesFromStart((int) Math.round(acumulado / 60) + embarques);
            alteradas.add(stop);
        }

        todas.stream().filter(s -> !comCoordenada.contains(s))
                .forEach(s -> {
                    s.setAvgMinutesFromStart(null);
                    alteradas.add(s);
                });

        alteradas.forEach(stopRepository::save);
        log.debug("Tempos recalculados para a rota {}", routeId);
    }

    private void limpar(List<Stop> stops) {
        stops.forEach(s -> {
            s.setAvgMinutesFromStart(null);
            stopRepository.save(s);
        });
    }
}
