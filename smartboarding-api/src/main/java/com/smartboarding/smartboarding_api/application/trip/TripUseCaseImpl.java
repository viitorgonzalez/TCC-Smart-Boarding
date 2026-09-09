package com.smartboarding.smartboarding_api.application.trip;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;
import com.smartboarding.smartboarding_api.domain.trip.port.in.ConductTripUseCase;
import com.smartboarding.smartboarding_api.domain.trip.port.out.TripCheckpointRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.UUID;

@Slf4j
@Service
public class TripUseCaseImpl implements ConductTripUseCase {

    /// O aviso do trajeto interessa no dia; depois disso vira ruído na caixa.
    private static final int NOTICE_DURATION_HOURS = 12;

    private final DailyListRepositoryPort dailyListRepository;
    private final StopRepositoryPort stopRepository;
    private final TripCheckpointRepositoryPort checkpointRepository;
    private final PublishNotificationUseCase publishNotificationUseCase;
    private final Clock clock;

    public TripUseCaseImpl(DailyListRepositoryPort dailyListRepository,
                           StopRepositoryPort stopRepository,
                           TripCheckpointRepositoryPort checkpointRepository,
                           PublishNotificationUseCase publishNotificationUseCase,
                           Clock clock) {
        this.dailyListRepository = dailyListRepository;
        this.stopRepository = stopRepository;
        this.checkpointRepository = checkpointRepository;
        this.publishNotificationUseCase = publishNotificationUseCase;
        this.clock = clock;
    }

    @Override
    @Transactional
    public DailyList start(UUID listId) {
        DailyList list = findList(listId);
        if (list.getTripStartedAt() != null) {
            throw new BadRequestException("TRIP_ALREADY_STARTED", "O trajeto de hoje já começou.");
        }
        list.setTripStartedAt(LocalDateTime.now(clock));
        DailyList saved = dailyListRepository.save(list);

        announce(saved, "Trajeto iniciado",
                "O ônibus da %s saiu. Acompanhe as paradas pelo app."
                        .formatted(saved.getRoute().getName()));
        return saved;
    }

    @Override
    @Transactional
    public DailyList checkpoint(UUID listId, UUID stopId) {
        DailyList list = findList(listId);
        assertInProgress(list);

        Stop stop = stopRepository.findById(stopId)
                .orElseThrow(() -> new NotFoundException("Parada não encontrada com ID: " + stopId));
        if (!stop.getRouteId().equals(list.getRoute().getId())) {
            throw new BadRequestException("STOP_NOT_IN_ROUTE", "Esta parada não é da rota da lista.");
        }
        if (!stop.isMainPoint()) {
            throw new BadRequestException("STOP_NOT_MAIN_POINT",
                    "Só ponto principal gera checkpoint — parada comum aparece só no mapa.");
        }

        // Idempotente: o admin pode tocar duas vezes, e a segunda não pode virar
        // um segundo aviso pro aluno.
        if (checkpointRepository.existsByDailyListIdAndStopId(listId, stopId)) {
            return list;
        }

        checkpointRepository.save(TripCheckpoint.builder()
                .dailyListId(listId)
                .stopId(stopId)
                .reachedAt(LocalDateTime.now(clock))
                .build());

        announce(list, "Ônibus chegou em " + stop.getName(),
                "O ônibus da %s chegou em %s.".formatted(list.getRoute().getName(), stop.getName()));
        return list;
    }

    @Override
    @Transactional
    public DailyList finish(UUID listId) {
        DailyList list = findList(listId);
        assertInProgress(list);

        list.setTripFinishedAt(LocalDateTime.now(clock));
        DailyList saved = dailyListRepository.save(list);

        announce(saved, "Trajeto finalizado",
                "O ônibus da %s concluiu o trajeto de hoje.".formatted(saved.getRoute().getName()));
        return saved;
    }

    private DailyList findList(UUID listId) {
        return dailyListRepository.findById(listId)
                .orElseThrow(() -> new NotFoundException("Lista não encontrada com ID: " + listId));
    }

    private void assertInProgress(DailyList list) {
        if (list.getTripStartedAt() == null) {
            throw new BadRequestException("TRIP_NOT_STARTED", "O trajeto de hoje não começou ainda.");
        }
        if (list.getTripFinishedAt() != null) {
            throw new BadRequestException("TRIP_ALREADY_FINISHED", "O trajeto de hoje já terminou.");
        }
    }

    // Persistir é o que faz o aviso sobreviver: o push é entrega, não registro --
    // com FCM desligado ele não deixa rastro nenhum pro aluno.
    private void announce(DailyList list, String title, String body) {
        try {
            publishNotificationUseCase.publish(title, body, list.getRoute().getId(),
                    NOTICE_DURATION_HOURS, null);
        } catch (Exception e) {
            log.error("Ação de trajeto registrada, mas o aviso falhou: {}", e.getMessage());
        }
    }
}
