package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class BootstrapAdminPolicy {

    private final UserRepositoryPort userRepository;
    private final String bootstrapAdminEmail;

    public BootstrapAdminPolicy(UserRepositoryPort userRepository,
                                @Value("${app.bootstrap-admin-email:}") String bootstrapAdminEmail) {
        this.userRepository = userRepository;
        this.bootstrapAdminEmail = bootstrapAdminEmail;
    }

    public Role roleForNewAccount(String email) {
        if (!grantsAdminTo(email)) {
            return Role.STUDENT;
        }
        log.warn("BOOTSTRAP: primeira conta do ambiente nasceu ADMIN ({}). "
                + "Remova BOOTSTRAP_ADMIN_EMAIL da configuracao.", maskEmail(email));
        return Role.ADMIN;
    }

    private static String maskEmail(String email) {
        int arroba = email == null ? -1 : email.indexOf('@');
        return arroba <= 1 ? "***" : email.charAt(0) + "***" + email.substring(arroba);
    }

    private boolean grantsAdminTo(String email) {
        return bootstrapAdminEmail != null
                && !bootstrapAdminEmail.isBlank()
                && bootstrapAdminEmail.equals(email)
                && userRepository.countAdmins() == 0;
    }
}
