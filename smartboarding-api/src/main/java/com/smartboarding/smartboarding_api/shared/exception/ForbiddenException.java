package com.smartboarding.smartboarding_api.shared.exception;

/// Autenticado, mas agindo fora do que lhe cabe.
///
/// Distinto do 401: ali o problema é a sessão, aqui é o alcance. Devolver 401
/// neste caso faria o app derrubar a sessão de quem só clicou onde não devia.
public class ForbiddenException extends AppException {
    public ForbiddenException(String code, String message) {
        super(code, message);
    }
}
