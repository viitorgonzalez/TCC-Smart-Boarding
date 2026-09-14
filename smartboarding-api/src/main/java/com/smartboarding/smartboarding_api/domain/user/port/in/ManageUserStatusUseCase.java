package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;

import java.util.List;
import java.util.UUID;

public interface ManageUserStatusUseCase {
    /// Toda mudança deixa registro de quem fez e quando — é por isso que
    /// [adminId] viaja no caminho, mesmo sendo anulável na tabela.
    User setActive(UUID userId, boolean active, UUID adminId);

    /// Concede ou retira o papel administrativo de uma conta que ja existe.
    /// Conta nao e criada aqui -- ela e do usuario; o que se concede e o papel.
    User setRole(UUID userId, Role role, UUID adminId);

    List<UserStatusLog> history(UUID userId);
}
