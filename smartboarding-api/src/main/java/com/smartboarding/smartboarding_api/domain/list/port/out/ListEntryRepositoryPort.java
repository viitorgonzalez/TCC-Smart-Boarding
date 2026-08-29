package com.smartboarding.smartboarding_api.domain.list.port.out;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ListEntryRepositoryPort {
    ListEntry save(ListEntry entry);
    Optional<ListEntry> findByUserIdAndDailyListId(UUID userId, UUID dailyListId);
    List<ListEntry> findAllByDailyListIdAndIsActiveTrue(UUID dailyListId);
    long countByDailyListIdAndIsActiveTrue(UUID dailyListId);

    /// Presenças do aluno a partir de uma data — base do histórico dele.
    List<ListEntry> findAttendanceSince(UUID userId, LocalDate since);
    void deleteAllByDailyListId(UUID dailyListId);
}
