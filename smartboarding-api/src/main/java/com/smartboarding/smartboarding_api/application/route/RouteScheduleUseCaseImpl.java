package com.smartboarding.smartboarding_api.application.route;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.in.UpdateRouteScheduleUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Slf4j
@Service
public class RouteScheduleUseCaseImpl implements UpdateRouteScheduleUseCase {

    private static final int NOTICE_DURATION_HOURS = 24;
    private static final DateTimeFormatter HOUR = DateTimeFormatter.ofPattern("HH:mm");

    private final RouteRepositoryPort routeRepository;
    private final PublishNotificationUseCase publishNotificationUseCase;
    private final DailyListRepositoryPort dailyListRepository;
    private final Clock clock;

    public RouteScheduleUseCaseImpl(RouteRepositoryPort routeRepository,
                                    PublishNotificationUseCase publishNotificationUseCase,
                                    DailyListRepositoryPort dailyListRepository,
                                    Clock clock) {
        this.routeRepository = routeRepository;
        this.publishNotificationUseCase = publishNotificationUseCase;
        this.dailyListRepository = dailyListRepository;
        this.clock = clock;
    }

    @Override
    @Transactional
    public Route execute(UUID routeId, LocalTime openTime, LocalTime closeTime, String reason) {
        if (openTime == null || closeTime == null) {
            throw new BadRequestException("SCHEDULE_REQUIRED",
                    "Informe os dois horários: abertura e fechamento.");
        }
        if (!openTime.isBefore(closeTime)) {
            throw new BadRequestException("INVALID_SCHEDULE",
                    "A lista precisa abrir antes de fechar.");
        }
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new NotFoundException("Rota não encontrada com ID: " + routeId));

        boolean changed = !openTime.equals(route.getOpenTime()) || !closeTime.equals(route.getCloseTime());
        if (!changed) {
            return route;
        }
        if (reason == null || reason.isBlank()) {
            throw new BadRequestException("REASON_REQUIRED",
                    "Explique o motivo — ele vai no aviso enviado aos alunos.");
        }

        route.setOpenTime(openTime);
        route.setCloseTime(closeTime);
        Route saved = routeRepository.save(route);
        reavaliarListaDeHoje(saved);

        publishNotificationUseCase.publish(
                "Horário da lista mudou",
                "%s A lista passa a abrir às %s e fechar às %s.".formatted(
                        reason.trim(), openTime.format(HOUR), closeTime.format(HOUR)),
                saved.getId(), NOTICE_DURATION_HOURS, null);
        return saved;
    }

    /// Põe a lista de hoje de acordo com o horário recém-salvo.
    ///
    /// Sem isto, mudar o horário só valeria a partir de amanhã: o scheduler de
    /// minuto só CRIA lista quando não existe nenhuma no dia, então uma lista já
    /// fechada nunca voltaria a abrir. O manual_override é limpo de propósito —
    /// mexer no horário é uma decisão mais recente do admin do que o botão que
    /// ele apertou antes.
    private void reavaliarListaDeHoje(Route route) {
        LocalDate hoje = LocalDate.now(clock);
        dailyListRepository.findByRouteIdAndDate(route.getId(), hoje).ifPresent(list -> {
            list.setRoute(route);
            boolean deveAbrir = list.isWithinSchedule(hoje, LocalTime.now(clock));
            ListStatus alvo = deveAbrir ? ListStatus.OPEN : ListStatus.CLOSED;
            if (list.getStatus() == alvo && !list.isManualOverride()) {
                return;
            }
            list.setManualOverride(false);
            list.setStatus(alvo);
            list.setClosedAt(deveAbrir ? null : LocalDateTime.now(clock));
            dailyListRepository.save(list);
            log.info("Lista de {} em {} ficou {} pelo horário novo",
                    route.getName(), hoje, alvo);
        });
    }
}
