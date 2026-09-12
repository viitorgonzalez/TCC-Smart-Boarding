package com.smartboarding.smartboarding_api.application.route;

import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RouteUseCaseImplTest {

    @Mock RouteRepositoryPort repository;

    private RouteUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new RouteUseCaseImpl(repository);
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(repository.existsByName(any())).thenReturn(false);
        when(repository.existsByNameAndIdNot(any(), any())).thenReturn(false);
    }

    private Route existente(String nome) {
        Route route = Route.builder().id(UUID.randomUUID()).name(nome)
                .openTime(LocalTime.of(6, 0)).closeTime(LocalTime.of(17, 0)).isActive(true).build();
        when(repository.findById(route.getId())).thenReturn(Optional.of(route));
        return route;
    }

    /// @Builder.Default não protege contra null explícito vindo do request — sem
    /// o fallback, criar rota sem horário violaria o NOT NULL da coluna.
    @Test
    void rotaSemHorarioRecebeOsPadroes() {
        Route nova = Route.builder().name("Rota Nova").build();
        nova.setOpenTime(null);
        nova.setCloseTime(null);

        Route saved = useCase.execute(nova);

        assertThat(saved.getOpenTime()).isEqualTo(Route.DEFAULT_OPEN_TIME);
        assertThat(saved.getCloseTime()).isEqualTo(Route.DEFAULT_CLOSE_TIME);
    }

    @Test
    void horarioInformadoNaoEsobrescrito() {
        Route saved = useCase.execute(Route.builder().name("Rota Nova")
                .openTime(LocalTime.of(5, 30)).closeTime(LocalTime.of(18, 0)).build());

        assertThat(saved.getOpenTime()).isEqualTo(LocalTime.of(5, 30));
        assertThat(saved.getCloseTime()).isEqualTo(LocalTime.of(18, 0));
    }

    @Test
    void nomeDuplicadoEBloqueadoNaCriacao() {
        when(repository.existsByName("Rota Universitária")).thenReturn(true);

        assertThatThrownBy(() -> useCase.execute(Route.builder().name("Rota Universitária").build()))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("Rota já cadastrada");

        verify(repository, never()).save(any());
    }

    @Test
    void findAllActiveFiltraAsDesativadas() {
        var ativas = List.of(Route.builder().name("Rota A").build());
        when(repository.findAllByIsActiveTrue()).thenReturn(ativas);

        assertThat(useCase.findAllActive()).isEqualTo(ativas);
    }

    @Test
    void findByIdInexistenteEstoura() {
        UUID id = UUID.randomUUID();
        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.findById(id))
                .isInstanceOf(NotFoundException.class)
                .hasMessageContaining(id.toString());
    }

    @Test
    void editarTrocaNomeDescricaoEHorarios() {
        Route route = existente("Rota Antiga");

        Route saved = useCase.execute(route.getId(), Route.builder().name("Rota Nova")
                .description("via centro").openTime(LocalTime.of(5, 0))
                .closeTime(LocalTime.of(19, 0)).build(), null);

        assertThat(saved.getName()).isEqualTo("Rota Nova");
        assertThat(saved.getDescription()).isEqualTo("via centro");
        assertThat(saved.getOpenTime()).isEqualTo(LocalTime.of(5, 0));
        assertThat(saved.getCloseTime()).isEqualTo(LocalTime.of(19, 0));
    }

    /// Horário nulo preserva o atual. O builder do Lombok injeta os defaults, então
    /// só o mapper do request chega aqui com null -- que e exatamente o caso a
    /// proteger: PUT sem os campos de horario nao pode zerar o que ja estava la.
    @Test
    void editarSemHorarioPreservaOAtual() {
        Route route = existente("Rota Antiga");
        Route mudanca = Route.builder().name("Rota Antiga").build();
        mudanca.setOpenTime(null);
        mudanca.setCloseTime(null);

        Route saved = useCase.execute(route.getId(), mudanca, null);

        assertThat(saved.getOpenTime()).isEqualTo(LocalTime.of(6, 0));
        assertThat(saved.getCloseTime()).isEqualTo(LocalTime.of(17, 0));
    }

    @Test
    void nomeUsadoPorOutraRotaEBloqueadoNaEdicao() {
        Route route = existente("Rota A");
        when(repository.existsByNameAndIdNot("Rota B", route.getId())).thenReturn(true);

        assertThatThrownBy(() -> useCase.execute(route.getId(),
                Route.builder().name("Rota B").build(), null))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("Nome de rota já utilizado");
    }

    /// isActive nulo mantém o estado atual — sem isso, rota desativada pelo
    /// DELETE não teria caminho de volta.
    @Test
    void isActiveNuloNaoMexeNoEstado() {
        Route route = existente("Rota A");
        route.setActive(false);

        Route saved = useCase.execute(route.getId(), Route.builder().name("Rota A").build(), null);

        assertThat(saved.isActive()).isFalse();
    }

    @Test
    void reativarRotaDesativada() {
        Route route = existente("Rota A");
        route.setActive(false);

        Route saved = useCase.execute(route.getId(), Route.builder().name("Rota A").build(), true);

        assertThat(saved.isActive()).isTrue();
    }

    /// DELETE desativa em vez de apagar: listas e relatórios antigos apontam pra
    /// rota e perderiam a referência. O port sequer expõe remoção física.
    @Test
    void deleteApenasDesativa() {
        Route route = existente("Rota A");

        useCase.execute(route.getId());

        assertThat(route.isActive()).isFalse();
        verify(repository).save(route);
    }
}
