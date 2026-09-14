package com.smartboarding.smartboarding_api.domain.user.port.out;

import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;

import java.util.List;
import java.util.UUID;

public interface UserStatusLogRepositoryPort {
    UserStatusLog save(UserStatusLog log);

    List<UserStatusLog> findAllByUserId(UUID userId);
}
