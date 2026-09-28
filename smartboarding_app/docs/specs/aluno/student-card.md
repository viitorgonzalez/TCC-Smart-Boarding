# Carteirinha de estudante virtual

**Rota:** empurrada do perfil (`profile_open_student_card`) · **Papel:** `STUDENT`

## O que é

Uma tela que o aluno aponta pra outra pessoa numa conferência. Não é documento
oficial nem prova de matrícula — o app sabe o que o aluno **declarou**, e não
valida vínculo com a instituição. A tela diz isso explicitamente; sem esse
aviso ela viraria um documento com aparência de oficial que ninguém auditou.

## O que mostra

| Bloco | Origem |
|---|---|
| Nome completo | `GET /api/me` → `fullName` |
| Instituição | `GET /api/me` → `institution` (nome, não id) |
| Curso | `GET /api/me` → `course` (omitido se vazio) |
| Endereço | `GET /api/me` → `address.shortForm` |

`shortForm` é **rua, número e bairro**, calculado no backend (`Address.shortForm`).
Sem CEP e sem cidade: nenhum dos dois identifica alguém numa conferência
presencial, e CEP é dado que não precisa circular numa tela que se mostra pra
outra pessoa. O e-mail também fica de fora.

Há teste de widget garantindo que CEP, cidade e e-mail **não** aparecem.

## Validade

Vale enquanto o aluno estiver **ativo e vinculado a uma rota** — que é
exatamente o que ela atesta. Não há campo de data.

> ⚠️ **Não usar `users.expiry_date` pra isso.** Aquela coluna alimenta o
> `isAccountNonExpired()` do Spring Security: preenchê-la com validade de
> carteirinha faria o aluno **perder o login** no dia do vencimento. São coisas
> diferentes com nomes parecidos.

## Estados

| Situação | O que aparece |
|---|---|
| Perfil incompleto | Aviso nomeando o que falta. Carteirinha com lacuna não serve pra conferência, e meia linha de endereço parece dado perdido. |
| Sem rota ativa | "Sem vínculo ativo" — é a condição de validade. |
| Tudo em ordem | O cartão. |

## Decidido ficar de fora

- **Foto** — não há campo em `users`; adicionar significa upload, storage e
  moderação. É outra frente.
- **QR code** — só faz sentido se alguém for escanear. Se a conferência é
  visual, é enfeite.
