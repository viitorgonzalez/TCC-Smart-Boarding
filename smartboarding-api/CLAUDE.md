# SmartBoarding — Guia Claude Code

## O Projeto

Sistema de gerenciamento de embarque em ônibus universitário (Unifor). Estudantes entram/saem de listas diárias automáticas via app Flutter. Admin gerencia rotas e envia notificações push. Backend Spring Boot + FCM Firebase.

## Estrutura do Repo

Duas aplicações independentes lado a lado (**não é monorepo** — sem workspace tooling nem pacote compartilhado):

```
TCC-Smart-Boarding/
  CLAUDE.md             # mapa do repo (leia primeiro)
  smartboarding-api/    # Backend Spring Boot
    CLAUDE.md           # este arquivo
    CONTEXT.md
    docs/spec.md        # spec do backend (papéis, RN, contratos, gaps)
  smartboarding_app/    # App Flutter — ⚠️ underscore, e JÁ IMPLEMENTADO
    docs/spec.md        # spec principal do produto
```

## Como Rodar o Backend

```bash
cd smartboarding-api

# 1. Subir banco (PostgreSQL + pgAdmin)
docker compose up -d

# 2. Configurar variáveis de ambiente
cp .env.example .env
# Editar .env com DB_NAME, DB_USER, DB_PASSWORD, JWT_SECRET, FIREBASE_CREDENTIALS_PATH

# 3. Rodar a aplicação
./run-local.sh    # ⚠️ NÃO use ./mvnw spring-boot:run direto:
                  # o compose lê o .env sozinho, o Maven não. Sem exportar as
                  # vars o Spring recebe ${DB_USER} literal e quebra no boot.

# 4. Rodar testes
./mvnw test      # unit — rápido, sem Docker
./mvnw verify     # unit + integration + GATE de cobertura — sobe Postgres via Testcontainers, precisa de Docker

# 5. Cobertura (unit)
./mvnw test && open target/site/jacoco/index.html   # (ou xdg-open no Linux)
# O `verify` REPROVA abaixo de 90% em application.* e 70% no resto.
# Entidade, DTO e config ficam fora do gate (record/Lombok sem ramo).
```

A API sobe em `http://localhost:8080`. Flyway aplica as migrations automaticamente.

## Como Rodar o Flutter

```bash
cd smartboarding_app

# Instalar dependências
flutter pub get

# Rodar no emulador/dispositivo
# ⚠️ a base URL vem de --dart-define; em device físico use o IP da LAN,
#    localhost não resolve pro seu host.
flutter run --dart-define=API_BASE_URL=http://<ip-da-lan>:8080 \
            --dart-define=GOOGLE_WEB_CLIENT_ID=<id>.apps.googleusercontent.com

# Build APK
flutter build apk --release
```

## Variáveis de Ambiente Necessárias

| Variável | Descrição |
|----------|-----------|
| `DB_NAME` | Nome do banco PostgreSQL |
| `DB_USER` | Usuário do banco |
| `DB_PASSWORD` | Senha do banco |
| `JWT_SECRET` | Chave JWT (mínimo 32 chars) |
| `FIREBASE_CREDENTIALS_PATH` | Caminho para o service account JSON do Firebase |

## Convenções Backend (Spring Boot)

- **Pacotes**: arquitetura **hexagonal** (ports & adapters), não a flat capitalizada de versões
  antigas deste doc — `domain/<contexto>/{entity,port/in,port/out}`,
  `application/<contexto>/*UseCaseImpl`, `infrastructure/web/<contexto>/*Controller` (+ `dto/`),
  `infrastructure/config/`, `shared/{exception,web}/`. Detalhe completo em `docs/spec.md` §4.
- **Entidades**: JPA com `@Entity`, UUID como PK (`gen_random_uuid()` no SQL)
- **DTOs**: sempre usar DTOs para request/response, nunca expor a entidade diretamente
- **Migrations Flyway**: `V{n}__{descricao_snake_case}.sql` em `src/main/resources/db/migration/`.
  Consolidadas em `V1__initial_schema.sql` + `V2__seed_data.sql` (12/08/2026) — próxima é `V3+`.
- **Roles**: `ADMIN`, `STUDENT` — coluna `role` (`VARCHAR(20)`, sem `CHECK`, validada na
  aplicação). Checar com `@PreAuthorize("hasRole('ADMIN')")` ou na `SecurityConfig`. Ações de
  trajeto (iniciar/checkpoint/finalizar) são do `ADMIN` — não existe papel de motorista separado
  (`docs/spec.md` §4.7).
- **Controllers**: retornar `ResponseEntity<?>` com status HTTP explícito
- **Scheduler**: usar `@Scheduled` com cron expression, habilitar `@EnableScheduling` na config

## Convenções Flutter

- **Estado**: Provider exclusivamente — sem BLoC, sem Riverpod
- **HTTP**: Dio com interceptor JWT injetando Bearer token em toda requisição
- **Autenticação**: JWT armazenado em SharedPreferences; nunca armazenar senha
- **Models**: sempre com `fromJson(Map<String, dynamic> json)` e `toJson()`
- **Separação**: `services/` fazem chamadas HTTP e retornam dados brutos; `providers/` gerenciam estado e chamam services

## Regras de Negócio Críticas

Resumo — detalhe e numeração (RN1…) em `docs/spec.md` §3.

1. Abertura e fechamento são **por rota** (`routes.open_time` default 00:00, `routes.close_time`
   default 16:00, ambos editáveis) — uma varredura a cada 5 min (seg-sex) abre as listas do dia e
   fecha as que já passaram do horário
2. Inscrição só vale na lista **de hoje** e **antes do `closeTime` da rota** — validado contra o
   relógio no use case, não só pela flag `status` (`400 LIST_CLOSED` / `400 LIST_NOT_TODAY`)
3. Ao fechar: gerar Report + FCM broadcast para todos os inscritos
4. Uma inscrição por (usuário, lista) — `UNIQUE(user_id, daily_list_id)`. Reentrar **reativa** o
   registro existente (idempotente, não retorna 409)
5. Ao sair da lista: soft-delete (`isActive = false`), não deletar o registro
6. Cada inscrição tem `tripType` (`ROUND_TRIP`/`TO_CAMPUS`/`FROM_CAMPUS`)

## Endpoints

Contrato completo (request/response/erros por endpoint) em `docs/spec.md` §6 — não duplicado
aqui pra não divergir de novo. ⚠️ `POST/DELETE /api/lists/{id}/entries` hoje libera **qualquer**
papel autenticado (não só `STUDENT`) — ver `docs/spec.md` §2.

## Firebase

- Backend usa **Firebase Admin SDK** (`firebase-admin` no pom.xml)
- Flutter usa **firebase_messaging** para receber push
- Credenciais do servidor: service account JSON em `FIREBASE_CREDENTIALS_PATH`
- Configuração Flutter: `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
