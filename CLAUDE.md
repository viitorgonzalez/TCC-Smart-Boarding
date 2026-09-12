# CLAUDE.md — `TCC-Smart-Boarding`

Sistema de gestão de embarque no ônibus universitário da Unifor: o aluno cria a própria conta, entra numa rota com o código que o admin distribui e entra/sai da lista diária pelo app, o admin gerencia rotas/instituições/veículos e dispara push, e conduz o trajeto do ônibus (não há papel de motorista separado). Projeto de TCC (entrega oficial: início de novembro/2026).

> ℹ️ **A `main` é a fonte da verdade.** Alinhada em 08/09/2026 (PR #9) — o app Flutter e a API
> completa estão nela. Branches de feature saem da `main` e voltam pra ela.

## Duas aplicações, um repo

**Não é monorepo** — não há workspace tooling nem pacote compartilhado. São dois projetos independentes lado a lado, com toolchains distintos:

| Path | O que é | Toolchain |
|---|---|---|
| `smartboarding-api/` | Backend REST + scheduler + push | Java 21 · Spring Boot 4.0.5 · Maven |
| `smartboarding_app/` | App mobile (consome a API) | Flutter · Dart `^3.11.4` |

⚠️ O diretório do app é `smartboarding_app` com **underscore** (exigência de nome de package Dart), não hífen.

## Comandos

**API** — tudo roda de dentro de `smartboarding-api/` (⚠️ **o `pom.xml` não está na raiz do repo**):

```bash
docker compose up -d    # Postgres :5433 + pgAdmin :5050
./run-local.sh          # sobe a API em :8080  ← NÃO use ./mvnw spring-boot:run direto
./mvnw test              # unit
./mvnw verify             # unit + integration (Testcontainers, precisa de Docker)
```

**App** — de dentro de `smartboarding_app/`:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<ip-da-lan>:8080 \
            --dart-define=GOOGLE_WEB_CLIENT_ID=<id>.apps.googleusercontent.com
flutter build apk --release --dart-define=API_BASE_URL=... --dart-define=GOOGLE_WEB_CLIENT_ID=...
flutter test --coverage && ./scripts/coverage-gate.sh                    # unit + gate (catraca)
flutter test integration_test/ --dart-define=API_BASE_URL=http://10.0.2.2:8080  # e2e (API+Postgres locais, emulador rodando)
```

## Onde ficam as docs

| Arquivo | O quê |
|---|---|
| `smartboarding_app/docs/spec.md` | **Spec do Flutter** — arquitetura, papéis, regras de negócio. Leia antes de mexer no app. |
| `smartboarding_app/docs/PAGES.md` + `docs/specs/<categoria>/<tela>.md` | Índice de telas + uma spec por tela (contrato de API e regras específicas daquela tela), agrupadas por categoria (autenticacao/aluno/notificacoes/relatorios/administrador). |
| `smartboarding_app/docs/design/` | `design-system.md` (tokens) + `design-prompts/<categoria>/` (prompts de layout) + `figma-screens/` (referência visual do Figma). |
| `smartboarding-api/docs/spec.md` | **Spec do backend** — papéis, regras de negócio (RN1…), arquitetura hexagonal, entidades, contratos de API. Leia antes de mexer na API. |
| `smartboarding-api/CONTEXT.md` | Contexto de domínio do backend (problema, entidades, papéis) |
| `smartboarding-api/CLAUDE.md` | Convenções detalhadas de backend e Flutter |
| `smartboarding_app/docs/firebase-setup.md` | Ativação do FCM (passo manual, feito pelo usuário) |
| `docs/README.md` | **Índice da documentação** — o que está em qual pasta e o que vale como fonte da verdade. |
| `docs/superpowers/plans/` | Planos de implementação (app e backend), um por frente, com data. Histórico — a spec vence em caso de divergência. |

Spec nova vai **neste repo**, não no harness — contrato em `../personal-harness/docs/README.md`, template em `../personal-harness/templates/spec.md`.

## Armadilhas conhecidas

- **`./mvnw spring-boot:run` direto não funciona.** O `docker compose` lê o `.env` sozinho; o Maven **não**. Sem exportar as vars, o Spring recebe `${DB_USER}`/`${JWT_SECRET}` literais e quebra no boot. Use `./run-local.sh`.
- **`JWT_SECRET` precisa de ≥32 chars.** Secret curto falha no **boot**, e o stacktrace não aponta pro `.env`.
- **Postgres em `:5433`, não `:5432`** — hardcoded na URL do `application.properties`. Se a porta já estiver ocupada por outro projeto, o compose sobe mas a API não conecta (`docker stop postgres_gelo pgadmin_gelo` resolve o caso conhecido).
- **Pacotes seguem arquitetura hexagonal** (`domain/`, `application/`, `infrastructure/`, `shared/`) — não a flat capitalizada (`Models/`, `Controllers/`...) de versões antigas do projeto. Detalhe em `smartboarding-api/docs/spec.md` §4.1.
- **Nunca edite migration já aplicada.** Mudança de schema = `V3__...` nova. Editar quebra o checksum do Flyway e o boot falha.
- **Migration removida continua no `target/`.** O Maven não limpa resources órfãos: se você apagar/renomear um `V*.sql`, a cópia velha fica em `target/classes/db/migration/` e o Flyway aborta com `Found more than one migration with version N`. Rode `./mvnw clean test` — não é problema da migration nova.
- **`localhost` não resolve em device físico.** O `API_BASE_URL` precisa do IP da máquina na LAN.
- **Mudança de contrato é trabalho nos dois lados.** Alterar um DTO na API quase sempre exige mexer no `lib/features/<x>/` correspondente. Trate como uma unidade lógica só.

## Convenções

- **Branch default / base de PR:** `main`
- **Papéis:** `ADMIN`, `STUDENT` (ações de trajeto são do `ADMIN` — sem papel de motorista separado)
- **Estado no app:** Provider exclusivamente — sem BLoC, sem Riverpod
- **Segredos:** `.env` a partir de `.env.example` — nunca commitados. Override pessoal de config: `application-local.properties` (gitignored por convenção do repo). Hook local anti-hardcode: `git config core.hooksPath .githooks` (bloqueia commit com secret/token/senha literal — motivo em `.githooks/pre-commit`).
- **Perfis Spring:** `local` (default) e `prod` (`SPRING_PROFILES_ACTIVE=prod` — desliga SQL no log, `ddl-auto=validate`, esconde stacktrace, limita o pool).
- **Deploy:** ainda não há ambiente publicado, mas a API já está preparada: `Dockerfile` multi-stage (JRE + usuário sem privilégio), host/porta do banco externalizados (`DB_HOST`/`DB_PORT`, ou `SPRING_DATASOURCE_URL` inteiro) e `PORT` respeitado. Variáveis necessárias em `.env.prod.example`.
- Commit/branch/PR: ver `../personal-harness/docs/CONVENTIONS.md`
