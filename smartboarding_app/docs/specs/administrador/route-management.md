# Spec — Gerenciar Rotas

> Telas: `RouteListScreen`, `RouteFormScreen` · Acesso: 🧑‍💼
> Providers: `RouteProvider`, `InstitutionProvider`, `VehicleProvider`
> Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §3.2.

## Objetivo

CRUD de rota, com as sub-entidades vinculadas (instituições, veículos, paradas) editáveis no
mesmo formulário.

## Dados & contrato

- Lista: `GET /api/routes` (ativas + inativas pro admin).
- Criar: `POST /api/routes {name, description?}`.
- Editar: `PATCH /api/routes/{id} {name?, description?, closeTime?}`.
- Desativar: `DELETE /api/routes/{id}` (soft-delete).
- Sub-seções do form: `CRUD /api/institutions` (com `routeId`), `CRUD /api/routes/{id}/vehicles`,
  `CRUD /api/routes/{id}/stops`.

## Layout / seções

- `RouteListScreen`: lista rotas ativas e inativas.
- `RouteFormScreen`: nome, descrição, `closeTime` (o horário de abertura não é editável — é
  sempre 00:00). Sub-seções:
  - **Instituições vinculadas** — adicionar/remover instituições cadastradas.
  - **Veículos disponíveis** — tipo + capacidade.
  - **Paradas/pontos no mapa** — nome + posição, com toggle "é ponto principal".

## Estados

- Nome de rota duplicado → erro de conflito.
- Instituição já vinculada a outra rota ativa → erro de conflito.
- Editar qualquer campo da rota dispara a notificação automática de mudança de regra (§3.4 do
  `spec.md`) — sem passo extra na UI, é automático ao salvar.

## Regras aplicáveis

`spec.md` §3.2. Backend: RN9, RN15, RN16, RN18, RN19, RN23 (paradas/pontos principais).
