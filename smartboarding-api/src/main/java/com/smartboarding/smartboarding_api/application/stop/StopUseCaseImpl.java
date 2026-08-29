package com.smartboarding.smartboarding_api.application.stop;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class StopUseCaseImpl implements ManageStopsUseCase {

    private final StopRepositoryPort stopRepository;

    public StopUseCaseImpl(StopRepositoryPort stopRepository) {
        this.stopRepository = stopRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Stop> listByRoute(UUID routeId) {
        return stopRepository.findAllByRouteIdOrderBySequenceAsc(routeId);
    }

    @Override
    @Transactional
    public Stop add(Stop stop) {
        List<Stop> existing = stopRepository.findAllByRouteIdOrderBySequenceAsc(stop.getRouteId());

        if (stop.getSequence() <= 0) {
            // Sem posição indicada: entra no fim do trajeto.
            stop.setSequence(existing.stream().mapToInt(Stop::getSequence).max().orElse(0) + 1);
            return stopRepository.save(stop);
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
        return stopRepository.save(stop);
    }

    @Override
    @Transactional
    public Stop update(UUID stopId, String name, Double latitude, Double longitude) {
        Stop stop = stopRepository.findById(stopId)
                .orElseThrow(() -> new NotFoundException("Parada não encontrada"));
        if (name != null && !name.isBlank()) {
            stop.setName(name.trim());
        }
        if (latitude != null && longitude != null) {
            stop.setLatitude(latitude);
            stop.setLongitude(longitude);
        }
        return stopRepository.save(stop);
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
    }
}
