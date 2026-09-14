package com.smartboarding.smartboarding_api.domain.trip.entity;

/// Perna do trajeto. A volta refaz as mesmas paradas na ordem inversa, por isso
/// o checkpoint precisa saber de qual perna é — sem isso a segunda visita à
/// mesma parada colidiria com a primeira.
public enum TripLeg {
    OUTBOUND, RETURN
}
