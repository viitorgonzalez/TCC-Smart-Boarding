package com.smartboarding.smartboarding_api.application.membership;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.entity.UserInstitution;
import com.smartboarding.smartboarding_api.domain.membership.port.out.UserInstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ForbiddenException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

/// Papel não é alcance: `ADMIN` diz o que a pessoa sabe fazer, isto diz sobre o
/// que ela pode fazer. Antes desta classe, quem administrava o IFMG revogava
/// código da UNIFOR.
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AdminScopeImplTest {

    private static final UUID ADMIN = UUID.randomUUID();
    private static final UUID UNIFOR = UUID.randomUUID();
    private static final UUID IFMG = UUID.randomUUID();
    private static final UUID ROTA_DE_FORMIGA = UUID.randomUUID();
    private static final UUID ROTA_DE_OUTRA_CIDADE = UUID.randomUUID();

    @Mock UserInstitutionRepositoryPort userInstitutionRepository;
    @Mock InstitutionRepositoryPort institutionRepository;
    @Mock RouteRepositoryPort routeRepository;

    private AdminScopeImpl scope;

    @BeforeEach
    void setUp() {
        scope = new AdminScopeImpl(userInstitutionRepository, institutionRepository, routeRepository);
        when(routeRepository.findAllByIsActiveTrue()).thenReturn(List.of(
                Route.builder().id(ROTA_DE_FORMIGA).name("Rota Universitária de Formiga").build(),
                Route.builder().id(ROTA_DE_OUTRA_CIDADE).name("Rota de Outra Cidade").build()));
        when(institutionRepository.findAll()).thenReturn(List.of(
                Institution.builder().id(UNIFOR).name("UNIFOR-MG").routeId(ROTA_DE_FORMIGA).build(),
                Institution.builder().id(IFMG).name("IFMG").routeId(ROTA_DE_FORMIGA).build(),
                Institution.builder().id(UUID.randomUUID()).name("Outra")
                        .routeId(ROTA_DE_OUTRA_CIDADE).build()));
    }

    private void administra(UUID... instituicoes) {
        when(userInstitutionRepository.findAllByUserId(ADMIN)).thenReturn(
                java.util.Arrays.stream(instituicoes)
                        .map(id -> UserInstitution.builder().userId(ADMIN).institutionId(id).build())
                        .toList());
    }

    @Test
    void asRotasSaoAsDasInstituicoesDeclaradas() {
        administra(IFMG);

        assertThat(scope.routesOf(ADMIN)).containsExactly(ROTA_DE_FORMIGA);
    }

    /// Duas instituições na mesma rota não duplicam a rota nem dão acesso extra.
    @Test
    void instituicoesQueDividemARotaNaoDuplicamNada() {
        administra(UNIFOR, IFMG);

        assertThat(scope.routesOf(ADMIN)).containsExactly(ROTA_DE_FORMIGA);
    }

    /// Admin recém-promovido não declarou instituição nenhuma. Sem isto ele
    /// cairia no caso "conjunto vazio não contém nada" e veria tudo por engano
    /// em qualquer filtro escrito ao contrário.
    @Test
    void semInstituicaoDeclaradaNaoAlcancaRotaNenhuma() {
        administra();

        assertThat(scope.routesOf(ADMIN)).isEmpty();
        assertThatThrownBy(() -> scope.assertAdministersRoute(ADMIN, ROTA_DE_FORMIGA))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void aceitaARotaQueAdministra() {
        administra(IFMG);

        assertThatCode(() -> scope.assertAdministersRoute(ADMIN, ROTA_DE_FORMIGA))
                .doesNotThrowAnyException();
    }

    @Test
    void recusaRotaDeOutraInstituicao() {
        administra(IFMG);

        assertThatThrownBy(() -> scope.assertAdministersRoute(ADMIN, ROTA_DE_OUTRA_CIDADE))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("não atende nenhuma instituição");
    }

    @Test
    void recusaRotaNula() {
        administra(IFMG);

        assertThatThrownBy(() -> scope.assertAdministersRoute(ADMIN, null))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void aceitaAInstituicaoQueAdministra() {
        administra(IFMG);

        assertThatCode(() -> scope.assertAdministersInstitution(ADMIN, IFMG))
                .doesNotThrowAnyException();
    }

    @Test
    void recusaInstituicaoAlheia() {
        administra(IFMG);

        assertThatThrownBy(() -> scope.assertAdministersInstitution(ADMIN, UNIFOR))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("não administra essa instituição");
    }

    /// Nulo é o código aberto: não pertence a instituição nenhuma, então não há
    /// dono pra conferir. Quem limita o alcance nesse caso é a rota.
    @Test
    void instituicaoNulaPassa() {
        administra(IFMG);

        assertThatCode(() -> scope.assertAdministersInstitution(ADMIN, null))
                .doesNotThrowAnyException();
    }

    /// Rota recém-criada ainda não tem instituição, e o vínculo se faz dentro
    /// dela. Escondê-la trancaria o admin do lado de fora da própria criação.
    @Test
    void rotaSemInstituicaoFicaVisivelATodoAdmin() {
        administra(IFMG);
        UUID orfa = UUID.randomUUID();
        when(routeRepository.findAllByIsActiveTrue()).thenReturn(List.of(
                Route.builder().id(ROTA_DE_FORMIGA).build(),
                Route.builder().id(ROTA_DE_OUTRA_CIDADE).build(),
                Route.builder().id(orfa).name("Rota recém-criada").build()));

        assertThat(scope.routesOf(ADMIN)).contains(orfa);
        assertThatCode(() -> scope.assertAdministersRoute(ADMIN, orfa))
                .doesNotThrowAnyException();
    }

    /// Assim que a rota ganha dono, ela sai do alcance de quem não é dono.
    @Test
    void rotaComInstituicaoDeixaDeSerDeTodos() {
        administra(IFMG);

        assertThat(scope.routesOf(ADMIN)).doesNotContain(ROTA_DE_OUTRA_CIDADE);
    }
}
