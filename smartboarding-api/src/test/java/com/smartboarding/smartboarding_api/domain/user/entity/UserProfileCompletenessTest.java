package com.smartboarding.smartboarding_api.domain.user.entity;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/// O que a entrada na lista exige do perfil.
///
/// Mora no domínio e não no controller porque o use case precisa da mesma
/// resposta -- duas versões da regra divergiriam na primeira mudança.
class UserProfileCompletenessTest {

    private static Address enderecoCompleto() {
        return Address.builder()
                .zipCode("35570-000").street("Av. Dr. Arnaldo de Senna")
                .neighborhood("Água Vermelha").streetNumber("328").build();
    }

    private static User.UserBuilder completo() {
        return User.builder()
                .fullName("Fernanda Lima")
                .phone("37999990000")
                .address(enderecoCompleto())
                .institutionId(UUID.randomUUID());
    }

    @Test
    void perfilCompletoNaoTemPendencia() {
        assertThat(completo().build().missingForList()).isEmpty();
    }

    @Test
    void semTelefoneApontaOTelefone() {
        assertThat(completo().phone(null).build().missingForList())
                .containsExactly("phone");
    }

    @Test
    void semEnderecoCompletoApontaOEndereco() {
        assertThat(completo().address(new Address()).build().missingForList())
                .containsExactly("address");
    }

    /// Endereço pela metade é tão inútil quanto vazio: o motorista continua sem
    /// saber onde parar.
    @Test
    void enderecoSemNumeroAindaConta() {
        Address semNumero = enderecoCompleto();
        semNumero.setStreetNumber(null);

        assertThat(completo().address(semNumero).build().missingForList())
                .containsExactly("address");
    }

    @Test
    void semInstituicaoApontaAInstituicao() {
        assertThat(completo().institutionId(null).build().missingForList())
                .containsExactly("institution");
    }

    @Test
    void semNomeApontaONome() {
        assertThat(completo().fullName("  ").build().missingForList())
                .containsExactly("fullName");
    }

    /// A mensagem genérica obriga o aluno a adivinhar. Faltando três coisas,
    /// ele precisa das três de uma vez, não de uma descoberta por tentativa.
    @Test
    void listaTodasAsPendenciasDeUmaVez() {
        User cru = User.builder().build();

        assertThat(cru.missingForList())
                .containsExactly("fullName", "phone", "address", "institution");
    }

    /// Descrevem a pessoa, não a operação do transporte. Exigi-los travaria
    /// alguém fora do ônibus por um campo que ninguém usa no dia da viagem.
    @Test
    void nascimentoECursoNaoImpedem() {
        User semOpcionais = completo().birthDate(null).course(null).build();

        assertThat(semOpcionais.missingForList()).isEmpty();
    }

    @Test
    void nascimentoECursoPreenchidosTambemNaoAparecem() {
        User comTudo = completo()
                .birthDate(LocalDate.of(2004, 5, 10)).course("Engenharia").build();

        assertThat(comTudo.missingForList()).isEmpty();
    }
}
