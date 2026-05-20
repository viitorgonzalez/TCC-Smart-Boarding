package com.smartboarding.smartboarding_api.infrastructure.persistence.list;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ListEntryJpaRepository extends JpaRepository<ListEntry, UUID> {
    Optional<ListEntry> findByUserIdAndDailyListId(UUID userId, UUID dailyListId);
    List<ListEntry> findAllByDailyListIdAndIsActiveTrue(UUID dailyListId);
    long countByDailyListIdAndIsActiveTrue(UUID dailyListId);
}
