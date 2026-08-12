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
    AGENTS.md
    PLAN.md
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
./mvnw test
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
flutter run --dart-define=API_BASE_URL=http://<ip-da-lan>:8080

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

- **Pacotes**: PascalCase — `Models/`, `Controllers/`, `Services/`, `Repositories/`, `DTO/`, `Configs/`, `Enums/`
- **Entidades**: JPA com `@Entity`, UUID como PK (`gen_random_uuid()` no SQL)
- **DTOs**: sempre usar DTOs para request/response, nunca expor a entidade diretamente
- **Migrations Flyway**: `V{n}__{descricao_snake_case}.sql` em `src/main/resources/db/migration/`
- **Roles**: `ADMIN`, `STUDENT`, `DRIVER` (adicionado na `V8__add_driver_user.sql`) — checar com `@PreAuthorize("hasRole('ADMIN')")` ou na SecurityConfig. O `DRIVER` só posta a notificação de saída: **não** tem acesso a rotas, usuários ou relatórios.
- **Controllers**: retornar `ResponseEntity<?>` com status HTTP explícito
- **Scheduler**: usar `@Scheduled` com cron expression, habilitar `@EnableScheduling` na config

## Convenções Flutter

- **Estado**: Provider exclusivamente — sem BLoC, sem Riverpod
- **HTTP**: Dio com interceptor JWT injetando Bearer token em toda requisição
- **Autenticação**: JWT armazenado em SharedPreferences; nunca armazenar senha
- **Models**: sempre com `fromJson(Map<String, dynamic> json)` e `toJson()`
- **Separação**: `services/` fazem chamadas HTTP e retornam dados brutos; `providers/` gerenciam estado e chamam services

## Regras de Negócio Críticas

1. Listas abrem às **00:00** (seg-sex) e fecham às **16:00** automaticamente via scheduler
2. Entre **16:01–23:59** não há lista ativa — estudante não pode se inscrever
3. Ao fechar (16:00): gerar Report + FCM broadcast para todos os inscritos
4. Estudante só pode ter **uma inscrição ativa** por lista (`UNIQUE(user_id, daily_list_id)`)
5. Ao sair da lista: soft-delete (`isActive = false`), não deletar o registro

## Endpoints Principais

| Método | Path | Role | Descrição |
|--------|------|------|-----------|
| POST | `/api/auth/login` | Público | Login JWT |
| POST | `/api/auth/register` | ADMIN | Cadastrar usuário |
| GET | `/api/routes` | ALL | Listar rotas ativas |
| POST | `/api/routes` | ADMIN | Criar rota |
| GET | `/api/lists/today` | ALL | Lista do dia |
| POST | `/api/lists/{id}/entries` | STUDENT | Inscrever-se |
| DELETE | `/api/lists/{id}/entries` | STUDENT | Sair da lista |
| GET | `/api/reports` | ADMIN | Histórico de relatórios |
| POST | `/api/notifications/broadcast` | ADMIN | Enviar push a todos |
| POST | `/api/devices/token` | ALL | Registrar token FCM |

## Firebase

- Backend usa **Firebase Admin SDK** (`firebase-admin` no pom.xml)
- Flutter usa **firebase_messaging** para receber push
- Credenciais do servidor: service account JSON em `FIREBASE_CREDENTIALS_PATH`
- Configuração Flutter: `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
