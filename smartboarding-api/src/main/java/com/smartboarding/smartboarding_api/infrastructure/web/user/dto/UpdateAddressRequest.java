package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.Address;
import jakarta.validation.constraints.Size;

/// Endereço vindo do formulário. Campo a campo porque o CEP preenche quase
/// tudo: o aluno digita CEP e número, e o resto chega pronto.
///
/// Nada é obrigatório aqui de propósito -- salvar pela metade é permitido, e
/// quem cobra o endereço completo é a entrada na lista, num lugar só.
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
