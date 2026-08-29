package com.smartboarding.smartboarding_api.infrastructure.persistence.list;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import com.smartboarding.smartboarding_api.domain.list.port.out.DailyListRepositoryPort;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class DailyListRepositoryAdapter implements DailyListRepositoryPort {

    private final DailyListJpaRepository jpa;

    public DailyListRepositoryAdapter(DailyListJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public DailyList save(DailyList dailyList) { return jpa.save(dailyList); }
    @Override public Optional<DailyList> findById(UUID id) { return jpa.findById(id); }
    @Override public List<DailyList> findAllByDateAndStatus(LocalDate date, ListStatus status) { return jpa.findAllByDateAndStatus(date, status); }
    @Override public List<DailyList> findAllByStatus(ListStatus status) { return jpa.findAllByStatus(status); }
    @Override public List<DailyList> findAllByDate(LocalDate date) { return jpa.findAllByDate(date); }
    @Override public boolean existsByRouteIdAndDate(UUID routeId, LocalDate date) { return jpa.existsByRouteIdAndDate(routeId, date); }
    @Override public void deleteById(UUID id) { jpa.deleteById(id); }
}
