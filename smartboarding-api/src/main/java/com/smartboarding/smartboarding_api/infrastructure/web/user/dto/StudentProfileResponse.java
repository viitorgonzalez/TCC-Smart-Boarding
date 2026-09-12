package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/// Ficha completa do aluno pro admin. Carrega contato e nascimento porque o
/// admin precisa falar com o aluno e conferir a matrícula.
///
/// A senha (hash incluso) nunca entra aqui: ela não tem uso de leitura nenhum,
/// e o endpoint é hasRole("ADMIN") justamente porque o resto é dado pessoal.
public record StudentProfileResponse(
        UUID id,
        String fullName,
        String email,
        String phone,
        String address,
        LocalDate birthDate,
        String course,
        String institution,
        boolean isActive,
        List<LocalDate> recentAttendance,
        List<StatusChange> statusHistory
) {
    public record StatusChange(String action, String adminName, LocalDateTime at) {}
}
