package com.smartboarding.smartboarding_api.domain.membership.port.out;

import com.smartboarding.smartboarding_api.domain.membership.entity.RouteInviteCode;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RouteInviteCodeRepositoryPort {
    RouteInviteCode save(RouteInviteCode code);

    Optional<RouteInviteCode> findByCode(String code);

    Optional<RouteInviteCode> findById(UUID id);

    /// Inclui arquivados. A listagem do admin usa a variante que os omite.
    List<RouteInviteCode> findAllByRouteId(UUID routeId);

    List<RouteInviteCode> findAllByRouteIdAndArchivedAtIsNull(UUID routeId);

    List<RouteInviteCode> findAllById(List<UUID> ids);

    boolean existsByCode(String code);
}
