#!/usr/bin/env bash
# Sobe o backend carregando as variáveis do .env no ambiente.
#
# Por que existe: o `docker compose` lê o .env automaticamente, mas o
# `./mvnw spring-boot:run` NÃO. Sem exportar as variáveis, o Spring recebe
# ${DB_USER}/${JWT_SECRET} literais e falha na conexão/boot.
#
# Uso:
#   1) suba o Postgres:  docker compose up -d
#      (se o outro projeto estiver usando a porta 5433:
#       docker stop postgres_gelo pgadmin_gelo)
#   2) rode:             ./run-local.sh
#
# Requisitos no .env: DB_NAME, DB_USER, DB_PASSWORD, JWT_SECRET (>=32 chars).

set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "ERRO: .env não encontrado em $(pwd). Copie de .env.example e preencha." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
. ./.env
set +a

# `dev` traz o dado de demonstracao; `local` fica pro override pessoal
# (gitignored). A base carrega so o schema de proposito, entao sem este perfil
# o banco sobe vazio -- que e o que producao faz.
export SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-local,dev}"

exec ./mvnw spring-boot:run
