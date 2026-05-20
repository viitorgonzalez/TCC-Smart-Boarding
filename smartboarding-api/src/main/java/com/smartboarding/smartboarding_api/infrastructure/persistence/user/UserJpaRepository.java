package com.smartboarding.smartboarding_api.infrastructure.persistence.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserJpaRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
