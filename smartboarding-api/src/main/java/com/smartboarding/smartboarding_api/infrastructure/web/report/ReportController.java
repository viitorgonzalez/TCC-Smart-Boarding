package com.smartboarding.smartboarding_api.infrastructure.web.report;

import com.smartboarding.smartboarding_api.domain.report.port.in.FindReportUseCase;
import com.smartboarding.smartboarding_api.infrastructure.web.report.dto.ReportDetailResponse;
import com.smartboarding.smartboarding_api.infrastructure.web.report.dto.ReportSummaryResponse;
import com.smartboarding.smartboarding_api.shared.web.ApiResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private final FindReportUseCase findReportUseCase;

    public ReportController(FindReportUseCase findReportUseCase) {
        this.findReportUseCase = findReportUseCase;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Page<ReportSummaryResponse>>> findAll(
            @PageableDefault(size = 20, sort = "generatedAt", direction = Sort.Direction.DESC) Pageable pageable) {
        Page<ReportSummaryResponse> page = findReportUseCase.findAll(pageable)
                .map(ReportSummaryResponse::from);
        return ResponseEntity.ok(ApiResponse.data(page));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ReportDetailResponse>> findById(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.data(ReportDetailResponse.from(findReportUseCase.findById(id))));
    }
}
