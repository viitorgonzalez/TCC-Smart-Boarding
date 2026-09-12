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
- `GET /api/users/admins/count` `{count}` — quantos admins existem. A ficha precisa disso pra
  saber se está olhando a última conta admin; contar no cliente exigiria baixar a listagem
  inteira — e-mail, telefone, endereço e nascimento de toda a base — a cada vez que a folha
  abre, de três telas diferentes.
- `PATCH /api/users/{id}/status` `{active}` — ativar/desativar.
- `PATCH /api/users/{id}/role` `{role: "ADMIN"|"STUDENT"}` — conceder/retirar acesso
  administrativo.

## Layout / seções

- **Seletor de rota** no topo, quando existe mais de uma.
- **Filtro por papel** (`ADMIN`, `STUDENT`); sem filtro, a lista agrupa por papel nessa ordem.
- **Lista**: nome, e-mail e papel. Tocar abre a ficha.
  - Mudou status ou papel na ficha, **a lista recarrega ao fechar**. O agrupamento e a etiqueta
    saem do papel; sem recarregar, o aluno recém-promovido continuaria no grupo "Alunos" com a
    etiqueta antiga até um pull-to-refresh. Fechar sem mexer em nada não custa requisição.

## A ficha do usuário

Abre como folha sobre a lista, com os dados cadastrais, as idas recentes e o histórico de
mudanças de status. Duas ações:

- **Conta ativa** (switch) — desativar impede a pessoa de entrar, por senha ou pelo Google, e
  o acesso cai na requisição seguinte: a autoridade de cada chamada é lida do banco, não da
  claim do token.
- **Acesso de administrador** — promove ou rebaixa a conta.

Cada mudança fica registrada com o nome de quem fez e a hora.

### As quatro travas aparecem na interface, não depois do toque

O backend recusa as quatro situações abaixo, mas a tela não deixa chegar lá: o admin não
descobre que não podia só quando a API responde erro.

| Situação | Na tela | Por quê |
|---|---|---|
| A conta é a sua | a opção de papel **não aparece** | um clique errado tiraria o próprio acesso, e só outro admin poderia devolver |
| É o último admin ativo | rebaixar fica **desabilitado** | sem admin nenhum, ninguém promove ninguém de volta — a saída seria editar o banco à mão |
| A conta está desativada | promover fica **desabilitado** | produziria um admin que não consegue entrar: a tela mostraria acesso concedido e o login negaria |
| A conta é de um admin ativo | o switch **Conta ativa** fica desabilitado, e o subtítulo vira "Remova o acesso de administrador antes de desativar." | desativar admin é recusado (`CANNOT_DEACTIVATE_ADMIN`); o fluxo é rebaixar e depois desativar, e quem fizesse na ordem errada levava o erro pós-toque sem saber qual era a saída |

Só o sentido **desativar** é barrado: reativar um admin inativo continua valendo, que é o que o
backend também aceita.

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
