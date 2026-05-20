# SmartBoarding — Agentes Claude

Este arquivo define a divisão de responsabilidades para uso com agentes Claude Code no desenvolvimento do SmartBoarding. Cada agente tem um escopo isolado para maximizar paralelismo e evitar conflitos.

## Ordem de Execução Recomendada

```
Fase 1 (paralelo): agent:backend-entities
Fase 2 (paralelo): agent:backend-routes-lists + agent:backend-fcm
Fase 3 (paralelo): agent:flutter-auth
Fase 4 (paralelo): agent:flutter-student-flow + agent:flutter-admin-flow
Fase 5 (paralelo): agent:flutter-fcm
```

---

## agent:backend-entities

**Responsabilidade**: Estrutura de dados do backend

**Tarefas:**
- Criar migrations Flyway V3–V7
- Criar entidades JPA: `Route`, `DailyList`, `ListEntry`, `Report`, `DeviceToken`
- Criar repositórios Spring Data JPA para cada entidade
- Ajustar `ListStatus` enum se necessário
- Verificar que `./mvnw test` passa após as mudanças

**Arquivos de saída:**
```
smartboarding-api/src/main/resources/db/migration/V3__create_routes.sql
smartboarding-api/src/main/resources/db/migration/V4__create_daily_lists.sql
smartboarding-api/src/main/resources/db/migration/V5__create_list_entries.sql
smartboarding-api/src/main/resources/db/migration/V6__create_reports.sql
smartboarding-api/src/main/resources/db/migration/V7__create_device_tokens.sql
smartboarding-api/src/main/java/.../Models/Route.java
smartboarding-api/src/main/java/.../Models/DailyList.java
smartboarding-api/src/main/java/.../Models/ListEntry.java
smartboarding-api/src/main/java/.../Models/Report.java
smartboarding-api/src/main/java/.../Models/DeviceToken.java
smartboarding-api/src/main/java/.../Repositories/*.java
```

---

## agent:backend-routes-lists

**Responsabilidade**: Lógica de negócio de rotas e listas (depende de `agent:backend-entities`)

**Tarefas:**
- Criar `RouteService` + `RouteController` (CRUD de rotas)
- Criar `ListService` + `ListController` (lista do dia, inscrição, saída)
- Criar `SchedulerService` com `@Scheduled`:
  - `openDailyLists()` → cron `0 0 0 * * MON-FRI`
  - `closeDailyLists()` → cron `0 0 16 * * MON-FRI`
- Criar `ReportService` + `ReportController`
- Criar DTOs necessários (`DTO/route/`, `DTO/list/`, `DTO/report/`)
- Atualizar `SecurityConfig` com novas rotas de acesso
- Habilitar `@EnableScheduling` na aplicação

**Endpoints a criar:**

| Método | Path | Role |
|--------|------|------|
| POST/GET/PATCH/DELETE | `/api/routes/**` | ADMIN/ALL |
| GET | `/api/lists/today` | ALL |
| POST/DELETE | `/api/lists/{id}/entries` | STUDENT |
| GET | `/api/lists/{id}/entries` | ADMIN |
| GET | `/api/reports/**` | ADMIN |

---

## agent:backend-fcm

**Responsabilidade**: Integração Firebase FCM no backend (pode rodar em paralelo com `agent:backend-routes-lists`)

**Tarefas:**
- Adicionar `firebase-admin:9.4.2` ao `pom.xml`
- Criar `FirebaseConfig.java` em `Configs/` (inicializa FirebaseApp via service account JSON)
- Criar `FcmService.java` com métodos:
  - `sendToUser(UUID userId, String title, String body)`
  - `sendBroadcast(String title, String body)`
- Criar `DeviceTokenService.java` + `DeviceController.java`
  - `POST /api/devices/token` — UPSERT do token FCM
  - `DELETE /api/devices/token` — remover token ao logout
- Criar `NotificationController.java`
  - `POST /api/notifications/broadcast` — ADMIN only
- Adicionar `firebase.credentials.path` ao `application.properties`
- Atualizar `.env.example` com `FIREBASE_CREDENTIALS_PATH`

---

## agent:flutter-auth

**Responsabilidade**: Setup inicial do projeto Flutter e autenticação

**Tarefas:**
- Criar projeto Flutter em `smartboarding-app/`
- Configurar `pubspec.yaml` (provider, dio, firebase_core, firebase_messaging, shared_preferences, flutter_local_notifications)
- Criar estrutura de pastas (`core/`, `screens/`, `widgets/`)
- Implementar `DioClient` com interceptor JWT (lê token do SharedPreferences, injeta no header)
- Implementar `AuthService` + `AuthProvider`
- Implementar `LoginScreen`
- Testar login end-to-end com o backend

---

## agent:flutter-student-flow

**Responsabilidade**: Fluxo principal do estudante (depende de `agent:flutter-auth`)

**Tarefas:**
- Implementar `RouteService` + `RouteProvider`
- Implementar `ListService` + `ListProvider`
- Implementar `HomeScreen` com lista do dia
  - Exibir todas as listas abertas
  - Botão "Entrar/Sair da Lista" por rota
  - Estado vazio quando não há lista ativa (fora do horário)
- Implementar loading states e tratamento de erros básico

---

## agent:flutter-admin-flow

**Responsabilidade**: Telas administrativas (pode rodar em paralelo com `agent:flutter-student-flow`)

**Tarefas:**
- Implementar `AdminDashboardScreen` (menu admin)
- Implementar `RouteListScreen` com CRUD de rotas (somente ADMIN vê botões de edição)
- Implementar `ReportsScreen` + `ReportDetailScreen`
- Implementar `SendNotificationScreen` (broadcast FCM)
- Controle de acesso por role no Flutter (esconder telas admin para STUDENT)

---

## agent:flutter-fcm

**Responsabilidade**: Integração FCM no Flutter (depende de `agent:flutter-auth`)

**Tarefas:**
- Configurar Firebase no projeto Flutter (`google-services.json`)
- Inicializar `firebase_messaging` no `main.dart`
- Solicitar permissão de notificações ao usuário
- Registrar FCM token no backend após login (`POST /api/devices/token`)
- Remover FCM token no logout (`DELETE /api/devices/token`)
- Handler de mensagens em foreground (usar `flutter_local_notifications`)
- Handler de mensagens em background/terminated

---

## Contexto Compartilhado

Todos os agentes devem ler:
- `CONTEXT.md` — regras de negócio e entidades
- `CLAUDE.md` — convenções de código e como rodar
- `PLAN.md` — roadmap completo com todos os endpoints
