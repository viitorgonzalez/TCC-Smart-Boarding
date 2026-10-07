package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.Address;
import jakarta.validation.constraints.Size;

public record UpdateAddressRequest(
        @Size(max = 9) String zipCode,
        @Size(max = 150) String street,
        @Size(max = 100) String neighborhood,
        @Size(max = 100) String city,
        @Size(max = 2) String state,
        @Size(max = 20) String streetNumber,
        @Size(max = 100) String complement
) {
    public Address toDomain() {
        return Address.builder()
                .zipCode(zipCode).street(street).neighborhood(neighborhood)
                .city(city).state(state).streetNumber(streetNumber)
                .complement(complement)
                .build();
    }
}
