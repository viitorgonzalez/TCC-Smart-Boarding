# Spec — Solicitações de Cadastro

> Tela: `RegistrationApprovalsScreen` · Acesso: 🧑‍💼 · Provider: `RegistrationProvider`
> Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §3.1.

## Objetivo

Admin revisa cadastros pendentes (aprovar/negar) e gera novos convites.

## Dados & contrato

- Lista: `GET /api/registration/pending` → inclui `institutionName` resolvido.
- Aprovar: `POST /api/registration/{id}/approve` → cria a conta de fato, copiando o nome da
  instituição escolhida pro `User`. Só aceita pedido `PENDING`; e-mail já cadastrado → conflito.
- Negar: `POST /api/registration/{id}/reject` `{reason}` — **motivo obrigatório** (máx. 500
  chars). Grava o motivo e dispara e-mail avisando o aluno, com o motivo e a instrução de pedir
  um novo código pra corrigir. Só aceita pedido `PENDING`.
- Gerar convite: `POST /api/registration/invite {email}` — envia o código de 6 dígitos.

## Layout / seções

- Lista de pendentes: nome, e-mail e instituição escolhida, botões "Aprovar"/"Negar".
- Aprovar: diálogo de confirmação simples.
- Negar: diálogo com campo de **motivo obrigatório** (multilinha, até 500 chars), explicando que
  o aluno recebe o motivo por e-mail e pode corrigir.
- Botão "Gerar convite" (só e-mail) pra iniciar um novo convite.

## Estados

- Lista vazia (sem pendências).
- Confirmação antes de aprovar/negar (evita ação acidental).
- Feedback de sucesso após aprovar/negar/gerar convite; erro do backend vira snackbar.

## Regras aplicáveis

`spec.md` §3.1. Backend: RN13, RN14.
