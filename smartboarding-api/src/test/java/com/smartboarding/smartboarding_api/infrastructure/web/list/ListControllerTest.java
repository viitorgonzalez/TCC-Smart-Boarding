package com.smartboarding.smartboarding_api.infrastructure.web.list;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import com.smartboarding.smartboarding_api.domain.list.port.in.AddEntryUseCase;
import com.smartboarding.smartboarding_api.domain.warning.port.in.EnrollByAdminUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.FindListUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.ManageDailyListUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.RemoveEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.report.port.out.ReportRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.stop.port.in.ManageStopsUseCase;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ListController.class)
class ListControllerTest extends WebMvcTestSupport {

    private static final UUID LIST_ID = UUID.fromString("aaaaaaaa-0000-0000-0000-000000000001");
    private static final UUID ROUTE_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");
    private static final UUID INSTITUTION_ID = UUID.fromString("cccccccc-0000-0000-0000-000000000001");

    @Autowired MockMvc mvc;

    @MockitoBean FindListUseCase findListUseCase;
    @MockitoBean AddEntryUseCase addEntryUseCase;
    @MockitoBean RemoveEntryUseCase removeEntryUseCase;
    @MockitoBean ListEntryRepositoryPort listEntryRepository;
    @MockitoBean UserRepositoryPort userRepository;
    @MockitoBean VehicleRepositoryPort vehicleRepository;
    @MockitoBean InstitutionRepositoryPort institutionRepository;
    @MockitoBean ReportRepositoryPort reportRepository;
    @MockitoBean ObjectMapper objectMapper;
    @MockitoBean ManageStopsUseCase manageStopsUseCase;
    @MockitoBean ManageDailyListUseCase manageDailyListUseCase;
    @MockitoBean EnrollByAdminUseCase enrollByAdminUseCase;

    private User aluno;

    @BeforeEach
    void setUp() {
        aluno = User.builder().id(STUDENT_ID).email("fernanda@edu.unifor.br")
                .fullName("Fernanda Lima").institutionId(INSTITUTION_ID).build();
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(Optional.of(aluno));
        when(userRepository.findByEmail("naiara@admin.com")).thenReturn(Optional.of(
                User.builder().id(ADMIN_ID).email("naiara@admin.com").fullName("Naiara").build()));
        when(institutionRepository.findAll()).thenReturn(List.of(
                Institution.builder().id(INSTITUTION_ID).name("Unifor").routeId(ROUTE_ID).build()));
        when(vehicleRepository.findAllByRouteId(any())).thenReturn(List.of());
        when(manageStopsUseCase.listByRoute(any())).thenReturn(List.of());
        when(listEntryRepository.findAllByDailyListIdAndIsActiveTrue(any())).thenReturn(List.of());
        when(listEntryRepository.findByUserIdAndDailyListId(any(), any())).thenReturn(Optional.empty());
        when(reportRepository.findByDailyListId(any())).thenReturn(Optional.empty());
    }

    private DailyList lista() {
        return DailyList.builder().id(LIST_ID).date(LocalDate.of(2026, 9, 9))
                .status(ListStatus.OPEN)
                .route(Route.builder().id(ROUTE_ID).name("Rota Universitária").build())
                .build();
    }

    private ListEntry inscricao() {
        return ListEntry.builder().id(UUID.randomUUID()).user(aluno)
                .dailyList(lista()).tripType(TripType.ROUND_TRIP).isActive(true).build();
    }

    @Test
    void semAutenticacaoDevolve401() throws Exception {
        mvc.perform(get("/api/lists/today")).andExpect(status().isUnauthorized());

        verify(findListUseCase, never()).findTodayLists(any());
    }

    /// O id vem do token, não do request: aceitar userId do cliente deixaria um
    /// aluno consultar e alterar a lista de outro.
    @Test
    void listaDeHojeUsaOUsuarioDoToken() throws Exception {
        when(findListUseCase.findTodayLists(STUDENT_ID)).thenReturn(List.of(lista()));

        mvc.perform(get("/api/lists/today").with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value(LIST_ID.toString()));

        verify(findListUseCase).findTodayLists(STUDENT_ID);
    }

    @Test
    void tokenDeUsuarioApagadoDevolve401() throws Exception {
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(Optional.empty());

        mvc.perform(get("/api/lists/today").with(student()))
                .andExpect(status().isUnauthorized());
    }

    /// Consultar lista de qualquer data é do admin — o aluno tem /today e o
    /// próprio histórico, não a agenda inteira da rota.
    @Test
    void byDateEDoAdminERepassaADataDoQueryParam() throws Exception {
        when(manageDailyListUseCase.findByDate(any())).thenReturn(List.of(lista()));

        mvc.perform(get("/api/lists").param("date", "2026-09-09").with(student()))
                .andExpect(status().isForbidden());

        mvc.perform(get("/api/lists").param("date", "2026-09-09").with(admin()))
                .andExpect(status().isOk());

        verify(manageDailyListUseCase).findByDate(LocalDate.of(2026, 9, 9));
    }

    @Test
    void entrarNaListaSemCorpoAssumeIdaEVolta() throws Exception {
        when(addEntryUseCase.add(STUDENT_ID, LIST_ID, TripType.ROUND_TRIP)).thenReturn(inscricao());

        mvc.perform(post("/api/lists/{id}/entries", LIST_ID).with(student()))
                .andExpect(status().isCreated());

        verify(addEntryUseCase).add(STUDENT_ID, LIST_ID, TripType.ROUND_TRIP);
    }

    @Test
    void entrarNaListaComDirecaoExplicita() throws Exception {
        when(addEntryUseCase.add(STUDENT_ID, LIST_ID, TripType.TO_CAMPUS)).thenReturn(inscricao());

        mvc.perform(post("/api/lists/{id}/entries", LIST_ID).with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"tripType":"TO_CAMPUS"}"""))
                .andExpect(status().isCreated());

        verify(addEntryUseCase).add(STUDENT_ID, LIST_ID, TripType.TO_CAMPUS);
    }

    @Test
    void listaFechadaDevolve409() throws Exception {
        when(addEntryUseCase.add(any(), any(), any()))
                .thenThrow(new ConflictException("LIST_CLOSED", "A lista já foi fechada."));

        mvc.perform(post("/api/lists/{id}/entries", LIST_ID).with(student()))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LIST_CLOSED"));
    }

    @Test
    void listaInexistenteDevolve404() throws Exception {
        when(findListUseCase.findById(any()))
                .thenThrow(new NotFoundException("Lista não encontrada"));

        mvc.perform(get("/api/lists/{id}", LIST_ID).with(student()))
                .andExpect(status().isNotFound());
    }

    @Test
    void sairDaListaRemoveOProprioUsuario() throws Exception {
        mvc.perform(delete("/api/lists/{id}/entries", LIST_ID).with(student()))
                .andExpect(status().isOk());

        verify(removeEntryUseCase).remove(STUDENT_ID, LIST_ID);
    }

    /// Inclusão tardia é do admin: aluno chamando o endpoint de admin não pode
    /// escolher em nome de terceiro nem escapar da advertência.
    @Test
    void alunoNaoPodeInscreverOutroPeloEndpointDeAdmin() throws Exception {
        mvc.perform(post("/api/lists/{id}/entries/admin", LIST_ID).with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"userId":"11111111-1111-1111-1111-111111111111","issueWarning":false}"""))
                .andExpect(status().isForbidden());

        verify(enrollByAdminUseCase, never())
                .enroll(any(), any(), any(), anyBooleanOrNull(), any(), any());
    }

    private static boolean anyBooleanOrNull() {
        return org.mockito.ArgumentMatchers.anyBoolean();
    }

    @Test
    void adminInscreveAlunoDecidindoSeAdverte() throws Exception {
        when(enrollByAdminUseCase.enroll(eq(LIST_ID), eq(STUDENT_ID), eq(TripType.ROUND_TRIP),
                eq(true), eq("Entrou fora do horário"), eq(ADMIN_ID))).thenReturn(inscricao());

        mvc.perform(post("/api/lists/{id}/entries/admin", LIST_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"userId":"11111111-1111-1111-1111-111111111111",\
                                "issueWarning":true,"warningReason":"Entrou fora do horário"}"""))
                .andExpect(status().isCreated());

        verify(enrollByAdminUseCase).enroll(LIST_ID, STUDENT_ID, TripType.ROUND_TRIP,
                true, "Entrou fora do horário", ADMIN_ID);
    }

    @Test
    void adminRemoveInscritoPeloId() throws Exception {
        mvc.perform(delete("/api/lists/{id}/entries/{userId}", LIST_ID, STUDENT_ID).with(admin()))
                .andExpect(status().isOk());

        verify(removeEntryUseCase).remove(STUDENT_ID, LIST_ID);
    }

    @Test
    void criarListaEDoAdmin() throws Exception {
        mvc.perform(post("/api/lists").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"routeId":"bbbbbbbb-0000-0000-0000-000000000001","date":"2026-09-10"}"""))
                .andExpect(status().isForbidden());

        verify(manageDailyListUseCase, never()).create(any(), any());
    }

    @Test
    void mudarStatusExigeMotivo() throws Exception {
        mvc.perform(patch("/api/lists/{id}", LIST_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"status":"CLOSED"}"""))
                .andExpect(status().isBadRequest());

        verify(manageDailyListUseCase, never()).setStatus(any(), any(), any());
    }

    @Test
    void mudarStatusComMotivoChegaNoUseCase() throws Exception {
        when(manageDailyListUseCase.setStatus(eq(LIST_ID), eq(ListStatus.CLOSED), any()))
                .thenReturn(lista());

        mvc.perform(patch("/api/lists/{id}", LIST_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"status":"CLOSED","reason":"Ônibus quebrou"}"""))
                .andExpect(status().isOk());

        verify(manageDailyListUseCase).setStatus(LIST_ID, ListStatus.CLOSED, "Ônibus quebrou");
    }

    @Test
    void apagarListaEDoAdmin() throws Exception {
        mvc.perform(delete("/api/lists/{id}", LIST_ID).with(student()))
                .andExpect(status().isForbidden());

        mvc.perform(delete("/api/lists/{id}", LIST_ID).with(admin()))
                .andExpect(status().isOk());

        verify(manageDailyListUseCase).delete(LIST_ID);
    }

    @Test
    void historicoDePresencaUsaOUsuarioDoToken() throws Exception {
        when(findListUseCase.findMyAttendance(eq(STUDENT_ID), org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn(List.of());

        mvc.perform(get("/api/lists/my-attendance").with(student()))
                .andExpect(status().isOk());

        verify(findListUseCase).findMyAttendance(eq(STUDENT_ID), org.mockito.ArgumentMatchers.anyInt());
    }

    @Test
    void inscritosDaListaSaemComONomeDaInstituicao() throws Exception {
        when(findListUseCase.findEntriesByList(LIST_ID)).thenReturn(List.of(inscricao()));

        mvc.perform(get("/api/lists/{id}/entries", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].institutionName").value("Unifor"));
    }

    private ListEntry inscricaoDe(String nome, UUID institutionId) {
        return ListEntry.builder().id(UUID.randomUUID())
                .user(User.builder().id(UUID.randomUUID()).fullName(nome)
                        .email(nome.toLowerCase() + "@edu.unifor.br")
                        .institutionId(institutionId).build())
                .dailyList(lista()).tripType(TripType.ROUND_TRIP).isActive(true).build();
    }

    /// A contagem por instituição é o que o admin usa pra saber quantos descem em
    /// cada campus. Aluno sem instituição não pode sumir da conta.
    @Test
    void contagemAgrupaPorInstituicaoEAcusaOsSemVinculo() throws Exception {
        UUID outra = UUID.fromString("cccccccc-0000-0000-0000-000000000002");
        when(institutionRepository.findAll()).thenReturn(List.of(
                Institution.builder().id(INSTITUTION_ID).name("Unifor").routeId(ROUTE_ID).build(),
                Institution.builder().id(outra).name("UECE").routeId(ROUTE_ID).build()));
        when(findListUseCase.findById(LIST_ID)).thenReturn(lista());
        when(listEntryRepository.findAllByDailyListIdAndIsActiveTrue(LIST_ID)).thenReturn(List.of(
                inscricaoDe("Fernanda", INSTITUTION_ID),
                inscricaoDe("Bruno", INSTITUTION_ID),
                inscricaoDe("Carla", outra),
                inscricaoDe("Sem vinculo", null)));

        mvc.perform(get("/api/lists/{id}", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                // TreeMap: ordem alfabetica estavel, nao a ordem de chegada.
                .andExpect(jsonPath("$.data.entriesByInstitution[0].name").value("Sem instituição"))
                .andExpect(jsonPath("$.data.entriesByInstitution[0].count").value(1))
                .andExpect(jsonPath("$.data.entriesByInstitution[1].name").value("UECE"))
                .andExpect(jsonPath("$.data.entriesByInstitution[2].name").value("Unifor"))
                .andExpect(jsonPath("$.data.entriesByInstitution[2].count").value(2));
    }

    /// RN16: a proposta de veículo sai do relatório do fechamento. Lista aberta
    /// não propõe nada — o total de confirmados ainda muda.
    @Test
    void listaAbertaNaoTrazVeiculoProposto() throws Exception {
        when(findListUseCase.findById(LIST_ID)).thenReturn(lista());

        mvc.perform(get("/api/lists/{id}", LIST_ID).with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.proposedVehicles").isEmpty())
                .andExpect(jsonPath("$.data.capacityShortfall").value(0));

        verify(reportRepository, never()).findByDailyListId(any());
    }

    @Test
    void listaFechadaTrazOVeiculoPropostoDoRelatorio() throws Exception {
        var fechada = DailyList.builder().id(LIST_ID).date(LocalDate.of(2026, 9, 9))
                .status(ListStatus.CLOSED)
                .route(Route.builder().id(ROUTE_ID).name("Rota Universitária").build()).build();
        when(findListUseCase.findById(LIST_ID)).thenReturn(fechada);
        when(reportRepository.findByDailyListId(LIST_ID)).thenReturn(Optional.of(
                com.smartboarding.smartboarding_api.domain.report.entity.Report.builder()
                        .proposedVehicles("[{\"label\":\"Van 01\",\"capacity\":\"15\"}]")
                        .capacityShortfall(3).build()));
        when(objectMapper.readValue(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.<com.fasterxml.jackson.core.type.TypeReference<Object>>any()))
                .thenReturn(List.of(java.util.Map.of("label", "Van 01", "capacity", "15")));

        mvc.perform(get("/api/lists/{id}", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.proposedVehicles[0].label").value("Van 01"))
                .andExpect(jsonPath("$.data.proposedVehicles[0].capacity").value(15))
                .andExpect(jsonPath("$.data.capacityShortfall").value(3));
    }

    /// JSON corrompido no relatório não pode derrubar a tela da lista: perde-se a
    /// proposta, mas o déficit gravado continua valendo.
    @Test
    void relatorioComJsonQuebradoNaoDerrubaATela() throws Exception {
        var fechada = DailyList.builder().id(LIST_ID).date(LocalDate.of(2026, 9, 9))
                .status(ListStatus.CLOSED)
                .route(Route.builder().id(ROUTE_ID).name("Rota Universitária").build()).build();
        when(findListUseCase.findById(LIST_ID)).thenReturn(fechada);
        when(reportRepository.findByDailyListId(LIST_ID)).thenReturn(Optional.of(
                com.smartboarding.smartboarding_api.domain.report.entity.Report.builder()
                        .proposedVehicles("{ nao e json valido").capacityShortfall(5).build()));
        when(objectMapper.readValue(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.<com.fasterxml.jackson.core.type.TypeReference<Object>>any()))
                .thenThrow(new RuntimeException("json invalido"));

        mvc.perform(get("/api/lists/{id}", LIST_ID).with(admin()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.proposedVehicles").isEmpty())
                .andExpect(jsonPath("$.data.capacityShortfall").value(5));
    }

    @Test
    void adminCriaListaERecebeAListaCriada() throws Exception {
        when(manageDailyListUseCase.create(eq(ROUTE_ID), any())).thenReturn(lista());

        mvc.perform(post("/api/lists").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"routeId":"bbbbbbbb-0000-0000-0000-000000000001","date":"2026-09-10"}"""))
                .andExpect(status().isCreated());

        verify(manageDailyListUseCase).create(ROUTE_ID, LocalDate.of(2026, 9, 10));
    }

    @Test
    void listaExistenteNoMesmoDiaDevolve409() throws Exception {
        when(manageDailyListUseCase.create(any(), any()))
                .thenThrow(new ConflictException("LIST_ALREADY_EXISTS", "Já existe lista dessa rota."));

        mvc.perform(post("/api/lists").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"routeId":"bbbbbbbb-0000-0000-0000-000000000001","date":"2026-09-10"}"""))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("LIST_ALREADY_EXISTS"));
    }
}
