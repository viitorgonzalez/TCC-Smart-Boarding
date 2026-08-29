package com.smartboarding.smartboarding_api.domain.institution.port.in;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

public interface CreateInstitutionUseCase {
    Institution execute(Institution institution);
}
