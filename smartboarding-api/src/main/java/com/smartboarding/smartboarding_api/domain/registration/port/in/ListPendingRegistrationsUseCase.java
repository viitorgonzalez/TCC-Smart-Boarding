package com.smartboarding.smartboarding_api.domain.registration.port.in;

import com.smartboarding.smartboarding_api.domain.registration.entity.RegistrationRequest;

import java.util.List;

public interface ListPendingRegistrationsUseCase {
    List<RegistrationRequest> listPending();
}
