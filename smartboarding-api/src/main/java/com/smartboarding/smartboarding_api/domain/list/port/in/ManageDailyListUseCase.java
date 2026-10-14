package com.smartboarding.smartboarding_api.domain.list.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface ManageDailyListUseCase {
    List<DailyList> findByDate(LocalDate date);
    DailyList create(UUID routeId, LocalDate date);
    DailyList setStatus(UUID listId, ListStatus status, String reason);
    void delete(UUID listId);
}
