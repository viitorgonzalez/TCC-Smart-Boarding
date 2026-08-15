# Spec — Painel do Admin

> Tela: `AdminHomeScreen` · Acesso: 🧑‍💼
> Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §2.

## Objetivo

Dashboard com atalhos pras áreas de gestão do admin.

## Dados & contrato

- Contagem de pendências: `GET /api/registration/pending` (tamanho da lista, pro badge).

## Layout / seções

Cards de atalho:
- Solicitações de Cadastro (badge com contagem de pendentes).
- Gerenciar Rotas (rotas + instituições + veículos + paradas).
- Trajeto.
- Notificações (inbox + enviar).
- Relatórios.
- Usuários (listagem).

## Estados

- Badge de pendências zerado quando não há solicitações.

## Regras aplicáveis

`spec.md` §2.
