package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class UpdateOwnProfileUseCaseImplTest {

    private static final UUID ALUNO = UUID.randomUUID();

    @Mock UserRepositoryPort userRepository;

    private UpdateOwnProfileUseCaseImpl useCase;
    private User conta;

    @BeforeEach
    void setUp() {
        useCase = new UpdateOwnProfileUseCaseImpl(userRepository);
        conta = User.builder().id(ALUNO).fullName("Fernanda Lima")
                .phone("37999990000").course("Engenharia").build();
        when(userRepository.findById(ALUNO)).thenReturn(Optional.of(conta));
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));
    }

    /// Telefone é o contato dele. Errado só prejudica ele mesmo, então não há
    /// o que um admin proteja ao revisar — só espera, e é espera que custa
    /// viagem: sem telefone o aluno nem entra na lista.
    @Test
    void telefoneSalvaNaHora() {
        useCase.update(ALUNO, "37988887777", null);

        assertThat(conta.getPhone()).isEqualTo("37988887777");
    }

    @Test
    void cursoSalvaNaHora() {
        useCase.update(ALUNO, null, "Sistemas de Informação");

        assertThat(conta.getCourse()).isEqualTo("Sistemas de Informação");
    }

    /// Campo nulo = não foi pedida mudança nele. Aplicar tudo sobrescreveria
    /// com nulo o que o aluno não quis mexer.
    @Test
    void campoNuloNaoApagaOQueJaExistia() {
        useCase.update(ALUNO, "37988887777", null);

        assertThat(conta.getCourse()).isEqualTo("Engenharia");
    }

    /// Distinguir "não mandei" de "mandei vazio": o aluno que apaga o curso
    /// está pedindo pra limpar, e string vazia é o jeito de dizer isso.
    @Test
    void stringVaziaLimpaOCampo() {
        useCase.update(ALUNO, null, "   ");

        assertThat(conta.getCourse()).isNull();
    }

    @Test
    void tiraEspacoDasPontas() {
        useCase.update(ALUNO, "  37988887777 ", null);

        assertThat(conta.getPhone()).isEqualTo("37988887777");
    }

    /// O nome identifica na chamada do motorista: trocá-lo é virar outra pessoa
    /// na lista. Ele continua passando pelo admin, e não tem entrada aqui.
    @Test
    void naoMexeNoNome() {
        useCase.update(ALUNO, "37988887777", "Direito");

        assertThat(conta.getFullName()).isEqualTo("Fernanda Lima");
    }

    @Test
    void recusaUsuarioInexistente() {
        UUID sumido = UUID.randomUUID();
        when(userRepository.findById(sumido)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.update(sumido, "37988887777", null))
                .isInstanceOf(NotFoundException.class);
    }
}
