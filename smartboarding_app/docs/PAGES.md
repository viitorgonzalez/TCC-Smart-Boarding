# Inventário de páginas — SmartBoarding App

> Mapa das telas do app, derivado de [`spec.md`](./spec.md) (regras, papéis) e
> `smartboarding-api/docs/spec.md` (contratos). Cada linha aponta pra uma spec em
> [`specs/`](./specs/) com o detalhe da tela.

**Legenda:** 🌐 público · 🎓 `STUDENT` · 🧑‍💼 `ADMIN`

---

## Autenticação

| Página | Acesso | Propósito | Contrato de API | Spec |
|---|---|---|---|---|
| Login | 🌐→🎓🧑‍💼 | Autenticação, com "lembrar de mim" | `POST /api/auth/login` | [`login.md`](./specs/autenticacao/login.md) |
| Cadastro | 🌐 | Criar conta com nome, e-mail e senha — ou entrar com Google | `POST /api/auth/signup`, `POST /api/auth/google` | [`signup-e-entrada-na-rota.md`](./specs/autenticacao/signup-e-entrada-na-rota.md) |
| Recuperar/redefinir senha | 🌐 | Esqueci a senha → e-mail → nova senha | `POST /api/auth/forgot-password`, `POST /api/auth/reset-password` | [`password-reset.md`](./specs/autenticacao/password-reset.md) |

## Aluno (🎓)

| Página | Acesso | Propósito | Contrato de API | Spec |
|---|---|---|---|---|
| Início do aluno | 🎓 | Lista do dia da própria rota, mapa, entrar/sair | `GET /api/lists/today`, `POST`/`DELETE /api/lists/{id}/entries` | [`student-home.md`](./specs/aluno/student-home.md) |
| Entrar na rota | 🎓 | Código que o admin distribui; porta fixa no cabeçalho da home | `POST /api/me/routes` | [`signup-e-entrada-na-rota.md`](./specs/autenticacao/signup-e-entrada-na-rota.md) |
| Meu perfil | 🎓🧑‍💼 | Dados cadastrais, instituições, pedido de alteração, criar senha local | `GET /api/me`, `/api/me/institutions`, `/api/me/profile-requests`, `POST /api/me/password` | — |
| Minha rota | 🎓 | Paradas da rota no mapa | `GET /api/routes/{id}/stops` | — |
| Minhas idas | 🎓 | Histórico de presença dos últimos 6 meses | `GET /api/users/me/attendance` | — |
| Relatórios (aluno) | 🎓 | Histórico dos últimos 7 dias | `GET /api/reports` (filtrado) | [`reports.md`](./specs/relatorios/reports.md) |

## Notificações (🎓🧑‍💼)

| Página | Acesso | Propósito | Contrato de API | Spec |
|---|---|---|---|---|
| Inbox de notificações | 🎓🧑‍💼 | Histórico de notificações recebidas | `GET /api/notifications` | [`notifications.md`](./specs/notificacoes/notifications.md) |
| Enviar notificação | 🧑‍💼 | Form de envio (FAB) — título, corpo, imagem, escopo | `POST /api/notifications`, `POST /api/notifications/upload-image` | [`notifications.md`](./specs/notificacoes/notifications.md) |

## Administrador (🧑‍💼)

| Página | Acesso | Propósito | Contrato de API | Spec |
|---|---|---|---|---|
| Painel do admin | 🧑‍💼 | Dashboard com atalhos + contagem de pendências | — | [`admin-home.md`](./specs/administrador/admin-home.md) |
| Códigos da rota | 🧑‍💼 | Gerar e revogar o código que o aluno usa pra entrar na rota | `POST`\|`DELETE /api/routes/{id}/invite-codes` | — |
| Pedidos de alteração de perfil | 🧑‍💼 | Aprovar/negar alteração de dado cadastral do aluno | `GET /api/profile-requests`, `POST .../approve`\|`/reject` | — |
| Rotas e listas | 🧑‍💼 | CRUD de rota + lista do dia, avisos automáticos, instituições, veículos e paradas | `CRUD /api/routes`, `/api/institutions`, `/api/routes/{id}/vehicles`, `/api/routes/{id}/stops`, `/api/lists`, `/api/notifications/scheduled` | [`route-management.md`](./specs/administrador/route-management.md) |
| Relatórios (admin) | 🧑‍💼 | Histórico completo, paginado, com veículo proposto | `GET /api/reports`, `GET /api/reports/{id}` | [`reports.md`](./specs/relatorios/reports.md) |
| Trajeto | 🧑‍💼 | Iniciar/checkpoint/finalizar o trajeto do dia | `GET /api/trip/{listId}`, `POST .../{start,checkpoint/{stopId},finish}` | [`trip.md`](./specs/administrador/trip.md) |
| Usuários | 🧑‍💼 | Listagem de contas, ficha completa do aluno, ativar/desativar | `GET /api/users`, `GET /api/users/{id}/profile`, `PATCH /api/users/{id}/status` | [`users-list.md`](./specs/administrador/users-list.md) |
| Instituições | 🧑‍💼 | Catálogo de instituições; a rota só escolhe quais atende | `CRUD /api/institutions` | — |
| Inscritos da lista | 🧑‍💼 | Quem está na lista do dia; inclusão manual com advertência | `GET`\|`POST /api/lists/{id}/entries` | — |
| Paradas da rota | 🧑‍💼 | Ordenar, mover e inserir parada no mapa | `CRUD /api/routes/{id}/stops` | — |
| Alunos da rota | 🧑‍💼 | Quem pertence à rota | `GET /api/routes/{id}/students` | — |
| Advertências | 🎓 🧑‍💼 | Advertência por inscrição fora do prazo; admin remove | `GET /api/warnings`, `/me`, `DELETE /api/warnings/{id}` | [`warnings.md`](./specs/notificacoes/warnings.md) |
