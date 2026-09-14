package com.smartboarding.smartboarding_api.domain.membership.port.in;

import java.util.List;
import java.util.UUID;

public interface ManageUserInstitutionsUseCase {
    List<UUID> institutionsOf(UUID userId);

    void add(UUID userId, UUID institutionId);

    void remove(UUID userId, UUID institutionId);
}
