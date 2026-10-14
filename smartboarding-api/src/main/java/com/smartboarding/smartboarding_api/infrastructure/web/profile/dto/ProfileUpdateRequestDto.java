package com.smartboarding.smartboarding_api.infrastructure.web.profile.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.Address;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.UUID;

public record ProfileUpdateRequestDto(
        @Size(max = 150) String fullName,
        UUID institutionId,
        LocalDate birthDate,
        @Size(max = 20) String phone,
        @Size(max = 100) String course,
        @Size(max = 9) String zipCode,
        @Size(max = 150) String street,
        @Size(max = 100) String neighborhood,
        @Size(max = 100) String city,
        @Size(max = 2) String state,
        @Size(max = 20) String streetNumber,
        @Size(max = 100) String complement
) {
    public Address addressOrNull() {
        if (zipCode == null && street == null && neighborhood == null
                && city == null && state == null && streetNumber == null
                && complement == null) {
            return null;
        }
        return Address.builder()
                .zipCode(zipCode).street(street).neighborhood(neighborhood)
                .city(city).state(state).streetNumber(streetNumber)
                .complement(complement)
                .build();
    }
}
