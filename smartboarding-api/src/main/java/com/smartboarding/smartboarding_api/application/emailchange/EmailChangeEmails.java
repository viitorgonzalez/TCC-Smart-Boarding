package com.smartboarding.smartboarding_api.application.emailchange;

final class EmailChangeEmails {

    static final String CODE_SUBJECT = "Confirme seu novo e-mail Smart Boarding";
    static final String CHANGED_SUBJECT = "Seu e-mail Smart Boarding foi alterado";

    private EmailChangeEmails() {}

    static String code(String code, long ttlMinutes) {
        return "<p>Seu código para confirmar este e-mail como o novo endereço da sua conta: "
                + "<strong>" + code + "</strong></p>"
                + "<p>Válido por " + ttlMinutes + " minutos.</p>"
                + "<p>Se não foi você que pediu, ignore este e-mail: nada muda na sua conta.</p>";
    }

    static String changed(String newEmail) {
        return "<p>O e-mail da sua conta Smart Boarding foi alterado para <strong>" + newEmail
                + "</strong>.</p>"
                + "<p>Se foi você, pode ignorar este aviso. Se não foi, fale com o administrador "
                + "o quanto antes — alguém pode ter acesso à sua conta.</p>";
    }
}
