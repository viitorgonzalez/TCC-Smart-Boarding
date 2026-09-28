package com.smartboarding.smartboarding_api.domain.user.port.in;

import com.smartboarding.smartboarding_api.domain.user.entity.Address;

import java.util.UUID;

/// O aluno escreve o próprio endereço, sem passar pela fila de aprovação.
///
/// Endereço não decide em qual transporte a pessoa entra — decide onde ela
/// embarca. Errar só prejudica ela mesma, então exigir um admin no meio só
/// criaria espera: a entrada na lista cobra endereço completo, e quem não
/// consegue preencher sozinho ficaria travado até alguém aprovar.
public interface UpdateAddressUseCase {
    Address update(UUID userId, Address address);
}
