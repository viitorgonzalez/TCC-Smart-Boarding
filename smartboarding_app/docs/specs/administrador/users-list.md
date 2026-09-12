# Spec — Usuários

> Telas: `UserManagementScreen` (listagem) + `StudentProfileSheet` (ficha) · Acesso: 🧑‍💼 ·
> Provider: `UserProvider`
> Base: [`../../PAGES.md`](../../PAGES.md), [`../../spec.md`](../../spec.md) §2.

## Objetivo

Ver quem usa o sistema e administrar o acesso de cada conta. **Não há criação de conta aqui** —
conta é criada pelo próprio dono (§3.1); o que o admin faz nesta tela é conceder e retirar
acesso, não cadastrar gente.

## Dados & contrato

- `GET /api/users` — listagem, com filtro opcional por rota.
- `GET /api/users/{id}/profile` — ficha completa, ao tocar num usuário.
- `PATCH /api/users/{id}/status` `{active}` — ativar/desativar.
- `PATCH /api/users/{id}/role` `{role: "ADMIN"|"STUDENT"}` — conceder/retirar acesso
  administrativo.

## Layout / seções

- **Seletor de rota** no topo, quando existe mais de uma.
- **Filtro por papel** (`ADMIN`, `STUDENT`); sem filtro, a lista agrupa por papel nessa ordem.
- **Lista**: nome, e-mail e papel. Tocar abre a ficha.

## A ficha do usuário

Abre como folha sobre a lista, com os dados cadastrais, as idas recentes e o histórico de
mudanças de status. Duas ações:

- **Conta ativa** (switch) — desativar impede a pessoa de entrar, por senha ou pelo Google. O
  token já emitido vale até expirar (1h).
- **Acesso de administrador** — promove ou rebaixa a conta.

Cada mudança fica registrada com o nome de quem fez e a hora.

### As três travas aparecem na interface, não depois do toque

O backend recusa as três situações abaixo, mas a tela não deixa chegar lá: o admin não descobre
que não podia só quando a API responde erro.

| Situação | Na tela | Por quê |
|---|---|---|
| A conta é a sua | a opção de papel **não aparece** | um clique errado tiraria o próprio acesso, e só outro admin poderia devolver |
| É o último admin ativo | rebaixar fica **desabilitado** | sem admin nenhum, ninguém promove ninguém de volta — a saída seria editar o banco à mão |
| A conta está desativada | promover fica **desabilitado** | produziria um admin que não consegue entrar: a tela mostraria acesso concedido e o login negaria |

A trava do último admin depende de saber quantos admins existem. Enquanto essa contagem não
chega — carregando ou falhou —, a opção fica **habilitada** de propósito, e o backend recusa se
for o caso. Desabilitar por falta de dado bloquearia uma ação legítima.

## Estados

- Lista: carregando, vazia (por filtro ou por rota), erro de fetch.
- Ficha: carregando, erro, e o estado ocupado que bloqueia as duas ações durante uma requisição.

## Regras aplicáveis

`spec.md` §2 (papéis), §3.1 (cadastro e entrada na rota).
Backend: RN27 (papel é concessão) e RN28 (primeiro admin) em
[`smartboarding-api/docs/spec.md`](../../../../smartboarding-api/docs/spec.md) §4.1.
