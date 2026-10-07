package com.smartboarding.smartboarding_api.application.stats;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.profile.entity.ProfileUpdateRequest;
import com.smartboarding.smartboarding_api.domain.profile.port.out.ProfileUpdateRequestRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
import com.smartboarding.smartboarding_api.domain.warning.entity.Warning;
import com.smartboarding.smartboarding_api.domain.warning.port.out.WarningRepositoryPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.*;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AdminStatsUseCaseImplTest {

    private static final LocalDate TODAY = LocalDate.of(2026, 8, 28);

    @Mock UserRepositoryPort userRepository;
    @Mock DailyListRepositoryPort dailyListRepository;
    @Mock ListEntryRepositoryPort listEntryRepository;
    @Mock VehicleRepositoryPort vehicleRepository;
    @Mock ProfileUpdateRequestRepositoryPort profileUpdateRequestRepository;
    @Mock WarningRepositoryPort warningRepository;

    private AdminStatsUseCaseImpl useCase() {
        var clock = Clock.fixed(TODAY.atStartOfDay(ZoneId.systemDefault()).toInstant(), ZoneId.systemDefault());
        when(profileUpdateRequestRepository.findAllPending()).thenReturn(List.of());
        when(warningRepository.findAll()).thenReturn(List.of());
        return new AdminStatsUseCaseImpl(userRepository, dailyListRepository,
                listEntryRepository, vehicleRepository, profileUpdateRequestRepository,
                warningRepository, clock);
    }

    private Warning warningAt(LocalDate date) {
        return Warning.builder().id(UUID.randomUUID())
                .createdAt(date.atTime(10, 0)).build();
    }

    private DailyList listOfRoute(UUID routeId) {
        return DailyList.builder().id(UUID.randomUUID())
                .route(Route.builder().id(routeId).name("R").build())
                .date(TODAY).build();
    }

    @Test
    void calculaOcupacaoSobreACapacidadeDasRotasComListaHoje() {
        var routeA = UUID.randomUUID();
        var routeB = UUID.randomUUID();
        var listA = listOfRoute(routeA);
        var listB = listOfRoute(routeB);
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(List.of(listA, listB));
        when(listEntryRepository.countByDailyListIdAndIsActiveTrue(listA.getId())).thenReturn(20L);
        when(listEntryRepository.countByDailyListIdAndIsActiveTrue(listB.getId())).thenReturn(5L);
        when(vehicleRepository.totalCapacityByRouteId(routeA)).thenReturn(40);
        when(vehicleRepository.totalCapacityByRouteId(routeB)).thenReturn(10);
        when(userRepository.countActiveStudents()).thenReturn(124L);

        var stats = useCase().execute();

        assertThat(stats.activeStudents()).isEqualTo(124L);
        assertThat(stats.enrolledToday()).isEqualTo(25L);
        assertThat(stats.capacityToday()).isEqualTo(50L);
        assertThat(stats.occupancyPercent()).isEqualTo(50);
    }

    @Test
    void semVeiculoCadastradoOcupacaoEZeroEmVezDeDivisaoPorZero() {
        var routeA = UUID.randomUUID();
        var listA = listOfRoute(routeA);
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(List.of(listA));
        when(listEntryRepository.countByDailyListIdAndIsActiveTrue(listA.getId())).thenReturn(7L);
        when(vehicleRepository.totalCapacityByRouteId(routeA)).thenReturn(0);
        when(userRepository.countActiveStudents()).thenReturn(3L);

        var stats = useCase().execute();

        assertThat(stats.occupancyPercent()).isZero();
    }

    @Test
    void semListaHojeNaoContaInscritosNemCapacidade() {
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(List.of());
        when(userRepository.countActiveStudents()).thenReturn(10L);

        var stats = useCase().execute();

        assertThat(stats.enrolledToday()).isZero();
        assertThat(stats.capacityToday()).isZero();
        assertThat(stats.occupancyPercent()).isZero();
    }

    @Test
    void contaSolicitacoesPendentesEAdvertenciasDeHoje() {
        var useCase = useCase();
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(List.of());
        when(userRepository.countActiveStudents()).thenReturn(10L);
        when(profileUpdateRequestRepository.findAllPending())
                .thenReturn(List.of(new ProfileUpdateRequest(), new ProfileUpdateRequest()));
        when(warningRepository.findAll()).thenReturn(List.of(
                warningAt(TODAY), warningAt(TODAY), warningAt(TODAY.minusDays(1))));

        var stats = useCase.execute();

        assertThat(stats.pendingProfileRequests()).isEqualTo(2L);
        assertThat(stats.warningsToday()).isEqualTo(2L);
    }
}
