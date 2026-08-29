package com.smartboarding.smartboarding_api.application.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.in.ManageDailyListUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.report.port.out.ReportRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class DailyListAdminUseCaseImpl implements ManageDailyListUseCase {

    private final DailyListRepositoryPort dailyListRepository;
    private final ListEntryRepositoryPort listEntryRepository;
    private final ReportRepositoryPort reportRepository;
    private final RouteRepositoryPort routeRepository;
    private final PublishNotificationUseCase publishNotificationUseCase;
    private final Clock clock;

    private static final int NOTICE_DURATION_HOURS = 24;

    public DailyListAdminUseCaseImpl(DailyListRepositoryPort dailyListRepository,
                                     ListEntryRepositoryPort listEntryRepository,
                                     ReportRepositoryPort reportRepository,
                                     RouteRepositoryPort routeRepository,
                                     PublishNotificationUseCase publishNotificationUseCase,
                                     Clock clock) {
        this.dailyListRepository = dailyListRepository;
        this.listEntryRepository = listEntryRepository;
        this.reportRepository = reportRepository;
        this.routeRepository = routeRepository;
        this.publishNotificationUseCase = publishNotificationUseCase;
        this.clock = clock;
    }

    @Override
    @Transactional(readOnly = true)
    public List<DailyList> findByDate(LocalDate date) {
        return dailyListRepository.findAllByDate(date);
    }

    @Override
    @Transactional
    public DailyList create(UUID routeId, LocalDate date) {
        Route route = routeRepository.findById(routeId)
                .orElseThrow(() -> new NotFoundException("Rota não encontrada"));
        // Uma lista por rota e dia: duas listas concorrentes dividiriam os
        // inscritos e nenhuma refletiria quem realmente embarca.
        if (dailyListRepository.existsByRouteIdAndDate(routeId, date)) {
            throw new ConflictException("LIST_ALREADY_EXISTS",
                    "Já existe lista dessa rota para essa data.");
        }
        DailyList created = dailyListRepository.save(DailyList.builder()
                .route(route)
                .date(date)
                .status(ListStatus.OPEN)
                .build());
        log.info("Lista criada manualmente: {} em {}", route.getName(), date);
        return created;
    }

    @Override
    @Transactional
    public DailyList setStatus(UUID listId, ListStatus status, String reason) {
        if (reason == null || reason.isBlank()) {
            throw new BadRequestException("REASON_REQUIRED",
                    "Explique o motivo — ele vai no aviso enviado aos alunos.");
        }
        DailyList list = dailyListRepository.findById(listId)
                .orElseThrow(() -> new NotFoundException("Lista não encontrada"));
        list.setStatus(status);
        // Reabrir limpa o fechamento: manter closedAt de um fechamento desfeito
        // faria o histórico afirmar algo que deixou de valer.
        list.setClosedAt(status == ListStatus.CLOSED ? LocalDateTime.now(clock) : null);
        list.setManualOverride(true);
        DailyList saved = dailyListRepository.save(list);

        // Aviso obrigatório: quem contava com o horário publicado precisa saber
        // que ele mudou, e por quê.
        String title = status == ListStatus.CLOSED
                ? "Lista fechada antes do horário"
                : "Lista reaberta";
        publishNotificationUseCase.publish(title, reason.trim(),
                list.getRoute().getId(), NOTICE_DURATION_HOURS, null);
        return saved;
    }

    @Override
    @Transactional
    public void delete(UUID listId) {
        DailyList list = dailyListRepository.findById(listId)
                .orElseThrow(() -> new NotFoundException("Lista não encontrada"));

        // Relatório é imutável (RN8) e é a prova de quem embarcou naquele dia.
        // Apagar a lista por baixo dele destruiria esse registro.
        if (reportRepository.findByDailyListId(listId).isPresent()) {
            throw new ConflictException("LIST_HAS_REPORT",
                    "Lista já tem relatório gerado e não pode ser apagada.");
        }

        listEntryRepository.deleteAllByDailyListId(listId);
        dailyListRepository.deleteById(listId);
        log.info("Lista {} apagada", listId);
    }
}
