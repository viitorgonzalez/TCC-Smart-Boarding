package com.smartboarding.smartboarding_api.infrastructure.web.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import com.smartboarding.smartboarding_api.domain.membership.port.in.JoinRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.in.FindRouteUseCase;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(MembershipController.class)
class MembershipControllerTest extends WebMvcTestSupport {

    private static final UUID ROTA = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");

    @Autowired MockMvc mvc;

    @MockitoBean JoinRouteUseCase joinRouteUseCase;
    @MockitoBean FindRouteUseCase findRouteUseCase;
    @MockitoBean UserRepositoryPort userRepository;

    @BeforeEach
    void setUp() {
        when(userRepository.findByEmail("fernanda@edu.unifor.br")).thenReturn(Optional.of(
                User.builder().id(STUDENT_ID).email("fernanda@edu.unifor.br").build()));
        when(findRouteUseCase.findById(ROTA)).thenReturn(
                Route.builder().id(ROTA).name("Rota Universitária").build());
        when(joinRouteUseCase.routesOf(any())).thenReturn(List.of());
    }

    @Test
    void semTokenNaoEntraEmRotaNenhuma() throws Exception {
        mvc.perform(post("/api/me/routes")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"RU7K2M"}"""))
                .andExpect(status().isUnauthorized());

        verify(joinRouteUseCase, never()).join(any(), anyString());
    }

    /// O id sai do token: aceitar userId do request deixaria um aluno pôr outro
    /// numa rota, ou tirá-lo dela.
    @Test
    void entrarUsaOUsuarioDoToken() throws Exception {
        when(joinRouteUseCase.join(eq(STUDENT_ID), eq("RU7K2M"))).thenReturn(
                RouteMember.builder().userId(STUDENT_ID).routeId(ROTA).build());

        mvc.perform(post("/api/me/routes").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"RU7K2M"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Rota Universitária"));

        verify(joinRouteUseCase).join(STUDENT_ID, "RU7K2M");
    }

    @Test
    void codigoVazioERecusadoAntesDoUseCase() throws Exception {
        mvc.perform(post("/api/me/routes").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":""}"""))
                .andExpect(status().isBadRequest());

        verify(joinRouteUseCase, never()).join(any(), anyString());
    }

    @Test
    void codigoExpiradoDevolve400ComOCodigoDoErro() throws Exception {
        when(joinRouteUseCase.join(any(), anyString()))
                .thenThrow(new BadRequestException("CODE_EXPIRED", "Esse código expirou."));

        mvc.perform(post("/api/me/routes").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"RU7K2M"}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("CODE_EXPIRED"));
    }

    @Test
    void jaEstarNaRotaDevolve409() throws Exception {
        when(joinRouteUseCase.join(any(), anyString()))
                .thenThrow(new ConflictException("ALREADY_MEMBER", "Você já está nessa rota."));

        mvc.perform(post("/api/me/routes").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"RU7K2M"}"""))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_MEMBER"));
    }

    @Test
    void listarDevolveAsRotasDoProprioAluno() throws Exception {
        when(joinRouteUseCase.routesOf(STUDENT_ID)).thenReturn(List.of(ROTA));

        mvc.perform(get("/api/me/routes").with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value(ROTA.toString()));

        verify(joinRouteUseCase).routesOf(STUDENT_ID);
    }

    @Test
    void alunoSemRotaRecebeListaVazia() throws Exception {
        mvc.perform(get("/api/me/routes").with(student()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isEmpty());
    }

    @Test
    void sairUsaOUsuarioDoToken() throws Exception {
        mvc.perform(delete("/api/me/routes/{id}", ROTA).with(student()))
                .andExpect(status().isOk());

        verify(joinRouteUseCase).leave(STUDENT_ID, ROTA);
    }

    /// Duplo toque no botao: a checagem do use case passa nas duas requisicoes e
    /// quem barra a segunda e a constraint UNIQUE(user_id, route_id). Sem tratar,
    /// o aluno via "erro interno no servidor" num caso que e so "voce ja entrou".
    @Test
    void corridaNaEntradaVira409EnaoErroInterno() throws Exception {
        org.mockito.Mockito.doThrow(new org.springframework.dao.DataIntegrityViolationException(
                        "duplicate key value violates unique constraint \"route_members_user_id_route_id_key\""))
                .when(joinRouteUseCase).join(any(), org.mockito.ArgumentMatchers.anyString());

        mvc.perform(post("/api/me/routes").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"ABC123"}"""))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("ALREADY_EXISTS"));
    }

    /// O nome da constraint nao pode vazar pro cliente: entrega nome de tabela e
    /// de coluna pra quem so mandou um codigo.
    @Test
    void aMensagemDoBancoNaoVazaNaResposta() throws Exception {
        org.mockito.Mockito.doThrow(new org.springframework.dao.DataIntegrityViolationException(
                        "duplicate key violates unique constraint \"route_members_user_id_route_id_key\""))
                .when(joinRouteUseCase).join(any(), org.mockito.ArgumentMatchers.anyString());

        String corpo = mvc.perform(post("/api/me/routes").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"ABC123"}"""))
                .andReturn().getResponse().getContentAsString();

        org.assertj.core.api.Assertions.assertThat(corpo)
                .doesNotContain("route_members")
                .doesNotContain("constraint");
    }
}
