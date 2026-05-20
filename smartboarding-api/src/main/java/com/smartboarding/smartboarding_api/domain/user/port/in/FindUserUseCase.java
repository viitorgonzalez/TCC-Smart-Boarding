package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

import java.util.List;
import java.util.UUID;

public interface FindUserUseCase {
    List<User> findAll();
    User findById(UUID id);
}
