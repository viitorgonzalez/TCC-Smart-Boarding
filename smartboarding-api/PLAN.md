ce# SmartBoarding — Plano de Implementação

## Estado Atual

Backend com autenticação JWT funcional:
- Entidade `User` com roles ADMIN/STUDENT
- `AuthController`: POST /api/auth/login, POST /api/auth/register
- `UserController`: GET /api/users, GET /api/users/{id}
- Flyway migrations V1 (schema) + V2 (seed data)
- Security com OAuth2 Resource Server (JWT HS256)
- Docker Compose com PostgreSQL 16

**Falta implementar:** tudo relacionado a rotas, listas, relatórios, FCM e o app Flutter.

---

## Fase 1 — Backend: Entidades e Banco (Prioridade Máxima)

### 1.1 Migrations Flyway

**V3__create_routes.sql**
```sql
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**V4__create_daily_lists.sql**
```sql
CREATE TABLE daily_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id),
    date DATE NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'OPEN',
    closed_at TIMESTAMP,
    CONSTRAINT uq_route_date UNIQUE (route_id, date)
);
```

**V5__create_list_entries.sql**
```sql
CREATE TABLE list_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    daily_list_id UUID NOT NULL REFERENCES daily_lists(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_user_list UNIQUE (user_id, daily_list_id)
);
```

**V6__create_reports.sql**
```sql
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_list_id UUID NOT NULL UNIQUE REFERENCES daily_lists(id),
    generated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    total_entries INT NOT NULL DEFAULT 0,
    snapshot_data TEXT
);
```

**V7__create_device_tokens.sql**
```sql
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    token VARCHAR(500) NOT NULL UNIQUE,
    platform VARCHAR(10) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
```

### 1.2 Entidades JPA

- `Models/Route.java`
- `Models/DailyList.java` — campo `status` mapeado para enum `ListStatus`
- `Models/ListEntry.java` — constraint unique via `@Table(uniqueConstraints = ...)`
- `Models/Report.java` — `@OneToOne` com DailyList
- `Models/DeviceToken.java`

### 1.3 Repositórios JPA

- `RouteRepository`: `findAllByIsActiveTrue()`
- `DailyListRepository`: `findAllByDateAndStatus(LocalDate, ListStatus)`, `findByRouteIdAndDate(UUID, LocalDate)`
- `ListEntryRepository`: `findByUserIdAndDailyListId(UUID, UUID)`, `countByDailyListIdAndIsActiveTrue(UUID)`
- `ReportRepository`: paginado com `findAll(Pageable)`
- `DeviceTokenRepository`: `findByUserId(UUID)`, `findByToken(String)`

---

## Fase 2 — Backend: Serviços e Endpoints

### 2.1 RouteService + RouteController

```
POST   /api/routes          → ADMIN → criar rota
GET    /api/routes          → ALL  → listar rotas ativas
GET    /api/routes/{id}     → ALL  → detalhe da rota
PATCH  /api/routes/{id}     → ADMIN → editar nome/descrição
DELETE /api/routes/{id}     → ADMIN → isActive = false
```

DTOs: `CreateRouteDTO`, `UpdateRouteDTO`, `RouteResponseDTO`

### 2.2 ListService + ListController

```
GET    /api/lists/today              → ALL    → listas do dia com status=OPEN
GET    /api/lists/{id}               → ALL    → detalhe da lista + count de inscritos
POST   /api/lists/{id}/entries       → STUDENT → inscrever-se
DELETE /api/lists/{id}/entries       → STUDENT → sair (soft-delete)
GET    /api/lists/{id}/entries       → ADMIN  → listar todos os inscritos
```

Validações no `ListService`:
- Lista deve estar `OPEN` para inscrição/saída
- Se já tem ListEntry (isActive=false): reativar em vez de criar novo
- Se já tem ListEntry (isActive=true): retornar 409 Conflict

DTOs: `ListResponseDTO`, `EntryResponseDTO`

### 2.3 SchedulerService

```java
@EnableScheduling // na classe principal ou config

@Scheduled(cron = "0 0 0 * * MON-FRI")
void openDailyLists() {
    // Para cada Route.isActive=true: criar DailyList(status=OPEN, date=today)
    // Se já existe (constraint UNIQUE): ignorar
}

@Scheduled(cron = "0 0 16 * * MON-FRI")
void closeDailyLists() {
    // Para cada DailyList com status=OPEN e date=today:
    //   status = CLOSED, closedAt = now()
    //   Gerar Report (snapshot dos inscritos ativos)
    //   FcmService.sendBroadcast(...)
}
```

### 2.4 ReportService + ReportController

```
GET /api/reports           → ADMIN → paginado, ordenado por generatedAt DESC
GET /api/reports/{id}      → ADMIN → detalhe com snapshotData deserializado
```

DTOs: `ReportSummaryDTO`, `ReportDetailDTO` (com lista de inscritos do snapshot)

### 2.5 Firebase Admin SDK

**pom.xml** (adicionar):
```xml
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <version>9.4.2</version>
</dependency>
```

**application.properties** (adicionar):
```
firebase.credentials.path=${FIREBASE_CREDENTIALS_PATH}
```

**FirebaseConfig.java**: inicializa `FirebaseApp` via `FileInputStream` do service account JSON

**FcmService.java**:
- `sendToUser(UUID userId, String title, String body)` — busca tokens do usuário → `FirebaseMessaging.send()`
- `sendBroadcast(String title, String body)` — busca todos os tokens → `FirebaseMessaging.sendEach()`

### 2.6 DeviceTokenService + DeviceController

```
POST   /api/devices/token   → ALL → UPSERT: atualiza updated_at se token já existe, senão insere
DELETE /api/devices/token   → ALL → remove token do usuário autenticado
```

DTO: `DeviceTokenRequestDTO` { token: String, platform: String }

### 2.7 NotificationController

```
POST /api/notifications/broadcast → ADMIN → {title, body} → FcmService.sendBroadcast()
```

DTO: `BroadcastNotificationDTO` { title: String, body: String }

### 2.8 SecurityConfig (atualizar)

Adicionar às regras:
```java
.requestMatchers(HttpMethod.GET, "/api/routes/**").permitAll()
.requestMatchers(HttpMethod.POST, "/api/routes/**").hasRole("ADMIN")
.requestMatchers(HttpMethod.PATCH, "/api/routes/**").hasRole("ADMIN")
.requestMatchers(HttpMethod.DELETE, "/api/routes/**").hasRole("ADMIN")
.requestMatchers(HttpMethod.GET, "/api/lists/**").authenticated()
.requestMatchers(HttpMethod.POST, "/api/lists/**").authenticated()
.requestMatchers(HttpMethod.DELETE, "/api/lists/**").authenticated()
.requestMatchers(HttpMethod.GET, "/api/reports/**").hasRole("ADMIN")
.requestMatchers(HttpMethod.POST, "/api/notifications/**").hasRole("ADMIN")
.requestMatchers("/api/devices/**").authenticated()
```

---

## Fase 3 — Flutter: Base + Auth

### 3.1 Setup do Projeto

```bash
flutter create smartboarding-app --org com.smartboarding
```

**pubspec.yaml** (dependências principais):
```yaml
provider: ^6.1.2
dio: ^5.7.0
firebase_core: ^3.6.0
firebase_messaging: ^15.1.3
shared_preferences: ^2.3.2
flutter_local_notifications: ^17.2.2
```

### 3.2 DioClient (`core/api/api_client.dart`)

- BaseUrl: `http://10.0.2.2:8080` (emulador Android) ou variável de ambiente
- Interceptor que lê JWT do SharedPreferences e injeta `Authorization: Bearer {token}`
- Interceptor de erro 401 → navegar para LoginScreen

### 3.3 AuthProvider + AuthService

- `login(email, password)` → POST /api/auth/login → salva JWT + role + fullName em SharedPreferences
- `logout()` → limpa SharedPreferences + remove DeviceToken do backend
- `isLoggedIn` getter para splash screen
- `role` getter para controle de acesso nas telas

### 3.4 LoginScreen

- Campos: email, senha
- Botão "Entrar"
- Navega para HomeScreen (STUDENT) ou AdminDashboard (ADMIN) após login bem-sucedido

---

## Fase 4 — Flutter: Fluxo do Estudante

### 4.1 HomeScreen

- Carrega `GET /api/lists/today` ao abrir
- Para cada rota/lista:
  - Nome da rota
  - Total de inscritos
  - Botão "Entrar na Lista" ou "Sair da Lista" (baseado no estado do usuário)
- Se não há lista ativa: mensagem "Nenhuma lista aberta no momento. Listas disponíveis de 00:00 às 16:00."
- Pull-to-refresh

### 4.2 ListProvider

- `loadTodayLists()` → atualiza `List<DailyListModel>`
- `addEntry(listId)` → POST /api/lists/{id}/entries → atualiza estado local
- `removeEntry(listId)` → DELETE /api/lists/{id}/entries → atualiza estado local
- `isUserEnrolled(listId)` → bool baseado no estado atual

---

## Fase 5 — Flutter: Fluxo Admin

### 5.1 AdminDashboardScreen

Menu com cards para:
- Gerenciar Rotas
- Ver Relatórios
- Enviar Notificação

### 5.2 RouteListScreen (admin view)

- Lista todas as rotas (ativas e inativas)
- Botão "+" para criar nova rota
- Swipe ou botão para editar/desativar
- CRUD completo via RouteProvider

### 5.3 ReportsScreen + ReportDetailScreen

- Lista paginada de relatórios (data, nome da rota, total de inscritos)
- Detalhe: lista de nomes e emails dos inscritos no dia

### 5.4 SendNotificationScreen

- Campos: título e corpo da mensagem
- Botão "Enviar para todos"
- POST /api/notifications/broadcast

---

## Fase 6 — Flutter: FCM

### 6.1 Configuração Firebase

- Baixar `google-services.json` do Firebase Console → `android/app/`
- Adicionar `classpath 'com.google.gms:google-services:4.4.0'` ao build.gradle raiz
- Aplicar plugin `com.google.gms.google-services` ao app/build.gradle

### 6.2 NotificationService (`core/services/notification_service.dart`)

```dart
// No main.dart / após login:
FirebaseMessaging messaging = FirebaseMessaging.instance;
await messaging.requestPermission();
String? token = await messaging.getToken();
// POST /api/devices/token {token, platform: 'android'}

// Foreground handler:
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Exibir via flutter_local_notifications
});

// Background/terminated handler:
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

---

## Verificação End-to-End

### Backend

```bash
# 1. Subir banco
docker compose up -d

# 2. Rodar aplicação (Flyway aplica V1-V7)
./mvnw spring-boot:run

# 3. Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@smartboarding.com","password":"sb@2026"}'
# Esperado: {"token": "...", "fullName": "...", "role": "ADMIN"}

# 4. Criar rota
curl -X POST http://localhost:8080/api/routes \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"name":"Rota Unifor","description":"Saída da Unifor às 18h"}'

# 5. Verificar lista do dia (após 00:00 ou acionar scheduler manualmente)
curl http://localhost:8080/api/lists/today \
  -H "Authorization: Bearer {token}"

# 6. Inscrever estudante
curl -X POST http://localhost:8080/api/lists/{id}/entries \
  -H "Authorization: Bearer {student_token}"

# 7. Verificar relatórios (após 16:00 ou acionar closeDailyLists())
curl http://localhost:8080/api/reports \
  -H "Authorization: Bearer {admin_token}"
```

### Flutter

1. Login → JWT armazenado → homescreen carrega listas
2. Botão "Entrar na Lista" → POST /entries → botão muda para "Sair"
3. Botão "Sair da Lista" → DELETE /entries → botão volta ao estado inicial
4. Receber push notification em foreground e background
5. Admin: criar rota → verificar no banco → listar em GET /api/routes
6. Admin: enviar broadcast → verificar push no dispositivo

---

## Ordem de Prioridade para o TCC

1. Backend Fase 1 (entidades + migrations) — base para tudo
2. Backend Fase 2.1 + 2.2 (rotas + listas) — funcionalidade core
3. Flutter Fase 3 (auth + base) — necessário para demonstrar
4. Flutter Fase 4 (fluxo estudante) — demonstração principal
5. Backend Fase 2.3 (scheduler) — automação
6. Backend Fase 2.5 + 2.6 (FCM backend) — notificações
7. Flutter Fase 6 (FCM Flutter) — notificações no app
8. Flutter Fase 5 (admin) + Backend Fase 2.4 (relatórios) — complementar
