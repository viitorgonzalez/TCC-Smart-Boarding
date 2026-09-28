package com.smartboarding.smartboarding_api.infrastructure.web.common;

import com.smartboarding.smartboarding_api.domain.membership.port.in.AdminScope;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.UnauthorizedException;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

import java.util.Set;
import java.util.UUID;

/// Traduz a sessão em alcance, pros controllers não repetirem os dois passos.
///
/// A resolução de e-mail pra id estava copiada em cada controller que precisava
/// saber quem estava agindo; juntar aqui deixa um lugar só pra mudar quando a
/// sessão mudar de forma.
@Component
public class AdminGuard {

    private final AdminScope scope;
    private final UserRepositoryPort userRepository;

    public AdminGuard(AdminScope scope, UserRepositoryPort userRepository) {
        this.scope = scope;
        this.userRepository = userRepository;
    }

    public UUID id(Authentication auth) {
        if (auth == null) {
            throw new UnauthorizedException("Requisição sem sessão.");
        }
        return userRepository.findByEmail(auth.getName())
                .map(u -> u.getId())
                .orElseThrow(() -> new UnauthorizedException("Usuário autenticado não encontrado."));
    }

    public Set<UUID> routes(Authentication auth) {
        return scope.routesOf(id(auth));
    }

    public Set<UUID> institutions(Authentication auth) {
        return scope.institutionsOf(id(auth));
    }

    public void ownsRoute(Authentication auth, UUID routeId) {
        scope.assertAdministersRoute(id(auth), routeId);
    }

    public void ownsInstitution(Authentication auth, UUID institutionId) {
        scope.assertAdministersInstitution(id(auth), institutionId);
    }
}
