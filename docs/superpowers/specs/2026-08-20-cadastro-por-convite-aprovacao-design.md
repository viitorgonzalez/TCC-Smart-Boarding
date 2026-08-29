# Cadastro por convite e aprovação — design

> **Status: aprovado, aguardando plano de implementação.**
> Data: 2026-08-20 · Origem: `/do` → `personal-harness/docs/work/2026-08-20-telas-pendentes-smartboarding/`

## 1. Problema

`PAGES.md` lista 13 telas do app; 8 já existem. Das 5 que faltam, esta é a primeira priorizada
(porta de entrada real do produto — aluno só nasce por convite, RN13). A tela e o design já estão
resolvidos (`docs/specs/autenticacao/register.md`, `docs/specs/administrador/registration-approvals.md`,
design-prompts prontos) — o que falta é o backend inteiro: não existe `RegistrationController`,
nem `Institution` (RN15 exige instituição como entidade real pro dropdown do cadastro, hoje
`User.institution` é só uma `String` solta).

## 2. Escopo

Fechar o fluxo ponta-a-ponta: admin gera convite → aluno recebe e-mail → preenche cadastro →
admin aprova/nega. Inclui o mínimo de `Institution` pra o dropdown funcionar (criar + listar).
**Não inclui** a UI rica de vincular instituição↔rota da RN15 completa (isso é enriquecimento
futuro da tela "Gerenciar Rotas", já implementada) — só uma tela mínima de criar instituição,
inserida na tela de Gerenciar Rotas existente.

## 3. Decisões

| Decisão | Escolha | Motivo |
|---|---|---|
| App Link / domínio | Implementa o formato final (`https://<domínio>/register/{token}`) + página de fallback; deploy/domínio fica pendência conhecida, não bloqueia o código | Projeto ainda não tem ambiente publicado. Subdomínio grátis de hospedagem (Railway/Render/Fly.io) resolve quando o deploy acontecer — não precisa domínio comprado. Dev testa colando token/URL direto, sem precisar do link clicável. |
| `RegistrationRequest` vs. reusar `User` | Entidade nova e separada, só vira `User` na aprovação | RN14 é explícito: "aprova (cria a conta de fato)" — o pedido pendente não é uma conta ainda. |
| `Institution` — escopo desta rodada | Entidade real (nome, endereço, lat/long) + `POST`/`GET` básicos + tela mínima de criação dentro de Gerenciar Rotas | Sem isso o dropdown do cadastro não tem o que listar; UI de vínculo com rota (RN15 completa) fica fora, é trabalho de outro domínio. |
| Página de fallback (sem app instalado) | `@Controller` simples, HTML inline, sem motor de template novo | App ainda não está nas lojas — link de "instalar" fica texto, não botão funcional. Não vale puxar Thymeleaf só pra uma página. |
| Deep-link no Flutter | Adiciona pacote de deep-link (`app_links` ou equivalente) + intercepta em `main.dart` | App não tem router dedicado nem pacote de deep-link hoje — navegação é `Navigator.push` direto; precisa desse pedaço novo pra abrir `RegisterScreen` a partir do link. |
| Validação de token/campos | Backend valida token (existe, não expirou) e campos obrigatórios (`@Valid`, mesmo padrão do `AuthController`) independente do estado do App Link | Validação de contrato não depende de deep-link funcionar. |
| Testes | Unit por use case novo (`*Test.java`, Surefire — mesmo padrão do restante da API), smoke test das duas telas + do `RegistrationProvider` no Flutter | Cobrado de verdade agora pelo `checks/TCC-Smart-Boarding.checks` do harness (`./mvnw test` + `flutter test` bloqueiam push vermelho). |

## 4. Arquitetura

### 4.1 Domínio (backend, hexagonal — `domain/`, `application/`, `infrastructure/`)

**`RegistrationRequest`** (`domain/registration/entity/`): `id`, `email`, `token` (único),
`tokenExpiresAt` (geração + 7 dias, RN13), `status` (`PENDING`/`APPROVED`/`REJECTED`), e os
dados do formulário (`fullName`, `institutionId`, `course?`, `phone?`, `address?`, `birthDate?`,
senha em hash) — nasce só com `email`+`token` na geração do convite; ganha o resto no submit.

**`Institution`** (`domain/institution/entity/`): `id`, `name`, `address`, `latitude`,
`longitude`. Vínculo com rota (RN15) fica pra depois — campo/relação não entra nesta rodada.

### 4.2 Endpoints novos

```
POST /api/registration/invite            {email}                              → ADMIN
GET  /api/registration/invite/{token}                                          → público
POST /api/registration/{token}/submit    {fullName, password, institutionId, …} → público
GET  /api/registration/pending                                                 → ADMIN
POST /api/registration/{id}/approve                                            → ADMIN
POST /api/registration/{id}/reject                                             → ADMIN
POST /api/institutions                   {name, address, lat, long}            → ADMIN
GET  /api/institutions                                                         → público (dropdown do cadastro não tem sessão ainda)
GET  /register/{token}                                                         → HTML fallback, não-REST
```

Use cases (um por endpoint, seguindo o padrão hexagonal já usado em `route`):
`GenerateInviteUseCase`, `ValidateTokenUseCase`, `SubmitRegistrationUseCase`,
`ApproveRegistrationUseCase`, `RejectRegistrationUseCase`, `CreateInstitutionUseCase`,
`ListInstitutionsUseCase`. `GenerateInviteUseCase` usa o `EmailPort`/`ResendEmailAdapter` já
existente (reuso — nenhuma infra de e-mail nova).

### 4.3 Flutter (`lib/features/registration/`, feature-first — mesmo padrão de `lists`/`notifications`)

```
registration/
  models/         RegistrationRequestModel, InstitutionModel
  providers/      RegistrationProvider
  services/       chamadas aos 7 endpoints REST (a página HTML não é chamada pelo app)
  screens/
    register_screen.dart               — pública, recebe token via deep-link, formulário + estados
    registration_approvals_screen.dart — admin, lista pendentes + aprovar/negar + gerar convite
```

Tela mínima de criar instituição entra dentro de `lib/features/routes/screens/` (já existe),
não como feature nova.

Deep-link: adicionar `app_links` (ou equivalente) ao `pubspec.yaml`, configurar intent-filter
Android (`AndroidManifest.xml`) e associated domain iOS, interceptar em `main.dart` e empurrar
pra `RegisterScreen(token: ...)` quando o link bater com `/register/{token}`.

## 5. Riscos / dependências conhecidas

| Item | Consequência | Status |
|---|---|---|
| Sem domínio publicado | App Link não abre o app de verdade fora de dev | **Aceito** — pendência pro deploy, fora de escopo aqui |
| App não publicado nas lojas | Página de fallback não tem link funcional de instalar | **Aceito** — texto por enquanto |
| `Institution` sem vínculo de rota | RN15 completa não fecha nesta rodada | **Aceito** — outro domínio (Gerenciar Rotas) |

## 6. Critérios de aceite

- [ ] Admin gera convite (`POST /api/registration/invite`) — e-mail chega via Resend com o link.
- [ ] Token inválido/expirado → `GET .../invite/{token}` retorna erro apropriado, tela mostra estado de erro sem formulário.
- [ ] Submissão válida (`POST .../submit`) não cria `User` — só marca `RegistrationRequest` como `PENDING` com os dados.
- [ ] Negar não invalida o token — aluno pode reenviar enquanto o token não expira (RN14).
- [ ] Aprovar cria o `User` de fato, com os dados do `RegistrationRequest`.
- [ ] Admin cria instituição (tela mínima em Gerenciar Rotas) e ela aparece no dropdown do cadastro.
- [ ] `./mvnw test` e `flutter test` verdes (gate do harness).
- [ ] `PAGES.md` não muda — já lista essas duas telas corretamente.

## 7. Fora de escopo

- Domínio/deploy publicado.
- Publicação nas lojas.
- UI de vincular instituição↔rota (RN15 completa).
- Reenvio/renovação de convite pelo admin (RN13 menciona "renovável" — reenviar o mesmo convite estende o prazo; fica pra quando o fluxo básico estiver rodando).

---

## 8. Atualização (2026-08-28) — o que mudou na execução

O plano foi executado, mas o desenho evoluiu em dois pontos durante a implementação. Esta seção é
a fonte da verdade onde divergir das seções acima.

### 8.1 Convite virou código de 6 dígitos (substitui o App Link)

App Link `https://` exige domínio publicado **e verificado** (`assetlinks.json`) — pendência de
deploy que não tinha prazo. O convite passou a ser um **código de 6 dígitos** por e-mail:

- Código hasheado (nunca em texto puro), validade de **15 min**, máximo de **5 tentativas**.
- `POST /api/registration/verify-code {email, code}` → devolve o token de 7 dias, que o app usa
  no resto do fluxo. O token deixou de aparecer em URL.
- O scheme customizado (`smartboarding://`) e a página de fallback continuam no código como
  caminho alternativo, mas o fluxo principal não depende deles.

### 8.2 Ciclo de negação fechado (motivo, aviso e correção)

RN14 dizia que negar não invalida o token, mas na prática o aluno não tinha como saber que fora
negado, nem o que corrigir, nem como voltar. Fechado assim:

- `rejection_reason` (migration `V6`) — **motivo obrigatório** ao negar (`POST /{id}/reject
  {reason}`, máx. 500 chars).
- Negar dispara **e-mail** com o motivo e a instrução de pedir um novo código. O motivo é
  escapado antes de entrar no HTML.
- `POST /api/registration/resend-code {email}` (público) — gera código novo **reusando o mesmo
  pedido**, o que preserva os dados pro prefill. Zera as tentativas. Cooldown de 60s pra o
  endpoint não virar vetor de flood de e-mail. Responde igual pra e-mail com e sem convite
  (não enumera quem tem cadastro aberto).
- `GET /api/registration/invite/{token}` passou a devolver `status`, `rejectionReason` e os dados
  já submetidos (**nunca** a senha) — é o que permite o formulário abrir preenchido.
- Reenviar limpa o `rejection_reason` — o motivo pertence à rodada que foi negada.

### 8.3 Guards que não estavam no desenho original

- `approve()` só aceita pedido `PENDING` e recusa e-mail já cadastrado (evitava colisão com
  `UNIQUE(email)` de `users`).
- `validateToken()` trata `APPROVED` como terminal — sem isso um resubmit sobrescrevia um pedido
  que já virou conta.
- `approve()` copia o **nome** da instituição escolhida pro `User.institution` (campo `String` que
  já existia). Migrar `users` pra FK de `institutions` foi avaliado e deixado de fora: mudaria o
  contrato de `GET /api/users` sem necessidade nesta rodada.

### 8.4 Pendências conhecidas

- Campos opcionais (curso, telefone, endereço, data de nascimento) existem no contrato e no
  prefill, mas ainda não têm campo na `RegisterScreen`.
- Domínio publicado, App Link verificado e publicação nas lojas seguem fora de escopo.
