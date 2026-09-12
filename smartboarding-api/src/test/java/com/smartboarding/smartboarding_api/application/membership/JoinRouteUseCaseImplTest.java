package com.smartboarding.smartboarding_api.application.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteInviteCodeRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
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
class JoinRouteUseCaseImplTest {

    private static final LocalDateTime AGORA = LocalDateTime.of(2026, 9, 11, 10, 0);
    private static final UUID ALUNO = UUID.randomUUID();
    private static final UUID ROTA = UUID.randomUUID();

    @Mock RouteInviteCodeRepositoryPort codeRepository;
    @Mock RouteMemberRepositoryPort memberRepository;

    private JoinRouteUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new JoinRouteUseCaseImpl(codeRepository, memberRepository,
                Clock.fixed(AGORA.toInstant(ZoneOffset.UTC), ZoneOffset.UTC));
        when(memberRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(memberRepository.existsByUserIdAndRouteId(any(), any())).thenReturn(false);
    }

    private RouteInviteCode codigo(String code, LocalDateTime expiresAt, LocalDateTime revokedAt) {
        var invite = RouteInviteCode.builder()
                .id(UUID.randomUUID()).routeId(ROTA).code(code)
                .expiresAt(expiresAt).revokedAt(revokedAt).build();
        when(codeRepository.findByCode(code)).thenReturn(Optional.of(invite));
        return invite;
    }

    @Test
    void codigoValidoEntraNaRotaSemAprovacao() {
        var invite = codigo("RU7K2M", AGORA.plusDays(30), null);

        RouteMember member = useCase.join(ALUNO, "RU7K2M");

        assertThat(member.getUserId()).isEqualTo(ALUNO);
        assertThat(member.getRouteId()).isEqualTo(ROTA);
        // Guardar a origem e o que permite contar quantos entraram por cada codigo.
        assertThat(member.getInviteCodeId()).isEqualTo(invite.getId());
    }

    /// O código é digitado à mão: espaço colado e minúscula são erro de digitação,
    /// não código errado.
    @Test
    void codigoEmMinusculaEComEspacoFunciona() {
        codigo("RU7K2M", AGORA.plusDays(30), null);

        assertThat(useCase.join(ALUNO, "  ru7k2m  ").getRouteId()).isEqualTo(ROTA);
    }

    @Test
    void codigoInexistenteERecusado() {
        when(codeRepository.findByCode(any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.join(ALUNO, "XXXXXX"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("inválido");

        verify(memberRepository, never()).save(any());
    }

    @Test
    void codigoVazioOuNuloERecusadoAntesDeConsultar() {
        assertThatThrownBy(() -> useCase.join(ALUNO, "   ")).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> useCase.join(ALUNO, null)).isInstanceOf(BadRequestException.class);

        verify(codeRepository, never()).findByCode(any());
    }

    /// Expirado e revogado dão mensagens diferentes de propósito: o aluno precisa
    /// saber se pede código novo ou se errou a digitação.
    @Test
    void codigoExpiradoDizQueExpirou() {
        codigo("RU7K2M", AGORA.minusDays(1), null);

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("expirou");

        verify(memberRepository, never()).save(any());
    }

    @Test
    void codigoRevogadoDizQueFoiCancelado() {
        codigo("RU7K2M", AGORA.plusDays(30), AGORA.minusHours(2));

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("cancelado");
    }

    /// Revogado vence a checagem de prazo: dentro da validade, mas cancelado,
    /// ainda assim não entra.
    @Test
    void revogadoBloqueiaMesmoDentroDoPrazo() {
        codigo("RU7K2M", AGORA.plusDays(30), AGORA.minusHours(2));

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .hasMessageContaining("cancelado");
    }

    /// Entrar duas vezes duplicaria o aluno em toda contagem da lista.
    @Test
    void alunoJaNaRotaNaoEntraDeNovo() {
        codigo("RU7K2M", AGORA.plusDays(30), null);
        when(memberRepository.existsByUserIdAndRouteId(ALUNO, ROTA)).thenReturn(true);

        assertThatThrownBy(() -> useCase.join(ALUNO, "RU7K2M"))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("já está nessa rota");

        verify(memberRepository, never()).save(any());
    }

    @Test
    void sairRemoveOVinculo() {
        useCase.leave(ALUNO, ROTA);

        verify(memberRepository).deleteByUserIdAndRouteId(ALUNO, ROTA);
    }

    @Test
    void routesOfDevolveTodasAsRotasDoAluno() {
        UUID outra = UUID.randomUUID();
        when(memberRepository.findAllByUserId(ALUNO)).thenReturn(List.of(
                RouteMember.builder().userId(ALUNO).routeId(ROTA).build(),
                RouteMember.builder().userId(ALUNO).routeId(outra).build()));

        assertThat(useCase.routesOf(ALUNO)).containsExactlyInAnyOrder(ROTA, outra);
    }

    @Test
    void alunoSemRotaDevolveListaVazia() {
        when(memberRepository.findAllByUserId(ALUNO)).thenReturn(List.of());

        assertThat(useCase.routesOf(ALUNO)).isEmpty();
    }
}
