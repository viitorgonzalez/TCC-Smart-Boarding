package com.smartboarding.smartboarding_api.application.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import com.smartboarding.smartboarding_api.domain.list.port.in.AddEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.FindListUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.in.RemoveEntryUseCase;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.SendToUserUseCase;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
public class ListUseCaseImpl implements FindListUseCase, AddEntryUseCase, RemoveEntryUseCase {

    private final DailyListRepositoryPort dailyListRepository;
    private final ListEntryRepositoryPort listEntryRepository;
    private final UserRepositoryPort userRepository;
    private final SendToUserUseCase sendToUserUseCase;

    public ListUseCaseImpl(DailyListRepositoryPort dailyListRepository,
                           ListEntryRepositoryPort listEntryRepository,
                           UserRepositoryPort userRepository,
                           SendToUserUseCase sendToUserUseCase) {
        this.dailyListRepository = dailyListRepository;
        this.listEntryRepository = listEntryRepository;
        this.userRepository = userRepository;
        this.sendToUserUseCase = sendToUserUseCase;
    }

    @Override
    public List<DailyList> findTodayLists() {
        return dailyListRepository.findAllByDateAndStatus(LocalDate.now(), ListStatus.OPEN);
    }

    @Override
    public DailyList findById(UUID id) {
        return dailyListRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Lista não encontrada com ID: " + id));
    }

    @Override
    public List<ListEntry> findEntriesByList(UUID listId) {
        findById(listId);
        return listEntryRepository.findAllByDailyListIdAndIsActiveTrue(listId);
    }

    @Override
    @Transactional
    public ListEntry add(UUID userId, UUID listId, TripType tripType) {
        DailyList dailyList = findById(listId);

        if (dailyList.getStatus() != ListStatus.OPEN) {
            throw new BadRequestException("LIST_CLOSED", "Esta lista já está fechada e não aceita inscrições.");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado com ID: " + userId));

        Optional<ListEntry> existing = listEntryRepository.findByUserIdAndDailyListId(userId, listId);

        if (existing.isPresent()) {
            // Já existe: reativa (se saiu antes) e/ou atualiza a direção.
            // Direção é editável enquanto a lista estiver aberta.
            ListEntry entry = existing.get();
            boolean wasInactive = !entry.isActive();
            entry.setActive(true);
            entry.setTripType(tripType);
            ListEntry saved = listEntryRepository.save(entry);
            if (wasInactive) {
                notifyEnrollment(userId, dailyList);
            }
            return saved;
        }

        ListEntry entry = ListEntry.builder()
                .user(user)
                .dailyList(dailyList)
                .isActive(true)
                .tripType(tripType)
                .build();

        ListEntry saved = listEntryRepository.save(entry);
        notifyEnrollment(userId, dailyList);
        log.info("Usuário {} inscrito na lista {} ({})", userId, listId, tripType);
        return saved;
    }

    @Override
    @Transactional
    public void remove(UUID userId, UUID listId) {
        DailyList dailyList = findById(listId);

        if (dailyList.getStatus() != ListStatus.OPEN) {
            throw new BadRequestException("LIST_CLOSED", "Não é possível sair de uma lista fechada.");
        }

        ListEntry entry = listEntryRepository.findByUserIdAndDailyListId(userId, listId)
                .filter(ListEntry::isActive)
                .orElseThrow(() -> new NotFoundException("Inscrição não encontrada para este usuário e lista."));

        entry.setActive(false);
        listEntryRepository.save(entry);
        log.info("Usuário {} removido da lista {}", userId, listId);
    }

    private void notifyEnrollment(UUID userId, DailyList dailyList) {
        try {
            sendToUserUseCase.execute(userId,
                    "Inscrição confirmada",
                    "Você está inscrito na lista de " + dailyList.getRoute().getName() +
                            " para hoje (" + dailyList.getDate() + ").");
        } catch (Exception e) {
            log.warn("Falha ao enviar notificação de inscrição para usuário {}: {}", userId, e.getMessage());
        }
    }
}
