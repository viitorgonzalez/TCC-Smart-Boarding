# Spec — Cadastro e entrada na rota

> Telas: `SignupScreen` (cadastro) + `JoinRouteScreen` (código) · Acesso: 🌐 / 🎓
> Providers: `AuthProvider`, `MembershipProvider`
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md) §3.1.

## Objetivo

O aluno cria a própria conta e entra numa rota com um código que o admin distribui —
modelo do Google Classroom. Substitui o convite por e-mail com aprovação do admin,
removido em setembro/2026.

## Duas coisas separadas, de propósito

**Existir no sistema** e **pertencer a uma rota** são etapas distintas. A conta nasce
sem rota nenhuma: quem cria a conta ainda não é aluno de lugar algum, e o admin não
precisa aprovar ninguém pra isso acontecer.

### 1. Cadastro — o mínimo

`POST /api/auth/signup` `{fullName, email, password}` → `{token, fullName, role, email}` (201)

Só três campos. Instituição, curso, telefone e endereço ficam pro perfil: pedir tudo
na primeira tela afasta quem só quer ver se o app serve pra ele.

- Senha: mínimo 6 caracteres (RN10), confirmação obrigatória na tela.
- E-mail duplicado → `409`. **Sem anti-enumeração aqui, de propósito**: o cadastro
  precisa dizer "esse e-mail já tem conta", senão a pessoa não sabe que deve entrar
  em vez de cadastrar. O login e o "esqueci a senha" continuam anti-enumeração.
- A resposta já traz a sessão — o aluno cai logado, sem redigitar o que acabou de
  digitar.

**Entrar com Google** (`POST /api/auth/google` `{idToken}`) é caminho alternativo e
devolve a mesma sessão. Quem entrou assim pode criar uma senha local depois
(`POST /api/me/password`) e passa a ter os dois caminhos. Requer a build com
`--dart-define=GOOGLE_WEB_CLIENT_ID`; sem ele o botão não aparece.

### 2. Perfil — pré-requisito

Antes do código, o aluno precisa ter **ao menos uma instituição** declarada no perfil.
Sem isso a API recusa a entrada com `PROFILE_INCOMPLETE`, e a tela do código mostra o
atalho "Ainda não defini minha instituição" antes de ele digitar qualquer coisa.

A instituição é o que diz onde o aluno desce e em que contagem ele entra na lista do
dia — deixar entrar sem ela poria na lista alguém que o motorista não sabe onde deixar.

### 3. Código da rota

`POST /api/me/routes` `{code}` → `RouteResponse`

- O admin gera em `POST /api/routes/{routeId}/invite-codes` e distribui como quiser.
- Validade padrão de **90 dias** (`ROUTE_INVITE_VALIDITY_DAYS`), revogável.
- O código é normalizado (trim + maiúsculas): espaço colado e minúscula são erro de
  digitação, não código errado.
- O aluno pode pertencer a **mais de uma rota**. A porta pro código fica fixa no
  cabeçalho da home, não só no estado "sem rota".

| Erro | Código | Quando |
|---|---|---|
| `400` | `INVALID_CODE` | vazio ou inexistente |
| `400` | `PROFILE_INCOMPLETE` | perfil sem instituição |
| `400` | `CODE_REVOKED` | admin cancelou |
| `400` | `CODE_EXPIRED` | passou da validade |
| `409` | `ALREADY_MEMBER` | já está nessa rota |

Expirado e revogado são mensagens diferentes de propósito: o aluno precisa saber se
pede um código novo ou se errou a digitação. O código não é dado pessoal, então
distinguir não entrega nada a ninguém.

## Sair da rota

`DELETE /api/me/routes/{routeId}` — o usuário sai do próprio vínculo; o id vem do
token, nunca do request.
