package com.smartboarding.smartboarding_api.application.stats;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
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

    private AdminStatsUseCaseImpl useCase() {
        var clock = Clock.fixed(TODAY.atStartOfDay(ZoneId.systemDefault()).toInstant(), ZoneId.systemDefault());
        return new AdminStatsUseCaseImpl(userRepository, dailyListRepository,
                listEntryRepository, vehicleRepository, clock);
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
        assertThat(stats.routesInUse()).isEqualTo(2L);
        assertThat(stats.occupancyPercent()).isEqualTo(50); // 25 de 50
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
    void semListaHojeNaoContaRotaEmUso() {
        when(dailyListRepository.findAllByDate(TODAY)).thenReturn(List.of());
        when(userRepository.countActiveStudents()).thenReturn(10L);

        var stats = useCase().execute();

        assertThat(stats.routesInUse()).isZero();
        assertThat(stats.occupancyPercent()).isZero();
    }
}
