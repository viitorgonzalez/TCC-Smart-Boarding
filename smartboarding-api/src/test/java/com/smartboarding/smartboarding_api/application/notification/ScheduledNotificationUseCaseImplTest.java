package com.smartboarding.smartboarding_api.application.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.NotificationFrequency;
import com.smartboarding.smartboarding_api.domain.notification.entity.ScheduledNotification;
import com.smartboarding.smartboarding_api.domain.notification.port.in.PublishNotificationUseCase;
import com.smartboarding.smartboarding_api.domain.notification.port.out.ScheduledNotificationRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ScheduledNotificationUseCaseImplTest {

    private static final UUID ROUTE = UUID.randomUUID();
    private static final ZoneId ZONE = ZoneOffset.UTC;

    @Mock ScheduledNotificationRepositoryPort repository;
    @Mock PublishNotificationUseCase publishNotificationUseCase;

    private ScheduledNotificationUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        // Quarta-feira, 08:00 — dia útil, pra WEEKDAYS e DAILY valerem.
        useCase = at(LocalDateTime.of(2026, 9, 9, 8, 0));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    private ScheduledNotificationUseCaseImpl at(LocalDateTime now) {
        Clock clock = Clock.fixed(now.toInstant(ZoneOffset.UTC), ZONE);
        return new ScheduledNotificationUseCaseImpl(repository, publishNotificationUseCase, clock);
    }

    private ScheduledNotification aviso(NotificationFrequency freq, LocalTime sendAt) {
        return ScheduledNotification.builder()
                .id(UUID.randomUUID()).routeId(ROUTE)
                .title("Lista aberta").body("A lista de hoje já está aberta")
                .frequency(freq).sendAt(sendAt).durationHours(4).active(true)
                .build();
    }

    private void ativos(ScheduledNotification... avisos) {
        when(repository.findAllActive()).thenReturn(List.of(avisos));
    }

    @Test
    void listarFiltraPelaRota() {
        var avisos = List.of(aviso(NotificationFrequency.DAILY, LocalTime.of(6, 0)));
        when(repository.findAllByRouteId(ROUTE)).thenReturn(avisos);

        assertThat(useCase.listByRoute(ROUTE)).isEqualTo(avisos);
    }

    @Test
    void toggleDesativaEPersiste() {
        var aviso = aviso(NotificationFrequency.DAILY, LocalTime.of(6, 0));
        when(repository.findById(aviso.getId())).thenReturn(Optional.of(aviso));

        var result = useCase.toggle(aviso.getId(), false);

        assertThat(result.isActive()).isFalse();
        verify(repository).save(aviso);
    }

    @Test
    void toggleDeAvisoInexistenteEstoura() {
        UUID id = UUID.randomUUID();
        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.toggle(id, true)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void deleteDelegaPeloId() {
        UUID id = UUID.randomUUID();

        useCase.delete(id);

        verify(repository).deleteById(id);
    }

    @Test
    void saveDelegaAoRepositorio() {
        var aviso = aviso(NotificationFrequency.DAILY, LocalTime.of(6, 0));

        assertThat(useCase.save(aviso)).isSameAs(aviso);
        verify(repository).save(aviso);
    }

    @Test
    void avisoNoHorarioEPublicadoNaRotaComADuracao() {
        var aviso = aviso(NotificationFrequency.DAILY, LocalTime.of(6, 0));
        ativos(aviso);

        assertThat(useCase.dispatchDue()).isEqualTo(1);

        verify(publishNotificationUseCase).publish("Lista aberta",
                "A lista de hoje já está aberta", ROUTE, 4, null);
        assertThat(aviso.getLastSentAt()).isNotNull();
    }

    @Test
    void avisoAntesDoHorarioNaoDispara() {
        ativos(aviso(NotificationFrequency.DAILY, LocalTime.of(18, 0)));

        assertThat(useCase.dispatchDue()).isZero();
        verify(publishNotificationUseCase, never()).publish(any(), any(), any(), any(), any());
    }

    /// A varredura roda a cada 5 minutos; sem a checagem por dia o mesmo aviso
    /// sairia doze vezes por hora.
    @Test
    void avisoJaEnviadoHojeNaoRepete() {
        var aviso = aviso(NotificationFrequency.DAILY, LocalTime.of(6, 0));
        aviso.setLastSentAt(LocalDateTime.of(2026, 9, 9, 6, 1));
        ativos(aviso);

        assertThat(useCase.dispatchDue()).isZero();
        verify(publishNotificationUseCase, never()).publish(any(), any(), any(), any(), any());
    }

    @Test
    void avisoEnviadoOntemDisparaDeNovoHoje() {
        var aviso = aviso(NotificationFrequency.DAILY, LocalTime.of(6, 0));
        aviso.setLastSentAt(LocalDateTime.of(2026, 9, 8, 6, 1));
        ativos(aviso);

        assertThat(useCase.dispatchDue()).isEqualTo(1);
    }

    @Test
    void weekdaysNaoDisparaNoSabado() {
        useCase = at(LocalDateTime.of(2026, 9, 12, 8, 0));
        ativos(aviso(NotificationFrequency.WEEKDAYS, LocalTime.of(6, 0)));

        assertThat(useCase.dispatchDue()).isZero();
    }

    @Test
    void weeklyDisparaSoNoDiaConfigurado() {
        var aviso = aviso(NotificationFrequency.WEEKLY, LocalTime.of(6, 0));
        aviso.setDayOfWeek(3); // quarta — bate com o clock do setUp
        ativos(aviso);

        assertThat(useCase.dispatchDue()).isEqualTo(1);

        var outroDia = aviso(NotificationFrequency.WEEKLY, LocalTime.of(6, 0));
        outroDia.setDayOfWeek(1); // segunda
        ativos(outroDia);

        assertThat(useCase.dispatchDue()).isZero();
    }

    @Test
    void avisoInativoNaoDispara() {
        var aviso = aviso(NotificationFrequency.DAILY, LocalTime.of(6, 0));
        aviso.setActive(false);
        ativos(aviso);

        assertThat(useCase.dispatchDue()).isZero();
    }

    /// Publicação que falha não pode marcar lastSentAt: o próximo tique tem que
    /// tentar de novo em vez de pular o dia.
    @Test
    void falhaNaPublicacaoNaoMarcaComoEnviado() {
        var aviso = aviso(NotificationFrequency.DAILY, LocalTime.of(6, 0));
        ativos(aviso);
        doThrow(new RuntimeException("FCM fora"))
                .when(publishNotificationUseCase).publish(any(), any(), any(), any(), any());

        assertThat(useCase.dispatchDue()).isEqualTo(1);

        assertThat(aviso.getLastSentAt()).isNull();
        verify(repository, never()).save(any());
    }

    @Test
    void umAvisoQuebradoNaoImpedeOsOutros() {
        var quebrado = aviso(NotificationFrequency.DAILY, LocalTime.of(6, 0));
        var bom = aviso(NotificationFrequency.DAILY, LocalTime.of(6, 30));
        ativos(quebrado, bom);
        doThrow(new RuntimeException("FCM fora"))
                .when(publishNotificationUseCase)
                .publish(any(), any(), any(), eq(4), any());

        useCase.dispatchDue();

        verify(publishNotificationUseCase, org.mockito.Mockito.times(2))
                .publish(any(), any(), any(), any(), any());
    }
}
