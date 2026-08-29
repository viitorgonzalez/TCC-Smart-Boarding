package com.smartboarding.smartboarding_api.infrastructure.web.stats;

import com.smartboarding.smartboarding_api.domain.stats.port.in.GetAdminStatsUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.stats.dto.AdminStatsResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin")
public class AdminStatsController {

    private final GetAdminStatsUseCase getAdminStatsUseCase;

    public AdminStatsController(GetAdminStatsUseCase getAdminStatsUseCase) {
        this.getAdminStatsUseCase = getAdminStatsUseCase;
    }

    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<AdminStatsResponse>> stats() {
        return ResponseEntity.ok(ApiResponse.data(AdminStatsResponse.from(getAdminStatsUseCase.execute())));
    }
}
