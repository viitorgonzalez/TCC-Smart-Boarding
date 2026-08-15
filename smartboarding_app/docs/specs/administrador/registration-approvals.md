# Spec — Solicitações de Cadastro

> Tela: `RegistrationApprovalsScreen` · Acesso: 🧑‍💼 · Provider: `RegistrationProvider`
> Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §3.1.

## Objetivo

Admin revisa cadastros pendentes (aprovar/negar) e gera novos convites.

## Dados & contrato

- Lista: `GET /api/registration/pending`.
- Aprovar: `POST /api/registration/{id}/approve` → cria a conta de fato.
- Negar: `POST /api/registration/{id}/reject`.
- Gerar convite: `POST /api/registration/invite {email}`.

## Layout / seções

- Lista de pendentes: dados enviados pelo aluno + instituição escolhida, botões "Aprovar"/"Negar"
  (ambos com confirmação).
- Botão "Gerar convite" (só e-mail) pra iniciar um novo convite.

## Estados

- Lista vazia (sem pendências).
- Confirmação antes de aprovar/negar (evita ação acidental).
- Feedback de sucesso após aprovar/negar/gerar convite.

## Regras aplicáveis

`spec.md` §3.1. Backend: RN13, RN14.
