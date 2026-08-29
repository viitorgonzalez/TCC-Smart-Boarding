package com.smartboarding.smartboarding_api.infrastructure.persistence.registration;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RegistrationRequestJpaRepository extends JpaRepository<RegistrationRequest, UUID> {
    Optional<RegistrationRequest> findByToken(String token);
    List<RegistrationRequest> findAllByStatus(RegistrationStatus status);
    Optional<RegistrationRequest> findTopByEmailOrderByCreatedAtDesc(String email);
}
