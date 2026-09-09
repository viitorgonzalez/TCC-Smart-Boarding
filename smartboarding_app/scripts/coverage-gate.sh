#!/usr/bin/env bash
# Gate de cobertura do app. Roda depois de `flutter test --coverage`.
#
# O lcov do Flutter só lista arquivo que algum teste importou -- hoje 34 dos 126
# em lib/. A porcentagem abaixo é, portanto, sobre o subconjunto testado, não
# sobre o app inteiro. Isso deixa uma brecha: apagar um teste tira o arquivo do
# relatório e pode SUBIR a porcentagem. Por isso o gate também exige um número
# mínimo de arquivos medidos -- sem ele, a trava premiaria remover teste. O piso
# fica um pouco abaixo do número atual pra não reprovar refactor que funde
# arquivos, mas ainda pegar remoção em massa.
set -euo pipefail

# Locale fixo: em pt_BR o awk imprime "82,1" e depois lê esse mesmo texto como
# 82 na comparacao, perdendo a casa decimal. O gate passaria a depender do
# locale do runner.
export LC_ALL=C

LCOV="${1:-coverage/lcov.info}"
MIN_PCT="${MIN_PCT:-70}"
MIN_FILES="${MIN_FILES:-28}"

if [ ! -f "$LCOV" ]; then
  echo "gate de cobertura: $LCOV não encontrado (rodou 'flutter test --coverage'?)" >&2
  exit 1
fi

read -r covered total files <<<"$(awk -F: '
  /^SF:/ {files++}
  /^LH:/ {lh+=$2}
  /^LF:/ {lf+=$2}
  END {print lh, lf, files}
' "$LCOV")"

if [ "${total:-0}" -eq 0 ]; then
  echo "gate de cobertura: relatório sem linhas medidas" >&2
  exit 1
fi

pct=$(awk -v c="$covered" -v t="$total" 'BEGIN{printf "%.1f", 100*c/t}')

echo "Cobertura (arquivos testados): ${pct}% (${covered}/${total} linhas, ${files} arquivos)"

fail=0
if awk -v p="$pct" -v m="$MIN_PCT" 'BEGIN{exit !(p < m)}'; then
  echo "FALHOU: cobertura ${pct}% abaixo do mínimo de ${MIN_PCT}%" >&2
  fail=1
fi
if [ "$files" -lt "$MIN_FILES" ]; then
  echo "FALHOU: só ${files} arquivos medidos, mínimo ${MIN_FILES}." >&2
  echo "        Teste removido tira o arquivo do relatório e mascara a queda." >&2
  fail=1
fi

exit "$fail"
