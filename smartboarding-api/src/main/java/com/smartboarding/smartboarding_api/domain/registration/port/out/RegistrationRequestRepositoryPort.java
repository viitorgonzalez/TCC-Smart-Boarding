package com.smartboarding.smartboarding_api.domain.registration.port.out;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RegistrationRequestRepositoryPort {
    RegistrationRequest save(RegistrationRequest request);
    Optional<RegistrationRequest> findByToken(String token);
    Optional<RegistrationRequest> findById(UUID id);
    Optional<RegistrationRequest> findTopByEmailOrderByCreatedAtDesc(String email);
    List<RegistrationRequest> findAllByStatus(RegistrationStatus status);
}
