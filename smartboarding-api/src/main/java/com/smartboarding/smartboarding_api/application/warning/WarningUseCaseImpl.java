package com.smartboarding.smartboarding_api.application.warning;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.SendToUserUseCase;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;
import com.smartboarding.smartboarding_api.domain.warning.port.in.EnrollByAdminUseCase;
import com.smartboarding.smartboarding_api.domain.warning.port.in.ManageWarningUseCase;
import com.smartboarding.smartboarding_api.domain.warning.port.out.WarningRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
public class WarningUseCaseImpl implements ManageWarningUseCase, EnrollByAdminUseCase {

    private static final String DEFAULT_REASON =
            "Inscrição feita pelo administrador fora do horário da lista.";

    private final WarningRepositoryPort warningRepository;
    private final DailyListRepositoryPort dailyListRepository;
    private final ListEntryRepositoryPort listEntryRepository;
    private final UserRepositoryPort userRepository;
    private final SendToUserUseCase sendToUserUseCase;

    public WarningUseCaseImpl(WarningRepositoryPort warningRepository,
                              DailyListRepositoryPort dailyListRepository,
                              ListEntryRepositoryPort listEntryRepository,
                              UserRepositoryPort userRepository,
                              SendToUserUseCase sendToUserUseCase) {
        this.warningRepository = warningRepository;
        this.dailyListRepository = dailyListRepository;
        this.listEntryRepository = listEntryRepository;
        this.userRepository = userRepository;
        this.sendToUserUseCase = sendToUserUseCase;
    }

    @Override
    public List<Warning> list(UUID userId) {
        return userId == null ? warningRepository.findAll() : warningRepository.findAllByUserId(userId);
    }

    @Override
    @Transactional
    public void delete(UUID id) {
        warningRepository.deleteById(id);
    }

    // Sem assertAcceptingChanges de propósito: é justamente o caminho que
    // ignora o horário. O preço de furar a regra é a advertência.
    @Override
    @Transactional
    public ListEntry enroll(UUID listId, UUID userId, TripType tripType,
                            boolean issueWarning, String warningReason, UUID adminId) {
        DailyList list = dailyListRepository.findById(listId)
                .orElseThrow(() -> new NotFoundException("Lista não encontrada com ID: " + listId));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado com ID: " + userId));

        Optional<ListEntry> existing = listEntryRepository.findByUserIdAndDailyListId(userId, listId);
        ListEntry entry = existing.orElseGet(() -> ListEntry.builder()
                .user(user)
                .dailyList(list)
                .build());
        entry.setActive(true);
        entry.setTripType(tripType);
        ListEntry saved = listEntryRepository.save(entry);

        if (issueWarning) {
            String reason = warningReason == null || warningReason.isBlank()
                    ? DEFAULT_REASON
                    : warningReason.trim();
            warningRepository.save(Warning.builder()
                    .user(user)
                    .dailyList(list)
                    .reason(reason)
                    .issuedBy(adminId == null ? null : userRepository.findById(adminId).orElse(null))
                    .build());
            notifyWarned(user, reason);
            log.info("Advertência emitida para o usuário {} na lista {}", userId, listId);
        }
        return saved;
    }

    // O aluno precisa saber que foi advertido — advertência que ele descobre
    // depois não muda o comportamento que ela existe pra corrigir.
    private void notifyWarned(User user, String reason) {
        try {
            sendToUserUseCase.execute(user.getId(), "Você recebeu uma advertência", reason);
        } catch (Exception e) {
            log.warn("Falha ao avisar o aluno {} da advertência: {}", user.getId(), e.getMessage());
        }
    }
}
