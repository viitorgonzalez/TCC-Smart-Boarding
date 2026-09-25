package com.smartboarding.smartboarding_api.application.stop;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import com.smartboarding.smartboarding_api.domain.stop.port.out.StopRepositoryPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class StopUseCaseImplTest {

    private static final UUID ROUTE = UUID.randomUUID();

    @Mock StopRepositoryPort repository;

    private Stop stop(String name, int seq) {
        return Stop.builder().id(UUID.randomUUID()).routeId(ROUTE).name(name).sequence(seq).build();
    }

    private List<Stop> route(Stop... stops) {
        var list = new ArrayList<>(List.of(stops));
        when(repository.findAllByRouteIdOrderBySequenceAsc(ROUTE)).thenReturn(list);
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        return list;
    }

    @Test
    void semSequenciaEntraNoFim() {
        route(stop("A", 1), stop("B", 2));
        var nova = Stop.builder().routeId(ROUTE).name("C").build();

        var saved = new StopUseCaseImpl(repository).add(nova);

        assertThat(saved.getSequence()).isEqualTo(3);
    }

    @Test
    void inserirNoMeioEmpurraAsSeguintes() {
        var a = stop("A", 1);
        var b = stop("B", 2);
        var c = stop("C", 3);
        route(a, b, c);
        var nova = Stop.builder().routeId(ROUTE).name("Nova").sequence(2).build();

        new StopUseCaseImpl(repository).add(nova);

        assertThat(a.getSequence()).isEqualTo(1);
        assertThat(b.getSequence()).isEqualTo(3);
        assertThat(c.getSequence()).isEqualTo(4);
    }

    @Test
    void moverAtualizaSoAsCoordenadas() {
        var a = stop("A", 1);
        when(repository.findById(a.getId())).thenReturn(Optional.of(a));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var moved = new StopUseCaseImpl(repository).update(a.getId(), null, -20.5, -45.5);

        assertThat(moved.getName()).isEqualTo("A");
        assertThat(moved.getLatitude()).isEqualTo(-20.5);
    }

    @Test
    void removerRenumeraParaNaoDeixarBuraco() {
        var a = stop("A", 1);
        var c = stop("C", 3);
        when(repository.findById(a.getId())).thenReturn(Optional.of(a));
        when(repository.findAllByRouteIdOrderBySequenceAsc(ROUTE)).thenReturn(new ArrayList<>(List.of(c)));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        new StopUseCaseImpl(repository).remove(a.getId());

        assertThat(c.getSequence()).isEqualTo(1);
    }

    // ─── Ponto principal (RN23) ──────────────────────────────────────────────

    /// BUG: nada em src/main escrevia is_main_point -- só a migration V20, uma
    /// vez. Como TripUseCaseImpl.checkpoint recusa parada que não seja ponto
    /// principal, TODA rota criada depois da V20 ficava sem nenhuma parada
    /// marcável: o admin iniciava o trajeto e cada toque devolvia
    /// STOP_NOT_MAIN_POINT.
    @Test
    void paradaQueServeInstituicaoNasceComoPontoPrincipal() {
        route();
        UUID instituicao = UUID.randomUUID();
        Stop nova = stop("UNIFOR-MG", 0);
        nova.setInstitutionId(instituicao);

        Stop salva = new StopUseCaseImpl(repository).add(nova);

        assertThat(salva.isMainPoint()).isTrue();
        assertThat(salva.getInstitutionId()).isEqualTo(instituicao);
    }

    /// A RN23 continua valendo: parada comum aparece no mapa e não gera
    /// marcação. O que mudou é existir um jeito de dizer que uma parada é
    /// principal.
    @Test
    void paradaComumNaoViraPontoPrincipal() {
        route();

        Stop salva = new StopUseCaseImpl(repository).add(stop("Av. Jair Leite", 0));

        assertThat(salva.isMainPoint()).isFalse();
    }

    /// A rodoviária é ponto principal e não é instituição nenhuma. Sem uma
    /// marcação explícita ela dependeria de casar o nome com 'Rodoviária%' --
    /// que é exatamente a fragilidade de onde esse bug veio.
    @Test
    void paradaPodeSerMarcadaComoPrincipalSemInstituicao() {
        route();
        Stop rodoviaria = stop("Rodoviária de Pimenta", 0);
        rodoviaria.setMainPoint(true);

        assertThat(new StopUseCaseImpl(repository).add(rodoviaria).isMainPoint()).isTrue();
    }

    /// O vínculo era adivinhado por `s.name LIKE i.name || '%'`. Renomear a
    /// parada pra "Portão 2 da UNIFOR" quebrava tudo em silêncio, e ninguém
    /// percebia até o aluno ver o tempo da parada errada.
    @Test
    void renomearNaoDesfazOVinculoComAInstituicao() {
        UUID instituicao = UUID.randomUUID();
        Stop existente = stop("UNIFOR-MG", 1);
        existente.setInstitutionId(instituicao);
        existente.setMainPoint(true);
        when(repository.findById(existente.getId())).thenReturn(Optional.of(existente));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Stop renomeada = new StopUseCaseImpl(repository)
                .update(existente.getId(), "Portão 2 da UNIFOR", null, null);

        assertThat(renomeada.getInstitutionId()).isEqualTo(instituicao);
        assertThat(renomeada.isMainPoint()).isTrue();
    }

    /// Desvincular a instituição tira o status: a parada deixou de servir
    /// alguém, e continuar aceitando checkpoint marcaria chegada num lugar que
    /// não é destino de ninguém.
    @Test
    void desvincularAInstituicaoTiraOPontoPrincipal() {
        Stop existente = stop("UNIFOR-MG", 1);
        existente.setInstitutionId(UUID.randomUUID());
        existente.setMainPoint(true);
        when(repository.findById(existente.getId())).thenReturn(Optional.of(existente));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Stop solta = new StopUseCaseImpl(repository)
                .update(existente.getId(), null, null, null, null, false);

        assertThat(solta.getInstitutionId()).isNull();
        assertThat(solta.isMainPoint()).isFalse();
    }
}
