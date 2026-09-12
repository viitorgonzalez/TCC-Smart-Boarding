package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

/// [email] vai junto de propósito: quem entra pelo Google nunca digita o
/// e-mail, então o app não teria de onde tirá-lo -- e sem ele a home ficava
/// carregando pra sempre, esperando um usuário que nunca chegava.
public record LoginResponse(String token, String fullName, String role, String email) {

    public static LoginResponse from(com.smartboarding.smartboarding_api.application.user.AuthToken token) {
        return new LoginResponse(token.token(), token.fullName(), token.role(), token.email());
    }
}
