package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Role;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import lombok.extern.slf4j.Slf4j;
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
@Slf4j
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
        if (!grantsAdminTo(email)) {
            return Role.STUDENT;
        }
        // Em WARN de proposito, e a unica linha que registra o evento: o cadastro
        // e publico e nao prova posse de e-mail, entao quem souber a variavel e
        // chegar primeiro leva o papel. Nao da pra impedir sem verificacao de
        // e-mail, mas da pra deixar DETECTAVEL -- sem esta linha, o operador nao
        // tem como saber se a janela foi consumida por ele ou por outra pessoa.
        log.warn("BOOTSTRAP: primeira conta do ambiente nasceu ADMIN ({}). "
                + "Remova BOOTSTRAP_ADMIN_EMAIL da configuracao.", maskEmail(email));
        return Role.ADMIN;
    }

    /// Mascara igual ao resto do sistema: log de auditoria nao precisa do
    /// endereco inteiro pra ser util, e log vaza com mais facilidade que banco.
    private static String maskEmail(String email) {
        int arroba = email == null ? -1 : email.indexOf('@');
        return arroba <= 1 ? "***" : email.charAt(0) + "***" + email.substring(arroba);
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
