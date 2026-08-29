package com.smartboarding.smartboarding_api.application.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.in.CreateInstitutionUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.in.ListInstitutionsUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.out.InstitutionRepositoryPort;
import com.smartboarding.smartboarding_api.domain.institution.port.in.LinkInstitutionRouteUseCase;
import com.smartboarding.smartboarding_api.domain.route.entity.Route;
import com.smartboarding.smartboarding_api.domain.route.port.out.RouteRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.ConflictException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import com.smartboarding.smartboarding_api.domain.institution.port.in.ManageInstitutionUseCase;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.util.List;

@Service
public class InstitutionUseCaseImpl implements CreateInstitutionUseCase, ListInstitutionsUseCase,
        LinkInstitutionRouteUseCase, ManageInstitutionUseCase {

    private final InstitutionRepositoryPort institutionRepository;
    private final RouteRepositoryPort routeRepository;
    private final UserRepositoryPort userRepository;

    public InstitutionUseCaseImpl(InstitutionRepositoryPort institutionRepository,
                                  RouteRepositoryPort routeRepository,
                                  UserRepositoryPort userRepository) {
        this.institutionRepository = institutionRepository;
        this.routeRepository = routeRepository;
        this.userRepository = userRepository;
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

    @Override
    @Transactional
    public Institution update(UUID id, String name, String address, Double latitude, Double longitude) {
        Institution institution = institutionRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Instituição não encontrada"));
        if (name != null && !name.isBlank()) {
            institution.setName(name.trim());
        }
        if (address != null) {
            institution.setAddress(address.isBlank() ? null : address.trim());
        }
        if (latitude != null) institution.setLatitude(latitude);
        if (longitude != null) institution.setLongitude(longitude);
        return institutionRepository.save(institution);
    }

    @Override
    @Transactional
    public void delete(UUID id) {
        institutionRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Instituição não encontrada"));
        // Aluno referencia a instituição e tira dela a própria rota (RN15).
        // Apagar por baixo deixaria o aluno sem rota e sem lista, sem aviso.
        long students = userRepository.countByInstitutionId(id);
        if (students > 0) {
            throw new ConflictException("INSTITUTION_IN_USE",
                    "Instituição tem " + students + " aluno(s) vinculado(s).");
        }
        institutionRepository.deleteById(id);
    }

    @Override
    @Transactional
    public Institution linkToRoute(UUID institutionId, UUID routeId) {
        Institution institution = institutionRepository.findById(institutionId)
                .orElseThrow(() -> new NotFoundException("Instituição não encontrada"));

        // RN15: trocar de rota exige desvincular antes, senão um vínculo errado
        // silenciosamente move todos os alunos daquela instituição de transporte.
        UUID current = institution.getRouteId();
        if (routeId != null && current != null && !current.equals(routeId)) {
            boolean currentIsActive = routeRepository.findById(current)
                    .map(Route::isActive).orElse(false);
            if (currentIsActive) {
                throw new ConflictException("INSTITUTION_ALREADY_LINKED",
                        "Instituição já vinculada a uma rota ativa; desvincule antes de trocar.");
            }
        }

        if (routeId != null) {
            routeRepository.findById(routeId)
                    .orElseThrow(() -> new NotFoundException("Rota não encontrada"));
        }

        institution.setRouteId(routeId);
        return institutionRepository.save(institution);
    }
}
