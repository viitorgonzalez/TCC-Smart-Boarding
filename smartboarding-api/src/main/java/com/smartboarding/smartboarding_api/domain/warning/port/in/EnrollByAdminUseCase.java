package com.smartboarding.smartboarding_api.domain.warning.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;

import java.util.UUID;

public interface EnrollByAdminUseCase {

    ListEntry enroll(UUID listId, UUID userId, TripType tripType,
                     boolean issueWarning, String warningReason, UUID adminId);
}
