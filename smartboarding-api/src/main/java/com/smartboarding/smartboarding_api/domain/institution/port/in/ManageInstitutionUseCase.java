package com.smartboarding.smartboarding_api.domain.institution.port.in;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

import java.util.UUID;

public interface ManageInstitutionUseCase {
    /// Campos nulos ficam como estão.
    Institution update(UUID id, String name, String address, Double latitude, Double longitude);

    void delete(UUID id);
}
