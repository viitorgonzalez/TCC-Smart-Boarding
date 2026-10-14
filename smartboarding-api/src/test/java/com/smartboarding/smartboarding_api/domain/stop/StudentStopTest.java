package com.smartboarding.smartboarding_api.domain.stop;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class StudentStopTest {

    private static final UUID UNIFOR = UUID.randomUUID();
    private static final UUID IFMG = UUID.randomUUID();

    private static Stop parada(String nome, int seq, boolean principal, UUID inst) {
        return Stop.builder().id(UUID.randomUUID()).name(nome).sequence(seq)
                .isMainPoint(principal).institutionId(inst).build();
    }

    private static List<Stop> rota() {
        return List.of(
                parada("Rodoviária", 1, true, null),
                parada("Av. Jair Leite", 2, false, null),
                parada("UNIFOR-MG", 3, true, UNIFOR),
                parada("IFMG", 4, true, IFMG));
    }

    @Test
    void achaAParadaDaInstituicaoDoAluno() {
        var r = StudentStop.resolve(rota(), UNIFOR);

        assertThat(r.stop().getName()).isEqualTo("UNIFOR-MG");
        assertThat(r.fallback()).isFalse();
    }

    @Test
    void alunosDeInstituicoesDiferentesCaemEmParadasDiferentes() {
        assertThat(StudentStop.resolve(rota(), UNIFOR).stop().getName()).isEqualTo("UNIFOR-MG");
        assertThat(StudentStop.resolve(rota(), IFMG).stop().getName()).isEqualTo("IFMG");
    }

    @Test
    void semParadaDaInstituicaoCaiNaUltimaEAvisa() {
        var r = StudentStop.resolve(rota(), UUID.randomUUID());

        assertThat(r.stop().getName()).isEqualTo("IFMG");
        assertThat(r.fallback()).isTrue();
    }

    @Test
    void alunoSemInstituicaoTambemCaiNoFallback() {
        assertThat(StudentStop.resolve(rota(), null).fallback()).isTrue();
    }

    @Test
    void paradaComumNuncaEEscolhida() {
        var so = List.of(parada("Av. Jair Leite", 1, false, UNIFOR));

        assertThat(StudentStop.resolve(so, UNIFOR)).isNull();
    }

    @Test
    void rotaSemParadaNenhumaDevolveNulo() {
        assertThat(StudentStop.resolve(List.of(), UNIFOR)).isNull();
    }

    @Test
    void oFallbackRespeitaAOrdemDoTrajetoNaoADeCadastro() {
        var foraDeOrdem = List.of(
                parada("IFMG", 4, true, IFMG),
                parada("Rodoviária", 1, true, null));

        assertThat(StudentStop.resolve(foraDeOrdem, UUID.randomUUID()).stop().getName())
                .isEqualTo("IFMG");
    }
}
