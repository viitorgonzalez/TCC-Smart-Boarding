package com.smartboarding.smartboarding_api.application.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.in.CloseDailyListsUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.OpenDailyListsUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.in.SendToUserUseCase;
import com.smartboarding.smartboarding_api.domain.report.port.in.GenerateReportUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Slf4j
@Service
public class SchedulerUseCaseImpl implements OpenDailyListsUseCase, CloseDailyListsUseCase {

    private static final int NOTICE_DURATION_HOURS = 12;

    private final RouteRepositoryPort routeRepository;
    private final DailyListRepositoryPort dailyListRepository;
    private final GenerateReportUseCase generateReportUseCase;
    private final ListEntryRepositoryPort listEntryRepository;
    private final SendToUserUseCase sendToUserUseCase;
    private final PublishNotificationUseCase publishNotificationUseCase;
    private final Clock clock;

    public SchedulerUseCaseImpl(RouteRepositoryPort routeRepository,
                                DailyListRepositoryPort dailyListRepository,
                                GenerateReportUseCase generateReportUseCase,
                                ListEntryRepositoryPort listEntryRepository,
                                SendToUserUseCase sendToUserUseCase,
                                PublishNotificationUseCase publishNotificationUseCase,
                                Clock clock) {
        this.routeRepository = routeRepository;
        this.dailyListRepository = dailyListRepository;
        this.generateReportUseCase = generateReportUseCase;
        this.listEntryRepository = listEntryRepository;
        this.sendToUserUseCase = sendToUserUseCase;
        this.publishNotificationUseCase = publishNotificationUseCase;
        this.clock = clock;
    }

    @Override
    @Scheduled(cron = "0 * * * * *")
    @Transactional
    public void open() {
        LocalDate today = LocalDate.now(clock);
        // A varredura roda a cada 5 min, mas não há transporte no fim de semana
        // — o cron antigo já limitava a seg-sex.
        if (today.getDayOfWeek() == DayOfWeek.SATURDAY || today.getDayOfWeek() == DayOfWeek.SUNDAY) {
            return;
        }

        LocalTime now = LocalTime.now(clock);
        routeRepository.findAllByIsActiveTrue().forEach(route -> {
            // Uma lista por rota e por dia; a varredura respeita o horário de
            // abertura configurado em vez de um cron fixo à meia-noite.
            if (!now.isBefore(route.getOpenTime())
                    && !dailyListRepository.existsByRouteIdAndDate(route.getId(), today)) {
                DailyList list = DailyList.builder()
                        .route(route)
                        .date(today)
                        .status(ListStatus.OPEN)
                        .build();
                dailyListRepository.save(list);
                announceOpen(route);
                log.info("Lista criada para rota: {}", route.getName());
            }
        });
    }

    // Varredura em vez de cron no horário: o fechamento é por rota (RN18) e uma
    // janela fixa só pegaria quem fecha naquele minuto, com a API no ar. Varre
    // todas as abertas, não só as de hoje, pra recuperar fechamento atrasado.
    @Override
    @Scheduled(cron = "0 * * * * *")
    @Transactional
    public void close() {
        LocalDate today = LocalDate.now(clock);
        LocalTime now = LocalTime.now(clock);

        List<DailyList> due = dailyListRepository.findAllByStatus(ListStatus.OPEN).stream()
                .filter(list -> isPastCloseTime(list, today, now))
                .toList();

        if (due.isEmpty()) {
            return;
        }

        due.forEach(list -> {
            list.setStatus(ListStatus.CLOSED);
            list.setClosedAt(LocalDateTime.now(clock));
            dailyListRepository.save(list);

            try {
                generateReportUseCase.execute(list);
            } catch (Exception e) {
                log.error("Erro ao gerar relatório para lista {}: {}", list.getId(), e.getMessage());
            }

            notifyEnrolled(list);
            announceClose(list);
            log.info("Lista fechada: {} de {}", list.getRoute().getName(), list.getDate());
        });

        log.info("{} lista(s) fechada(s)", due.size());
    }

    private boolean isPastCloseTime(DailyList list, LocalDate today, LocalTime now) {
        // Lista de dia passado fecha mesmo com override: o dia do admin acabou.
        if (list.getDate().isBefore(today)) {
            return true;
        }
        if (list.isManualOverride()) {
            return false;
        }
        return list.getDate().isEqual(today) && !now.isBefore(list.getRoute().getCloseTime());
    }

    // O push do notifyEnrolled não fica registrado em lugar nenhum: quem estava
    // offline (ou com FCM desligado) nunca saberia. O aviso persistido é o que
    // sobrevive — a caixa de entrada é a fonte, o push é entrega.
    private void announceOpen(com.smartboarding.smartboarding_api.domain.route.entity.Route route) {
        publishBestEffort("Lista de hoje aberta",
                "A lista da %s está aberta até as %s. Confirme sua presença.".formatted(
                        route.getName(), route.getCloseTime()),
                route.getId());
    }

    private void announceClose(DailyList list) {
        publishBestEffort("Lista de hoje fechada",
                "A lista da %s fechou. Quem confirmou já está no transporte de hoje.".formatted(
                        list.getRoute().getName()),
                list.getRoute().getId());
    }

    // Best-effort: falha de aviso não pode impedir a lista de abrir ou fechar.
    private void publishBestEffort(String title, String body, java.util.UUID routeId) {
        try {
            publishNotificationUseCase.publish(title, body, routeId, NOTICE_DURATION_HOURS, null);
        } catch (Exception e) {
            log.error("Lista processada, mas o aviso à rota falhou: {}", e.getMessage());
        }
    }

    // RN2 manda avisar os inscritos, não todo mundo: com horário por rota, um
    // broadcast global avisaria de fechamento quem ainda tem lista aberta.
    private void notifyEnrolled(DailyList list) {
        String routeName = list.getRoute().getName();
        listEntryRepository.findAllByDailyListIdAndIsActiveTrue(list.getId()).forEach(entry -> {
            try {
                sendToUserUseCase.execute(entry.getUser().getId(), "Lista fechada",
                        "A lista de hoje da rota " + routeName + " foi fechada.");
            } catch (Exception e) {
                log.warn("Falha ao notificar inscrito {}: {}", entry.getUser().getId(), e.getMessage());
            }
        });
    }
}
