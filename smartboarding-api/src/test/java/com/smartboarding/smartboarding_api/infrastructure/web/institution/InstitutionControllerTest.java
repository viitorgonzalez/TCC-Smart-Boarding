package com.smartboarding.smartboarding_api.infrastructure.web.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.in.CreateInstitutionUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.in.LinkInstitutionRouteUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.in.ListInstitutionsUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.in.ManageInstitutionUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.WebMvcTestSupport;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(InstitutionController.class)
class InstitutionControllerTest extends WebMvcTestSupport {

    private static final UUID INSTITUTION_ID = UUID.fromString("cccccccc-0000-0000-0000-000000000001");
    private static final UUID ROUTE_ID = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000001");

    @Autowired MockMvc mvc;

    @MockitoBean CreateInstitutionUseCase createInstitutionUseCase;
    @MockitoBean ListInstitutionsUseCase listInstitutionsUseCase;
    @MockitoBean LinkInstitutionRouteUseCase linkInstitutionRouteUseCase;
    @MockitoBean ManageInstitutionUseCase manageInstitutionUseCase;

    private Institution unifor() {
        return Institution.builder().id(INSTITUTION_ID).name("Unifor")
                .address("Av. Washington Soares, 1321").latitude(-3.76).longitude(-38.48)
                .routeId(ROUTE_ID).build();
    }

    /// GET é permitAll: o formulário de cadastro precisa da lista antes do login.
    @Test
    void listarInstituicoesEPublico() throws Exception {
        when(listInstitutionsUseCase.findAll()).thenReturn(List.of(unifor()));

        mvc.perform(get("/api/institutions"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].name").value("Unifor"))
                .andExpect(jsonPath("$.data[0].routeId").value(ROUTE_ID.toString()));
    }

    @Test
    void criarEditarEApagarSaoDoAdmin() throws Exception {
        mvc.perform(post("/api/institutions").with(student())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Falsa"}"""))
                .andExpect(status().isForbidden());
        mvc.perform(patch("/api/institutions/{id}", INSTITUTION_ID).with(student())
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mvc.perform(delete("/api/institutions/{id}", INSTITUTION_ID).with(student()))
                .andExpect(status().isForbidden());

        verify(createInstitutionUseCase, never()).execute(any());
        verify(manageInstitutionUseCase, never()).delete(any());
    }

    @Test
    void adminCriaInstituicao() throws Exception {
        when(createInstitutionUseCase.execute(any())).thenReturn(unifor());

        mvc.perform(post("/api/institutions").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Unifor","address":"Av. Washington Soares, 1321",\
                                "latitude":-3.76,"longitude":-38.48}"""))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.name").value("Unifor"));
    }

    @Test
    void instituicaoSemNomeERecusada() throws Exception {
        mvc.perform(post("/api/institutions").with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":""}"""))
                .andExpect(status().isBadRequest());

        verify(createInstitutionUseCase, never()).execute(any());
    }

    /// RN15: a rota do aluno é derivada da instituição, por isso o vínculo tem
    /// endpoint próprio.
    @Test
    void vincularRotaRepassaOIdDaRota() throws Exception {
        when(linkInstitutionRouteUseCase.linkToRoute(INSTITUTION_ID, ROUTE_ID)).thenReturn(unifor());

        mvc.perform(patch("/api/institutions/{id}/route", INSTITUTION_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"routeId":"bbbbbbbb-0000-0000-0000-000000000001"}"""))
                .andExpect(status().isOk());

        verify(linkInstitutionRouteUseCase).linkToRoute(INSTITUTION_ID, ROUTE_ID);
    }

    @Test
    void desvincularMandaRotaNula() throws Exception {
        when(linkInstitutionRouteUseCase.linkToRoute(INSTITUTION_ID, null)).thenReturn(unifor());

        mvc.perform(patch("/api/institutions/{id}/route", INSTITUTION_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"routeId":null}"""))
                .andExpect(status().isOk());

        verify(linkInstitutionRouteUseCase).linkToRoute(INSTITUTION_ID, null);
    }

    @Test
    void editarRepassaOsCamposParciais() throws Exception {
        when(manageInstitutionUseCase.update(any(), any(), any(), any(), any())).thenReturn(unifor());

        mvc.perform(patch("/api/institutions/{id}", INSTITUTION_ID).with(admin())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"UECE","latitude":-3.79}"""))
                .andExpect(status().isOk());

        verify(manageInstitutionUseCase).update(INSTITUTION_ID, "UECE", null, -3.79, null);
    }

    /// Aluno referencia a instituição e tira dela a própria rota — apagar com
    /// aluno vinculado devolve 409, não um 500.
    @Test
    void apagarInstituicaoComAlunoDevolve409() throws Exception {
        org.mockito.Mockito.doThrow(new ConflictException("INSTITUTION_HAS_STUDENTS",
                        "Instituição tem alunos vinculados."))
                .when(manageInstitutionUseCase).delete(INSTITUTION_ID);

        mvc.perform(delete("/api/institutions/{id}", INSTITUTION_ID).with(admin()))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("INSTITUTION_HAS_STUDENTS"));
    }

    @Test
    void adminApagaInstituicaoSemAluno() throws Exception {
        mvc.perform(delete("/api/institutions/{id}", INSTITUTION_ID).with(admin()))
                .andExpect(status().isOk());

        verify(manageInstitutionUseCase).delete(INSTITUTION_ID);
    }
}
