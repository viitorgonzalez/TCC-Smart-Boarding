# Spec — Relatórios

> Telas: `ReportsListScreen`, `ReportDetailScreen` · Acesso: 🎓 (7 dias) / 🧑‍💼 (completo)
> Provider: `ReportProvider` · Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.5.

## Objetivo

Histórico de fechamentos de lista, com o snapshot dos inscritos e o veículo proposto.

## Dados & contrato

- Lista: `GET /api/reports?page&size&sort=generatedAt,desc` — o backend já filtra pra 7 dias se
  quem pede é `STUDENT`; `ADMIN` vê tudo.
- Detalhe: `GET /api/reports/{id}` (só `ADMIN`) — snapshot completo + veículo(s) proposto(s).

## Layout / seções

- Lista: data, rota, total de inscritos por relatório.
- Detalhe (admin): nome/e-mail dos inscritos no fechamento + veículo(s) proposto(s)
  (`proposedVehicles`).

## Estados

- Lista vazia (aluno sem relatórios recentes, ou rota nova).
- Loading, erro de fetch, paginação (admin).

## Regras aplicáveis

`spec.md` §3.5. Backend: RN8, RN16, RN17.
