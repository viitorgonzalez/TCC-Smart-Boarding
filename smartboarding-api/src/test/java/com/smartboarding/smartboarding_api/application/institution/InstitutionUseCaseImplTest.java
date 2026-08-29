package com.smartboarding.smartboarding_api.application.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InstitutionUseCaseImplTest {

    @Mock
    InstitutionRepositoryPort repository;

    @Mock
    com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort routeRepository;

    @Mock
    com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort userRepository;

    @Test
    void criaInstituicaoEDelegaPraORepositorio() {
        var useCase = new InstitutionUseCaseImpl(repository, routeRepository, userRepository);
        var institution = Institution.builder().name("Unifor — Campus Central").build();
        when(repository.save(institution)).thenReturn(institution);

        var result = useCase.execute(institution);

        assertThat(result.getName()).isEqualTo("Unifor — Campus Central");
    }

    @Test
    void listaTodasAsInstituicoes() {
        var useCase = new InstitutionUseCaseImpl(repository, routeRepository, userRepository);
        var institution = Institution.builder().name("Unifor — Campus Central").build();
        when(repository.findAll()).thenReturn(List.of(institution));

        var result = useCase.findAll();

        assertThat(result).hasSize(1);
    }

    @Test
    void vincularInstituicaoSemRotaFunciona() {
        var useCase = new InstitutionUseCaseImpl(repository, routeRepository, userRepository);
        var id = java.util.UUID.randomUUID();
        var routeId = java.util.UUID.randomUUID();
        var institution = Institution.builder().id(id).name("IFMG").build();
        when(repository.findById(id)).thenReturn(java.util.Optional.of(institution));
        when(routeRepository.findById(routeId)).thenReturn(java.util.Optional.of(
                com.smartboarding.smartboarding_api.domain.route.entity.Route.builder()
                        .id(routeId).name("Formiga").isActive(true).build()));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var result = useCase.linkToRoute(id, routeId);

        assertThat(result.getRouteId()).isEqualTo(routeId);
    }

    @Test
    void duasInstituicoesPodemDividirAMesmaRota() {
        var useCase = new InstitutionUseCaseImpl(repository, routeRepository, userRepository);
        var routeId = java.util.UUID.randomUUID();
        var route = com.smartboarding.smartboarding_api.domain.route.entity.Route.builder()
                .id(routeId).name("Formiga").isActive(true).build();
        when(routeRepository.findById(routeId)).thenReturn(java.util.Optional.of(route));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        for (String name : new String[] {"IFMG", "UNIFOR-MG"}) {
            var id = java.util.UUID.randomUUID();
            when(repository.findById(id)).thenReturn(java.util.Optional.of(
                    Institution.builder().id(id).name(name).build()));
            assertThat(useCase.linkToRoute(id, routeId).getRouteId()).isEqualTo(routeId);
        }
    }

    @Test
    void trocarDeRotaAtivaSemDesvincularAntesLancaConflito() {
        var useCase = new InstitutionUseCaseImpl(repository, routeRepository, userRepository);
        var id = java.util.UUID.randomUUID();
        var rotaAtual = java.util.UUID.randomUUID();
        when(repository.findById(id)).thenReturn(java.util.Optional.of(
                Institution.builder().id(id).name("IFMG").routeId(rotaAtual).build()));
        when(routeRepository.findById(rotaAtual)).thenReturn(java.util.Optional.of(
                com.smartboarding.smartboarding_api.domain.route.entity.Route.builder()
                        .id(rotaAtual).isActive(true).build()));

        assertThatThrownBy(() -> useCase.linkToRoute(id, java.util.UUID.randomUUID()))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.ConflictException.class);
        verify(repository, never()).save(any());
    }

    @Test
    void desvincularSempreFunciona() {
        var useCase = new InstitutionUseCaseImpl(repository, routeRepository, userRepository);
        var id = java.util.UUID.randomUUID();
        when(repository.findById(id)).thenReturn(java.util.Optional.of(
                Institution.builder().id(id).name("IFMG").routeId(java.util.UUID.randomUUID()).build()));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        assertThat(useCase.linkToRoute(id, null).getRouteId()).isNull();
    }

    @Test
    void naoApagaInstituicaoComAlunoVinculado() {
        var useCase = new InstitutionUseCaseImpl(repository, routeRepository, userRepository);
        var id = java.util.UUID.randomUUID();
        when(repository.findById(id)).thenReturn(java.util.Optional.of(
                Institution.builder().id(id).name("IFMG").build()));
        when(userRepository.countByInstitutionId(id)).thenReturn(3L);

        assertThatThrownBy(() -> useCase.delete(id))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.ConflictException.class);
        verify(repository, never()).deleteById(any());
    }

    @Test
    void apagaInstituicaoSemAluno() {
        var useCase = new InstitutionUseCaseImpl(repository, routeRepository, userRepository);
        var id = java.util.UUID.randomUUID();
        when(repository.findById(id)).thenReturn(java.util.Optional.of(
                Institution.builder().id(id).name("Vazia").build()));
        when(userRepository.countByInstitutionId(id)).thenReturn(0L);

        useCase.delete(id);

        verify(repository).deleteById(id);
    }
}
