package com.smartboarding.smartboarding_api.application.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.in.CreateInstitutionUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.in.ListInstitutionsUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class InstitutionUseCaseImpl implements CreateInstitutionUseCase, ListInstitutionsUseCase {

    private final InstitutionRepositoryPort institutionRepository;

    public InstitutionUseCaseImpl(InstitutionRepositoryPort institutionRepository) {
        this.institutionRepository = institutionRepository;
    }

    @Override
    @Transactional
    public Institution execute(Institution institution) {
        return institutionRepository.save(institution);
    }

    @Override
    public List<Institution> findAll() {
        return institutionRepository.findAll();
    }
}
