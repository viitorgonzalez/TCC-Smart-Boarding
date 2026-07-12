package com.smartboarding.smartboarding_api.domain.list.entity;

/**
 * Direção do transporte escolhida pelo aluno ao entrar na lista.
 * ROUND_TRIP = ida e volta (padrão), TO_CAMPUS = só ida, FROM_CAMPUS = só volta.
 */
public enum TripType {
    ROUND_TRIP, TO_CAMPUS, FROM_CAMPUS
}
