package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;

import java.util.List;
import java.util.UUID;

public interface ManageUserStatusUseCase {
    User setActive(UUID userId, boolean active, UUID adminId);

    User setRole(UUID userId, Role role, UUID adminId);

    List<UserStatusLog> history(UUID userId);
}
