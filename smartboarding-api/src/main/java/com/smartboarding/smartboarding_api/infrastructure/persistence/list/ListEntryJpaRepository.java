package com.smartboarding.smartboarding_api.infrastructure.persistence.list;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ListEntryJpaRepository extends JpaRepository<ListEntry, UUID> {

    Optional<ListEntry> findByUserIdAndDailyListId(UUID userId, UUID dailyListId);

    List<ListEntry> findAllByDailyListIdAndIsActiveTrue(UUID dailyListId);

    long countByDailyListIdAndIsActiveTrue(UUID dailyListId);

    @Modifying
    void deleteAllByDailyListId(UUID dailyListId);

    @Query("""
            SELECT e FROM ListEntry e
            JOIN e.dailyList dl
            WHERE e.user.id = :userId AND e.isActive = true AND dl.date >= :since
            ORDER BY dl.date DESC
            """)
    List<ListEntry> findAttendanceSince(@Param("userId") UUID userId,
                                        @Param("since") LocalDate since);
}
