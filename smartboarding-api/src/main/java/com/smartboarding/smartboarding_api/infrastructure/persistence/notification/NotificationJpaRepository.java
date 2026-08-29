package com.smartboarding.smartboarding_api.infrastructure.persistence.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface NotificationJpaRepository extends JpaRepository<Notification, UUID> {

    @Query("""
            SELECT n FROM Notification n
            WHERE (n.routeId IS NULL OR n.routeId = :routeId)
              AND (n.expiresAt IS NULL OR n.expiresAt > :now)
            ORDER BY n.createdAt DESC
            """)
    List<Notification> findVisible(@Param("routeId") UUID routeId,
                                   @Param("now") LocalDateTime now);

    List<Notification> findAllByOrderByCreatedAtDesc();
}
