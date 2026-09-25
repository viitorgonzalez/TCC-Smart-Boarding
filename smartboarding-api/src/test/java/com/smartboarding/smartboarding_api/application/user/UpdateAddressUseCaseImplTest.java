package com.smartboarding.smartboarding_api.application.user;

import com.smartboarding.smartboarding_api.domain.user.entity.Address;
import com.smartboarding.smartboarding_api.domain.user.entity.User;
import com.smartboarding.smartboarding_api.domain.user.port.out.UserRepositoryPort;
import com.smartboarding.smartboarding_api.shared.exception.BadRequestException;
import com.smartboarding.smartboarding_api.shared.exception.NotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class UpdateAddressUseCaseImplTest {

    private static final UUID ALUNO = UUID.randomUUID();

    @Mock UserRepositoryPort userRepository;

    private UpdateAddressUseCaseImpl useCase;
    private User conta;

    private static Address.AddressBuilder endereco() {
        return Address.builder()
                .zipCode("35570-000")
                .street("Av. Dr. Arnaldo de Senna")
                .neighborhood("Água Vermelha")
                .city("Formiga")
                .state("MG")
                .streetNumber("328");
    }

    @BeforeEach
    void setUp() {
        useCase = new UpdateAddressUseCaseImpl(userRepository);
        conta = User.builder().id(ALUNO).email("fernanda@edu.unifor.br").build();
        when(userRepository.findById(ALUNO)).thenReturn(Optional.of(conta));
        when(userRepository.save(org.mockito.ArgumentMatchers.any(User.class)))
                .thenAnswer(i -> i.getArgument(0));
    }

    private Address salvo() {
        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        return captor.getValue().getAddress();
    }

    /// O ponto da mudança: o aluno escreve o próprio endereço. Passar pela fila
    /// de aprovação o deixaria bloqueado da lista até um admin agir.
    @Test
    void salvaDiretoSemPassarPorAprovacao() {
        useCase.update(ALUNO, endereco().build());

        assertThat(salvo().getStreet()).isEqualTo("Av. Dr. Arnaldo de Senna");
        assertThat(salvo().isComplete()).isTrue();
    }

    @Test
    void formataOCepQueChegouSoComDigitos() {
        useCase.update(ALUNO, endereco().zipCode("35570000").build());

        assertThat(salvo().getZipCode()).isEqualTo("35570-000");
    }

    @Test
    void recusaCepQueNaoTemOitoDigitos() {
        assertThatThrownBy(() -> useCase.update(ALUNO, endereco().zipCode("3557").build()))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("CEP");
    }

    @Test
    void aceitaUfEmMinusculaEGuardaEmMaiuscula() {
        useCase.update(ALUNO, endereco().state("mg").build());

        assertThat(salvo().getState()).isEqualTo("MG");
    }

    @Test
    void tiraEspacoDasPontas() {
        useCase.update(ALUNO, endereco().streetNumber("  328 ").build());

        assertThat(salvo().getStreetNumber()).isEqualTo("328");
    }

    /// Salvar pela metade é permitido de propósito: quem descobriu o CEP mas
    /// ainda não sabe o número volta depois. Quem cobra o endereço completo é
    /// a entrada na lista, num lugar só.
    @Test
    void aceitaEnderecoAindaIncompleto() {
        useCase.update(ALUNO, Address.builder().zipCode("35570-000").build());

        assertThat(salvo().isComplete()).isFalse();
        assertThat(salvo().getZipCode()).isEqualTo("35570-000");
    }

    /// Campo em branco vira nulo: guardar "" faria isComplete() ter que saber
    /// de duas formas de vazio, e uma delas ia escapar.
    @Test
    void campoEmBrancoViraNulo() {
        useCase.update(ALUNO, endereco().complement("   ").build());

        assertThat(salvo().getComplement()).isNull();
    }

    @Test
    void recusaUsuarioInexistente() {
        UUID sumido = UUID.randomUUID();
        when(userRepository.findById(sumido)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> useCase.update(sumido, endereco().build()))
                .isInstanceOf(NotFoundException.class);
    }
}
