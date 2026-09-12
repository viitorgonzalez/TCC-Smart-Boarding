package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/// Cadastro do próprio aluno: nome, e-mail e senha, nada mais.
///
/// Instituição, curso e contato ficaram no perfil, que é pré-requisito pra
/// entrar numa rota. Pedir tudo aqui faria o formulário de entrada carregar
/// dado que só importa depois — e quem desiste no meio não cria conta nenhuma.
///
/// Não tem campo `role`: quem se cadastra aqui é sempre STUDENT, e aceitar o
/// papel do cliente deixaria qualquer um criar admin por um endpoint público.
public record SignupRequest(
        @NotBlank(message = "informe seu nome") @Size(max = 150) String fullName,
        @NotBlank(message = "informe seu e-mail") @Email(message = "e-mail inválido")
        @Size(max = 100) String email,
        /// RN10: mínimo de 6 caracteres.
        @NotBlank(message = "informe uma senha") @Size(min = 6, max = 100) String password
) {}
