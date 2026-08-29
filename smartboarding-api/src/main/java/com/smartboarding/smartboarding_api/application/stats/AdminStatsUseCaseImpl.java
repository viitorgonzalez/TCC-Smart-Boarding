package com.smartboarding.smartboarding_api.application.stats;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import com.smartboarding.smartboarding_api.domain.stats.port.in.GetAdminStatsUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.domain.vehicle.port.out.VehicleRepositoryPort;
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
    private final Clock clock;

    public AdminStatsUseCaseImpl(UserRepositoryPort userRepository,
                                 DailyListRepositoryPort dailyListRepository,
                                 ListEntryRepositoryPort listEntryRepository,
                                 VehicleRepositoryPort vehicleRepository,
                                 Clock clock) {
        this.userRepository = userRepository;
        this.dailyListRepository = dailyListRepository;
        this.listEntryRepository = listEntryRepository;
        this.vehicleRepository = vehicleRepository;
        this.clock = clock;
    }

    @Override
    @Transactional(readOnly = true)
    public AdminStats execute() {
        List<DailyList> today = dailyListRepository.findAllByDate(LocalDate.now(clock));

        long enrolled = today.stream()
                .mapToLong(list -> listEntryRepository.countByDailyListIdAndIsActiveTrue(list.getId()))
                .sum();
        int capacity = today.stream()
                .mapToInt(list -> vehicleRepository.totalCapacityByRouteId(list.getRoute().getId()))
                .sum();

        // Sem veículo cadastrado a ocupação seria divisão por zero; 0% é o
        // valor honesto ("não há capacidade conhecida"), não 100%.
        int occupancy = capacity == 0 ? 0 : (int) Math.round(enrolled * 100.0 / capacity);

        return new AdminStats(userRepository.countActiveStudents(), today.size(), occupancy);
    }
}
