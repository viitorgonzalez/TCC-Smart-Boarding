package com.smartboarding.smartboarding_api.application.trip;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripLeg;
import com.smartboarding.smartboarding_api.domain.trip.port.in.ConductTripUseCase;
import com.smartboarding.smartboarding_api.domain.trip.port.out.TripCheckpointRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
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

        TripLeg leg = currentLeg(list);

        // Idempotente DENTRO da perna: o admin pode tocar duas vezes, e a segunda
        // não pode virar um segundo aviso. Mas a mesma parada na volta é uma
        // chegada nova, não repetição.
        if (checkpointRepository.existsByDailyListIdAndStopIdAndLeg(listId, stopId, leg)) {
            return list;
        }

        checkpointRepository.save(TripCheckpoint.builder()
                .dailyListId(listId)
                .stopId(stopId)
                .leg(leg)
                .reachedAt(LocalDateTime.now(clock))
                .build());

        String direcao = leg == TripLeg.OUTBOUND ? "" : " (volta)";
        announce(list, "Ônibus chegou em " + stop.getName() + direcao,
                "O ônibus da %s chegou em %s%s."
                        .formatted(list.getRoute().getName(), stop.getName(), direcao));

        return advanceIfLegComplete(list, leg);
    }

    /// Chegar ao último ponto da ida vira a volta; chegar ao último da volta
    /// encerra o dia. O admin não precisa apertar mais nada — ele já disse onde
    /// está, e pedir uma confirmação extra pra algo que o sistema sabe deduzir
    /// só adiciona um toque no meio do trajeto.
    private DailyList advanceIfLegComplete(DailyList list, TripLeg leg) {
        List<Stop> pontos = mainPoints(list);
        if (pontos.isEmpty()) {
            return list;
        }
        long marcados = checkpointRepository.findAllByDailyListId(list.getId()).stream()
                .filter(c -> c.getLeg() == leg)
                .count();
        if (marcados < pontos.size()) {
            return list;
        }

        LocalDateTime agora = LocalDateTime.now(clock);
        if (leg == TripLeg.OUTBOUND) {
            list.setOutboundFinishedAt(agora);
            DailyList saved = dailyListRepository.save(list);
            announce(saved, "Ida concluída",
                    "O ônibus da %s chegou ao destino final. A volta começa agora."
                            .formatted(saved.getRoute().getName()));
            return saved;
        }

        list.setTripFinishedAt(agora);
        DailyList saved = dailyListRepository.save(list);
        announce(saved, "Trajeto finalizado",
                "O ônibus da %s concluiu a volta de hoje.".formatted(saved.getRoute().getName()));
        return saved;
    }

    /// Ida até o destino final estar marcado; volta dali em diante.
    private TripLeg currentLeg(DailyList list) {
        return list.getOutboundFinishedAt() == null ? TripLeg.OUTBOUND : TripLeg.RETURN;
    }

    /// Só ponto principal entra no trajeto. Na volta a ordem é a inversa —
    /// o ônibus refaz o mesmo caminho de trás pra frente.
    private List<Stop> mainPoints(DailyList list) {
        return stopRepository.findAllByRouteIdOrderBySequenceAsc(list.getRoute().getId()).stream()
                .filter(Stop::isMainPoint)
                .toList();
    }

    @Override
    @Transactional
    public DailyList finish(UUID listId) {
        DailyList list = findList(listId);
        assertInProgress(list);

        // Encerrar a mao fecha o dia inteiro, esteja na ida ou na volta: e a
        // saida pro caso de o onibus nao completar o percurso.
        LocalDateTime agora = LocalDateTime.now(clock);
        if (list.getOutboundFinishedAt() == null) {
            list.setOutboundFinishedAt(agora);
        }
        list.setTripFinishedAt(agora);
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
