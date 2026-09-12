# Spec — Trajeto

> Tela: `TripScreen` (dentro do painel do admin) · Acesso: 🧑‍💼 · Provider: `TripProvider`
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.8.

## Objetivo

Admin conduz o trajeto do dia: inicia, passa por pontos principais, finaliza — cada ação avisa
os inscritos ativos por push.

## Dados & contrato

- Entrada pela tela da rota, na seção "Lista de hoje" (botão *Conduzir trajeto*).
- `GET /api/trip/{listId}` — estado atual, com os pontos principais e quais já foram marcados.
- `POST /api/trip/{listId}/start` — iniciar.
- `POST /api/trip/{listId}/checkpoint/{stopId}` — checkpoint (só aceito em pontos com
  `isMainPoint=true`).
- `POST /api/trip/{listId}/finish` — finalizar.

## Layout / seções

- Cartão com a rota do trajeto selecionado.
- Botão "Iniciar trajeto".
- Um botão de checkpoint por ponto principal da rota (rodoviária + instituições) — paradas
  comuns não aparecem aqui, só no mapa.
- Botão "Finalizar".

## Estados

- Confirmação antes de cada ação (evita toque acidental).
- Feedback pós-ação: "Notificação enviada para N alunos".
- Funciona com a lista `OPEN` ou `CLOSED` — o trajeto acontece depois do fechamento.

## Regras aplicáveis

`spec.md` §3.4, §3.8. Backend: RN20, RN23.
