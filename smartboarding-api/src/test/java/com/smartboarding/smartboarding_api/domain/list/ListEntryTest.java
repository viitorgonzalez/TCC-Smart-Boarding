package com.smartboarding.smartboarding_api.domain.list;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ListEntryTest {

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
