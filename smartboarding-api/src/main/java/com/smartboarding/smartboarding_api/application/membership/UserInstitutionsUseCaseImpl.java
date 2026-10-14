package com.smartboarding.smartboarding_api.application.membership;

import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.membership.entity.UserInstitution;
import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageUserInstitutionsUseCase;
import com.smartboarding.smartboarding_api.domain.membership.port.out.UserInstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class UserInstitutionsUseCaseImpl implements ManageUserInstitutionsUseCase {

    private final UserInstitutionRepositoryPort repository;
    private final InstitutionRepositoryPort institutionRepository;
    private final UserRepositoryPort userRepository;

    public UserInstitutionsUseCaseImpl(UserInstitutionRepositoryPort repository,
                                       InstitutionRepositoryPort institutionRepository,
                                       UserRepositoryPort userRepository) {
        this.repository = repository;
        this.institutionRepository = institutionRepository;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<UUID> institutionsOf(UUID userId) {
        return repository.findAllByUserId(userId).stream()
                .map(UserInstitution::getInstitutionId)
                .toList();
    }

    @Override
    @Transactional
    public void add(UUID userId, UUID institutionId) {
        institutionRepository.findById(institutionId)
                .orElseThrow(() -> new NotFoundException("Instituição não encontrada"));
        if (repository.existsByUserIdAndInstitutionId(userId, institutionId)) {
            throw new ConflictException("ALREADY_LINKED", "Você já declarou essa instituição.");
        }
        repository.save(UserInstitution.builder()
                .userId(userId).institutionId(institutionId).build());
        syncPrimary(userId);
    }

    @Override
    @Transactional
    public void remove(UUID userId, UUID institutionId) {
        repository.deleteByUserIdAndInstitutionId(userId, institutionId);
        syncPrimary(userId);
    }

    private void syncPrimary(UUID userId) {
        userRepository.findById(userId).ifPresent(user -> {
            var vinculos = repository.findAllByUserId(userId);
            UUID principal = vinculos.isEmpty() ? null : vinculos.getFirst().getInstitutionId();
            boolean atualAindaVale = user.getInstitutionId() != null
                    && vinculos.stream().anyMatch(v -> v.getInstitutionId().equals(user.getInstitutionId()));
            if (!atualAindaVale) {
                user.setInstitutionId(principal);
                userRepository.save(user);
            }
        });
    }
}
