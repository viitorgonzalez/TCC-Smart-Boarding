package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.UUID;

/// Cadastro do próprio aluno. Não tem campo `role`: quem se cadastra aqui é
/// sempre STUDENT, e aceitar o papel do cliente deixaria qualquer um criar admin.
///
/// [institutionId] é opcional e só informativo — ela alimenta a contagem por
/// instituição na lista. A rota vem do código, não daqui.
public record SignupRequest(
        @NotBlank(message = "informe seu nome") @Size(max = 150) String fullName,
        @NotBlank(message = "informe seu e-mail") @Email(message = "e-mail inválido")
        @Size(max = 100) String email,
        /// RN10: mínimo de 6 caracteres.
        @NotBlank(message = "informe uma senha") @Size(min = 6, max = 100) String password,
        UUID institutionId,
        @Size(max = 100) String course,
        @Size(max = 20) String phone,
        LocalDate birthDate
) {}
