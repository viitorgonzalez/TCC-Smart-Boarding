# SmartBoarding API — Documentação Técnica

> Sistema de gerenciamento de embarque em ônibus universitário (Unifor).  
> Backend: Spring Boot 4.0.5 · Java 21 · PostgreSQL 16 · JWT (HS256) · FCM

---

## 1. Arquitetura

### Estilo: Hexagonal (Ports & Adapters) + DDD

```
┌─────────────────────────────────────────────────────────────┐
│  infrastructure/web        (Controllers, DTOs)              │
│  infrastructure/persistence (JPA Entities, Adapters)        │
│  infrastructure/config      (Security, JWT, Firebase)       │
│  infrastructure/fcm         (FcmAdapter)                    │
│                    ↕ via ports (interfaces)                 │
│  application/               (Use Case Implementations)      │
│                    ↕ via ports (interfaces)                 │
│  domain/                    (Entities POJO, Ports)          │
└─────────────────────────────────────────────────────────────┘
```

**Regra de dependência:** `infrastructure → application → domain`. O domínio não conhece nenhuma camada externa.

### Pacotes

```
com.smartboarding.smartboarding_api
├── domain/
│   ├── user/entity/          User.java, Role.java
│   ├── user/port/in/         LoginUseCase, RegisterUseCase, FindUserUseCase
│   ├── user/port/out/        UserRepositoryPort
│   ├── route/entity/         Route.java
│   ├── route/port/in/        CreateRouteUseCase, FindRouteUseCase, UpdateRouteUseCase, DeleteRouteUseCase
│   ├── route/port/out/       RouteRepositoryPort
│   ├── list/entity/          DailyList.java, ListEntry.java, ListStatus.java
│   ├── list/port/in/         OpenDailyListsUseCase, CloseDailyListsUseCase, FindListUseCase,
│   │                         AddEntryUseCase, RemoveEntryUseCase
│   ├── list/port/out/        DailyListRepositoryPort, ListEntryRepositoryPort
│   ├── report/entity/        Report.java
│   ├── report/port/in/       GenerateReportUseCase, FindReportUseCase
│   ├── report/port/out/      ReportRepositoryPort
│   ├── notification/entity/  DeviceToken.java
│   └── notification/port/    RegisterDeviceTokenUseCase, RemoveDeviceTokenUseCase,
│                             SendToUserUseCase, SendBroadcastUseCase,
│                             DeviceTokenRepositoryPort, FcmPort
│
├── application/
│   ├── user/     AuthUseCaseImpl, UserUseCaseImpl, AuthToken
│   ├── route/    RouteUseCaseImpl
│   ├── list/     ListUseCaseImpl, SchedulerUseCaseImpl
│   ├── report/   ReportUseCaseImpl
│   └── notification/ DeviceTokenUseCaseImpl, NotificationUseCaseImpl
│
├── infrastructure/
│   ├── config/       SecurityConfig, JwtConfig, FirebaseConfig, SchedulingConfig, AppConfig
│   ├── persistence/
│   │   ├── user/     UserJpaEntity, UserJpaRepository, UserMapper, UserRepositoryAdapter
│   │   ├── route/    RouteJpaEntity, RouteJpaRepository, RouteMapper, RouteRepositoryAdapter
│   │   ├── list/     DailyListJpaEntity, DailyListJpaRepository, DailyListMapper, DailyListRepositoryAdapter
│   │   │             ListEntryJpaEntity, ListEntryJpaRepository, ListEntryMapper, ListEntryRepositoryAdapter
│   │   ├── report/   ReportJpaEntity, ReportJpaRepository, ReportMapper, ReportRepositoryAdapter
│   │   └── notification/ DeviceTokenJpaEntity, DeviceTokenJpaRepository, DeviceTokenMapper, DeviceTokenRepositoryAdapter
│   ├── fcm/          FcmAdapter
│   └── web/
│       ├── common/   GlobalExceptionHandler
│       ├── user/     AuthController, UserController + DTOs
│       ├── route/    RouteController + DTOs
│       ├── list/     ListController + DTOs
│       ├── report/   ReportController + DTOs
│       └── notification/ DeviceController, NotificationController + DTOs
│
└── shared/
    ├── exception/    AppException, NotFoundException, BadRequestException,
    │                 UnauthorizedException, ConflictException
    └── web/          ApiResponse<T>
```

### Padrão JPA (FK por UUID)

Entidades JPA usam UUID direto para writes + `insertable=false, updatable=false` para reads, evitando `TransientPropertyValueException`:

```java
@Column(name = "route_id")          UUID routeId;          // FK — write
@ManyToOne @JoinColumn(name = "route_id", insertable=false, updatable=false)
RouteJpaEntity route;                                       // relação — read (EAGER)
```

---

## 2. Banco de Dados

### Schema

```sql
users
  id UUID PK, email VARCHAR(100) UNIQUE, password VARCHAR(255),
  role VARCHAR(20), full_name VARCHAR(150), birth_date DATE,
  course VARCHAR(100), institution VARCHAR(100), phone VARCHAR(20),
  address TEXT, expiry_date DATE, is_active BOOL, created_at TS, updated_at TS

routes
  id UUID PK, name VARCHAR(100), description VARCHAR(255),
  is_active BOOL, created_at TS, updated_at TS

daily_lists
  id UUID PK, route_id UUID FK(routes), date DATE, status VARCHAR(10),
  closed_at TS
  UNIQUE(route_id, date)

list_entries
  id UUID PK, user_id UUID FK(users), daily_list_id UUID FK(daily_lists),
  created_at TS, is_active BOOL
  UNIQUE(user_id, daily_list_id)

reports
  id UUID PK, daily_list_id UUID FK(daily_lists) UNIQUE,
  generated_at TS, total_entries INT, snapshot_data TEXT

device_tokens
  id UUID PK, user_id UUID FK(users), token VARCHAR(500) UNIQUE,
  platform VARCHAR(10), created_at TS, updated_at TS
  INDEX(user_id)
```

### Relacionamentos

```
routes ──< daily_lists ──< list_entries >── users
                │
                └──< reports
users ──< device_tokens
```

### Migrations (Flyway)

| Arquivo | Conteúdo |
|---------|----------|
| `V1__create_schema.sql` | Criação das 6 tabelas com constraints e indexes |
| `V2__seed_data.sql` | 3 usuários iniciais (1 ADMIN, 2 STUDENT) |

---

## 3. Segurança

### Autenticação

- **Tipo:** JWT HS256 (stateless)
- **Expiração:** 1 hora
- **Header:** `Authorization: Bearer <token>`
- **Claim principal:** `sub` = email do usuário; `scope` = role sem prefixo
- **Secret:** mínimo 32 bytes (validado no startup via `@PostConstruct`)

### Roles

| Role | Acesso |
|------|--------|
| `ADMIN` | Tudo |
| `STUDENT` | Listas (ver/inscrever/sair), dispositivos |
| Sem auth | `GET /api/routes`, `GET /api/routes/{id}`, `POST /api/auth/login` |

### Mapa de acesso por endpoint

| Método | Path | Acesso |
|--------|------|--------|
| POST | `/api/auth/login` | Público |
| POST | `/api/auth/register` | ADMIN |
| GET | `/api/users` | ADMIN |
| GET | `/api/users/{id}` | ADMIN |
| GET | `/api/routes` | Público |
| GET | `/api/routes/{id}` | Público |
| POST | `/api/routes` | ADMIN |
| PATCH | `/api/routes/{id}` | ADMIN |
| DELETE | `/api/routes/{id}` | ADMIN |
| GET | `/api/lists/today` | Autenticado |
| GET | `/api/lists/{id}` | Autenticado |
| POST | `/api/lists/{id}/entries` | Autenticado |
| DELETE | `/api/lists/{id}/entries` | Autenticado |
| GET | `/api/lists/{id}/entries` | ADMIN |
| GET | `/api/reports` | ADMIN |
| GET | `/api/reports/{id}` | ADMIN |
| POST | `/api/notifications/broadcast` | ADMIN |
| POST | `/api/devices/token` | Autenticado |
| DELETE | `/api/devices/token` | Autenticado |

---

## 4. Endpoints — Contratos

### Formato padrão de resposta

**Sucesso com dado:**
```json
{ "data": { ... } }
```

**Sucesso sem dado:**
```json
{ "data": { "success": true } }
```

**Erro:**
```json
{ "code": "NOT_FOUND", "error": "Mensagem descritiva" }
```

---

### Auth

#### `POST /api/auth/login`
```json
// Request
{ "email": "admin@smartboarding.com", "password": "sb@2026" }

// Response 200
{
  "data": {
    "token": "eyJhbGci...",
    "fullName": "System Administrator",
    "role": "ADMIN"
  }
}
```

#### `POST /api/auth/register` · ADMIN
```json
// Request
{
  "email": "novo@student.com",
  "password": "senha123",
  "role": "STUDENT",
  "fullName": "Nome Completo"
}

// Response 201
{
  "data": {
    "id": "uuid",
    "email": "novo@student.com",
    "fullName": "Nome Completo",
    "role": "STUDENT",
    "course": null,
    "institution": null,
    "phone": null,
    "address": null,
    "birthDate": null,
    "expiryDate": null,
    "isActive": true
  }
}
```

---

### Usuários

#### `GET /api/users` · ADMIN — lista todos
#### `GET /api/users/{id}` · ADMIN — busca por ID
```json
// Response 200
{
  "data": {
    "id": "uuid", "email": "...", "fullName": "...", "role": "STUDENT",
    "course": "...", "institution": "...", "phone": "...",
    "address": "...", "birthDate": "2000-05-15", "expiryDate": null, "isActive": true
  }
}
```

---

### Rotas

#### `POST /api/routes` · ADMIN
```json
// Request
{ "name": "Rota Centro", "description": "Saída pelo centro" }
// Response 201 — RouteResponse
```

#### `GET /api/routes` · Público — lista rotas ativas
#### `GET /api/routes/{id}` · Público — busca por ID
```json
// Response 200
{
  "data": {
    "id": "uuid", "name": "Rota Centro", "description": "...",
    "isActive": true, "createdAt": "2026-05-20T10:00:00"
  }
}
```

#### `PATCH /api/routes/{id}` · ADMIN
```json
// Request
{ "name": "Novo Nome", "description": "Nova descrição" }
// Response 200 — RouteResponse atualizado
```

#### `DELETE /api/routes/{id}` · ADMIN
```json
// Response 200
{ "data": { "success": true } }
```
> Soft-delete: marca `is_active = false`.

---

### Listas Diárias

#### `GET /api/lists/today` · Autenticado
```json
// Response 200
{
  "data": [
    {
      "id": "uuid",
      "routeId": "uuid",
      "routeName": "Rota Centro",
      "date": "2026-05-20",
      "status": "OPEN",
      "totalEntries": 12
    }
  ]
}
```

#### `GET /api/lists/{id}` · Autenticado — busca lista específica

#### `POST /api/lists/{id}/entries` · Autenticado
Inscreve o usuário autenticado na lista.
```json
// Response 201
{
  "data": {
    "id": "uuid",
    "userId": "uuid",
    "fullName": "Vítor Gonzalez",
    "email": "vitor@student.com",
    "createdAt": "2026-05-20T08:30:00"
  }
}
```

#### `DELETE /api/lists/{id}/entries` · Autenticado
Sai da lista (soft-delete: `is_active = false`).

#### `GET /api/lists/{id}/entries` · ADMIN
Lista todos os inscritos ativos na lista.

---

### Relatórios

#### `GET /api/reports` · ADMIN
Paginado. Query params: `?page=0&size=20&sort=generatedAt,desc`
```json
// Response 200
{
  "data": {
    "content": [
      {
        "id": "uuid",
        "dailyListId": "uuid",
        "listDate": "2026-05-19",
        "routeName": "Rota Centro",
        "totalEntries": 15,
        "generatedAt": "2026-05-19T16:00:05"
      }
    ],
    "totalElements": 50,
    "totalPages": 3,
    "number": 0
  }
}
```

#### `GET /api/reports/{id}` · ADMIN
Inclui `snapshotData`: JSON com array de `{id, fullName, email}` dos inscritos no momento do fechamento.

---

### Notificações

#### `POST /api/notifications/broadcast` · ADMIN
Envia push para todos os dispositivos registrados via FCM.
```json
// Request
{ "title": "Aviso importante", "body": "Mensagem para todos os alunos" }
// Response 200 — success
```

---

### Dispositivos

#### `POST /api/devices/token` · Autenticado
```json
// Request
{ "token": "fcm_token_string", "platform": "android" }
// platform: android | ios
// Response 200 — success
```

#### `DELETE /api/devices/token` · Autenticado
Remove todos os tokens FCM do usuário (logout de notificações).

---

## 5. Regras de Negócio

### Scheduler (automático, dias úteis)

| Horário | Ação |
|---------|------|
| `00:00` seg-sex | Cria uma `DailyList` com `status=OPEN` para cada rota ativa |
| `16:00` seg-sex | Fecha todas as `OPEN` → `CLOSED`, gera Report + envia broadcast FCM |

- Se já existe lista para (rota + data), não recria — idempotente.
- Entre 16:01 e 23:59: não há lista `OPEN` — estudante não pode se inscrever.
- Erros no relatório ou FCM são logados mas não interrompem o restante.

### Inscrição em Lista

1. Lista deve estar com `status = OPEN`
2. Usuário não pode ter inscrição ativa na mesma lista — `UNIQUE(user_id, daily_list_id)`
3. Ao sair: `is_active = false` (soft-delete — histórico preservado)
4. Contagem de inscritos: `COUNT WHERE is_active = true`

### Relatório

- Gerado automaticamente ao fechar a lista (16:00)
- `snapshot_data`: JSON com `[{id, fullName, email}]` dos inscritos ativos no momento do fechamento
- `total_entries`: total de inscritos ativos

### Rotas

- Nome único entre rotas ativas — conflito retorna 409
- Delete é soft (`is_active = false`)

### Usuários

- E-mail único — retorna 409 se já cadastrado
- `isAccountNonExpired()`: verifica `expiry_date < today`
- `isEnabled()`: verifica `is_active = true`
- Senha: mínimo 6 caracteres (validação de request)
- JWT identifica usuário pelo `email` (claim `sub`)

---

## 6. Tratamento de Erros

| Exceção | HTTP | Código |
|---------|------|--------|
| `NotFoundException` | 404 | `NOT_FOUND` |
| `ConflictException` | 409 | Customizável (ex: `EMAIL_ALREADY_EXISTS`) |
| `UnauthorizedException` | 401 | `UNAUTHORIZED` |
| `BadRequestException` | 400 | Customizável |
| `MethodArgumentNotValidException` | 400 | `VALIDATION_ERROR` |
| `Exception` (genérico) | 500 | `INTERNAL_SERVER_ERROR` |

---

## 7. Firebase (FCM)

- **SDK:** `firebase-admin 9.4.2`
- **Credenciais:** JSON de service account em `FIREBASE_CREDENTIALS_PATH`
- **Comportamento:** Se `FIREBASE_CREDENTIALS_PATH` estiver vazio, Firebase não inicializa — chamadas FCM falham silenciosamente com log de erro
- **FcmAdapter:** envia para lista de tokens; loga tokens com falha vs sucesso
- **Para ativar:** baixar service account JSON no Firebase Console, apontar o path na variável de ambiente

---

## 8. Configuração Local

### Pré-requisitos
- Java 21+
- Docker + Docker Compose
- Maven Wrapper incluído (`./mvnw`)

### Variáveis de Ambiente

| Variável | Exemplo | Descrição |
|----------|---------|-----------|
| `DB_NAME` | `smartboarding_db` | Nome do banco PostgreSQL |
| `DB_USER` | `admin` | Usuário do banco |
| `DB_PASSWORD` | `sb_pass_2026` | Senha do banco |
| `JWT_SECRET` | `smartboarding_jwt_secret_key_2026_secure` | Mínimo 32 bytes |
| `FIREBASE_CREDENTIALS_PATH` | `/path/service-account.json` | Opcional — FCM push |

### Inicialização

```bash
# 1. Banco
sudo docker compose up -d

# 2. API (carrega application-local.properties automaticamente via profile=local)
./mvnw spring-boot:run

# API disponível em:  http://localhost:8080
# pgAdmin disponível: http://localhost:5050
```

> `application-local.properties` tem as credenciais locais hardcoded e está no `.gitignore`.  
> `application.properties` usa env vars — usado em produção/CI.

### Usuários Seed

| Email | Senha | Role |
|-------|-------|------|
| `admin@smartboarding.com` | `sb@2026` | ADMIN |
| `vitor@student.com` | `sb@2026@123` | STUDENT |
| `ana@student.com` | `sb@2026` | STUDENT |

### Reset do banco

```bash
sudo docker compose down -v && sudo docker compose up -d
```

---

## 9. Qualidade de Código

### Convenções

- **Controllers:** recebem/devolvem DTOs (`record`), nunca entidades de domínio
- **Use Cases:** `execute()` como método principal; lógica de negócio pura, sem JPA
- **Repository Ports:** interfaces no domínio; adapters na infraestrutura fazem o mapeamento
- **Mappers:** classes utilitárias estáticas com `toDomain()` e `toJpa()` — sem estado
- **Exceções:** sempre lançar subclasse de `AppException` com código semântico
- **Transações:** `@Transactional` nos use cases que escrevem no banco
- **Logs:** `@Slf4j` em todos os services — logar operações críticas e erros

### O que NÃO fazer

- Não expor entidades JPA (`*JpaEntity`) fora da camada de persistência
- Não injetar `*JpaRepository` diretamente nos use cases — sempre via porta de domínio
- Não colocar lógica de negócio nos controllers
- Não usar `@Autowired` por campo — sempre injeção por construtor
- Não commitar `application-local.properties` ou `.env` (ambos no `.gitignore`)
- Não adicionar anotações JPA/Jakarta Persistence nas entidades do domínio
