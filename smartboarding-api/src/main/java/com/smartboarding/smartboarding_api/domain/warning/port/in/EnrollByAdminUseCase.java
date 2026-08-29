package com.smartboarding.smartboarding_api.domain.warning.port.in;

import com.smartboarding.smartboarding_api.domain.list.entity.ListEntry;
import com.smartboarding.smartboarding_api.domain.list.entity.TripType;

import java.util.UUID;

/// Inclusão tardia pelo admin: entra na lista mesmo fora do horário, porque às
/// vezes o aluno realmente vai embarcar e o sistema não pode negar o embarque.
public interface EnrollByAdminUseCase {

    /// [issueWarning] é escolha do admin — nem toda inclusão tardia é falta do
    /// aluno (ônibus adiantado, problema no app, decisão da coordenação).
    ListEntry enroll(UUID listId, UUID userId, TripType tripType,
                     boolean issueWarning, String warningReason, UUID adminId);
}
