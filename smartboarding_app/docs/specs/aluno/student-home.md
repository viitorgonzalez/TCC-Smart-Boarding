# Spec — Início do Aluno

> Tela: `StudentHomeScreen` · Acesso: 🎓 · Provider: `ListProvider`
> Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §3.2, §3.3.

## Objetivo

Tela principal do aluno: lista do dia da própria rota, mapa, entrar/sair.

## Dados & contrato

- Carrega `GET /api/lists/today` ao abrir + pull-to-refresh — já filtrado pela rota derivada da
  instituição do aluno (o aluno nunca escolhe rota).
- `POST /api/lists/{id}/entries {tripType?}` — entrar (default `ROUND_TRIP`).
- `DELETE /api/lists/{id}/entries` — sair.

## Layout / seções

- Card da rota: nome, contagem de inscritos, status, mapa (`google_maps_flutter`, pontos da
  rota — paradas e pontos principais, com ícone).
- Botão "Entrar na Lista" (não inscrito, lista `OPEN`) ou "Sair da Lista" + badge "Você está na
  lista" (inscrito).
- Acesso à tela de notificações e à tela de relatórios (últimos 7 dias).

## Estados

- Sem lista `OPEN` → mensagem explicativa com o horário real de fechamento **daquela rota**.
- Loading, erro de fetch, sucesso.
- `403 ACCOUNT_EXPIRED` ao entrar na lista → mensagem dedicada de carteirinha expirada.

## Regras aplicáveis

`spec.md` §3.2, §3.3, §3.6. Backend: RN1-RN7, RN12, RN15.
