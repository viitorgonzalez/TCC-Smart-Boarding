package com.smartboarding.smartboarding_api.infrastructure.web.list.dto;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;

import java.time.LocalDateTime;
import java.util.UUID;

/// Inscrito da lista do dia. O e-mail só vai para o admin.
///
/// A lista é compartilhada -- o aluno vê quem embarca junto, e isso é proposital.
/// Mas GET /api/lists/{id}/entries é `authenticated()`, não admin: mandar o
/// e-mail de todo mundo transformava a lista num diretório de contatos da turma,
/// bastando chamar a API direto. A tela do aluno nunca exibiu o campo, só que
/// não exibir não protege nada -- o dado ia no fio do mesmo jeito.
public record EntryResponse(UUID id, UUID userId, String fullName, String email, String institutionName,
                            TripType tripType, LocalDateTime createdAt) {

    public static EntryResponse from(ListEntry entry, String institutionName, boolean includeEmail) {
        return new EntryResponse(
                entry.getId(),
                entry.getUser().getId(),
                entry.getUser().getFullName(),
                includeEmail ? entry.getUser().getEmail() : null,
                institutionName,
                entry.getTripType(),
                entry.getCreatedAt()
        );
    }
}
