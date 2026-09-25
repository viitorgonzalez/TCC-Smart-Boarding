package com.smartboarding.smartboarding_api.infrastructure.web.profile.dto;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.infrastructure.web.user.dto.AddressResponse;

import java.util.List;
import java.util.UUID;

/// Quem sou eu, do ponto de vista da sessão atual.
///
/// [hasPassword] e [hasGoogle] dizem por quais caminhos esta conta entra. É o
/// que permite à tela oferecer "criar senha" só a quem ainda não tem — sem
/// isso, ela ofereceria a todos e metade tomaria 409.
public record MeResponse(UUID id, String fullName, String email, String role,
                         boolean hasPassword, boolean hasGoogle,
                         String phone, String course, AddressResponse address,
                         List<String> missingForList) {

    public static MeResponse from(User user) {
        return new MeResponse(user.getId(), user.getFullName(), user.getEmail(),
                user.getRole().name(), user.hasPassword(), user.hasGoogle(),
                user.getPhone(), user.getCourse(),
                AddressResponse.from(user.getAddress()),
                // Quem decide o que falta é o domínio, e o app só exibe. Refazer
                // a conta em Dart daria duas versões da regra pra divergirem, e
                // a que vale é a do backend -- que é quem recusa a entrada.
                user.missingForList());
    }
}
