# Spec — Login

> Tela: `LoginScreen` · Acesso: 🌐 → 🎓🧑‍💼 · Provider: `AuthProvider`
> Base: [`../PAGES.md`](../PAGES.md), [`../spec.md`](../spec.md) §3.7.

## Objetivo

Gate do app. Autentica e redireciona por papel (`ADMIN` → painel admin, `STUDENT` → início do
aluno).

## Dados & contrato

- `POST /api/auth/login` `{email, password, rememberMe?}` → `{token, fullName, role,
  refreshToken?}`.
- `rememberMe` marcado grava o `refreshToken` no `StorageService`; sem ele, sessão de 1h só.

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
