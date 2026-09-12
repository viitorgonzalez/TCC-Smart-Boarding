package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/// RN28 — primeiro admin de um ambiente novo. A regra fica aqui, e não dentro de
/// um caso de uso, porque vale pros DOIS caminhos que criam conta: cadastro por
/// senha e primeiro login com Google. Se valesse só num deles, o operador que
/// escolhesse o outro nasceria STUDENT, o caminho restante recusaria por e-mail
/// já cadastrado e o ambiente ficaria sem admin nenhum pra promovê-lo — a saída
/// seria editar o banco à mão.
///
/// A janela se fecha sozinha: num banco novo não existe admin, logo não há quem
/// promova; no instante em que existe um, a condição nunca mais é verdadeira. A
/// variável CONCEDE o papel a uma conta que a própria pessoa criou — não cria
/// conta nenhuma.
@Component
public class BootstrapAdminPolicy {

    private final UserRepositoryPort userRepository;
    private final String bootstrapAdminEmail;

    public BootstrapAdminPolicy(UserRepositoryPort userRepository,
                                @Value("${app.bootstrap-admin-email:}") String bootstrapAdminEmail) {
        this.userRepository = userRepository;
        this.bootstrapAdminEmail = bootstrapAdminEmail;
    }

    /// Papel com que uma conta nova nasce.
    public Role roleForNewAccount(String email) {
        return grantsAdminTo(email) ? Role.ADMIN : Role.STUDENT;
    }

    /// Comparação exata, não equalsIgnoreCase: a unicidade de e-mail no Postgres
    /// é case-sensitive e nada normaliza o valor antes de gravar. Casando sem
    /// diferenciar caixa, CHEFE@x e chefe@x seriam contas DISTINTAS e ambas
    /// satisfariam a mesma janela — quem chegasse primeiro levaria uma grafia, o
    /// cadastro legítimo sucederia como STUDENT sem conflito, e nada sinalizaria
    /// que a janela já tinha sido consumida.
    private boolean grantsAdminTo(String email) {
        return bootstrapAdminEmail != null
                && !bootstrapAdminEmail.isBlank()
                && bootstrapAdminEmail.equals(email)
                && userRepository.countAdmins() == 0;
    }
}
