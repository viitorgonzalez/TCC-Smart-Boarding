# Cadastro aberto + código de convite por rota

**Aberto em:** 11/09/2026 · **Branch:** `feature/hardening-pre-producao` · **Status:** decidido, não iniciado

## A mudança

O convite deixa de ser o portão para **criar conta** e vira a chave para **entrar
numa rota** — modelo Google Classroom.

| | Hoje | Depois |
|---|---|---|
| Criar conta | Só por convite do admin (RN13) + aprovação (RN14) | Aluno se cadastra sozinho |
| Chegar na rota | Derivada: aluno → instituição → rota (RN15) | Concedida: aluno digita código da rota |
| Instituição | **Decide** a rota do aluno | Só informação + contagem por instituição |

## Decisões do autor (11/09/2026)

1. **Aluno pode estar em várias rotas** → tabela `route_members`, não coluna.
2. **Fluxo antigo sai inteiro** → `RegistrationRequest`, 8 use cases, fila e 3 telas removidos; migration dropa a tabela.
3. **O código basta** → sem aprovação depois de usar.
4. **Código reutilizável por rota, até expirar** → um código serve a turma toda, com data de expiração, revogação e contagem de uso.

## Risco que não pode ser esquecido

Os alunos de hoje têm rota via `institution_id → institution.route_id`. A migration
**tem que carregar esse vínculo para `route_members` no mesmo passo**. Sem isso,
todo aluno existente perde a rota no deploy, e o dado de quem estava em qual rota
não existe em nenhum outro lugar para reconstruir.

## Tasks abertas

| # | Task |
|---|---|
| 65 | Fundação: `route_members` + `route_invite_codes` + migração dos vínculos atuais |
| 66 | Trocar `routeOf(aluno)` por membership em `findTodayLists`, inbox e filtro de usuários |
| 67 | Cadastro próprio (endpoint público + tela) |
| 68 | Código da rota: gerar, usar, expirar, revogar |
| 69 | Remover o fluxo antigo (só depois do novo verde) |
| 70 | App: seletor de rota e estado "sem rota" |

Pendentes de antes, não relacionadas: **62** (instituições como tela própria),
**63** (simplificar trajeto), **64** (perfil + solicitação de atualização).

## Onde mexer

- Cadeia atual a substituir: `ListUseCaseImpl.routeOf()` (linha ~117).
- Quem usa `getInstitutionId()`: `ListUseCaseImpl`, `NotificationUseCaseImpl`,
  `RegistrationUseCaseImpl`, `ListController`, `UserController` + DTOs de registration.
- Última migration aplicada: **V21** (`user_status_log`). A nova entra como V22.
- Gate de cobertura ligado: **90%** em `application.*`, **70%** no resto. Código
  novo sem teste reprova o build.
