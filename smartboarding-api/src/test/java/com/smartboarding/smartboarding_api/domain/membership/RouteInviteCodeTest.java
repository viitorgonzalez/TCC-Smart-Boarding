package com.smartboarding.smartboarding_api.domain.membership;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class RouteInviteCodeTest {

    private static final LocalDateTime AGORA = LocalDateTime.of(2026, 9, 11, 10, 0);

    private RouteInviteCode code(LocalDateTime expiresAt, LocalDateTime revokedAt) {
        return RouteInviteCode.builder()
                .id(UUID.randomUUID()).routeId(UUID.randomUUID())
                .code("RU-7K2M").expiresAt(expiresAt).revokedAt(revokedAt)
                .build();
    }

    @Test
    void codigoDentroDoPrazoEUsavel() {
        var c = code(AGORA.plusDays(30), null);

        assertThat(c.isUsable(AGORA)).isTrue();
        assertThat(c.isExpired(AGORA)).isFalse();
        assertThat(c.isRevoked()).isFalse();
    }

    @Test
    void codigoVencidoNaoServeMais() {
        var c = code(AGORA.minusMinutes(1), null);

        assertThat(c.isUsable(AGORA)).isFalse();
        assertThat(c.isExpired(AGORA)).isTrue();
    }

    /// O instante exato da expiração já conta como vencido: deixar passar daria
    /// uma janela de ambiguidade bem no limite.
    @Test
    void oInstanteDaExpiracaoJaContaComoVencido() {
        var c = code(AGORA, null);

        assertThat(c.isExpired(AGORA)).isTrue();
        assertThat(c.isUsable(AGORA)).isFalse();
    }

    /// Revogar vale na hora, sem esperar o prazo — é o botão de pânico do admin
    /// quando o código vaza.
    @Test
    void codigoRevogadoNaoServeMesmoDentroDoPrazo() {
        var c = code(AGORA.plusDays(30), AGORA.minusHours(1));

        assertThat(c.isUsable(AGORA)).isFalse();
        assertThat(c.isRevoked()).isTrue();
        assertThat(c.isExpired(AGORA)).isFalse();
    }

    /// Revogado e expirado são estados distintos pro admin ver, mas valem o
    /// mesmo na hora de usar.
    @Test
    void revogadoEExpiradoSaoDistintosMasAmbosBloqueiam() {
        var revogado = code(AGORA.plusDays(30), AGORA.minusHours(1));
        var vencido = code(AGORA.minusDays(1), null);

        assertThat(revogado.isUsable(AGORA)).isFalse();
        assertThat(vencido.isUsable(AGORA)).isFalse();
        assertThat(revogado.isExpired(AGORA)).isNotEqualTo(vencido.isExpired(AGORA));
    }
}
