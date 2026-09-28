package com.smartboarding.smartboarding_api.infrastructure.web.trip;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.port.in.FindListUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripCheckpoint;
import com.smartboarding.smartboarding_api.domain.trip.entity.TripLeg;
import com.smartboarding.smartboarding_api.domain.trip.port.in.ConductTripUseCase;
import com.smartboarding.smartboarding_api.domain.trip.port.out.TripCheckpointRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(TripController.class)
class TripControllerTest extends WebMvcTestSupport {

    private static final UUID LIST_ID = UUID.fromString("aaaaaaaa-0000-0000-0000-000000000001");
    private static final UUID ROUTE_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");
    private static final UUID STOP_ID = UUID.fromString("dddddddd-0000-0000-0000-000000000001");

    @Autowired MockMvc mvc;

    @MockitoBean ConductTripUseCase conductTripUseCase;
    @MockitoBean FindListUseCase findListUseCase;
    @MockitoBean ManageStopsUseCase manageStopsUseCase;
    @MockitoBean TripCheckpointRepositoryPort checkpointRepository;
    @MockitoBean com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort
            userRepository;
    @MockitoBean com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort
            routeMemberRepository;

    private static final UUID INSTITUICAO = UUID.fromString("cccccccc-0000-0000-0000-000000000001");
    private static final UUID STOP_UNIFOR = UUID.fromString("dddddddd-0000-0000-0000-000000000002");

    private DailyList lista;

    /// Duas paradas principais: a rodoviária (início) e a instituição do aluno.
    private void rotaComInstituicao(Integer minutosRodoviaria, Integer minutosUnifor) {
        when(manageStopsUseCase.listByRoute(ROUTE_ID)).thenReturn(List.of(
                Stop.builder().id(STOP_ID).routeId(ROUTE_ID).name("Rodoviária")
                        .sequence(1).isMainPoint(true)
                        .avgMinutesFromStart(minutosRodoviaria).build(),
                Stop.builder().id(STOP_UNIFOR).routeId(ROUTE_ID).name("UNIFOR-MG")
                        .sequence(2).isMainPoint(true).institutionId(INSTITUICAO)
                        .avgMinutesFromStart(minutosUnifor).build()));
    }

    @BeforeEach
    void setUp() {
        lista = DailyList.builder().id(LIST_ID)
                .route(Route.builder().id(ROUTE_ID).name("Rota Universitária").build()).build();
        when(findListUseCase.findById(LIST_ID)).thenReturn(lista);
        when(userRepository.findByEmail("naiara@admin.com")).thenReturn(java.util.Optional.of(
                com.smartboarding.smartboarding_api.domain.user.entity.User.builder()
                        .id(ADMIN_ID).email("naiara@admin.com")
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN)
                        .build()));
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(java.util.Optional.of(
                com.smartboarding.smartboarding_api.domain.user.entity.User.builder()
                        .id(STUDENT_ID).email("fernanda@edu.unifor.br")
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                        .institutionId(INSTITUICAO).build()));
        when(routeMemberRepository.existsByUserIdAndRouteId(STUDENT_ID, ROUTE_ID)).thenReturn(true);
        when(checkpointRepository.findAllByDailyListId(any())).thenReturn(List.of());
        when(manageStopsUseCase.listByRoute(ROUTE_ID)).thenReturn(List.of(
                Stop.builder().id(STOP_ID).routeId(ROUTE_ID).name("Rodoviária")
                        .sequence(1).isMainPoint(true).build(),
                Stop.builder().id(UUID.randomUUID()).routeId(ROUTE_ID).name("Posto do Zé")
                        .sequence(2).isMainPoint(false).build()));
    }

    /// /api/trip/** é hasRole("ADMIN"): quem conduz o ônibus é o admin, e um aluno
    /// marcando checkpoint falsificaria a posição do trajeto.
    @Test
    void alunoNaoConduzOTrajeto() throws Exception {
        mvc.perform(post("/api/trip/{id}/start", LIST_ID).with(student()))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/trip/{id}/checkpoint/{stopId}", LIST_ID, STOP_ID).with(student()))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/trip/{id}/finish", LIST_ID).with(student()))
                .andExpect(status().isForbidden());

        verify(conductTripUseCase, never()).start(any());
        verify(conductTripUseCase, never()).checkpoint(any(), any());
        verify(conductTripUseCase, never()).finish(any());
    }

    @Test
    void semTokenDevolve401() throws Exception {
        mvc.perform(get("/api/trip/{id}", LIST_ID)).andExpect(status().isUnauthorized());
    }

    /// Só ponto principal aparece no trajeto — parada intermediária polui a tela
    /// de quem está dirigindo.
    @Test
    void statusListaSoOsPontosPrincipais() throws Exception {
        mvc.perform(get("/api/trip/{id}", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.routeName").value("Rota Universitária"))
                .andExpect(jsonPath("$.data.stops.length()").value(1))
                .andExpect(jsonPath("$.data.stops[0].name").value("Rodoviária"))
                .andExpect(jsonPath("$.data.stops[0].reachedAt").doesNotExist());
    }

    @Test
    void checkpointJaAlcancadoVemComOHorario() throws Exception {
        var alcancado = LocalDateTime.of(2026, 9, 9, 6, 15);
        when(checkpointRepository.findAllByDailyListId(LIST_ID)).thenReturn(List.of(
                TripCheckpoint.builder().dailyListId(LIST_ID).stopId(STOP_ID)
                        .reachedAt(alcancado).build()));

        mvc.perform(get("/api/trip/{id}", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.stops[0].reachedAt").exists());
    }

    @Test
    void iniciarTrajetoDevolveOStatusAtualizado() throws Exception {
        lista.setTripStartedAt(LocalDateTime.of(2026, 9, 9, 6, 0));
        when(conductTripUseCase.start(LIST_ID)).thenReturn(lista);

        mvc.perform(post("/api/trip/{id}/start", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.startedAt").exists());

        verify(conductTripUseCase).start(LIST_ID);
    }

    @Test
    void iniciarDuasVezesDevolve409() throws Exception {
        when(conductTripUseCase.start(LIST_ID))
                .thenThrow(new ConflictException("TRIP_ALREADY_STARTED", "Trajeto já iniciado."));

        mvc.perform(post("/api/trip/{id}/start", LIST_ID).with(admin()))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TRIP_ALREADY_STARTED"));
    }

    @Test
    void marcarCheckpointRepassaListaEParada() throws Exception {
        when(conductTripUseCase.checkpoint(LIST_ID, STOP_ID)).thenReturn(lista);

        mvc.perform(post("/api/trip/{id}/checkpoint/{stopId}", LIST_ID, STOP_ID).with(admin()))
                .andExpect(status().isOk());

        verify(conductTripUseCase).checkpoint(LIST_ID, STOP_ID);
    }

    @Test
    void checkpointEmParadaQueNaoEPontoPrincipalDevolve409() throws Exception {
        when(conductTripUseCase.checkpoint(any(), any()))
                .thenThrow(new ConflictException("STOP_NOT_MAIN_POINT", "Parada não é ponto principal."));

        mvc.perform(post("/api/trip/{id}/checkpoint/{stopId}", LIST_ID, STOP_ID).with(admin()))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("STOP_NOT_MAIN_POINT"));
    }

    @Test
    void encerrarTrajetoDevolveOStatusFinal() throws Exception {
        lista.setTripStartedAt(LocalDateTime.of(2026, 9, 9, 6, 0));
        lista.setTripFinishedAt(LocalDateTime.of(2026, 9, 9, 7, 30));
        when(conductTripUseCase.finish(LIST_ID)).thenReturn(lista);

        mvc.perform(post("/api/trip/{id}/finish", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.finishedAt").exists());
    }

    @Test
    void encerrarSemIniciarDevolve409() throws Exception {
        when(conductTripUseCase.finish(any()))
                .thenThrow(new ConflictException("TRIP_NOT_STARTED", "Trajeto não foi iniciado."));

        mvc.perform(post("/api/trip/{id}/finish", LIST_ID).with(admin()))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TRIP_NOT_STARTED"));
    }

    // ─── Ida e volta ──────────────────────────────────────────────────────────

    private static final UUID SEGUNDO = UUID.fromString("dddddddd-0000-0000-0000-000000000002");

    private void doisPontosPrincipais() {
        when(manageStopsUseCase.listByRoute(ROUTE_ID)).thenReturn(List.of(
                Stop.builder().id(STOP_ID).routeId(ROUTE_ID).name("Rodoviária")
                        .sequence(1).isMainPoint(true).build(),
                Stop.builder().id(SEGUNDO).routeId(ROUTE_ID).name("UNIFOR-MG")
                        .sequence(2).isMainPoint(true).build()));
    }

    @Test
    void naIdaAsParadasSaemNaOrdemDaRota() throws Exception {
        doisPontosPrincipais();

        mvc.perform(get("/api/trip/{id}", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.leg").value("OUTBOUND"))
                .andExpect(jsonPath("$.data.stops[0].name").value("Rodoviária"))
                .andExpect(jsonPath("$.data.stops[1].name").value("UNIFOR-MG"));
    }

    /// Na volta o onibus refaz o mesmo caminho de tras pra frente -- a ordem tem
    /// que inverter, senao a tela pede pra marcar a primeira parada da cidade
    /// enquanto ele ainda esta no campus.
    @Test
    void naVoltaAsParadasSaemInvertidas() throws Exception {
        doisPontosPrincipais();
        lista.setOutboundFinishedAt(LocalDateTime.of(2026, 9, 12, 7, 0));

        mvc.perform(get("/api/trip/{id}", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.leg").value("RETURN"))
                .andExpect(jsonPath("$.data.stops[0].name").value("UNIFOR-MG"))
                .andExpect(jsonPath("$.data.stops[1].name").value("Rodoviária"));
    }

    /// A mesma parada tem checkpoint nas DUAS pernas. Sem filtrar por perna antes
    /// de indexar, o toMap por stopId estoura com chave duplicada e o endpoint
    /// inteiro morre em 500 assim que a volta comeca.
    @Test
    void aMesmaParadaNasDuasPernasNaoDerrubaOEndpoint() throws Exception {
        doisPontosPrincipais();
        lista.setOutboundFinishedAt(LocalDateTime.of(2026, 9, 12, 7, 0));
        when(checkpointRepository.findAllByDailyListId(LIST_ID)).thenReturn(List.of(
                TripCheckpoint.builder().dailyListId(LIST_ID).stopId(STOP_ID)
                        .leg(TripLeg.OUTBOUND)
                        .reachedAt(LocalDateTime.of(2026, 9, 12, 6, 10)).build(),
                TripCheckpoint.builder().dailyListId(LIST_ID).stopId(STOP_ID)
                        .leg(TripLeg.RETURN)
                        .reachedAt(LocalDateTime.of(2026, 9, 12, 18, 30)).build()));

        mvc.perform(get("/api/trip/{id}", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                // Mostra o horario da VOLTA, nao o da ida.
                .andExpect(jsonPath("$.data.stops[1].reachedAt").value(
                        org.hamcrest.Matchers.containsString("18:30")));
    }

    @Test
    void outboundFinishedAtVaiNaResposta() throws Exception {
        doisPontosPrincipais();
        lista.setOutboundFinishedAt(LocalDateTime.of(2026, 9, 12, 7, 0));

        mvc.perform(get("/api/trip/{id}", LIST_ID).with(admin()))
                .andExpect(jsonPath("$.data.outboundFinishedAt").exists());
    }

    // ─── O aluno acompanha o trajeto ─────────────────────────────────────────

    /// Até esta mudança /api/trip/** inteiro era hasRole("ADMIN") e não checava
    /// rota nenhuma. Abrir pro aluno sem guard deixaria qualquer um ler o
    /// trajeto de qualquer rota.
    @Test
    void alunoDeOutraRotaNaoLeOTrajeto() throws Exception {
        when(routeMemberRepository.existsByUserIdAndRouteId(STUDENT_ID, ROUTE_ID))
                .thenReturn(false);

        mvc.perform(get("/api/trip/{listId}", LIST_ID).with(student()))
                .andExpect(status().isForbidden());
    }

    @Test
    void alunoDaRotaLeOTrajeto() throws Exception {
        mvc.perform(get("/api/trip/{listId}", LIST_ID).with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.routeName").value("Rota Universitária"));
    }

    /// Conduzir continua sendo do admin -- é a RN23, e abrir a leitura não
    /// pode ter aberto a escrita junto.
    @Test
    void alunoNaoIniciaNemMarcaTrajeto() throws Exception {
        mvc.perform(post("/api/trip/{listId}/start", LIST_ID).with(student()))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/trip/{listId}/checkpoint/{stopId}", LIST_ID, STOP_ID)
                        .with(student()))
                .andExpect(status().isForbidden());

        verify(conductTripUseCase, never()).start(any());
    }

    /// Cada aluno vê a parada dele. O nome vem junto: sem nomear o destino,
    /// quem vê o número do colega conclui que o app está errado.
    @Test
    void alunoVeAParadaDaPropriaInstituicao() throws Exception {
        rotaComInstituicao(1, 13);

        mvc.perform(get("/api/trip/{listId}", LIST_ID).with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.myStop.stopName").value("UNIFOR-MG"))
                .andExpect(jsonPath("$.data.myStop.fallback").value(false))
                .andExpect(jsonPath("$.data.myStop.etaMinutes").value(13));
    }

    /// O tempo sai da diferença entre os minutos já calculados: da última
    /// parada alcançada até a dele. Nada de bater no OSRM por consulta.
    @Test
    void oTempoDesconta_oQueJaFoiPercorrido() throws Exception {
        rotaComInstituicao(3, 13);
        when(checkpointRepository.findAllByDailyListId(LIST_ID)).thenReturn(List.of(
                TripCheckpoint.builder().stopId(STOP_ID).leg(TripLeg.OUTBOUND)
                        .reachedAt(LocalDateTime.now()).build()));

        mvc.perform(get("/api/trip/{listId}", LIST_ID).with(student()))
                .andExpect(jsonPath("$.data.myStop.etaMinutes").value(10));
    }

    /// Instituição sem parada declarada: mostra a última e AVISA que é ela.
    /// Omitir deixaria o aluno sem nenhuma noção de quando chega.
    @Test
    void semParadaDaInstituicaoCaiNaUltimaEAvisa() throws Exception {
        rotaComInstituicao(1, 13);
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(java.util.Optional.of(
                com.smartboarding.smartboarding_api.domain.user.entity.User.builder()
                        .id(STUDENT_ID).email("fernanda@edu.unifor.br")
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                        .institutionId(UUID.randomUUID()).build()));

        mvc.perform(get("/api/trip/{listId}", LIST_ID).with(student()))
                .andExpect(jsonPath("$.data.myStop.stopName").value("UNIFOR-MG"))
                .andExpect(jsonPath("$.data.myStop.fallback").value(true));
    }

    /// O ônibus já passou pela parada dele: mostrar tempo negativo seria pior
    /// que não mostrar nada.
    @Test
    void depoisDeAlcancadaNaoHaTempoNegativo() throws Exception {
        rotaComInstituicao(1, 13);
        when(checkpointRepository.findAllByDailyListId(LIST_ID)).thenReturn(List.of(
                TripCheckpoint.builder().stopId(STOP_UNIFOR).leg(TripLeg.OUTBOUND)
                        .reachedAt(LocalDateTime.now()).build()));

        mvc.perform(get("/api/trip/{listId}", LIST_ID).with(student()))
                .andExpect(jsonPath("$.data.myStop.alreadyReached").value(true))
                .andExpect(jsonPath("$.data.myStop.etaMinutes").doesNotExist());
    }

    /// O admin esqueceu de marcar a parada do aluno e marcou a seguinte. A
    /// conta dá negativo -- e um "-4 min" na tela é pior que não mostrar nada.
    @Test
    void checkpointPuladoNaoProduzTempoNegativo() throws Exception {
        UUID stopFinal = UUID.fromString("dddddddd-0000-0000-0000-000000000003");
        when(manageStopsUseCase.listByRoute(ROUTE_ID)).thenReturn(List.of(
                Stop.builder().id(STOP_ID).routeId(ROUTE_ID).name("Rodoviária")
                        .sequence(1).isMainPoint(true).avgMinutesFromStart(1).build(),
                Stop.builder().id(STOP_UNIFOR).routeId(ROUTE_ID).name("UNIFOR-MG")
                        .sequence(2).isMainPoint(true).institutionId(INSTITUICAO)
                        .avgMinutesFromStart(13).build(),
                Stop.builder().id(stopFinal).routeId(ROUTE_ID).name("IFMG")
                        .sequence(3).isMainPoint(true).avgMinutesFromStart(20).build()));
        // O ônibus está no IFMG (20 min) sem ter marcado a UNIFOR (13 min).
        when(checkpointRepository.findAllByDailyListId(LIST_ID)).thenReturn(List.of(
                TripCheckpoint.builder().stopId(stopFinal).leg(TripLeg.OUTBOUND)
                        .reachedAt(LocalDateTime.now()).build()));

        mvc.perform(get("/api/trip/{listId}", LIST_ID).with(student()))
                .andExpect(jsonPath("$.data.myStop.alreadyReached").value(false))
                .andExpect(jsonPath("$.data.myStop.etaMinutes").doesNotExist());
    }

    /// Nulo é "não sei" e a tela omite. Um zero ali viraria "o ônibus chegou".
    @Test
    void semTempoCalculadoOEtaFicaNulo() throws Exception {
        rotaComInstituicao(null, null);

        mvc.perform(get("/api/trip/{listId}", LIST_ID).with(student()))
                .andExpect(jsonPath("$.data.myStop.stopName").value("UNIFOR-MG"))
                .andExpect(jsonPath("$.data.myStop.etaMinutes").doesNotExist());
    }

    /// Quem conduz o ônibus não viaja nele: calcular "a parada dele" seria
    /// inventar um destino.
    @Test
    void oAdminNaoTemParadaPropria() throws Exception {
        rotaComInstituicao(1, 13);

        mvc.perform(get("/api/trip/{listId}", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.myStop").doesNotExist());
    }
}
