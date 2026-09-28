package com.smartboarding.smartboarding_api.infrastructure.web.user.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.Address;

/// Endereço como o app precisa dele: campo a campo, pro formulário reabrir o
/// que já foi preenchido, mais [complete] pronto pra tela não repetir a regra.
///
/// [shortForm] é o que a carteirinha mostra — rua, número e bairro, sem CEP
/// nem cidade. Vem calculado do domínio pra não haver duas versões da mesma
/// linha, uma aqui e outra em Dart.
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
