# Spec — Gerenciar Rotas

> Telas: `RouteListScreen`, `RouteFormScreen` · Acesso: 🧑‍💼
> Providers: `RouteProvider`, `InstitutionProvider`, `VehicleProvider`
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.2.

## Objetivo

CRUD de rota, com as sub-entidades vinculadas (instituições, veículos, paradas) editáveis no
mesmo formulário.

## Dados & contrato

- Lista: `GET /api/routes` (ativas + inativas pro admin).
- Criar: `POST /api/routes {name, description?}`.
- Editar: `PATCH /api/routes/{id} {name?, description?}`.
- Horário da lista: `PATCH /api/routes/{id}/schedule {openTime, closeTime, reason}` — endpoint
  separado porque exige motivo e avisa a rota (RN18/RN24).
- Desativar: `DELETE /api/routes/{id}` (soft-delete).
- Sub-seções do form: `CRUD /api/institutions` (com `routeId`), `CRUD /api/routes/{id}/vehicles`,
  `CRUD /api/routes/{id}/stops`.
- Lista do dia da rota: `GET /api/lists?date=<hoje>` (filtrada pelo `routeId`), `POST /api/lists`,
  `PATCH /api/lists/{id} {status, reason}`, `DELETE /api/lists/{id}`.
- Avisos automáticos: `CRUD /api/notifications/scheduled` (`?routeId=` no GET).

## Layout / seções

- `RouteListScreen`: lista rotas ativas e inativas.
- `RouteFormScreen`: nome e descrição. Sub-seções:
  - **Lista de hoje** — a rota tem no máximo uma lista por dia, então ela é gerenciada aqui e não
    numa tela separada: horário de abertura/fechamento (alterar exige motivo e avisa a rota),
    status, total de inscritos, divisão por instituição, atalho pros inscritos, abrir/fechar
    manualmente e apagar.
  - **Avisos automáticos** — aviso recorrente por rota (frequência, horário, validade), disparado
    pelo backend; pode ser pausado ou removido.
  - **Instituições vinculadas** — adicionar/remover instituições cadastradas.
  - **Veículos disponíveis** — tipo + capacidade.
  - **Paradas/pontos no mapa** — nome + posição, com toggle "é ponto principal".

## Estados

- Nome de rota duplicado → erro de conflito.
- Segunda lista pra mesma rota e data → `409 LIST_ALREADY_EXISTS`.
- Abrir/fechar a lista na mão exige confirmação com motivo (`400 REASON_REQUIRED` sem ele); o texto
  vira o aviso enviado a todos da rota.
- Apagar lista que já tem relatório → recusado (RN8).
- Instituição já vinculada a outra rota ativa → erro de conflito.
- Editar qualquer campo da rota dispara a notificação automática de mudança de regra (§3.4 do
  `spec.md`) — sem passo extra na UI, é automático ao salvar.

## Regras aplicáveis

`spec.md` §3.2. Backend: RN9, RN15, RN16, RN18, RN19, RN23 (paradas/pontos principais).
