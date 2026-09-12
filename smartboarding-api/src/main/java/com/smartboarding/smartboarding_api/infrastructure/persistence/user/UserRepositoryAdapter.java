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

    @Override public Optional<User> findByEmail(String email) { return jpa.findByEmail(email); }
    @Override public Optional<User> findById(UUID id) { return jpa.findById(id); }
    @Override public List<User> findAll() { return jpa.findAll(); }
    @Override public User save(User user) { return jpa.save(user); }
    @Override public boolean existsByEmail(String email) { return jpa.existsByEmail(email); }
    @Override public long countActiveStudents() { return jpa.countActiveStudents(); }
    @Override public long countByInstitutionId(UUID institutionId) { return jpa.countByInstitutionId(institutionId); }
    @Override public java.util.List<User> findByRouteId(UUID routeId) { return jpa.findByRouteId(routeId); }

    @Override
    public java.util.Optional<com.smartboarding.smartboarding_api.domain.user.entity.User>
            findByGoogleId(String googleId) {
        return jpa.findByGoogleId(googleId);
    }
}
