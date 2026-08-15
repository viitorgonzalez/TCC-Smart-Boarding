# Spec — Notificações (Inbox + Envio)

> Telas: `NotificationsInboxScreen`, `SendNotificationScreen` · Acesso: inbox 🎓🧑‍💼, envio 🧑‍💼
> Provider: `NotificationProvider` · Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §3.4.

## Objetivo

Histórico de notificações (aluno e admin) + envio manual pelo admin, com imagem opcional.

## Dados & contrato

- Inbox: `GET /api/notifications?page&size` — filtrado por escopo/rota do usuário logado.
- Envio: `POST /api/notifications/upload-image` (multipart, se houver imagem) →
  `{imageUrl}`, depois `POST /api/notifications {title, body, imageUrl?, scope, routeId?}`.

## Layout / seções

- Inbox: lista cronológica, cada item com título, corpo, imagem (se houver), rota (se
  `scope=ROUTE`), data.
- FAB estilo "compor" do Gmail (só visível pro `ADMIN`) → abre `SendNotificationScreen`: título,
  corpo, picker de imagem, seletor de escopo (geral ou uma rota específica), confirmação antes
  de enviar.

## Estados

- Inbox vazia, loading, erro de fetch.
- Envio: validação de campos obrigatórios, confirmação antes de disparar, feedback de sucesso.

## Regras aplicáveis

`spec.md` §3.4. Backend: RN19, RN20.
