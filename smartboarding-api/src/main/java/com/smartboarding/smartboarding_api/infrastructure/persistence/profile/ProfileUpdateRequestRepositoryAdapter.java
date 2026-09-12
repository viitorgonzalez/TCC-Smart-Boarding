package com.smartboarding.smartboarding_api.infrastructure.persistence.profile;

import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateStatus;
import com.smartboarding.smartboarding_api.domain.profile.port.out.ProfileUpdateRequestRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class ProfileUpdateRequestRepositoryAdapter
        implements ProfileUpdateRequestRepositoryPort {

    private final ProfileUpdateRequestJpaRepository jpa;

    public ProfileUpdateRequestRepositoryAdapter(ProfileUpdateRequestJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public ProfileUpdateRequest save(ProfileUpdateRequest r) { return jpa.save(r); }
    @Override public Optional<ProfileUpdateRequest> findById(UUID id) { return jpa.findById(id); }

    @Override
    public Optional<ProfileUpdateRequest> findPendingByUserId(UUID userId) {
        return jpa.findByUserIdAndStatus(userId, ProfileUpdateStatus.PENDING);
    }

    @Override
    public List<ProfileUpdateRequest> findAllPending() {
        // Mais antigo primeiro: a fila e ordem de chegada, senao pedido antigo
        // afunda e fica sem resposta.
        return jpa.findAllByStatusOrderByCreatedAtAsc(ProfileUpdateStatus.PENDING);
    }

    @Override
    public List<ProfileUpdateRequest> findAllByUserId(UUID userId) {
        return jpa.findAllByUserIdOrderByCreatedAtDesc(userId);
    }
}
