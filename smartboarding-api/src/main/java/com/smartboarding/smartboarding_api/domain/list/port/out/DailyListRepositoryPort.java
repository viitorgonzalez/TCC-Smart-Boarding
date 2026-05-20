package com.smartboarding.smartboarding_api.domain.list.port.out;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DailyListRepositoryPort {
    DailyList save(DailyList dailyList);
    Optional<DailyList> findById(UUID id);
    List<DailyList> findAllByDateAndStatus(LocalDate date, ListStatus status);
    boolean existsByRouteIdAndDate(UUID routeId, LocalDate date);
}
