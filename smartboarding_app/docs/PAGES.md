# Inventário de páginas — SmartBoarding App

> Mapa das telas do app, derivado de [`spec.md`](./spec.md) (regras, papéis) e
> `smartboarding-api/docs/spec.md` (contratos). Cada linha aponta pra uma spec em
> [`specs/`](./specs/) com o detalhe da tela.

**Legenda:** 🌐 público · 🎓 `STUDENT` · 🧑‍💼 `ADMIN`

---

## Autenticação

| Página | Acesso | Propósito | Contrato de API | Spec |
|---|---|---|---|---|
| Login | 🌐→🎓🧑‍💼 | Autenticação, com "lembrar de mim" | `POST /api/auth/login` | [`login.md`](./specs/login.md) |
| Cadastro (convite) | 🌐 | Autocadastro do aluno a partir do link do e-mail | `GET /api/registration/invite/{token}`, `POST /api/registration/{token}/submit` | [`register.md`](./specs/register.md) |
| Recuperar/redefinir senha | 🌐 | Esqueci a senha → e-mail → nova senha | `POST /api/auth/forgot-password`, `POST /api/auth/reset-password` | [`password-reset.md`](./specs/password-reset.md) |

## Aluno (🎓)

| Página | Acesso | Propósito | Contrato de API | Spec |
|---|---|---|---|---|
| Início do aluno | 🎓 | Lista do dia da própria rota, mapa, entrar/sair | `GET /api/lists/today`, `POST`/`DELETE /api/lists/{id}/entries` | [`student-home.md`](./specs/student-home.md) |
| Relatórios (aluno) | 🎓 | Histórico dos últimos 7 dias | `GET /api/reports` (filtrado) | [`reports.md`](./specs/reports.md) |

## Notificações (🎓🧑‍💼)

| Página | Acesso | Propósito | Contrato de API | Spec |
|---|---|---|---|---|
| Inbox de notificações | 🎓🧑‍💼 | Histórico de notificações recebidas | `GET /api/notifications` | [`notifications.md`](./specs/notifications.md) |
| Enviar notificação | 🧑‍💼 | Form de envio (FAB) — título, corpo, imagem, escopo | `POST /api/notifications`, `POST /api/notifications/upload-image` | [`notifications.md`](./specs/notifications.md) |

## Administrador (🧑‍💼)

| Página | Acesso | Propósito | Contrato de API | Spec |
|---|---|---|---|---|
| Painel do admin | 🧑‍💼 | Dashboard com atalhos + contagem de pendências | — | [`admin-home.md`](./specs/admin-home.md) |
| Solicitações de cadastro | 🧑‍💼 | Aprovar/negar cadastros pendentes, gerar convite | `GET /api/registration/pending`, `POST .../approve`\|`/reject`, `POST /api/registration/invite` | [`registration-approvals.md`](./specs/registration-approvals.md) |
| Gerenciar rotas | 🧑‍💼 | CRUD de rota + instituições, veículos e paradas vinculadas | `CRUD /api/routes`, `/api/institutions`, `/api/routes/{id}/vehicles`, `/api/routes/{id}/stops` | [`route-management.md`](./specs/route-management.md) |
| Relatórios (admin) | 🧑‍💼 | Histórico completo, paginado, com veículo proposto | `GET /api/reports`, `GET /api/reports/{id}` | [`reports.md`](./specs/reports.md) |
| Trajeto | 🧑‍💼 | Iniciar/checkpoint/finalizar o trajeto do dia | `POST /api/trip/{listId}/{start,checkpoint/{stopId},finish}` | [`trip.md`](./specs/trip.md) |
| Usuários | 🧑‍💼 | Listagem de contas (sem criação de aluno) | `GET /api/users` | [`users-list.md`](./specs/users-list.md) |
