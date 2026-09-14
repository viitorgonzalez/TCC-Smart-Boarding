package com.smartboarding.smartboarding_api.application.passwordreset;

/// Texto do e-mail fora do use case: muda por motivo diferente do que muda a regra.
final class PasswordResetEmails {

    static final String SUBJECT = "Redefinição de senha Smart Boarding";

    private PasswordResetEmails() {}

    static String code(String code, long ttlMinutes) {
        return "<p>Seu código para redefinir a senha: <strong>" + code + "</strong></p>"
                + "<p>Válido por " + ttlMinutes + " minutos.</p>"
                + "<p>Se não foi você que pediu, ignore este e-mail: a senha atual continua valendo.</p>";
    }
}
