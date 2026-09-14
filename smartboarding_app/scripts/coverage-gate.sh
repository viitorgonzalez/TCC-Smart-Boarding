#!/usr/bin/env bash
# Gate de cobertura do app. Roda DEPOIS de `flutter test --coverage`.
#
# Catraca, nao atestado: os pisos ficam abaixo do valor atual e sobem de
# proposito. O lcov mede o que os testes carregam, e teste de tela arrasta o
# grafo de imports junto -- entao somar teste ABAIXA a porcentagem, e por isso
# o piso global tem mais folga que o da logica.
set -euo pipefail

# Em pt_BR o awk imprime "82,1" e relê como 82, perdendo a casa decimal.
export LC_ALL=C

LCOV="${1:-coverage/lcov.info}"
MIN_PCT="${MIN_PCT:-35}"
MIN_LOGIC_PCT="${MIN_LOGIC_PCT:-45}"
MIN_FILES="${MIN_FILES:-80}"

if [ ! -f "$LCOV" ]; then
  echo "gate de cobertura: $LCOV não encontrado (rodou 'flutter test --coverage'?)" >&2
  exit 1
fi

# Relatorio velho ja passou por verde aqui enquanto o CI reprovava.
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
# Sem este piso a trava premiaria apagar teste: menos arquivo no relatorio pode
# ate SUBIR a porcentagem.
if [ "$files" -lt "$MIN_FILES" ]; then
  echo "FALHOU: só ${files} arquivos medidos, mínimo ${MIN_FILES}." >&2
  echo "        Teste removido tira o arquivo do relatório e mascara a queda." >&2
  fail=1
fi

exit "$fail"
