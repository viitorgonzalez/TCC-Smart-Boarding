package com.smartboarding.smartboarding_api.domain.user.port.out;

import com.smartboarding.smartboarding_api.domain.user.entity.User;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepositoryPort {
    Optional<User> findByEmail(String email);
    Optional<User> findById(UUID id);
    List<User> findAll();
    User save(User user);
    boolean existsByEmail(String email);
    long countActiveStudents();
    long countByInstitutionId(UUID institutionId);
    List<User> findByRouteId(UUID routeId);
}
