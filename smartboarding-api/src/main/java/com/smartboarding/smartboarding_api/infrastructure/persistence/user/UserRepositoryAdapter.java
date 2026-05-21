package com.smartboarding.smartboarding_api.infrastructure.persistence.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class UserRepositoryAdapter implements UserRepositoryPort {

    private final UserJpaRepository jpa;

    public UserRepositoryAdapter(UserJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Optional<User> findByEmail(String email) {
        return jpa.findByEmail(email).map(UserMapper::toDomain);
    }

    @Override
    public Optional<User> findById(UUID id) {
        return jpa.findById(id).map(UserMapper::toDomain);
    }

    @Override
    public List<User> findAll() {
        return jpa.findAll().stream().map(UserMapper::toDomain).toList();
    }

    @Override
    public User save(User user) {
        return UserMapper.toDomain(jpa.save(UserMapper.toJpa(user)));
    }

    @Override
    public boolean existsByEmail(String email) {
        return jpa.existsByEmail(email);
    }
}
