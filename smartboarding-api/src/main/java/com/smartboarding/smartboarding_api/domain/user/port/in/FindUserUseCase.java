package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.UUID;

public interface FindUserUseCase {
    List<User> findAll();

    Page<User> findPage(UUID routeId, Pageable pageable);

    List<User> findByRoute(UUID routeId);
    User findById(UUID id);

    long countAdmins();
}
