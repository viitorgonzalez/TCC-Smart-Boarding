package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/// Perfil breve pro card do admin. Não carrega e-mail, endereço, telefone nem
/// data de nascimento: o card é pra conferência rápida, e o que não trafega não
/// vaza.
public record StudentProfileResponse(
        UUID id,
        String fullName,
        String course,
        String institution,
        boolean isActive,
        List<LocalDate> recentAttendance,
        List<StatusChange> statusHistory
) {
    public record StatusChange(String action, String adminName, LocalDateTime at) {}
}
