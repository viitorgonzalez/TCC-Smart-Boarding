package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;

import java.util.List;
import java.util.UUID;

public interface ManageUserStatusUseCase {
    /// Toda mudança deixa registro de quem fez e quando — é por isso que
    /// [adminId] viaja no caminho, mesmo sendo anulável na tabela.
    User setActive(UUID userId, boolean active, UUID adminId);

    List<UserStatusLog> history(UUID userId);
}
