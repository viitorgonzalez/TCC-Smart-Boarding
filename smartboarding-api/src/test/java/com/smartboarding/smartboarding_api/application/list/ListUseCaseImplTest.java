package com.smartboarding.smartboarding_api.application.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.notification.port.in.SendToUserUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.*;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ListUseCaseImplTest {

    private static final ZoneId ZONE = ZoneId.systemDefault();
    private static final LocalDate TODAY = LocalDate.of(2026, 8, 28);

    @Mock DailyListRepositoryPort dailyListRepository;
    @Mock ListEntryRepositoryPort listEntryRepository;
    @Mock UserRepositoryPort userRepository;
    @Mock SendToUserUseCase sendToUserUseCase;
    @Mock com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort institutionRepository;

    private Clock clockAt(LocalTime time) {
        return Clock.fixed(TODAY.atTime(time).atZone(ZONE).toInstant(), ZONE);
    }

    private ListUseCaseImpl useCaseAt(LocalTime now) {
        return new ListUseCaseImpl(dailyListRepository, listEntryRepository,
                userRepository, sendToUserUseCase, institutionRepository, clockAt(now));
    }

    private DailyList listWithCloseTime(LocalTime closeTime, LocalDate date) {
        Route route = Route.builder().id(UUID.randomUUID()).name("Rota X")
                .isActive(true).closeTime(closeTime).build();
        return DailyList.builder().id(UUID.randomUUID()).route(route)
                .date(date).status(ListStatus.OPEN).build();
    }

    private UUID stubList(DailyList list) {
        when(dailyListRepository.findById(list.getId())).thenReturn(Optional.of(list));
        // Aluno da própria rota: isola as regras de horário do guard de rota.
        var institutionId = UUID.randomUUID();
        when(userRepository.findById(any())).thenReturn(Optional.of(User.builder()
                .id(UUID.randomUUID())
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .institutionId(institutionId).build()));
        when(institutionRepository.findById(institutionId)).thenReturn(Optional.of(
                com.smartboarding.smartboarding_api.domain.institution.entity.Institution.builder()
                        .id(institutionId).routeId(list.getRoute().getId()).build()));
        when(listEntryRepository.findByUserIdAndDailyListId(any(), any())).thenReturn(Optional.empty());
        when(listEntryRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        return list.getId();
    }

    @Test
    void alunoNaoEntraEmListaDeOutraRota() {
        var list = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        when(dailyListRepository.findById(list.getId())).thenReturn(Optional.of(list));
        var institutionId = UUID.randomUUID();
        when(userRepository.findById(any())).thenReturn(Optional.of(User.builder()
                .id(UUID.randomUUID())
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .institutionId(institutionId).build()));
        // Instituição do aluno aponta pra outra rota.
        when(institutionRepository.findById(institutionId)).thenReturn(Optional.of(
                com.smartboarding.smartboarding_api.domain.institution.entity.Institution.builder()
                        .id(institutionId).routeId(UUID.randomUUID()).build()));
        var useCase = useCaseAt(LocalTime.of(10, 0));

        assertThatThrownBy(() -> useCase.add(UUID.randomUUID(), list.getId(), TripType.ROUND_TRIP))
                .isInstanceOf(BadRequestException.class);
        verify(listEntryRepository, never()).save(any());
    }

    @Test
    void alunoSemInstituicaoNaoVeListaNenhuma() {
        var list = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(java.util.List.of(list));
        var studentId = UUID.randomUUID();
        when(userRepository.findById(studentId)).thenReturn(Optional.of(User.builder()
                .id(studentId)
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .build()));

        assertThat(useCaseAt(LocalTime.of(10, 0)).findTodayLists(studentId)).isEmpty();
    }

    @Test
    void adminVeTodasAsListasDoDia() {
        var a = listWithCloseTime(LocalTime.of(16, 0), TODAY);
        var b = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(java.util.List.of(a, b));
        var adminId = UUID.randomUUID();
        when(userRepository.findById(adminId)).thenReturn(Optional.of(User.builder()
                .id(adminId)
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.ADMIN)
                .build()));

        assertThat(useCaseAt(LocalTime.of(10, 0)).findTodayLists(adminId)).hasSize(2);
    }

    @Test
    void alunoVeSoAListaDaRotaDaSuaInstituicao() {
        var minha = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        var outra = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(java.util.List.of(minha, outra));
        var studentId = UUID.randomUUID();
        var institutionId = UUID.randomUUID();
        when(userRepository.findById(studentId)).thenReturn(Optional.of(User.builder()
                .id(studentId)
                .role(com.smartboarding.smartboarding_api.domain.user.entity.Role.STUDENT)
                .institutionId(institutionId).build()));
        when(institutionRepository.findById(institutionId)).thenReturn(Optional.of(
                com.smartboarding.smartboarding_api.domain.institution.entity.Institution.builder()
                        .id(institutionId).routeId(minha.getRoute().getId()).build()));

        var result = useCaseAt(LocalTime.of(10, 0)).findTodayLists(studentId);

        assertThat(result).containsExactly(minha);
    }

    @Test
    void entrarAntesDoCloseTimeFunciona() {
        var list = listWithCloseTime(LocalTime.of(16, 0), TODAY);
        var id = stubList(list);
        var useCase = useCaseAt(LocalTime.of(15, 59));

        ListEntry saved = useCase.add(UUID.randomUUID(), id, TripType.ROUND_TRIP);

        assertThat(saved.isActive()).isTrue();
    }

    @Test
    void entrarDepoisDoCloseTimeLancaExcecao() {
        var list = listWithCloseTime(LocalTime.of(16, 0), TODAY);
        var id = stubList(list);
        var useCase = useCaseAt(LocalTime.of(16, 1));

        assertThatThrownBy(() -> useCase.add(UUID.randomUUID(), id, TripType.ROUND_TRIP))
                .isInstanceOf(BadRequestException.class);
        verify(listEntryRepository, never()).save(any());
    }

    @Test
    void closeTimeMaisTardePermiteEntrarDepoisDas16() {
        var list = listWithCloseTime(LocalTime.of(23, 0), TODAY);
        var id = stubList(list);
        var useCase = useCaseAt(LocalTime.of(18, 30));

        ListEntry saved = useCase.add(UUID.randomUUID(), id, TripType.ROUND_TRIP);

        assertThat(saved.isActive()).isTrue();
    }

    @Test
    void entrarEmListaDeOutroDiaLancaExcecao() {
        var list = listWithCloseTime(LocalTime.of(23, 0), TODAY.minusDays(3));
        var id = stubList(list);
        var useCase = useCaseAt(LocalTime.of(10, 0));

        assertThatThrownBy(() -> useCase.add(UUID.randomUUID(), id, TripType.ROUND_TRIP))
                .isInstanceOf(BadRequestException.class);
        verify(listEntryRepository, never()).save(any());
    }

    @Test
    void sairDepoisDoCloseTimeLancaExcecao() {
        var list = listWithCloseTime(LocalTime.of(16, 0), TODAY);
        when(dailyListRepository.findById(list.getId())).thenReturn(Optional.of(list));
        var useCase = useCaseAt(LocalTime.of(17, 0));

        assertThatThrownBy(() -> useCase.remove(UUID.randomUUID(), list.getId()))
                .isInstanceOf(BadRequestException.class);
        verify(listEntryRepository, never()).save(any());
    }
}
