package com.smartboarding.smartboarding_api.infrastructure.persistence.list;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.port.out.ListEntryRepositoryPort;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class ListEntryRepositoryAdapter implements ListEntryRepositoryPort {

    private final ListEntryJpaRepository jpa;

    public ListEntryRepositoryAdapter(ListEntryJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override public ListEntry save(ListEntry entry) { return jpa.save(entry); }
    @Override public Optional<ListEntry> findByUserIdAndDailyListId(UUID userId, UUID dailyListId) { return jpa.findByUserIdAndDailyListId(userId, dailyListId); }
    @Override public List<ListEntry> findAllByDailyListIdAndIsActiveTrue(UUID dailyListId) { return jpa.findAllByDailyListIdAndIsActiveTrue(dailyListId); }
    @Override public long countByDailyListIdAndIsActiveTrue(UUID dailyListId) { return jpa.countByDailyListIdAndIsActiveTrue(dailyListId); }
}
