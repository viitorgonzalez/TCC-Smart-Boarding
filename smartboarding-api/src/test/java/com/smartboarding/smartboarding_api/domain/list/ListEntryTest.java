package com.smartboarding.smartboarding_api.domain.list;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ListEntryTest {

    /// Sem @Builder.Default o Lombok ignora o `= true` do campo e a inscricao
    /// nasce inativa. Como toda leitura da lista filtra por isActive, o aluno
    /// entraria na lista e simplesmente nao apareceria nela -- sem erro nenhum.
    @Test
    void inscricaoNasceAtivaMesmoSemPassarNoBuilder() {
        ListEntry entry = ListEntry.builder().build();

        assertThat(entry.isActive()).isTrue();
    }

    @Test
    void quemPassaExplicitamenteContinuaMandando() {
        assertThat(ListEntry.builder().isActive(false).build().isActive()).isFalse();
    }

    @Test
    void tipoDeViagemPadraoEIdaEVolta() {
        assertThat(ListEntry.builder().build().getTripType()).isEqualTo(TripType.ROUND_TRIP);
    }
}
