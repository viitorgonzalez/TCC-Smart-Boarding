package com.smartboarding.smartboarding_api.domain.route.port.in;

import java.util.UUID;

/// Recalcula quanto leva do início do trajeto até cada parada.
///
/// No backend e não no app: o número é estável (só muda quando as paradas
/// mudam), e calcular no aparelho faria cada aluno que abre a lista bater no
/// OSRM pra chegar ao mesmo resultado. O serviço público tem limite de uso --
/// uma chamada por mudança de parada é sustentável; uma por abertura de tela
/// não é.
public interface RouteTimingUseCase {
    void recalculate(UUID routeId);

    /// Calcula só se ainda não há tempo nenhum na rota.
    ///
    /// Existe porque a V33 nasceu com a coluna vazia: rota criada ANTES dela
    /// só ganharia tempo se alguém mexesse numa parada, e até lá o aluno
    /// abriria o acompanhamento sem nenhum "faltam X min". Chamado ao iniciar
    /// o trajeto -- uma vez por dia por rota, que é bem menos que uma
    /// varredura no boot e chega no momento em que o número passa a importar.
    void recalculateIfMissing(UUID routeId);
}
