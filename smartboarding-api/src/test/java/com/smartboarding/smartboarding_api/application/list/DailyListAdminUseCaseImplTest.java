package com.smartboarding.smartboarding_api.application.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.report.entity.Report;
import com.smartboarding.smartboarding_api.domain.report.port.out.ReportRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DailyListAdminUseCaseImplTest {

    private static final UUID ROUTE = UUID.randomUUID();
    private static final LocalDate HOJE = LocalDate.of(2026, 9, 9);
    private static final LocalDateTime AGORA = LocalDateTime.of(2026, 9, 9, 14, 30);

    @Mock DailyListRepositoryPort dailyListRepository;
    @Mock ListEntryRepositoryPort listEntryRepository;
    @Mock ReportRepositoryPort reportRepository;
    @Mock RouteRepositoryPort routeRepository;
    @Mock PublishNotificationUseCase publishNotificationUseCase;

    private DailyListAdminUseCaseImpl useCase;
    private Route route;

    @BeforeEach
    void setUp() {
        useCase = new DailyListAdminUseCaseImpl(dailyListRepository, listEntryRepository,
                reportRepository, routeRepository, publishNotificationUseCase,
                Clock.fixed(AGORA.toInstant(ZoneOffset.UTC), ZoneOffset.UTC));
        route = Route.builder().id(ROUTE).name("Rota Universitária").build();
        when(routeRepository.findById(ROUTE)).thenReturn(Optional.of(route));
        when(dailyListRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(dailyListRepository.existsByRouteIdAndDate(any(), any())).thenReturn(false);
        when(reportRepository.findByDailyListId(any())).thenReturn(Optional.empty());
    }

    private DailyList lista(ListStatus status) {
        DailyList list = DailyList.builder().id(UUID.randomUUID()).route(route)
                .date(HOJE).status(status).build();
        when(dailyListRepository.findById(list.getId())).thenReturn(Optional.of(list));
        return list;
    }

    @Test
    void findByDateRepassaAData() {
        var listas = List.of(DailyList.builder().build());
        when(dailyListRepository.findAllByDate(HOJE)).thenReturn(listas);

        assertThat(useCase.findByDate(HOJE)).isEqualTo(listas);
    }

    @Test
    void criarListaNasceAberta() {
        DailyList created = useCase.create(ROUTE, HOJE);

        assertThat(created.getStatus()).isEqualTo(ListStatus.OPEN);
        assertThat(created.getRoute()).isSameAs(route);
        assertThat(created.getDate()).isEqualTo(HOJE);
    }

    @Test
    void criarEmRotaInexistenteEstoura() {
        UUID desconhecida = UUID.randomUUID();
        when(routeRepository.findById(desconhecida)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.create(desconhecida, HOJE))
                .isInstanceOf(NotFoundException.class);
    }

    /// Duas listas da mesma rota no mesmo dia dividiriam os inscritos e nenhuma
    /// refletiria quem embarca de verdade.
    @Test
    void segundaListaDaMesmaRotaNoMesmoDiaEBloqueada() {
        when(dailyListRepository.existsByRouteIdAndDate(ROUTE, HOJE)).thenReturn(true);

        assertThatThrownBy(() -> useCase.create(ROUTE, HOJE))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("Já existe lista");

        verify(dailyListRepository, never()).save(any());
    }

    /// RN18/RN24: mudança manual de status sempre avisa os alunos, com o motivo.
    @Test
    void fecharManualmenteAvisaOsAlunosComOMotivo() {
        DailyList list = lista(ListStatus.OPEN);

        DailyList saved = useCase.setStatus(list.getId(), ListStatus.CLOSED, "  Ônibus quebrou  ");

        assertThat(saved.getStatus()).isEqualTo(ListStatus.CLOSED);
        assertThat(saved.getClosedAt()).isEqualTo(AGORA);
        assertThat(saved.isManualOverride()).isTrue();
        verify(publishNotificationUseCase).publish(eq("Lista fechada antes do horário"),
                eq("Ônibus quebrou"), eq(ROUTE), eq(24), eq(null));
    }

    /// Manter closedAt de um fechamento desfeito faria o histórico afirmar algo
    /// que deixou de valer.
    @Test
    void reabrirLimpaOFechamentoEAvisa() {
        DailyList list = lista(ListStatus.CLOSED);
        list.setClosedAt(LocalDateTime.of(2026, 9, 9, 6, 0));

        DailyList saved = useCase.setStatus(list.getId(), ListStatus.OPEN, "Ônibus consertado");

        assertThat(saved.getStatus()).isEqualTo(ListStatus.OPEN);
        assertThat(saved.getClosedAt()).isNull();
        verify(publishNotificationUseCase).publish(eq("Lista reaberta"),
                eq("Ônibus consertado"), eq(ROUTE), eq(24), eq(null));
    }

    @Test
    void mudarStatusSemMotivoERecusado() {
        DailyList list = lista(ListStatus.OPEN);

        assertThatThrownBy(() -> useCase.setStatus(list.getId(), ListStatus.CLOSED, "   "))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("motivo");

        assertThatThrownBy(() -> useCase.setStatus(list.getId(), ListStatus.CLOSED, null))
                .isInstanceOf(BadRequestException.class);

        verify(dailyListRepository, never()).save(any());
        verify(publishNotificationUseCase, never()).publish(any(), any(), any(), any(), any());
    }

    @Test
    void mudarStatusDeListaInexistenteEstoura() {
        UUID id = UUID.randomUUID();
        when(dailyListRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.setStatus(id, ListStatus.CLOSED, "motivo"))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void apagarListaRemoveOsInscritosJunto() {
        DailyList list = lista(ListStatus.OPEN);

        useCase.delete(list.getId());

        verify(listEntryRepository).deleteAllByDailyListId(list.getId());
        verify(dailyListRepository).deleteById(list.getId());
    }

    /// RN8: o relatório é a prova de quem embarcou. Apagar a lista por baixo dele
    /// destruiria esse registro.
    @Test
    void listaComRelatorioNaoPodeSerApagada() {
        DailyList list = lista(ListStatus.CLOSED);
        when(reportRepository.findByDailyListId(list.getId()))
                .thenReturn(Optional.of(Report.builder().build()));

        assertThatThrownBy(() -> useCase.delete(list.getId()))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("relatório");

        verify(listEntryRepository, never()).deleteAllByDailyListId(any());
        verify(dailyListRepository, never()).deleteById(any());
    }

    @Test
    void apagarListaInexistenteEstoura() {
        UUID id = UUID.randomUUID();
        when(dailyListRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.delete(id)).isInstanceOf(NotFoundException.class);
    }
}
