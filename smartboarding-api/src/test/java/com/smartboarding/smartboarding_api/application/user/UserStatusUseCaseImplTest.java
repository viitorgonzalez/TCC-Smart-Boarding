package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusAction;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserStatusLogRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.*;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.mockito.Mockito.never;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class UserStatusUseCaseImplTest {

    private static final ZoneId ZONE = ZoneId.systemDefault();
    private static final LocalDateTime NOW = LocalDateTime.of(2026, 9, 8, 14, 0);
    private static final UUID STUDENT = UUID.randomUUID();
    private static final UUID ADMIN = UUID.randomUUID();

    @Mock UserRepositoryPort userRepository;
    @Mock UserStatusLogRepositoryPort logRepository;

    private UserStatusUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new UserStatusUseCaseImpl(userRepository, logRepository,
                Clock.fixed(NOW.atZone(ZONE).toInstant(), ZONE));
        when(userRepository.findById(STUDENT)).thenReturn(Optional.of(
                User.builder().id(STUDENT).fullName("Ana Oliveira").isActive(true)
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                        .build()));
        when(userRepository.save(any())).thenAnswer(i -> i.getArgument(0));
        when(logRepository.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    @Test
    void desativarGravaLogComAdminEInstante() {
        useCase.setActive(STUDENT, false, ADMIN);

        ArgumentCaptor<UserStatusLog> captor = ArgumentCaptor.forClass(UserStatusLog.class);
        verify(logRepository).save(captor.capture());
        UserStatusLog log = captor.getValue();

        assertThat(log.getUserId()).isEqualTo(STUDENT);
        assertThat(log.getAdminId()).isEqualTo(ADMIN);
        assertThat(log.getAction()).isEqualTo(UserStatusAction.DEACTIVATED);
        assertThat(log.getCreatedAt()).isEqualTo(NOW);
    }

    @Test
    void desativarDesligaAConta() {
        User saved = useCase.setActive(STUDENT, false, ADMIN);

        assertThat(saved.isActive()).isFalse();
    }

    @Test
    void reativarGravaAcaoDeAtivacao() {
        when(userRepository.findById(STUDENT)).thenReturn(Optional.of(
                User.builder().id(STUDENT).fullName("Ana Oliveira").isActive(false).build()));

        useCase.setActive(STUDENT, true, ADMIN);

        ArgumentCaptor<UserStatusLog> captor = ArgumentCaptor.forClass(UserStatusLog.class);
        verify(logRepository).save(captor.capture());
        assertThat(captor.getValue().getAction()).isEqualTo(UserStatusAction.ACTIVATED);
    }

    @Test
    void mudancaSemEfeitoNaoPoluiOLog() {
        // Ja esta ativo: registrar "ativou" de novo encheria o historico de ruido
        // e faria parecer que houve acao.
        useCase.setActive(STUDENT, true, ADMIN);

        verify(logRepository, never()).save(any());
        verify(userRepository, never()).save(any());
    }

    /// Desativar existe pra conter aluno que abusa da lista. Valendo pra admin,
    /// o primeiro clique errado tranca quem administra o sistema pra fora dele
    /// -- e nao sobra ninguem pra desfazer.
    @Test
    void adminNaoPodeSerDesativado() {
        UUID outroAdmin = UUID.randomUUID();
        when(userRepository.findById(outroAdmin)).thenReturn(Optional.of(
                User.builder().id(outroAdmin).fullName("Naiara").isActive(true)
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN)
                        .build()));

        org.assertj.core.api.Assertions
                .assertThatThrownBy(() -> useCase.setActive(outroAdmin, false, ADMIN))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.BadRequestException.class)
                .hasMessageContaining("administrador");

        org.mockito.Mockito.verify(userRepository, org.mockito.Mockito.never()).save(any());
    }

    @Test
    void ninguemDesativaAPropriaConta() {
        when(userRepository.findById(ADMIN)).thenReturn(Optional.of(
                User.builder().id(ADMIN).fullName("Naiara").isActive(true)
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                        .build()));

        org.assertj.core.api.Assertions
                .assertThatThrownBy(() -> useCase.setActive(ADMIN, false, ADMIN))
                .isInstanceOf(com.smartboarding.smartboarding_api.shared.exception.BadRequestException.class)
                .hasMessageContaining("própria conta");
    }

    /// Reativar continua livre: a trava e so pra nao trancar ninguem pra fora.
    @Test
    void reativarAdminContinuaPermitido() {
        UUID outroAdmin = UUID.randomUUID();
        when(userRepository.findById(outroAdmin)).thenReturn(Optional.of(
                User.builder().id(outroAdmin).fullName("Naiara").isActive(false)
                        .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN)
                        .build()));

        assertThat(useCase.setActive(outroAdmin, true, ADMIN).isActive()).isTrue();
    }

    /// Promover e conceder acesso, nao criar conta: a conta ja existe e e da
    /// pessoa. O log guarda quem concedeu.
    @Test
    void promoverGravaLogComOAdminQueConcedeu() {
        ArgumentCaptor<UserStatusLog> captor = ArgumentCaptor.forClass(UserStatusLog.class);

        User saved = useCase.setRole(STUDENT, Role.ADMIN, ADMIN);

        assertThat(saved.getRole()).isEqualTo(Role.ADMIN);
        verify(logRepository).save(captor.capture());
        assertThat(captor.getValue().getAction()).isEqualTo(UserStatusAction.PROMOTED);
        assertThat(captor.getValue().getAdminId()).isEqualTo(ADMIN);
        assertThat(captor.getValue().getUserId()).isEqualTo(STUDENT);
    }

    /// PATCH role e declaracao de estado, nao acao: repetir tem que dar o mesmo
    /// resultado. Duplo toque e retry de request que deu timeout nao podem virar
    /// erro, e o log nao pode encher de linha duplicada.
    @Test
    void declararOMesmoPapelNaoGeraLogNemErro() {
        when(userRepository.findById(ADMIN)).thenReturn(Optional.of(
                User.builder().id(ADMIN).fullName("Naiara").isActive(true)
                        .role(Role.ADMIN).build()));

        User saved = useCase.setRole(ADMIN, Role.ADMIN, STUDENT);

        assertThat(saved.getRole()).isEqualTo(Role.ADMIN);
        verify(logRepository, never()).save(any());
        verify(userRepository, never()).save(any());
    }

    /// Um clique errado tiraria o acesso de quem esta operando, e so outro admin
    /// poderia devolver.
    @Test
    void ninguemRebaixaAPropriaConta() {
        when(userRepository.findById(ADMIN)).thenReturn(Optional.of(
                User.builder().id(ADMIN).fullName("Naiara").isActive(true)
                        .role(Role.ADMIN).build()));

        assertThatThrownBy(() -> useCase.setRole(ADMIN, Role.STUDENT, ADMIN))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("própria conta");
    }

    /// Sem admin nenhum, ninguem promove ninguem de volta: a recuperacao seria
    /// editar o banco a mao. Esta e a trava que impede o sistema de se trancar.
    @Test
    void oUltimoAdminNaoPodeSerRebaixado() {
        UUID outro = UUID.randomUUID();
        when(userRepository.findById(outro)).thenReturn(Optional.of(
                User.builder().id(outro).fullName("Naiara").isActive(true)
                        .role(Role.ADMIN).build()));
        when(userRepository.countAdmins()).thenReturn(1L);

        assertThatThrownBy(() -> useCase.setRole(outro, Role.STUDENT, ADMIN))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("único administrador");
    }

    @Test
    void comOutroAdminORebaixamentoPassa() {
        UUID outro = UUID.randomUUID();
        when(userRepository.findById(outro)).thenReturn(Optional.of(
                User.builder().id(outro).fullName("Naiara").isActive(true)
                        .role(Role.ADMIN).build()));
        when(userRepository.countAdmins()).thenReturn(2L);

        assertThat(useCase.setRole(outro, Role.STUDENT, ADMIN).getRole())
                .isEqualTo(Role.STUDENT);
    }

    /// Promover conta desativada produz um admin que nao consegue entrar: a tela
    /// mostra acesso concedido e o login nega.
    @Test
    void contaDesativadaNaoPodeSerPromovida() {
        UUID inativo = UUID.randomUUID();
        when(userRepository.findById(inativo)).thenReturn(Optional.of(
                User.builder().id(inativo).fullName("Ana").isActive(false)
                        .role(Role.STUDENT).build()));

        assertThatThrownBy(() -> useCase.setRole(inativo, Role.ADMIN, ADMIN))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("desativada");
    }

    /// A trava do ultimo admin so vale se a contagem e a decisao acontecerem sem
    /// outra transacao no meio. Sem o lock, duas que rebaixam admins diferentes
    /// leem 2, as duas passam, e o sistema fica sem administrador.
    @Test
    void rebaixarSerializaAntesDeContar() {
        UUID outro = UUID.randomUUID();
        when(userRepository.findById(outro)).thenReturn(Optional.of(
                User.builder().id(outro).fullName("Naiara").isActive(true)
                        .role(Role.ADMIN).build()));
        when(userRepository.countAdmins()).thenReturn(2L);

        useCase.setRole(outro, Role.STUDENT, ADMIN);

        org.mockito.InOrder ordem = org.mockito.Mockito.inOrder(userRepository);
        ordem.verify(userRepository).lockAdminRoleChanges();
        ordem.verify(userRepository).countAdmins();
    }

    /// Promover nao mexe na contagem de admins pra baixo, entao nao precisa
    /// segurar ninguem -- pagar o lock ali seria serializar promocao a toa.
    @Test
    void promoverNaoPegaOLock() {
        useCase.setRole(STUDENT, Role.ADMIN, ADMIN);

        verify(userRepository, never()).lockAdminRoleChanges();
    }
}
