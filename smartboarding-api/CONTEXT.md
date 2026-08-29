# SmartBoarding — Contexto de Domínio

## O Problema

Estudantes universitários que dependem do ônibus fretado da instituição (ex: Unifor) não sabem quantas vagas existem nem se haverá espaço. Administradores não têm visibilidade do número de passageiros por dia. O SmartBoarding resolve isso com uma lista diária digital de embarque.

## Atores

### ADMIN
- Cria e gerencia rotas de ônibus permanentes
- Visualiza a lista do dia de qualquer rota
- Consulta histórico de relatórios
- Envia notificações push broadcast para todos os estudantes
- Registra novos usuários (estudantes)

### STUDENT
- Visualiza a lista diária de todas as rotas
- Entra e sai da lista enquanto ela estiver aberta (00:00–16:00)
- Recebe notificações individuais (confirmação de inscrição) e broadcast (avisos do admin, fechamento da lista)

---

## Entidades de Domínio

### Route (Rota)
Rota de ônibus permanente, criada pelo admin uma única vez. Serve de template para as listas diárias.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | UUID | PK |
| name | String (100) | Ex: "Rota Unifor" |
| description | String (255) | Detalhes da rota |
| isActive | boolean | Se false, não gera listas |
| createdAt | LocalDateTime | Auto |
| updatedAt | LocalDateTime | Auto |

### DailyList (Lista Diária)
Gerada automaticamente pelo scheduler para cada rota ativa, de segunda a sexta.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | UUID | PK |
| route | Route | FK para a rota |
| date | LocalDate | Data da lista |
| status | ListStatus | OPEN ou CLOSED |
| closedAt | LocalDateTime | Quando foi fechada (nullable) |

**Constraint:** `UNIQUE(route_id, date)` — uma lista por rota por dia.

### ListEntry (Inscrição)
Representa a inscrição de um estudante em uma lista do dia.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | UUID | PK |
| user | User | FK para o estudante |
| dailyList | DailyList | FK para a lista |
| createdAt | LocalDateTime | Quando se inscreveu |
| isActive | boolean | false = saiu da lista (soft-delete) |

**Constraint:** `UNIQUE(user_id, daily_list_id)` — uma inscrição por estudante por lista.

### Report (Relatório)
Snapshot imutável gerado no momento do fechamento da lista (16:00).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | UUID | PK |
| dailyList | DailyList | OneToOne |
| generatedAt | LocalDateTime | Momento da geração |
| totalEntries | int | Contagem de inscritos ativos |
| snapshotData | TEXT (JSON) | Array com nome/email dos inscritos |

### DeviceToken (Token FCM)
Token FCM do dispositivo Flutter, necessário para enviar push notifications.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | UUID | PK |
| user | User | FK para o usuário |
| token | String | Token FCM único |
| platform | String | "android" ou "ios" |
| createdAt | LocalDateTime | Auto |
| updatedAt | LocalDateTime | Atualizado no login |

---

## Regras de Negócio

### Ciclo de Vida da Lista Diária

```
00:00 (seg-sex)
  └─ Scheduler cria DailyList (status=OPEN) para cada Route.isActive=true

00:01 – 15:59
  └─ Estudantes podem entrar/sair livremente

16:00 (seg-sex)
  └─ Scheduler fecha todas as listas abertas (status=CLOSED)
  └─ Gera Report com snapshot dos inscritos
  └─ Envia FCM broadcast: "Embarque confirmado: X pessoas na [Rota]"

16:01 – 23:59
  └─ Nenhuma lista ativa — estudante não pode se inscrever

Final de semana
  └─ Scheduler não roda — sem listas
```

### Inscrição na Lista
- Estudante só pode se inscrever se `DailyList.status == OPEN`
- Ao entrar: cria `ListEntry` com `isActive=true` + envia FCM individual de confirmação
- Ao sair: `ListEntry.isActive = false` (soft-delete)
- Ao tentar entrar novamente: reativa o ListEntry existente (sem criar duplicata)

### Relatórios
- Gerados automaticamente ao fechar a lista
- Imutáveis após geração (snapshot)
- Acessíveis apenas pelo ADMIN
- Paginados (mais recentes primeiro)

### Notificações FCM
- **Individual**: enviada ao estudante quando ele se inscreve na lista
- **Broadcast ao fechar**: enviada a todos os tokens registrados quando a lista fecha
- **Broadcast manual (admin)**: admin envia título + corpo via endpoint, dispara para todos os tokens

---

## Fluxos Principais

### Fluxo 1 — Estudante se inscreve na lista

```
1. Estudante abre o app → LoginScreen
2. Faz login → recebe JWT + role=STUDENT
3. App obtém FCM token → POST /api/devices/token (registra/atualiza)
4. HomeScreen carrega → GET /api/lists/today → exibe listas abertas
5. Estudante toca em "Entrar na Lista" (Rota Unifor)
6. App → POST /api/lists/{id}/entries
7. Backend valida: lista OPEN? usuário já inscrito?
8. Cria ListEntry, envia FCM individual de confirmação
9. App exibe botão "Sair da Lista" (estado invertido)
```

### Fluxo 2 — Fechamento automático da lista (16:00)

```
1. SchedulerService.closeDailyLists() dispara
2. Busca todas as DailyList com status=OPEN e date=today
3. Para cada lista:
   a. status = CLOSED, closedAt = agora
   b. Conta ListEntries com isActive=true
   c. Gera snapshotData JSON com nome/email dos inscritos
   d. Persiste Report
   e. FcmService.sendBroadcast("Lista fechada", "X pessoas confirmadas na [Rota]")
```

### Fluxo 3 — Admin envia notificação manual

```
1. Admin abre a tela "Notificações"
2. Preenche título e corpo da mensagem
3. Toca em "Enviar para todos"
4. App → POST /api/notifications/broadcast {title, body}
5. Backend → FcmService.sendBroadcast(title, body)
6. Firebase Cloud Messaging → push para todos os DeviceTokens
```

### Fluxo 4 — Admin consulta histórico

```
1. Admin abre tela "Relatórios"
2. App → GET /api/reports?page=0&size=20
3. Backend retorna lista paginada de Reports (data, rota, total)
4. Admin seleciona um relatório
5. App → GET /api/reports/{id}
6. Exibe lista de inscritos no dia (do snapshotData)
```

---

## Modelo de Dados (Resumo)

```
User ──< ListEntry >── DailyList >── Route
User ──< DeviceToken
DailyList ──── Report (1:1)
```

---

## Enums

| Enum | Valores |
|------|---------|
| `Role` | ADMIN, STUDENT |
| `ListStatus` | OPEN, CLOSED |
| `TripType` | ROUND_TRIP, TO_CAMPUS, FROM_CAMPUS |

> Detalhe completo de regras de negócio, entidades e contratos: `docs/spec.md`.
