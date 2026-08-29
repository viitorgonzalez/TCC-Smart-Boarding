package com.smartboarding.smartboarding_api.application.route;

import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.in.UpdateRouteScheduleUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Service
public class RouteScheduleUseCaseImpl implements UpdateRouteScheduleUseCase {

    private static final int NOTICE_DURATION_HOURS = 24;
    private static final DateTimeFormatter HOUR = DateTimeFormatter.ofPattern("HH:mm");

    private final RouteRepositoryPort routeRepository;
    private final PublishNotificationUseCase publishNotificationUseCase;

    public RouteScheduleUseCaseImpl(RouteRepositoryPort routeRepository,
                                    PublishNotificationUseCase publishNotificationUseCase) {
        this.routeRepository = routeRepository;
        this.publishNotificationUseCase = publishNotificationUseCase;
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

        // O horário é o combinado com quem pega o ônibus: mudar em silêncio faria
        // o aluno chegar numa lista que já fechou.
        publishNotificationUseCase.publish(
                "Horário da lista mudou",
                "%s A lista passa a abrir às %s e fechar às %s.".formatted(
                        reason.trim(), openTime.format(HOUR), closeTime.format(HOUR)),
                saved.getId(), NOTICE_DURATION_HOURS, null);
        return saved;
    }
}
