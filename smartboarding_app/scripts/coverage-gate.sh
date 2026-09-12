#!/usr/bin/env bash
# Gate de cobertura do app. Roda DEPOIS de `flutter test --coverage`.
#
# Por que os pisos são estes e não um número redondo: o lcov do Flutter mede o
# que os testes carregam, e um teste de tela arrasta o grafo de imports inteiro
# junto. Conforme a suíte cresceu (19 -> 154 testes), o denominador foi de 328
# pra 2664 linhas -- somar teste ABAIXA a porcentagem, porque cada teste novo
# traz mais código não coberto pro relatório do que cobre. Um piso alto fixado
# no vácuo só faria o gate ser desligado na primeira vez que atrapalhasse.
#
# Então o gate é uma catraca: os pisos ficam abaixo do valor atual e sobem de
# propósito, nunca por acidente. O que ele impede é regressão, não é atestar que
# o app está bem testado -- não está, e o número dizendo isso é honesto.
#
# A folga do piso global é de propósito e precisa ser maior que a da lógica:
# um teste de tela novo arrasta centenas de linhas não cobertas pro denominador
# e derruba a porcentagem em ponto percentual inteiro. Piso colado no valor
# atual reprovaria justamente quem escreveu teste a mais.
#
# Duas faixas, espelhando o JaCoCo da API (regra de negócio 90%, resto 70%):
# a lógica (providers/services/models/utils) é onde regressão dói, e tem piso
# próprio, mais alto que o global.
set -euo pipefail

# Locale fixo: em pt_BR o awk imprime "82,1" e depois lê esse mesmo texto como
# 82 na comparacao, perdendo a casa decimal. O gate passaria a depender do
# locale do runner.
export LC_ALL=C

LCOV="${1:-coverage/lcov.info}"
MIN_PCT="${MIN_PCT:-35}"
MIN_LOGIC_PCT="${MIN_LOGIC_PCT:-45}"
MIN_FILES="${MIN_FILES:-80}"

if [ ! -f "$LCOV" ]; then
  echo "gate de cobertura: $LCOV não encontrado (rodou 'flutter test --coverage'?)" >&2
  exit 1
fi

# Relatório velho é pior que relatório nenhum: foi assim que uma medição de
# horas antes passou por verde enquanto o CI reprovava.
if find "$LCOV" -mmin +60 | grep -q .; then
  echo "gate de cobertura: $LCOV tem mais de 1h -- rode 'flutter test --coverage' de novo." >&2
  exit 1
fi

medir() {
  awk -F: -v filtro="$1" '
    /^SF:/ { conta = (filtro == "" || index($0, filtro) > 0) }
    /^LH:/ { if (conta) lh += $2 }
    /^LF:/ { if (conta) { lf += $2; arquivos++ } }
    END { print lh+0, lf+0, arquivos+0 }
  ' "$LCOV"
}

pct() { awk -v c="$1" -v t="$2" 'BEGIN{ printf "%.1f", (t ? 100*c/t : 0) }'; }

read -r covered total files <<<"$(medir "")"
if [ "$total" -eq 0 ]; then
  echo "gate de cobertura: relatório sem linhas medidas" >&2
  exit 1
fi

# A lógica vive em quatro pastas; o lcov traz o caminho completo do arquivo.
logic_c=0; logic_t=0; logic_f=0
for pasta in /providers/ /services/ /models/ /utils/; do
  read -r c t f <<<"$(medir "$pasta")"
  logic_c=$((logic_c + c)); logic_t=$((logic_t + t)); logic_f=$((logic_f + f))
done

global_pct=$(pct "$covered" "$total")
logic_pct=$(pct "$logic_c" "$logic_t")

echo "Cobertura global:  ${global_pct}% (${covered}/${total} linhas, ${files} arquivos)"
echo "Cobertura lógica:  ${logic_pct}% (${logic_c}/${logic_t} linhas, ${logic_f} arquivos)"

fail=0
abaixo() { awk -v p="$1" -v m="$2" 'BEGIN{exit !(p < m)}'; }

if abaixo "$global_pct" "$MIN_PCT"; then
  echo "FALHOU: cobertura global ${global_pct}% abaixo do mínimo de ${MIN_PCT}%" >&2
  fail=1
fi
if abaixo "$logic_pct" "$MIN_LOGIC_PCT"; then
  echo "FALHOU: cobertura da lógica ${logic_pct}% abaixo do mínimo de ${MIN_LOGIC_PCT}%" >&2
  fail=1
fi
# Sem este piso a trava premiaria apagar teste: menos teste, menos arquivo no
# relatório, e a porcentagem pode até SUBIR.
if [ "$files" -lt "$MIN_FILES" ]; then
  echo "FALHOU: só ${files} arquivos medidos, mínimo ${MIN_FILES}." >&2
  echo "        Teste removido tira o arquivo do relatório e mascara a queda." >&2
  fail=1
fi

exit "$fail"
