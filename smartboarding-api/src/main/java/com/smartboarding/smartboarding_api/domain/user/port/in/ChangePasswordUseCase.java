package com.smartboarding.smartboarding_api.domain.user.port.in;

import java.util.UUID;

public interface ChangePasswordUseCase {
    /// Troca a senha de quem já tem uma, exigindo a atual como prova de posse.
    ///
    /// Separado de SetLocalPasswordUseCase de propósito: lá o caso é *criar* a
    /// primeira senha de quem entrou pelo Google, e não há senha antiga pra
    /// provar. Juntar os dois num método só faria a prova de posse virar um
    /// parâmetro opcional — e um parâmetro opcional esquecido vira troca de
    /// senha sem prova nenhuma.
    void changePassword(UUID userId, String currentPassword, String newPassword);
}
