# Design — Acesso administrativo por promoção

> 12/09/2026 · substitui a criação de conta admin por outro admin.

## Problema

O SmartBoarding passou a tratar **criar conta** como responsabilidade do usuário. Foi
por isso que o convite deixou de ser de conta e virou de **rota**: qualquer um cria a
própria conta, e o acesso a uma rota é concedido depois, por um código.

Um lugar ficou para trás. `POST /api/auth/register` ainda deixa um admin **criar a
conta** de outro admin, escolhendo o e-mail e digitando a senha da pessoa. Isso carrega
dois problemas:

1. **Contradiz o modelo.** É o último ponto onde o sistema cria conta pra alguém.
2. **Terceiro conhece a credencial.** O admin que cria digita a senha inicial de outra
   pessoa, e nada garante que ela troque. Quem criou continua sabendo entrar.

E, do outro lado, o requisito oposto: **não pode qualquer um virar admin**. Autocadastro
aberto resolve o item 1 e destrói esse requisito.

## Decisão

Separar as duas coisas, como já foi feito com a rota:

> **Conta é criada pelo dono. Papel administrativo é concedido.**

Ninguém cria conta de admin. A pessoa se cadastra como qualquer outra, e um admin
**promove a conta existente**.

### O que foi considerado e descartado

**Código de convite de admin**, simétrico ao código de rota. Descartado porque um código
que concede admin é um segredo portátil: vazou no grupo da equipe, quem achar vira
admin. O código de rota pode vazar sem consequência séria; esse não.

**Domínio institucional** (`@...gov.br` pede acesso, admin aprova). Descartado porque
depende de um domínio que nem todos têm — motorista terceirizado, por exemplo — e o
e-mail sozinho não prova cargo, então ainda precisaria de aprovação. Complexidade a mais
pro mesmo resultado.

### Papéis continuam dois

`ADMIN` e `STUDENT`, sem subdivisão. Hoje o motorista e a equipe da prefeitura são ambos
`ADMIN`, com os mesmos poderes — inclusive o de promover.

Isso é **decisão consciente**, tomada em 12/09/2026: separar em `MOTORISTA` e `GESTOR`
foi avaliado e adiado por não valer o custo na escala atual. A consequência que fica
valendo é que o motorista pode promover pessoas e mexer em cadastro. Se a equipe crescer
a ponto de isso incomodar, a separação volta à mesa — e este parágrafo existe pra que
essa volta seja uma decisão, não uma descoberta.

## Contrato

### Sai

`POST /api/auth/register`, `RegisterUseCase`, `RegisterRequest`.

### Entra

`PATCH /api/users/{id}/role` `{"role": "ADMIN" | "STUDENT"}` → `UserResponse` · **ADMIN**

Qualquer outro valor é `400` de validação. Não existe papel além desses dois.

Promove e rebaixa: quem entra também precisa poder sair, e rebaixar é como um motorista
que troca de emprego perde o acesso.

| Situação | Resposta |
|---|---|
| Promoção ou rebaixamento válido | `200` |
| Papel já é o pedido | `200`, sem efeito e sem log |
| Rebaixar a própria conta | `400 CANNOT_DEMOTE_SELF` |
| Rebaixar o último admin ativo | `400 LAST_ADMIN` |
| Promover conta desativada | `400 INACTIVE_ACCOUNT` |
| Usuário inexistente | `404` |

### As travas, e por que cada uma existe

1. **Não rebaixa a si mesmo.** Espelha a trava de autodesativação já existente. Um
   clique errado tiraria o próprio acesso de quem está operando.
2. **Não rebaixa o último admin ativo.** Sem admin nenhum, ninguém promove ninguém de
   volta — a recuperação seria editar o banco à mão. É a trava que impede o sistema de
   se trancar por fora.
3. **Promover só conta ativa.** Promover alguém desativado produz um admin que não
   consegue entrar: um estado que a interface mostra como acesso concedido e o login
   nega.
4. **Idempotente.** `PATCH .../role` é uma **declaração de estado** ("o papel desta
   pessoa é ADMIN"), não uma ação. A mesma declaração repetida tem que dar o mesmo
   resultado: duplo toque, retry de requisição que deu timeout e dois admins agindo ao
   mesmo tempo não podem virar erro. O operador ainda é informado — pela interface, que
   não oferece o botão a quem já é admin, não por erro da API.

   Contrastar com `ALREADY_MEMBER` ao entrar numa rota, que **é** `409`: lá repetir é um
   engano com efeito colateral (cria vínculo, conta na lista). Aqui é estado.

### Remover um admin

Duas ações deliberadas, nesta ordem: **rebaixar** e depois **desativar**. Desativar um
`ADMIN` continua recusado (`CANNOT_DEACTIVATE_ADMIN`), o que hoje é uma trava sem saída
e passa a ser o primeiro passo de um caminho que existe.

### O que acontece com os vínculos de quem é promovido

**Nada.** As linhas de `route_members` e `user_institutions` da pessoa permanecem
intactas na promoção e no rebaixamento.

A alternativa — apagar os vínculos ao promover — foi descartada porque destrói dado que
não dá pra reconstruir e quebra a reversibilidade: rebaixar deixaria a pessoa sem as
rotas que ela tinha, e o histórico de presença ficaria órfão.

**Consequência a conhecer:** um aluno promovido continua inscrito nas rotas dele e segue
aparecendo na lista do dia e na contagem que propõe o veículo. Hoje isso não acontece
(nenhum dos 4 admins tem vínculo), e quando acontecer a saída é a própria pessoa sair da
rota — `DELETE /api/me/routes/{routeId}`, que ela já pode fazer sozinha. Se virar rotina,
aí sim vale automatizar; enquanto for exceção, apagar dado por precaução custa mais do
que resolve.

## Auditoria

`UserStatusAction` ganha `PROMOTED` e `DEMOTED`. O `user_status_log`
(`user_id`, `admin_id`, `action`, `created_at`) passa a responder "o que foi feito nesta
conta, por quem e quando" incluindo papel. **Nenhuma migration de estrutura**: a tabela
já tem a forma certa e `action` é `VARCHAR(20)`.

## Primeiro admin

O caminho A abre um buraco: num banco novo não existe admin, logo não há quem promove.
Hoje isso vem do seed, que não vai pra produção.

**`BOOTSTRAP_ADMIN_EMAIL`**: no cadastro, se o e-mail que está se cadastrando bate com a
variável **e o sistema tem zero admins**, a conta nasce `ADMIN`.

- **A pessoa ainda cria a própria conta.** A variável concede, não cria — o princípio
  vale sem exceção.
- **A janela fecha sozinha.** Assim que existe um admin, a condição nunca mais é
  verdadeira, mesmo com a variável configurada pra sempre.
- **Fica auditado**, com `admin_id` nulo: a coluna já é nullable e nulo significa "foi o
  sistema".
- **Não exige reiniciar.** Promover no boot obrigaria a subir, cadastrar e reiniciar —
  atrito numa operação que acontece uma vez.

Em desenvolvimento nada muda: o seed cria admins, a condição "zero admins" é falsa e o
gatilho nunca dispara.

## Interface

A folha que hoje tem o switch "Conta ativa" na tela de usuários recebe o papel. As travas
aparecem como **ausência de opção**, não como erro depois do toque:

- Na própria conta, a opção de papel não aparece.
- No último admin ativo, rebaixar fica desabilitado com o motivo à vista.
- Em conta desativada, promover fica desabilitado com o motivo à vista.

## Janela residual

O papel viaja no JWT, que vale 1 hora. **Quem for rebaixado mantém poderes de admin até
o token expirar.** Fechar isso exigiria consultar o banco a cada requisição — mesma
janela que a desativação já tem, e mesma decisão.

## Testes

Um por trava (auto-rebaixamento, último admin, conta desativada, idempotência), mais o
bootstrap nos dois estados: com zero admins promove, com admin existente não promove.
Cada um escrito para reprovar sem a correção.

## Documentação afetada

- `smartboarding-api/docs/spec.md`: RN13 passa a descrever promoção; RN nova para o
  bootstrap; contratos do `register` saem da tabela de endpoints.
- `smartboarding_app/docs/PAGES.md`: linha de gestão de papel na tela de usuários.
