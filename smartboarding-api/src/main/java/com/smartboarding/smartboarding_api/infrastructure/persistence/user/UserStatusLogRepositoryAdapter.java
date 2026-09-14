package com.smartboarding.smartboarding_api.infrastructure.persistence.user;

import com.smartboarding.smartboarding_api.domain.user.entity.UserStatusLog;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserStatusLogRepositoryPort;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
public class UserStatusLogRepositoryAdapter implements UserStatusLogRepositoryPort {

    private final UserStatusLogJpaRepository jpaRepository;

    public UserStatusLogRepositoryAdapter(UserStatusLogJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public UserStatusLog save(UserStatusLog log) {
        return jpaRepository.save(log);
    }

    @Override
    public List<UserStatusLog> findAllByUserId(UUID userId) {
        return jpaRepository.findAllByUserIdOrderByCreatedAtDesc(userId);
    }
}
