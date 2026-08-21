package com.smartboarding.smartboarding_api.infrastructure.web.registration;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class RegistrationFallbackController {

    // Só existe pro caso "App Link clicado sem o app instalado" (RN13) — quando
    // o app está instalado, o SO nem chega a bater aqui, abre a tela direto.
    @GetMapping(value = "/register/{token}", produces = MediaType.TEXT_HTML_VALUE)
    @ResponseBody
    public String fallback(@PathVariable String token) {
        return """
                <!DOCTYPE html>
                <html lang="pt-BR">
                <head><meta charset="UTF-8"><title>Smart Boarding — Cadastro</title></head>
                <body style="font-family: sans-serif; text-align: center; padding: 48px 24px;">
                    <h1>Smart Boarding</h1>
                    <p>Pra completar seu cadastro, instale o app Smart Boarding e abra este link de novo.</p>
                </body>
                </html>
                """;
    }
}
