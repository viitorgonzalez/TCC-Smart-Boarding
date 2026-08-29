package com.smartboarding.smartboarding_api.application.warning;

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
import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;
import com.smartboarding.smartboarding_api.domain.warning.port.out.WarningRepositoryPort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class WarningUseCaseImplTest {

    private static final UUID LIST_ID = UUID.randomUUID();
    private static final UUID STUDENT_ID = UUID.randomUUID();
    private static final UUID ADMIN_ID = UUID.randomUUID();

    @Mock WarningRepositoryPort warningRepository;
    @Mock DailyListRepositoryPort dailyListRepository;
    @Mock ListEntryRepositoryPort listEntryRepository;
    @Mock UserRepositoryPort userRepository;
    @Mock SendToUserUseCase sendToUserUseCase;

    private WarningUseCaseImpl useCase;

    @BeforeEach
    void setUp() {
        useCase = new WarningUseCaseImpl(warningRepository, dailyListRepository,
                listEntryRepository, userRepository, sendToUserUseCase);

        Route route = Route.builder().id(UUID.randomUUID()).name("Rota X")
                .closeTime(LocalTime.of(16, 0)).build();
        // Lista já fechada de propósito: é o caso que o caminho do admin existe pra atender.
        DailyList closed = DailyList.builder().id(LIST_ID).route(route)
                .date(LocalDate.of(2026, 8, 28)).status(ListStatus.CLOSED).build();
        User student = User.builder().id(STUDENT_ID).fullName("Aluno Teste").build();
        User admin = User.builder().id(ADMIN_ID).fullName("Admin Teste").build();

        when(dailyListRepository.findById(LIST_ID)).thenReturn(Optional.of(closed));
        when(userRepository.findById(STUDENT_ID)).thenReturn(Optional.of(student));
        when(userRepository.findById(ADMIN_ID)).thenReturn(Optional.of(admin));
        when(listEntryRepository.findByUserIdAndDailyListId(STUDENT_ID, LIST_ID))
                .thenReturn(Optional.empty());
        when(listEntryRepository.save(any(ListEntry.class))).thenAnswer(i -> i.getArgument(0));
    }

    @Test
    void inscreveNaListaFechadaSemAdvertenciaQuandoOAdminNaoQuer() {
        ListEntry saved = useCase.enroll(LIST_ID, STUDENT_ID, TripType.ROUND_TRIP,
                false, null, ADMIN_ID);

        assertThat(saved.isActive()).isTrue();
        verify(warningRepository, never()).save(any());
    }

    @Test
    void emiteAdvertenciaQuandoOAdminEscolhe() {
        useCase.enroll(LIST_ID, STUDENT_ID, TripType.ROUND_TRIP, true,
                "Chegou depois do fechamento.", ADMIN_ID);

        ArgumentCaptor<Warning> captor = ArgumentCaptor.forClass(Warning.class);
        verify(warningRepository).save(captor.capture());
        assertThat(captor.getValue().getReason()).isEqualTo("Chegou depois do fechamento.");
        assertThat(captor.getValue().getUser().getId()).isEqualTo(STUDENT_ID);
        assertThat(captor.getValue().getIssuedBy().getId()).isEqualTo(ADMIN_ID);
    }

    @Test
    void advertenciaSemTextoUsaOMotivoPadrao() {
        useCase.enroll(LIST_ID, STUDENT_ID, TripType.ROUND_TRIP, true, "   ", ADMIN_ID);

        ArgumentCaptor<Warning> captor = ArgumentCaptor.forClass(Warning.class);
        verify(warningRepository).save(captor.capture());
        assertThat(captor.getValue().getReason()).contains("fora do horário");
    }

    @Test
    void alunoEhAvisadoDaAdvertencia() {
        useCase.enroll(LIST_ID, STUDENT_ID, TripType.ROUND_TRIP, true, "Motivo.", ADMIN_ID);

        verify(sendToUserUseCase).execute(eq(STUDENT_ID), contains("advertência"), eq("Motivo."));
    }

    @Test
    void pushQueFalhaNaoDesfazAInscricao() {
        doThrow(new RuntimeException("FCM fora")).when(sendToUserUseCase)
                .execute(any(), any(), any());

        ListEntry saved = useCase.enroll(LIST_ID, STUDENT_ID, TripType.ROUND_TRIP,
                true, "Motivo.", ADMIN_ID);

        assertThat(saved.isActive()).isTrue();
        verify(warningRepository).save(any());
    }
}
