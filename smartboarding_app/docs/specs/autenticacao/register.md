# Spec — Cadastro por Convite

> Telas: `VerifyInviteCodeScreen` (entrada) + `RegisterScreen` (formulário) ·
> Acesso: 🌐 · Provider: `RegistrationProvider`
> Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §3.1.

## Objetivo

Autocadastro do aluno a partir do convite gerado pelo admin — substitui o cadastro manual.

## Entrada: código, não link

O convite chega por e-mail como **código de 6 dígitos**, não como link. App Link `https://` exige
domínio publicado e verificado (`assetlinks.json`), que é pendência de deploy — o código funciona
sem nenhuma dependência de domínio, em dev e em produção. O token de 64 chars continua existindo,
mas só internamente: a verificação do código o devolve pro app, que o usa no submit.

- Código: validade de **15 minutos**, guardado em hash, **5 tentativas** no máximo.
- Token: validade de **7 dias** (RN13).

## Dados & contrato

- Verificar código: `POST /api/registration/verify-code` `{email, code}` → `{token}`.
- Pedir novo código: `POST /api/registration/resend-code` `{email}` → reusa o **mesmo** pedido
  (preserva os dados já enviados). Cooldown de 60s entre pedidos.
- Abertura do formulário: `GET /api/registration/invite/{token}` → `{email, status,
  rejectionReason, fullName, institutionId, course, phone, address, birthDate}`.
  Token inválido/expirado → tela de erro, sem formulário. Cadastro já aprovado → erro
  (`ALREADY_APPROVED`).
- Submissão: `POST /api/registration/{token}/submit`
  `{fullName, password, institutionId, course?, phone?, address?, birthDate?}` →
  `{status: "SUBMITTED"}`.
- Lista de instituições pro dropdown: `GET /api/institutions`.

## Layout / campos

- E-mail (pré-preenchido, somente leitura), nome completo, senha (mín. 6), instituição (dropdown).
- Campos opcionais (curso, telefone, endereço, data de nascimento) estão no contrato da API e no
  prefill, mas **ainda não têm campo na tela** — pendência conhecida.

## Estados

- Token inválido/expirado/já aprovado → tela de erro dedicada, sem formulário, com ação de voltar.
- Submissão com sucesso → tela de confirmação "Cadastro enviado, aguardando aprovação do
  administrador", com ação de voltar pro login.
- **Cadastro negado (RN14):** o aluno recebe e-mail com o motivo. Ao voltar (pedindo um novo
  código na tela de entrada), o formulário abre com um aviso de negação exibindo o motivo, com os
  dados anteriores **já preenchidos** — a senha não, é sempre redigitada. O botão vira
  "Reenviar cadastro". Reenviar limpa o motivo e volta o pedido pra `PENDING`.
- Validação de campo obrigatório antes de enviar.

## Regras aplicáveis

`spec.md` §3.1. Backend: RN13, RN14, RN15.
