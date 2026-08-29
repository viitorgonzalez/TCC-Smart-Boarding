package com.smartboarding.smartboarding_api.domain.registration.port.in;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

import java.time.LocalDate;
import java.util.UUID;

public interface SubmitRegistrationUseCase {
    record SubmitData(String fullName, String rawPassword, UUID institutionId,
                       String course, String phone, String address, LocalDate birthDate) {}

    RegistrationRequest submitRegistration(String token, SubmitData data);
}
