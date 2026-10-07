package com.smartboarding.smartboarding_api.application.profile;

import com.smartboarding.smartboarding_api.domain.membership.port.in.ManageUserInstitutionsUseCase;
import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateStatus;
import com.smartboarding.smartboarding_api.domain.profile.port.in.ManageProfileUpdateUseCase;
import com.smartboarding.smartboarding_api.domain.profile.port.out.ProfileUpdateRequestRepositoryPort;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
public class ProfileUpdateUseCaseImpl implements ManageProfileUpdateUseCase {

    private final ProfileUpdateRequestRepositoryPort requestRepository;
    private final UserRepositoryPort userRepository;
    private final ManageUserInstitutionsUseCase userInstitutions;
    private final Clock clock;

    public ProfileUpdateUseCaseImpl(ProfileUpdateRequestRepositoryPort requestRepository,
                                    UserRepositoryPort userRepository,
                                    ManageUserInstitutionsUseCase userInstitutions,
                                    Clock clock) {
        this.requestRepository = requestRepository;
        this.userRepository = userRepository;
        this.userInstitutions = userInstitutions;
        this.clock = clock;
    }

    @Override
    @Transactional
    public ProfileUpdateRequest request(UUID userId, ProfileUpdateRequest pedido) {
        userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado"));

        if (pedido.isEmpty()) {
            throw new BadRequestException("EMPTY_REQUEST",
                    "Altere ao menos um campo antes de enviar.");
        }
        if (requestRepository.findPendingByUserId(userId).isPresent()) {
            throw new ConflictException("PENDING_REQUEST_EXISTS",
                    "Você já tem uma solicitação em análise.");
        }

        pedido.setUserId(userId);
        pedido.setStatus(ProfileUpdateStatus.PENDING);
        ProfileUpdateRequest saved = requestRepository.save(pedido);
        log.info("Solicitação de atualização de perfil aberta pelo usuário {}", userId);
        return saved;
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<ProfileUpdateRequest> myPending(UUID userId) {
        return requestRepository.findPendingByUserId(userId);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<ProfileUpdateRequest> myLatest(UUID userId) {
        return requestRepository.findAllByUserId(userId).stream().findFirst();
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProfileUpdateRequest> listPending() {
        return requestRepository.findAllPending();
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProfileUpdateRequest> listAll(String status) {
        var filtro = (status == null || status.isBlank())
                ? null
                : ProfileUpdateStatus.valueOf(status.toUpperCase());
        return requestRepository.findAllByStatusOrAll(filtro);
    }

    @Override
    @Transactional
    public ProfileUpdateRequest approve(UUID requestId, UUID adminId) {
        ProfileUpdateRequest pedido = pendente(requestId);
        User user = userRepository.findById(pedido.getUserId())
                .orElseThrow(() -> new NotFoundException("Usuário do pedido não existe mais"));

        if (pedido.getFullName() != null) user.setFullName(pedido.getFullName());
        if (pedido.getPhone() != null) user.setPhone(pedido.getPhone());
        if (pedido.getStructuredAddress() != null) user.setAddress(pedido.getStructuredAddress());
        if (pedido.getCourse() != null) user.setCourse(pedido.getCourse());
        if (pedido.getInstitutionId() != null
                && !userInstitutions.institutionsOf(user.getId()).contains(pedido.getInstitutionId())) {
            userInstitutions.add(user.getId(), pedido.getInstitutionId());
        }
        if (pedido.getBirthDate() != null) user.setBirthDate(pedido.getBirthDate());
        userRepository.save(user);

        pedido.setStatus(ProfileUpdateStatus.APPROVED);
        pedido.setReviewedBy(adminId);
        pedido.setReviewedAt(LocalDateTime.now(clock));
        log.info("Perfil do usuário {} atualizado por aprovação do admin {}",
                user.getId(), adminId);
        return requestRepository.save(pedido);
    }

    @Override
    @Transactional
    public ProfileUpdateRequest reject(UUID requestId, String reason, UUID adminId) {
        if (reason == null || reason.isBlank()) {
            throw new BadRequestException("REASON_REQUIRED",
                    "Explique o motivo — é o que o aluno vê pra saber o que corrigir.");
        }
        ProfileUpdateRequest pedido = pendente(requestId);
        pedido.setStatus(ProfileUpdateStatus.REJECTED);
        pedido.setRejectionReason(reason.trim());
        pedido.setReviewedBy(adminId);
        pedido.setReviewedAt(LocalDateTime.now(clock));
        return requestRepository.save(pedido);
    }

    private ProfileUpdateRequest pendente(UUID requestId) {
        ProfileUpdateRequest pedido = requestRepository.findById(requestId)
                .orElseThrow(() -> new NotFoundException("Solicitação não encontrada"));
        if (!pedido.isPending()) {
            throw new ConflictException("ALREADY_REVIEWED",
                    "Essa solicitação já foi analisada.");
        }
        return pedido;
    }
}
