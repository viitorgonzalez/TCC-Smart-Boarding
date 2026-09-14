# Spec — Login

> Tela: `LoginScreen` · Acesso: 🌐 → 🎓🧑‍💼 · Provider: `AuthProvider`
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.7.

## Objetivo

Gate do app. Autentica e redireciona por papel (`ADMIN` → painel admin, `STUDENT` → início do
aluno).

## Dados & contrato

- `POST /api/auth/login` `{email, password}` → `{token, fullName, role, email}`.
- `POST /api/auth/google` `{idToken}` → mesma sessão. O botão só aparece em build com
  `--dart-define=GOOGLE_WEB_CLIENT_ID`.
- Sessão de 1h, sem refresh token. O `email` vem do servidor porque quem entra pelo
  Google nunca o digita — sem ele o app não sabe de quem é a sessão.
- Conta desativada pelo admin recebe mensagem própria, diferente de credencial inválida:
  quem foi desativado precisa saber que o problema não é a senha.

## Layout / campos

- E-mail, senha, checkbox "Lembrar de mim", botão "Entrar", link "Esqueci minha senha".

## Estados

- Loading durante submit.
- Credencial inválida → mensagem genérica de erro.
- Cadastro `PENDING`/`SUBMITTED` (ainda não aprovado) → mensagem dedicada ("Seu cadastro ainda
  está em análise"), não o erro genérico.
- Conta expirada (`ACCOUNT_EXPIRED`) → "Sua carteirinha de transporte expirou — procure o
  administrador".
- Sucesso → navega por papel.

## Regras aplicáveis

`spec.md` §3.6 (expiração), §3.7 (sessão longa). Backend: RN10, RN12, RN14, RN21.
