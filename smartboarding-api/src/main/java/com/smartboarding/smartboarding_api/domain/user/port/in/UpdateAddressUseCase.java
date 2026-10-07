package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.Address;

import java.util.UUID;

public interface UpdateAddressUseCase {
    Address update(UUID userId, Address address);
}
