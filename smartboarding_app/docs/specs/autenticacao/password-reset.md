# Spec — Recuperação de Senha

> Telas: `ForgotPasswordScreen`, `ResetPasswordScreen` · Acesso: 🌐 · Provider: `AuthProvider`
> Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §3.

## Objetivo

Aluno/admin que esqueceu a senha pede um link por e-mail e define uma nova.

## Dados & contrato

- `ForgotPasswordScreen`: `POST /api/auth/forgot-password {email}` → `{success:true}` sempre
  (mesmo se o e-mail não existir — não confirma se a conta existe).
- `ResetPasswordScreen` (aberta a partir do link do e-mail, com o token na URL):
  `POST /api/auth/reset-password {token, newPassword}` → `{success:true}` ou erro de token
  inválido/expirado.

## Layout / campos

- Esqueci senha: só e-mail + botão enviar.
- Redefinir senha: nova senha + confirmar senha.

## Estados

- Esqueci senha: sempre mostra confirmação de envio (nunca revela se o e-mail existe).
- Redefinir: token inválido/expirado → mensagem de erro, sem formulário; sucesso → confirmação +
  volta pro login.

## Regras aplicáveis

Backend: RN22.
