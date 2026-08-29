package com.smartboarding.smartboarding_api.application.registration;

/// Corpos dos e-mails do fluxo de convite. Separado do use case pra manter a
/// regra de negócio legível — e porque texto de e-mail muda por motivo
/// diferente do que muda a regra.
final class RegistrationEmails {

    static final String VERIFICATION_SUBJECT = "Código de verificação Smart Boarding";
    static final String REJECTED_SUBJECT = "Cadastro Smart Boarding não aprovado";

    private RegistrationEmails() {}

    static String verificationCode(String code, long ttlMinutes) {
        return "<p>Seu código de verificação: <strong>" + code + "</strong></p>"
                + "<p>Válido por " + ttlMinutes + " minutos.</p>";
    }

    static String rejected(String reason) {
        return "<p>Seu cadastro não foi aprovado.</p>"
                + "<p>Motivo: <strong>" + escapeHtml(reason) + "</strong></p>"
                + "<p>Você pode corrigir os dados e enviar de novo: peça um novo código "
                + "de verificação no app.</p>";
    }

    /// O motivo é texto livre do admin indo pra dentro de um corpo HTML.
    private static String escapeHtml(String raw) {
        return raw.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
