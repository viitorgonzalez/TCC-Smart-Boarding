package com.smartboarding.smartboarding_api.infrastructure.persistence.list;

import com.smartboarding.smartboarding_api.domain.list.entity.ListStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface DailyListJpaRepository extends JpaRepository<DailyListJpaEntity, UUID> {
    List<DailyListJpaEntity> findAllByDateAndStatus(LocalDate date, ListStatus status);
    boolean existsByRouteIdAndDate(UUID routeId, LocalDate date);
}
