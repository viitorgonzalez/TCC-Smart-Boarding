package com.smartboarding.smartboarding_api.infrastructure.persistence.notification;

import com.smartboarding.smartboarding_api.domain.notification.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface NotificationJpaRepository extends JpaRepository<Notification, UUID> {

    /// Aviso sem rota e geral (vale pra todo mundo); com rota, so pra quem faz
    /// parte dela. O aluno pode estar em varias, dai a colecao.
    @Query("""
            SELECT n FROM Notification n
            WHERE (n.routeId IS NULL OR n.routeId IN :routeIds)
              AND (n.expiresAt IS NULL OR n.expiresAt > :now)
            ORDER BY n.createdAt DESC
            """)
    List<Notification> findVisibleForRoutes(@Param("routeIds") Collection<UUID> routeIds,
                                            @Param("now") LocalDateTime now);

    /// Aluno sem rota nenhuma: so os avisos gerais. Existe separado porque IN
    /// com lista vazia gera SQL invalido.
    @Query("""
            SELECT n FROM Notification n
            WHERE n.routeId IS NULL
              AND (n.expiresAt IS NULL OR n.expiresAt > :now)
            ORDER BY n.createdAt DESC
            """)
    List<Notification> findVisibleGeneralOnly(@Param("now") LocalDateTime now);

    List<Notification> findAllByOrderByCreatedAtDesc();
}
