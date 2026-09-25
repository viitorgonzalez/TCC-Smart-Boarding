package com.smartboarding.smartboarding_api.domain.route.port.out;

import java.util.List;
import java.util.Optional;

/// Quanto tempo o ônibus leva entre pontos consecutivos, pelas ruas.
///
/// Porta, e não chamada direta ao OSRM: o serviço público usado hoje é o de
/// demonstração do projeto, sem SLA e com limite de uso, e vai ser trocado
/// quando houver deploy. O use case não pode saber disso.
public interface RoutePlannerPort {

    /// Duração de cada trecho entre pontos consecutivos, em segundos.
    /// `points` com N pontos devolve N-1 durações.
    ///
    /// [Optional#empty()] quando o serviço não responde -- e não uma lista de
    /// zeros: "não sei" e "leva zero segundo" são coisas diferentes, e
    /// confundi-las mostraria ao aluno um tempo inventado.
    Optional<List<Double>> legDurationsSeconds(List<GeoPoint> points);
}
