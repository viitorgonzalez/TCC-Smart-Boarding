package com.smartboarding.smartboarding_api.infrastructure.auth;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PepperedPasswordEncoderTest {

    private static final String PEPPER_A = "pepper-de-teste-com-32-bytes-ou-mais-aa";
    private static final String PEPPER_B = "outro-pepper-de-teste-com-32-bytes-ou-mais";

    @Test
    void senhaCodificadaBateComAMesmaSenhaCrua() {
        var encoder = new PepperedPasswordEncoder(PEPPER_A);

        String hash = encoder.encode("minhaSenha123");

        assertThat(encoder.matches("minhaSenha123", hash)).isTrue();
    }

    @Test
    void senhaErradaNaoBate() {
        var encoder = new PepperedPasswordEncoder(PEPPER_A);

        String hash = encoder.encode("minhaSenha123");

        assertThat(encoder.matches("senhaErrada", hash)).isFalse();
    }

    @Test
    void pepperDiferenteNaoReconheceOMesmoHash() {
        var comPepperA = new PepperedPasswordEncoder(PEPPER_A);
        var comPepperB = new PepperedPasswordEncoder(PEPPER_B);

        String hash = comPepperA.encode("minhaSenha123");

        assertThat(comPepperB.matches("minhaSenha123", hash)).isFalse();
    }

    @Test
    void formatoDoHashEArgon2id() {
        var encoder = new PepperedPasswordEncoder(PEPPER_A);

        String hash = encoder.encode("minhaSenha123");

        assertThat(hash).startsWith("$argon2id$");
    }

    @Test
    void duasCodificacoesDaMesmaSenhaGeramHashesDiferentes() {
        var encoder = new PepperedPasswordEncoder(PEPPER_A);

        String hash1 = encoder.encode("minhaSenha123");
        String hash2 = encoder.encode("minhaSenha123");

        assertThat(hash1).isNotEqualTo(hash2);
        assertThat(encoder.matches("minhaSenha123", hash1)).isTrue();
        assertThat(encoder.matches("minhaSenha123", hash2)).isTrue();
    }

    @Test
    void pepperCurtoDemaisEstouraNoBoot() {
        assertThatThrownBy(() -> new PepperedPasswordEncoder("curto-demais"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("32 bytes");
    }

    @Test
    void pepperNuloEstouraNoBoot() {
        assertThatThrownBy(() -> new PepperedPasswordEncoder(null))
                .isInstanceOf(IllegalStateException.class);
    }
}
