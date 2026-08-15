# Spec — Cadastro por Convite

> Tela: `RegisterScreen` · Rota: `/register/:token` (entrada via App Link/Universal Link) ·
> Acesso: 🌐 · Provider: `RegistrationProvider`
> Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §3.1.

## Objetivo

Autocadastro do aluno a partir do convite gerado pelo admin — substitui o cadastro manual.

## Dados & contrato

- Abertura: `GET /api/registration/invite/{token}` valida o token e traz o e-mail do convite.
  Token inválido/expirado → tela de erro, sem formulário.
- Submissão: `POST /api/registration/{token}/submit`
  `{fullName, password, institutionId, course?, phone?, address?, birthDate?}` →
  `{status: "SUBMITTED"}`.
- Lista de instituições pro dropdown: `GET /api/institutions`.

## Layout / campos

- E-mail (pré-preenchido, somente leitura), nome completo, senha, instituição (dropdown),
  campos opcionais (curso, telefone, endereço, data de nascimento).

## Estados

- Token inválido/expirado → tela de erro dedicada, sem formulário.
- Submissão com sucesso → tela de confirmação "Cadastro enviado, aguardando aprovação do
  administrador".
- Reenvio (cadastro negado antes, token ainda válido): cai no mesmo endpoint de submit — sem
  tela separada de "negado", só a confirmação de novo.
- Validação de campo obrigatório antes de enviar.

## Regras aplicáveis

`spec.md` §3.1. Backend: RN13, RN14, RN15.
