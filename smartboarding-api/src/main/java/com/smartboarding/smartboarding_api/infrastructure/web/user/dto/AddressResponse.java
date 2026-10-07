package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.Address;

public record AddressResponse(
        String zipCode,
        String street,
        String neighborhood,
        String city,
        String state,
        String streetNumber,
        String complement,
        boolean complete,
        String shortForm
) {
    public static AddressResponse from(Address a) {
        if (a == null) a = new Address();
        return new AddressResponse(
                a.getZipCode(), a.getStreet(), a.getNeighborhood(),
                a.getCity(), a.getState(), a.getStreetNumber(), a.getComplement(),
                a.isComplete(), a.shortForm());
    }
}
