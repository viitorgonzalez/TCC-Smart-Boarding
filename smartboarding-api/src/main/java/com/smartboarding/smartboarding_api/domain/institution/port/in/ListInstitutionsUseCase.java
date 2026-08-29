package com.smartboarding.smartboarding_api.domain.institution.port.in;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;

import java.util.List;

public interface ListInstitutionsUseCase {
    List<Institution> findAll();
}
