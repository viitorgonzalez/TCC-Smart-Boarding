package com.smartboarding.smartboarding_api.domain.user.entity;

/// O que um admin fez com uma conta. Papel entra aqui junto de ativacao porque
/// a pergunta que a auditoria responde e a mesma: o que mudou nesta conta, por
/// quem e quando.
public enum UserStatusAction {
    ACTIVATED, DEACTIVATED, PROMOTED, DEMOTED
}
