package com.smartboarding.smartboarding_api.infrastructure.web.list.dto;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;

import java.time.LocalDate;

/// Um dia de presença do aluno. Enxuto de propósito: o histórico dele é um log
/// de comparecimento, não o relatório operacional que o admin consulta.
public record AttendanceResponse(LocalDate date, String routeName, TripType tripType) {
    public static AttendanceResponse from(ListEntry entry) {
        return new AttendanceResponse(
                entry.getDailyList().getDate(),
                entry.getDailyList().getRoute().getName(),
                entry.getTripType());
    }
}
