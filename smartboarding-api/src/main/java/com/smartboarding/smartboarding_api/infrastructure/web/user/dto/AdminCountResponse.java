package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

/// Só o número. A ficha do usuário precisa saber se está olhando o último admin
/// pra desabilitar "rebaixar" antes do toque; devolver a listagem completa pra
/// isso levaria e-mail, telefone, endereço e nascimento da base inteira no fio a
/// cada vez que a folha abre.
public record AdminCountResponse(long count) {}
