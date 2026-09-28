package com.smartboarding.smartboarding_api.domain.stop;

import com.smartboarding.smartboarding_api.domain.stop.entity.Stop;

import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/// Qual parada é a do aluno, numa rota.
///
/// Função pura, fora de qualquer controller, porque duas telas fazem a mesma
/// pergunta: o acompanhamento do trajeto ("faltam X min até a sua
/// instituição") e o card da lista ("a viagem até a sua instituição leva X").
/// Duas cópias divergiriam na primeira mudança, e a divergência apareceria
/// como dois tempos diferentes pro mesmo aluno na mesma tela.
public record StudentStop(Stop stop, boolean fallback) {

    /// [fallback] verdadeiro quando a instituição do aluno não tem parada
    /// declarada e isto é a última do trajeto. Quem chama precisa avisar: um
    /// tempo até um lugar que não é o dele, sem aviso, é pior que tempo nenhum.
    ///
    /// Nulo quando a rota não tem ponto principal nenhum — aí não há o que
    /// prometer.
    public static StudentStop resolve(List<Stop> paradasDaRota, UUID institutionId) {
        List<Stop> principais = paradasDaRota.stream()
                .filter(Stop::isMainPoint)
                .sorted(Comparator.comparingInt(Stop::getSequence))
                .toList();
        if (principais.isEmpty()) return null;

        // A instituição principal do aluno é a mesma que decide em que
        // contagem ele entra na lista -- uma regra só no sistema inteiro.
        Stop dele = principais.stream()
                .filter(s -> s.getInstitutionId() != null
                        && s.getInstitutionId().equals(institutionId))
                .findFirst()
                .orElse(null);

        return dele != null
                ? new StudentStop(dele, false)
                : new StudentStop(principais.getLast(), true);
    }
}
