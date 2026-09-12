# Spec — Recuperação de Senha

> Telas: `ForgotPasswordScreen`, `ResetPasswordScreen` · Acesso: 🌐 · Provider: `AuthProvider`
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.

## Objetivo

Aluno/admin que esqueceu a senha pede um código por e-mail e define uma nova.

## Dados & contrato

- `ForgotPasswordScreen`: `POST /api/auth/forgot-password {email}` → `{success:true}` sempre
  (mesmo se o e-mail não existir — não confirma se a conta existe).
- `ResetPasswordScreen` (aberta a partir da tela anterior, recebendo o e-mail):
  `POST /api/auth/reset-password {email, code, newPassword}` → `{success:true}` ou erro de código
  inválido/expirado/tentativas esgotadas. O código de 6 dígitos é digitado nesta mesma tela, acima
  dos campos de senha — não vem por URL.

## Layout / campos

- Esqueci senha: só e-mail + botão enviar.
- Redefinir senha: código recebido por e-mail + nova senha + confirmar senha.

## Estados

- Esqueci senha: sempre mostra confirmação de envio (nunca revela se o e-mail existe).
- Redefinir: token inválido/expirado → mensagem de erro, sem formulário; sucesso → confirmação +
  volta pro login.

## Regras aplicáveis

Backend: RN22.
