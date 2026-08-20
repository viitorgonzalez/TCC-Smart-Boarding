package com.smartboarding.smartboarding_api.infrastructure.persistence.registration;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;
import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationStatus;
import com.smartboarding.smartboarding_api.domain.registration.port.out.RegistrationRequestRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class RegistrationRequestRepositoryAdapter implements RegistrationRequestRepositoryPort {

    private final RegistrationRequestJpaRepository jpa;

    public RegistrationRequestRepositoryAdapter(RegistrationRequestJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public RegistrationRequest save(RegistrationRequest request) { return jpa.save(request); }
    @Override public Optional<RegistrationRequest> findByToken(String token) { return jpa.findByToken(token); }
    @Override public Optional<RegistrationRequest> findById(UUID id) { return jpa.findById(id); }
    @Override public List<RegistrationRequest> findAllByStatus(RegistrationStatus status) { return jpa.findAllByStatus(status); }
}
