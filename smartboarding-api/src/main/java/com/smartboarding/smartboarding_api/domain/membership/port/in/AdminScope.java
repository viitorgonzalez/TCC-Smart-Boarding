package com.smartboarding.smartboarding_api.domain.membership.port.in;

import java.util.Set;
import java.util.UUID;

public interface AdminScope {

    Set<UUID> institutionsOf(UUID adminId);

    Set<UUID> routesOf(UUID adminId);

    void assertAdministersRoute(UUID adminId, UUID routeId);

    void assertAdministersInstitution(UUID adminId, UUID institutionId);
}
