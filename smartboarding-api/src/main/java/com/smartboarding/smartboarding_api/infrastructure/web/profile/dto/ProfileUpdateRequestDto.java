package com.smartboarding.smartboarding_api.infrastructure.web.profile.dto;

import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.UUID;

/// Campo ausente = não foi pedida mudança nele. Por isso nada é @NotBlank: o
/// aluno manda só o que quer mudar.
///
/// Sobrou pouco: telefone, curso e endereço saíram pra caminhos diretos, e o
/// que resta aqui é o que decide em qual transporte a pessoa entra. O nome
/// identifica na chamada do motorista; a instituição decide em que contagem
/// ela cai.
public record ProfileUpdateRequestDto(
        @Size(max = 150) String fullName,
        UUID institutionId,
        LocalDate birthDate
) {}
