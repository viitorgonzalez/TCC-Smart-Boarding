package com.smartboarding.smartboarding_api.application.notification;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;
import com.smartboarding.smartboarding_api.domain.notification.port.out.DeviceTokenRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.out.FcmPort;
import com.smartboarding.smartboarding_api.domain.notification.port.out.NotificationRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.*;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class NotificationUseCaseImplTest {

    private static final LocalDateTime NOW = LocalDateTime.of(2026, 8, 28, 12, 0);

    @Mock FcmPort fcmPort;
    @Mock DeviceTokenRepositoryPort deviceTokenRepository;
    @Mock NotificationRepositoryPort notificationRepository;
    @Mock UserRepositoryPort userRepository;
    @Mock RouteMemberRepositoryPort routeMemberRepository;

    private NotificationUseCaseImpl useCase() {
        var clock = Clock.fixed(NOW.atZone(ZoneId.systemDefault()).toInstant(), ZoneId.systemDefault());
        return new NotificationUseCaseImpl(fcmPort, deviceTokenRepository,
                notificationRepository, userRepository, routeMemberRepository, clock);
    }

    @Test
    void publicarComDuracaoDefineAExpiracao() {
        when(notificationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(deviceTokenRepository.findAllTokens()).thenReturn(List.of("tok"));

        useCase().publish("Atraso", "O ônibus vai atrasar", null, 6, UUID.randomUUID());

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository).save(captor.capture());
        assertThat(captor.getValue().getExpiresAt()).isEqualTo(NOW.plusHours(6));
    }

    @Test
    void publicarSemDuracaoNaoExpira() {
        when(notificationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(deviceTokenRepository.findAllTokens()).thenReturn(List.of());

        useCase().publish("Aviso", "Mensagem", null, null, UUID.randomUUID());

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository).save(captor.capture());
        assertThat(captor.getValue().getExpiresAt()).isNull();
    }

    @Test
    void falhaNoPushNaoDesfazOAvisoGravado() {
        when(notificationRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(deviceTokenRepository.findAllTokens()).thenReturn(List.of("tok"));
        doThrow(new RuntimeException("FCM fora do ar"))
                .when(fcmPort).sendToTokens(anyList(), anyString(), anyString());

        var saved = useCase().publish("Aviso", "Mensagem", null, 1, UUID.randomUUID());

        assertThat(saved.getTitle()).isEqualTo("Aviso");
        verify(notificationRepository).save(any());
    }

    @Test
    void alunoVeGeraisEOsDasRotasDele() {
        var studentId = UUID.randomUUID();
        var routeId = UUID.randomUUID();
        when(userRepository.findById(studentId)).thenReturn(Optional.of(User.builder()
                .id(studentId).role(Role.STUDENT).build()));
        when(routeMemberRepository.findAllByUserId(studentId)).thenReturn(List.of(
                RouteMember.builder().userId(studentId).routeId(routeId).build()));
        when(notificationRepository.findVisible(List.of(routeId), NOW)).thenReturn(List.of(
                Notification.builder().title("Geral").build()));

        var result = useCase().listFor(studentId);

        assertThat(result).hasSize(1);
        verify(notificationRepository).findVisible(List.of(routeId), NOW);
        verify(notificationRepository, never()).findAll();
    }

    /// O aluno pode estar em mais de uma rota, e precisa ver o aviso de todas --
    /// perder o aviso de uma delas e perder a informacao que o faz nao aparecer
    /// no ponto.
    @Test
    void alunoEmDuasRotasVeOsAvisosDasDuas() {
        var studentId = UUID.randomUUID();
        var rotaA = UUID.randomUUID();
        var rotaB = UUID.randomUUID();
        when(userRepository.findById(studentId)).thenReturn(Optional.of(User.builder()
                .id(studentId).role(Role.STUDENT).build()));
        when(routeMemberRepository.findAllByUserId(studentId)).thenReturn(List.of(
                RouteMember.builder().userId(studentId).routeId(rotaA).build(),
                RouteMember.builder().userId(studentId).routeId(rotaB).build()));

        useCase().listFor(studentId);

        verify(notificationRepository).findVisible(List.of(rotaA, rotaB), NOW);
    }

    @Test
    void adminVeTodosInclusiveExpirados() {
        var adminId = UUID.randomUUID();
        when(userRepository.findById(adminId)).thenReturn(Optional.of(
                User.builder().id(adminId).role(Role.ADMIN).build()));
        when(notificationRepository.findAll()).thenReturn(List.of(
                Notification.builder().title("A").build(),
                Notification.builder().title("B").build()));

        assertThat(useCase().listFor(adminId)).hasSize(2);
        verify(notificationRepository, never()).findVisible(any(), any());
    }

    @Test
    void pushDirigidoUsaSoOsTokensDaquelesUsuario() {
        UUID userId = UUID.randomUUID();
        when(deviceTokenRepository.findByUserId(userId)).thenReturn(List.of(
                com.smartboarding.smartboarding_api.domain.notification.entity.DeviceToken.builder()
                        .token("tok-a").build(),
                com.smartboarding.smartboarding_api.domain.notification.entity.DeviceToken.builder()
                        .token("tok-b").build()));

        useCase().execute(userId, "Advertência", "Você entrou fora do horário");

        verify(fcmPort).sendToTokens(List.of("tok-a", "tok-b"),
                "Advertência", "Você entrou fora do horário");
    }

    @Test
    void usuarioSemDispositivoNaoChamaOFcm() {
        UUID userId = UUID.randomUUID();
        when(deviceTokenRepository.findByUserId(userId)).thenReturn(List.of());

        useCase().execute(userId, "Advertência", "corpo");

        verify(fcmPort, never()).sendToTokens(anyList(), anyString(), anyString());
    }

    @Test
    void deleteAllVazioNaoChamaORepositorio() {
        useCase().deleteAll(List.of());

        verify(notificationRepository, never()).deleteAllById(any());
    }

    @Test
    void deleteAllRepassaOsIds() {
        var ids = List.of(UUID.randomUUID(), UUID.randomUUID());

        useCase().deleteAll(ids);

        verify(notificationRepository).deleteAllById(ids);
    }

    /// Admin vê tudo; aluno vê só o que vale pra rota dele e ainda não expirou.
    @Test
    void adminVeTodosOsAvisos() {
        UUID adminId = UUID.randomUUID();
        when(userRepository.findById(adminId)).thenReturn(Optional.of(
                User.builder().id(adminId).role(Role.ADMIN).build()));
        var todos = List.of(Notification.builder().build());
        when(notificationRepository.findAll()).thenReturn(todos);

        assertThat(useCase().listFor(adminId)).isEqualTo(todos);
        verify(notificationRepository, never()).findVisible(any(), any());
    }

    @Test
    void alunoSemRotaNenhumaRecebeSoOsAvisosGerais() {
        UUID studentId = UUID.randomUUID();
        when(userRepository.findById(studentId)).thenReturn(Optional.of(
                User.builder().id(studentId).role(Role.STUDENT).build()));

        useCase().listFor(studentId);

        verify(notificationRepository).findVisible(List.of(), NOW);
    }

    @Test
    void alunoRecebeOsAvisosDaRotaDaSuaInstituicao() {
        UUID studentId = UUID.randomUUID();
        UUID routeId = UUID.randomUUID();
        when(userRepository.findById(studentId)).thenReturn(Optional.of(
                User.builder().id(studentId).role(Role.STUDENT).build()));
        when(routeMemberRepository.findAllByUserId(studentId)).thenReturn(List.of(
                RouteMember.builder().userId(studentId).routeId(routeId).build()));

        useCase().listFor(studentId);

        verify(notificationRepository).findVisible(List.of(routeId), NOW);
    }
}
