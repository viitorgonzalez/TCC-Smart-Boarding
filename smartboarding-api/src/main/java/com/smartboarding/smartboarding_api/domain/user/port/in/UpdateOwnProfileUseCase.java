package com.smartboarding.smartboarding_api.domain.user.port.in;

import java.util.UUID;

/// O que o aluno muda sozinho, sem fila de aprovação.
///
/// Telefone e curso descrevem a pessoa ou a alcançam; nenhum dos dois decide em
/// qual transporte ela entra. Quem decide isso -- nome e instituição -- segue
/// passando pelo admin.
///
/// A separação existe porque a entrada na lista passou a exigir perfil
/// completo: sem ela, "complete seu perfil pra entrar na lista" viraria uma
/// parede que a própria pessoa não consegue destravar, e ela perderia a viagem
/// de amanhã esperando alguém aprovar um telefone.
public interface UpdateOwnProfileUseCase {
    /// Campo nulo = não foi pedida mudança nele. String em branco = pedido pra
    /// limpar -- é como o formulário diz "apaguei este campo".
    void update(UUID userId, String phone, String course);
}
