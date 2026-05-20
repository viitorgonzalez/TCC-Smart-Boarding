package com.smartboarding.smartboarding_api.domain.report.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.DailyList;
import com.smartboarding.smartboarding_api.domain.report.entity.Report;

public interface GenerateReportUseCase {
    Report execute(DailyList dailyList);
}
