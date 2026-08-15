# Spec — Usuários

> Tela: `UserManagementScreen` (só listagem) · Acesso: 🧑‍💼 · Provider: `UserProvider`
> Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §2.

## Objetivo

Visualizar contas ativas do sistema — sem formulário de criação (aluno nasce só por convite).

## Dados & contrato

- `GET /api/users` / `GET /api/users/{id}`.

## Layout / seções

- Lista simples: nome, e-mail, papel.

## Estados

- Lista vazia, loading, erro de fetch.

## Regras aplicáveis

`spec.md` §2, §3.1.
