package com.smartboarding.smartboarding_api.application.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.in.CloseDailyListsUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.OpenDailyListsUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.SendBroadcastUseCase;
import com.smartboarding.smartboarding_api.domain.report.port.in.GenerateReportUseCase;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
public class SchedulerUseCaseImpl implements OpenDailyListsUseCase, CloseDailyListsUseCase {

    private final RouteRepositoryPort routeRepository;
    private final DailyListRepositoryPort dailyListRepository;
    private final GenerateReportUseCase generateReportUseCase;
    private final SendBroadcastUseCase sendBroadcastUseCase;

    public SchedulerUseCaseImpl(RouteRepositoryPort routeRepository,
                                DailyListRepositoryPort dailyListRepository,
                                GenerateReportUseCase generateReportUseCase,
                                SendBroadcastUseCase sendBroadcastUseCase) {
        this.routeRepository = routeRepository;
        this.dailyListRepository = dailyListRepository;
        this.generateReportUseCase = generateReportUseCase;
        this.sendBroadcastUseCase = sendBroadcastUseCase;
    }

    @Override
    @Scheduled(cron = "0 0 0 * * MON-FRI")
    @Transactional
    public void open() {
        LocalDate today = LocalDate.now();
        log.info("Abrindo listas diárias para {}", today);

        routeRepository.findAllByIsActiveTrue().forEach(route -> {
            if (!dailyListRepository.existsByRouteIdAndDate(route.getId(), today)) {
                DailyList list = DailyList.builder()
                        .route(route)
                        .date(today)
                        .status(ListStatus.OPEN)
                        .build();
                dailyListRepository.save(list);
                log.info("Lista criada para rota: {}", route.getName());
            }
        });
    }

    @Override
    @Scheduled(cron = "0 0 16 * * MON-FRI")
    @Transactional
    public void close() {
        LocalDate today = LocalDate.now();
        log.info("Fechando listas diárias de {}", today);

        List<DailyList> openLists = dailyListRepository.findAllByDateAndStatus(today, ListStatus.OPEN);
        openLists.forEach(list -> {
            list.setStatus(ListStatus.CLOSED);
            list.setClosedAt(LocalDateTime.now());
            dailyListRepository.save(list);

            try {
                generateReportUseCase.execute(list);
            } catch (Exception e) {
                log.error("Erro ao gerar relatório para lista {}: {}", list.getId(), e.getMessage());
            }
        });

        if (!openLists.isEmpty()) {
            try {
                sendBroadcastUseCase.execute(
                        "Embarque confirmado",
                        "As listas de hoje foram fechadas. Verifique o app para detalhes."
                );
            } catch (Exception e) {
                log.warn("Falha ao enviar broadcast de fechamento: {}", e.getMessage());
            }
        }

        log.info("{} lista(s) fechada(s)", openLists.size());
    }
}
