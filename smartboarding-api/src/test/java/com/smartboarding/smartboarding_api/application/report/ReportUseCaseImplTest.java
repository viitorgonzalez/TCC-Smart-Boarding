package com.smartboarding.smartboarding_api.application.report;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.report.entity.Report;
import com.smartboarding.smartboarding_api.domain.report.port.out.ReportRepositoryPort;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.vehicle.entity.Vehicle;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.util.List;
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
class ReportUseCaseImplTest {

    private static final UUID ROUTE = UUID.randomUUID();

    @Mock ReportRepositoryPort reportRepository;
    @Mock ListEntryRepositoryPort listEntryRepository;
    @Mock VehicleRepositoryPort vehicleRepository;

    private ReportUseCaseImpl useCase;
    private DailyList dailyList;

    @BeforeEach
    void setUp() {
        useCase = new ReportUseCaseImpl(reportRepository, listEntryRepository,
                new ObjectMapper(), vehicleRepository);
        dailyList = DailyList.builder()
                .id(UUID.randomUUID())
                .route(Route.builder().id(ROUTE).name("Rota Universitária").build())
                .build();
        when(reportRepository.findByDailyListId(any())).thenReturn(Optional.empty());
        when(reportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(vehicleRepository.findAllByRouteId(ROUTE)).thenReturn(List.of());
        when(listEntryRepository.findAllByDailyListIdAndIsActiveTrue(any())).thenReturn(List.of());
    }

    private ListEntry entry(String name, TripType type) {
        return ListEntry.builder()
                .id(UUID.randomUUID())
                .user(User.builder().id(UUID.randomUUID()).fullName(name)
                        .email(name.toLowerCase() + "@edu.unifor.br").build())
                .tripType(type)
                .build();
    }

    private void inscritos(ListEntry... entries) {
        when(listEntryRepository.findAllByDailyListIdAndIsActiveTrue(dailyList.getId()))
                .thenReturn(List.of(entries));
    }

    private void frota(Vehicle... vehicles) {
        when(vehicleRepository.findAllByRouteId(ROUTE)).thenReturn(List.of(vehicles));
    }

    private Vehicle vehicle(String label, int capacity) {
        return Vehicle.builder().id(UUID.randomUUID()).routeId(ROUTE)
                .label(label).capacity(capacity).build();
    }

    @Test
    void snapshotGuardaCadaInscritoComNomeEmailEDirecao() {
        inscritos(entry("Fernanda", TripType.ROUND_TRIP), entry("Bruno", TripType.TO_CAMPUS));

        Report report = useCase.execute(dailyList);

        assertThat(report.getTotalEntries()).isEqualTo(2);
        assertThat(report.getSnapshotData())
                .contains("Fernanda", "fernanda@edu.unifor.br", "ROUND_TRIP")
                .contains("Bruno", "TO_CAMPUS");
    }

    @Test
    void listaVaziaGeraRelatorioZeradoENaoQuebra() {
        Report report = useCase.execute(dailyList);

        assertThat(report.getTotalEntries()).isZero();
        assertThat(report.getSnapshotData()).isEqualTo("[]");
        assertThat(report.getCapacityShortfall()).isZero();
    }

    /// RN8: relatório é imutável e um por lista. Uma lista reaberta e fechada de
    /// novo não pode produzir um segundo relatório.
    @Test
    void listaJaComRelatorioDevolveOOriginalSemRegravar() {
        Report original = Report.builder().id(UUID.randomUUID()).totalEntries(7).build();
        when(reportRepository.findByDailyListId(dailyList.getId())).thenReturn(Optional.of(original));

        Report report = useCase.execute(dailyList);

        assertThat(report).isSameAs(original);
        verify(reportRepository, never()).save(any());
        verify(listEntryRepository, never()).findAllByDailyListIdAndIsActiveTrue(any());
    }

    /// RN16: o veículo proposto sai da contagem real no fechamento.
    @Test
    void veiculoPropostoCobreOsInscritosSemSobra() {
        frota(vehicle("Ônibus 01", 44), vehicle("Van 01", 15));
        inscritos(entry("A", TripType.ROUND_TRIP), entry("B", TripType.ROUND_TRIP));

        Report report = useCase.execute(dailyList);

        assertThat(report.getProposedVehicles()).contains("Van 01").doesNotContain("Ônibus 01");
        assertThat(report.getCapacityShortfall()).isZero();
    }

    @Test
    void frotaInsuficienteRegistraQuantosFicaramSemLugar() {
        frota(vehicle("Van 01", 15));
        ListEntry[] muitos = new ListEntry[20];
        for (int i = 0; i < muitos.length; i++) {
            muitos[i] = entry("Aluno" + i, TripType.ROUND_TRIP);
        }
        inscritos(muitos);

        Report report = useCase.execute(dailyList);

        assertThat(report.getCapacityShortfall()).isEqualTo(5);
    }

    @Test
    void semFrotaCadastradaTodoMundoFicaSemLugar() {
        inscritos(entry("A", TripType.ROUND_TRIP), entry("B", TripType.ROUND_TRIP));

        Report report = useCase.execute(dailyList);

        assertThat(report.getProposedVehicles()).isEqualTo("[]");
        assertThat(report.getCapacityShortfall()).isEqualTo(2);
    }

    @Test
    void findByIdInexistenteEstoura() {
        UUID id = UUID.randomUUID();
        when(reportRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.findById(id))
                .isInstanceOf(NotFoundException.class)
                .hasMessageContaining(id.toString());
    }

    @Test
    void findByIdExistenteDevolveORelatorio() {
        Report stored = Report.builder().id(UUID.randomUUID()).totalEntries(3).build();
        when(reportRepository.findById(stored.getId())).thenReturn(Optional.of(stored));

        assertThat(useCase.findById(stored.getId())).isSameAs(stored);
    }

    @Test
    void findAllRepassaAPaginacao() {
        Pageable pageable = Pageable.ofSize(10);
        Page<Report> page = new PageImpl<>(List.of(Report.builder().build()));
        when(reportRepository.findAll(pageable)).thenReturn(page);

        assertThat(useCase.findAll(pageable)).isSameAs(page);
    }
}
