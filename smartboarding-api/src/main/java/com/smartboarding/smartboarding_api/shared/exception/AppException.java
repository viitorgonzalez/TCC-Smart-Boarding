package com.smartboarding.smartboarding_api.shared.exception;

import java.util.Map;

public abstract class AppException extends RuntimeException {

    private final String code;

    /// Dado extra que o cliente precisa pra agir, além do texto do erro.
    ///
    /// Existe porque "complete seu perfil" obriga o aluno a adivinhar qual
    /// campo falta: o erro carrega a lista, e a tela mostra o que fazer. Vazio
    /// na maioria dos erros, que se resolvem com a mensagem sozinha.
    private final Map<String, Object> details;

    protected AppException(String code, String message) {
        this(code, message, Map.of());
    }

    protected AppException(String code, String message, Map<String, Object> details) {
        super(message);
        this.code = code;
        this.details = details == null ? Map.of() : Map.copyOf(details);
    }

    public String getCode() {
        return code;
    }

    public Map<String, Object> getDetails() {
        return details;
    }
}
