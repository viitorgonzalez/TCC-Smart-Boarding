package com.smartboarding.smartboarding_api.infrastructure.web.institution;

import com.smartboarding.smartboarding_api.domain.institution.entity.Institution;
import com.smartboarding.smartboarding_api.domain.institution.port.in.CreateInstitutionUseCase;
import com.smartboarding.smartboarding_api.domain.institution.port.in.ListInstitutionsUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.institution.dto.CreateInstitutionRequest;
import com.smartboarding.smartboarding_api.infrastructure.web.institution.dto.InstitutionResponse;
import com.smartboarding.smartboarding_api.domain.institution.port.in.LinkInstitutionRouteUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.institution.dto.LinkRouteRequest;
import com.smartboarding.smartboarding_api.domain.institution.port.in.ManageInstitutionUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.institution.dto.UpdateInstitutionRequest;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;
import java.util.List;

@RestController
@RequestMapping("/api/institutions")
public class InstitutionController {

    private final CreateInstitutionUseCase createInstitutionUseCase;
    private final ListInstitutionsUseCase listInstitutionsUseCase;
    private final LinkInstitutionRouteUseCase linkInstitutionRouteUseCase;
    private final ManageInstitutionUseCase manageInstitutionUseCase;

    public InstitutionController(CreateInstitutionUseCase createInstitutionUseCase,
                                 ListInstitutionsUseCase listInstitutionsUseCase,
                                 LinkInstitutionRouteUseCase linkInstitutionRouteUseCase,
                                 ManageInstitutionUseCase manageInstitutionUseCase) {
        this.createInstitutionUseCase = createInstitutionUseCase;
        this.listInstitutionsUseCase = listInstitutionsUseCase;
        this.linkInstitutionRouteUseCase = linkInstitutionRouteUseCase;
        this.manageInstitutionUseCase = manageInstitutionUseCase;
    }

    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<InstitutionResponse>> update(@PathVariable UUID id,
                                                                   @RequestBody @Valid UpdateInstitutionRequest request) {
        return ResponseEntity.ok(ApiResponse.data(InstitutionResponse.from(
                manageInstitutionUseCase.update(id, request.name(), request.address(),
                        request.latitude(), request.longitude()))));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> delete(@PathVariable UUID id) {
        manageInstitutionUseCase.delete(id);
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PatchMapping("/{id}/route")
    public ResponseEntity<ApiResponse<InstitutionResponse>> linkRoute(@PathVariable UUID id,
                                                                      @RequestBody LinkRouteRequest request) {
        return ResponseEntity.ok(ApiResponse.data(InstitutionResponse.from(
                linkInstitutionRouteUseCase.linkToRoute(id, request.routeId()))));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<InstitutionResponse>> create(@RequestBody @Valid CreateInstitutionRequest request) {
        Institution institution = Institution.builder()
                .name(request.name()).address(request.address())
                .latitude(request.latitude()).longitude(request.longitude())
                .routeId(request.routeId())
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
