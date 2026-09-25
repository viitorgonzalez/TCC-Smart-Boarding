package com.smartboarding.smartboarding_api.domain.route.port.out;

/// Um ponto no mapa, no vocabulário do domínio.
///
/// Existe pra porta não falar em `Stop`: quem calcula trajeto não precisa
/// saber o que é uma parada, e amarrar os dois faria o adapter HTTP depender
/// de uma entidade JPA.
public record GeoPoint(double latitude, double longitude) {}
