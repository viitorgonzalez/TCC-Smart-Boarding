package com.smartboarding.smartboarding_api.application.stats;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.profile.port.out.ProfileUpdateRequestRepositoryPort;
import com.smartboarding.smartboarding_api.domain.stats.port.in.GetAdminStatsUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
import com.smartboarding.smartboarding_api.domain.warning.port.out.WarningRepositoryPort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.util.List;

@Service
public class AdminStatsUseCaseImpl implements GetAdminStatsUseCase {

    private final UserRepositoryPort userRepository;
    private final DailyListRepositoryPort dailyListRepository;
    private final ListEntryRepositoryPort listEntryRepository;
    private final VehicleRepositoryPort vehicleRepository;
    private final ProfileUpdateRequestRepositoryPort profileUpdateRequestRepository;
    private final WarningRepositoryPort warningRepository;
    private final Clock clock;

    public AdminStatsUseCaseImpl(UserRepositoryPort userRepository,
                                 DailyListRepositoryPort dailyListRepository,
                                 ListEntryRepositoryPort listEntryRepository,
                                 VehicleRepositoryPort vehicleRepository,
                                 ProfileUpdateRequestRepositoryPort profileUpdateRequestRepository,
                                 WarningRepositoryPort warningRepository,
                                 Clock clock) {
        this.userRepository = userRepository;
        this.dailyListRepository = dailyListRepository;
        this.listEntryRepository = listEntryRepository;
        this.vehicleRepository = vehicleRepository;
        this.profileUpdateRequestRepository = profileUpdateRequestRepository;
        this.warningRepository = warningRepository;
        this.clock = clock;
    }

    @Override
    @Transactional(readOnly = true)
    public AdminStats execute() {
        LocalDate today = LocalDate.now(clock);
        List<DailyList> todayLists = dailyListRepository.findAllByDate(today);

        long enrolled = todayLists.stream()
                .mapToLong(list -> listEntryRepository.countByDailyListIdAndIsActiveTrue(list.getId()))
                .sum();
        int capacity = todayLists.stream()
                .mapToInt(list -> vehicleRepository.totalCapacityByRouteId(list.getRoute().getId()))
                .sum();

        int occupancy = capacity == 0 ? 0 : (int) Math.round(enrolled * 100.0 / capacity);

        long warningsToday = warningRepository.findAll().stream()
                .filter(w -> w.getCreatedAt().toLocalDate().equals(today))
                .count();

        return new AdminStats(
                userRepository.countActiveStudents(),
                enrolled,
                capacity,
                occupancy,
                profileUpdateRequestRepository.findAllPending().size(),
                warningsToday);
    }
}
