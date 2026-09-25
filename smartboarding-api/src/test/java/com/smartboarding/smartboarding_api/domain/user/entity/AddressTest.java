package com.smartboarding.smartboarding_api.domain.user.entity;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AddressTest {

    private static Address.AddressBuilder completo() {
        return Address.builder()
                .zipCode("35570-000")
                .street("Av. Dr. Arnaldo de Senna")
                .neighborhood("Água Vermelha")
                .city("Formiga")
                .state("MG")
                .streetNumber("328");
    }

    @Test
    void completoQuandoTemCepRuaBairroENumero() {
        assertThat(completo().build().isComplete()).isTrue();
    }

    @Test
    void complementoNaoEObrigatorio() {
        assertThat(completo().complement(null).build().isComplete()).isTrue();
    }

    @Test
    void incompletoSemNumero() {
        assertThat(completo().streetNumber(null).build().isComplete()).isFalse();
    }

    @Test
    void incompletoSemRua() {
        assertThat(completo().street(null).build().isComplete()).isFalse();
    }

    @Test
    void incompletoSemBairro() {
        assertThat(completo().neighborhood(null).build().isComplete()).isFalse();
    }

    @Test
    void incompletoSemCep() {
        assertThat(completo().zipCode(null).build().isComplete()).isFalse();
    }

    /// Campo em branco é o que um formulário manda quando o usuário toca e sai
    /// sem digitar. Contar como preenchido deixaria passar endereço vazio.
    @Test
    void espacoEmBrancoNaoContaComoPreenchido() {
        assertThat(completo().streetNumber("   ").build().isComplete()).isFalse();
    }

    @Test
    void enderecoInteiroNuloEIncompleto() {
        assertThat(new Address().isComplete()).isFalse();
    }

    @Test
    void formaCurtaTrazRuaNumeroEBairro() {
        assertThat(completo().build().shortForm())
                .isEqualTo("Av. Dr. Arnaldo de Senna, 328 — Água Vermelha");
    }

    /// A carteirinha se mostra pra outra pessoa. CEP e cidade não ajudam numa
    /// conferência presencial e não precisam circular numa tela dessas.
    @Test
    void formaCurtaNaoExpoeCepNemCidade() {
        assertThat(completo().build().shortForm())
                .doesNotContain("35570")
                .doesNotContain("Formiga")
                .doesNotContain("MG");
    }

    @Test
    void formaCurtaIncluiOComplementoQuandoExiste() {
        assertThat(completo().complement("Apto 12").build().shortForm())
                .isEqualTo("Av. Dr. Arnaldo de Senna, 328, Apto 12 — Água Vermelha");
    }

    @Test
    void formaCompletaTrazCidadeEstadoECep() {
        assertThat(completo().build().fullForm())
                .isEqualTo("Av. Dr. Arnaldo de Senna, 328 — Água Vermelha, Formiga/MG — 35570-000");
    }

    @Test
    void formaCompletaTambemEVaziaQuandoIncompleto() {
        assertThat(completo().zipCode(null).build().fullForm()).isEmpty();
    }

    /// Endereço incompleto não rende linha parcial: quem chama decide o que
    /// mostrar no lugar, e meia linha numa carteirinha parece dado perdido.
    @Test
    void formaCurtaEVaziaQuandoOEnderecoEIncompleto() {
        assertThat(completo().street(null).build().shortForm()).isEmpty();
    }
}
