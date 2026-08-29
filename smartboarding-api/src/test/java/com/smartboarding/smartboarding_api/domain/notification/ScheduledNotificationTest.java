package com.smartboarding.smartboarding_api.domain.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.NotificationFrequency;
import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.time.LocalTime;

import static org.assertj.core.api.Assertions.assertThat;

class ScheduledNotificationTest {

    // 2026-08-28 é uma sexta-feira; 29 é sábado.
    private static final LocalDateTime SEXTA_07H = LocalDateTime.of(2026, 8, 28, 7, 0);
    private static final LocalDateTime SEXTA_05H = LocalDateTime.of(2026, 8, 28, 5, 0);
    private static final LocalDateTime SABADO_07H = LocalDateTime.of(2026, 8, 29, 7, 0);

    private ScheduledNotification.ScheduledNotificationBuilder base() {
        return ScheduledNotification.builder()
                .title("Saída").body("O ônibus sai em 30 min")
                .sendAt(LocalTime.of(6, 30))
                .active(true);
    }

    @Test
    void diarioDisparaDepoisDoHorario() {
        var n = base().frequency(NotificationFrequency.DAILY).build();

        assertThat(n.isDue(SEXTA_07H)).isTrue();
    }

    @Test
    void naoDisparaAntesDoHorario() {
        var n = base().frequency(NotificationFrequency.DAILY).build();

        assertThat(n.isDue(SEXTA_05H)).isFalse();
    }

    @Test
    void naoRepeteNoMesmoDia() {
        var n = base().frequency(NotificationFrequency.DAILY)
                .lastSentAt(SEXTA_07H.minusHours(1)).build();

        assertThat(n.isDue(SEXTA_07H)).isFalse();
    }

    @Test
    void voltaADispararNoDiaSeguinte() {
        var n = base().frequency(NotificationFrequency.DAILY)
                .lastSentAt(SEXTA_07H).build();

        assertThat(n.isDue(SEXTA_07H.plusDays(1))).isTrue();
    }

    @Test
    void diasUteisNaoDisparaNoFimDeSemana() {
        var n = base().frequency(NotificationFrequency.WEEKDAYS).build();

        assertThat(n.isDue(SEXTA_07H)).isTrue();
        assertThat(n.isDue(SABADO_07H)).isFalse();
    }

    @Test
    void semanalDisparaSoNoDiaEscolhido() {
        var sexta = base().frequency(NotificationFrequency.WEEKLY).dayOfWeek(5).build();
        var segunda = base().frequency(NotificationFrequency.WEEKLY).dayOfWeek(1).build();

        assertThat(sexta.isDue(SEXTA_07H)).isTrue();
        assertThat(segunda.isDue(SEXTA_07H)).isFalse();
    }

    @Test
    void desligadoNuncaDispara() {
        var n = base().frequency(NotificationFrequency.DAILY).active(false).build();

        assertThat(n.isDue(SEXTA_07H)).isFalse();
    }
}
