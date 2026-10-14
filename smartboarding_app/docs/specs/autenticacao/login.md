# Spec — Login

> Tela: `LoginScreen` · Acesso: 🌐 → 🎓🧑‍💼 · Provider: `AuthProvider`
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.7.

## Objetivo

Gate do app. Autentica e redireciona por papel (`ADMIN` → painel admin, `STUDENT` → início do
aluno).

## Dados & contrato

- `POST /api/auth/login` `{email, password}` → `{token, fullName, role, email}`.
- `POST /api/auth/google` `{idToken}` → mesma sessão. O botão só aparece em build com
  `--dart-define=GOOGLE_WEB_CLIENT_ID`. Precisa ser o client ID **Web** do Google, não o do
  Android: é ele que vai no `aud` do ID token, e o backend compara com o mesmo valor —
  trocar pelo do Android faz o login falhar sempre, com erro que não aponta a causa. No app,
  esse valor entra como `serverClientId` na inicialização do `google_sign_in` — é o que faz o
  Google emitir um token endereçado à nossa API; sem ele o token sai endereçado ao app e o
  backend recusa no `aud`.
- Quem valida o ID token do Google é sempre o **backend**, contra o próprio Google — o app só
  transporta o token. Confiar no app pra dizer quem entrou deixaria qualquer um forjar uma
  sessão.
- `GoogleAuthService` falha (`StateError`) antes de abrir a tela de escolha de conta quando o
  build não tem `GOOGLE_WEB_CLIENT_ID` configurado — deixar passar faria o usuário escolher a
  conta pra só então tomar 401. No logout, desconectar do Google exige inicializar o SDK antes
  (`_garantirInicializado`): depois de reabrir o app, a sessão vem do `storage` e o `signIn()`
  nunca rodou naquele processo — sem inicializar, o `signOut()` seria no-op e o próximo login
  reentraria sozinho na conta anterior.
- Sessão de 1h, sem refresh token. O `email` vem do servidor porque quem entra pelo
  Google nunca o digita — sem ele o app não sabe de quem é a sessão. `AuthToken.fromLogin`
  aceita um e-mail de fallback (o digitado no formulário) só pra cobrir sessão de API antiga
  que ainda não mandava o campo; pelo Google não há fallback possível, o valor tem que vir da
  resposta.
- Conta desativada pelo admin recebe mensagem própria, diferente de credencial inválida:
  quem foi desativado precisa saber que o problema não é a senha.

## Layout / campos

- E-mail, senha, checkbox "Lembrar de mim", botão "Entrar", link "Esqueci minha senha".
- Logo no topo, sem repetir "Smart Boarding" em texto abaixo: a própria imagem já carrega o
  wordmark, e duplicar o nome na mesma dobra seria redundante. Largura da logo é proporcional à
  tela (não um valor fixo), pra não estourar a margem em aparelho estreito.

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
