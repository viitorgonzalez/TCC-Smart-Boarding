package com.smartboarding.smartboarding_api.application.list;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteMember;
import com.smartboarding.smartboarding_api.domain.membership.port.out.RouteMemberRepositoryPort;
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
import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
public class ListUseCaseImpl implements FindListUseCase, AddEntryUseCase, RemoveEntryUseCase {

    private final DailyListRepositoryPort dailyListRepository;
    private final ListEntryRepositoryPort listEntryRepository;
    private final UserRepositoryPort userRepository;
    private final SendToUserUseCase sendToUserUseCase;
    private final RouteMemberRepositoryPort routeMemberRepository;
    private final Clock clock;

    public ListUseCaseImpl(DailyListRepositoryPort dailyListRepository,
                           ListEntryRepositoryPort listEntryRepository,
                           UserRepositoryPort userRepository,
                           SendToUserUseCase sendToUserUseCase,
                           RouteMemberRepositoryPort routeMemberRepository,
                           Clock clock) {
        this.dailyListRepository = dailyListRepository;
        this.listEntryRepository = listEntryRepository;
        this.userRepository = userRepository;
        this.sendToUserUseCase = sendToUserUseCase;
        this.routeMemberRepository = routeMemberRepository;
        this.clock = clock;
    }

    // Filtrar a listagem não basta: sem esta checagem a API continuaria aceitando
    // um POST direto na lista de outra rota.
    private void assertBelongsToRoute(User user, DailyList list) {
        if (user.getRole() != Role.STUDENT) {
            return;
        }
        if (!routesOf(user.getId()).contains(list.getRoute().getId())) {
            throw new BadRequestException("ROUTE_NOT_ALLOWED",
                    "Você não faz parte da rota dessa lista.");
        }
    }

    // O status só vira CLOSED quando o agendador roda. Com a API fora do ar no
    // horário, a lista seguiria OPEN aceitando inscrição — por isso a checagem é
    // contra o relógio, não contra a flag (RN2/RN18).
    private void assertAcceptingChanges(DailyList list, String action) {
        if (list.getStatus() != ListStatus.OPEN) {
            throw new BadRequestException("LIST_CLOSED", action);
        }
        if (!list.getDate().isEqual(LocalDate.now(clock))) {
            throw new BadRequestException("LIST_NOT_TODAY",
                    "Só é possível mexer na lista do dia de hoje.");
        }
        LocalTime closeTime = list.getRoute().getCloseTime();
        if (!LocalTime.now(clock).isBefore(closeTime)) {
            throw new BadRequestException("LIST_CLOSED", action);
        }
    }

    @Override
    public List<DailyList> findTodayLists(UUID requesterId) {
        // Todas as do dia, não só as abertas: filtrar por OPEN fazia a lista sumir
        // da tela no instante do fechamento, inclusive pra quem estava inscrito.
        List<DailyList> today = dailyListRepository.findAllByDate(LocalDate.now(clock));

        User requester = userRepository.findById(requesterId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado com ID: " + requesterId));
        if (requester.getRole() != Role.STUDENT) {
            return today;
        }

        Set<UUID> routes = routesOf(requesterId);
        if (routes.isEmpty()) {
            // Conta nova sem código usado ainda. Devolver tudo deixaria o aluno
            // entrar em transporte que não é o dele.
            return List.of();
        }
        return today.stream()
                .filter(list -> routes.contains(list.getRoute().getId()))
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<ListEntry> findMyAttendance(UUID userId, int months) {
        return listEntryRepository.findAttendanceSince(
                userId, LocalDate.now(clock).minusMonths(months));
    }

    /// As rotas do aluno vêm do vínculo criado ao usar o código da rota. Até a
    /// V22 isso era derivado da instituição (RN15); agora a instituição é só
    /// informação, e o aluno pode estar em mais de uma rota.
    private Set<UUID> routesOf(UUID userId) {
        return routeMemberRepository.findAllByUserId(userId).stream()
                .map(RouteMember::getRouteId)
                .collect(Collectors.toSet());
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
        assertAcceptingChanges(dailyList, "Esta lista já está fechada e não aceita inscrições.");

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Usuário não encontrado com ID: " + userId));
        assertBelongsToRoute(user, dailyList);

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
        assertAcceptingChanges(dailyList, "Não é possível sair de uma lista fechada.");

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
