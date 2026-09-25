package com.smartboarding.smartboarding_api.infrastructure.web.trip.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/// Estado do trajeto pra tela desenhar o stepper sem fazer várias chamadas.
public record TripStatusResponse(
        UUID listId,
        String routeName,
        LocalDateTime startedAt,
        /// Quando a ida acabou. Nulo = ainda na ida.
        LocalDateTime outboundFinishedAt,
        LocalDateTime finishedAt,
        /// OUTBOUND ou RETURN -- o app usa pra inverter a ordem das paradas e
        /// rotular a tela.
        String leg,
        List<TripStopStatus> stops,
        /// Onde ESTE usuário desce, e quanto falta. Nulo pro admin, que conduz
        /// o ônibus em vez de viajar nele.
        MyStop myStop
) {
    /// Só ponto principal entra aqui — parada comum não vira passo (RN23).
    public record TripStopStatus(UUID stopId, String name, int sequence, LocalDateTime reachedAt) {}

    /// A parada do aluno e o tempo até ela.
    ///
    /// Cada aluno vê um número diferente: quem desce na terceira de sete
    /// paradas não quer saber quando o ônibus chega na sétima. Por isso
    /// [stopName] vem junto — sem nomear o destino, quem vê o número do colega
    /// conclui que o app está errado.
    ///
    /// [fallback] diz que a instituição do aluno não tem parada declarada e
    /// isto aqui é a última do trajeto. Omitir seria pior: ele ficaria sem
    /// nenhuma noção de quando chega.
    public record MyStop(UUID stopId, String stopName, boolean fallback,
                         boolean alreadyReached, Integer etaMinutes) {}
}
