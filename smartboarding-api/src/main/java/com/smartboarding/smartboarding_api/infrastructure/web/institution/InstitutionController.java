package com.smartboarding.smartboarding_api.infrastructure.web.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.in.CreateInstitutionUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.in.ListInstitutionsUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.institution.dto.CreateInstitutionRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.institution.dto.InstitutionResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/institutions")
public class InstitutionController {

    private final CreateInstitutionUseCase createInstitutionUseCase;
    private final ListInstitutionsUseCase listInstitutionsUseCase;

    public InstitutionController(CreateInstitutionUseCase createInstitutionUseCase,
                                 ListInstitutionsUseCase listInstitutionsUseCase) {
        this.createInstitutionUseCase = createInstitutionUseCase;
        this.listInstitutionsUseCase = listInstitutionsUseCase;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<InstitutionResponse>> create(@RequestBody @Valid CreateInstitutionRequest request) {
        Institution institution = Institution.builder()
                .name(request.name()).address(request.address())
                .latitude(request.latitude()).longitude(request.longitude())
                .build();
        Institution saved = createInstitutionUseCase.execute(institution);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.data(InstitutionResponse.from(saved)));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<InstitutionResponse>>> findAll() {
        List<InstitutionResponse> institutions = listInstitutionsUseCase.findAll().stream()
                .map(InstitutionResponse::from).toList();
        return ResponseEntity.ok(ApiResponse.data(institutions));
    }
}
