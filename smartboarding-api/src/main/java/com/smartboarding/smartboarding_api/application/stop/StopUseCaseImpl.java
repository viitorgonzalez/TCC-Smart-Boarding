package com.smartboarding.smartboarding_api.application.stop;

import com.smartboarding.smartboarding_api.domain.route.port.in.RouteTimingUseCase;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class StopUseCaseImpl implements ManageStopsUseCase {

    private final StopRepositoryPort stopRepository;
    private final RouteTimingUseCase routeTiming;

    public StopUseCaseImpl(StopRepositoryPort stopRepository,
                           RouteTimingUseCase routeTiming) {
        this.stopRepository = stopRepository;
        this.routeTiming = routeTiming;
    }

    /// O tempo por parada depende do trajeto inteiro: mexer numa parada muda o
    /// número de todas as seguintes.
    ///
    /// Em try/catch porque o cálculo bate no OSRM, que não tem SLA. O admin
    /// criou a parada; o serviço externo estar fora não pode desfazer isso --
    /// o tempo fica nulo e a tela omite.
    private void recalcular(UUID routeId) {
        try {
            routeTiming.recalculate(routeId);
        } catch (RuntimeException e) {
            log.warn("Não foi possível recalcular os tempos da rota {}: {}",
                    routeId, e.getMessage());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<Stop> listByRoute(UUID routeId) {
        return stopRepository.findAllByRouteIdOrderBySequenceAsc(routeId);
    }

    @Override
    @Transactional
    public Stop add(Stop stop) {
        // Sem esta linha a parada nasce comum e o trajeto recusa todo
        // checkpoint nela -- que era o estado de toda rota criada depois da V20.
        stop.refreshMainPoint(stop.isMainPoint());

        List<Stop> existing = stopRepository.findAllByRouteIdOrderBySequenceAsc(stop.getRouteId());

        if (stop.getSequence() <= 0) {
            // Sem posição indicada: entra no fim do trajeto.
            stop.setSequence(existing.stream().mapToInt(Stop::getSequence).max().orElse(0) + 1);
            Stop salva = stopRepository.save(stop);
            recalcular(stop.getRouteId());
            return salva;
        }

        // Inserção no meio: as seguintes descem uma posição, senão duas paradas
        // ficariam com a mesma sequência e a ordem do trajeto viraria empate.
        existing.stream()
                .filter(s -> s.getSequence() >= stop.getSequence())
                .sorted((a, b) -> Integer.compare(b.getSequence(), a.getSequence()))
                .forEach(s -> {
                    s.setSequence(s.getSequence() + 1);
                    stopRepository.save(s);
                });
        Stop salva = stopRepository.save(stop);
        recalcular(stop.getRouteId());
        return salva;
    }

    @Override
    @Transactional
    public Stop update(UUID stopId, String name, Double latitude, Double longitude) {
        Stop stop = aplicar(stopId, name, latitude, longitude);
        Stop salva = stopRepository.save(stop);
        recalcular(salva.getRouteId());
        return salva;
    }

    @Override
    @Transactional
    public Stop update(UUID stopId, String name, Double latitude, Double longitude,
                       UUID institutionId, boolean mainPoint) {
        Stop stop = aplicar(stopId, name, latitude, longitude);
        stop.setInstitutionId(institutionId);
        // Desvincular tira o status: a parada deixou de servir alguém, e seguir
        // aceitando checkpoint marcaria chegada num lugar que não é destino de
        // ninguém.
        stop.refreshMainPoint(mainPoint);
        Stop salva = stopRepository.save(stop);
        recalcular(salva.getRouteId());
        return salva;
    }

    private Stop aplicar(UUID stopId, String name, Double latitude, Double longitude) {
        Stop stop = stopRepository.findById(stopId)
                .orElseThrow(() -> new NotFoundException("Parada não encontrada"));
        if (name != null && !name.isBlank()) {
            stop.setName(name.trim());
        }
        if (latitude != null && longitude != null) {
            stop.setLatitude(latitude);
            stop.setLongitude(longitude);
        }
        return stop;
    }

    @Override
    @Transactional
    public void remove(UUID stopId) {
        Stop stop = stopRepository.findById(stopId)
                .orElseThrow(() -> new NotFoundException("Parada não encontrada"));
        UUID routeId = stop.getRouteId();
        stopRepository.deleteById(stopId);

        // Renumera pra não deixar buraco (1,2,4...) — a sequência é a ordem de
        // passagem, e furo nela confunde tanto a tela quanto o próximo insert.
        List<Stop> remaining = stopRepository.findAllByRouteIdOrderBySequenceAsc(routeId);
        for (int i = 0; i < remaining.size(); i++) {
            Stop current = remaining.get(i);
            if (current.getSequence() != i + 1) {
                current.setSequence(i + 1);
                stopRepository.save(current);
            }
        }
        recalcular(routeId);
    }
}
