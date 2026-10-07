# Spec — Advertências

> Tela: `WarningsScreen` · Acesso: 🎓 (as próprias) e 🧑‍💼 (todas)
> Base: [`../PAGES.md`](../../PAGES.md), [`../spec.md`](../../spec.md)

## Objetivo

Registrar que o aluno entrou na lista fora do prazo e precisou do admin. Colocar o nome no horário
é responsabilidade dele; a advertência é a memória disso — não uma punição automática.

## Dados & contrato

- Aluno: `GET /api/warnings/me` (resolve o usuário pelo token — sem parâmetro, pra não virar
  caminho de leitura das advertências alheias).
- Admin: `GET /api/warnings` (todas) ou `?userId=` (de um aluno); `DELETE /api/warnings/{id}`.
  Resposta paginada (`{content, totalPages, ...}`, `page`/`size` na query, default `size=20`) —
  a tela carrega mais conforme rola, igual Relatórios. `/me` do aluno não pagina: devolve a
  lista inteira direto (`{data: [...]}`), por ser curta.
- Origem: `POST /api/lists/{id}/entries/admin {userId, tripType?, issueWarning, warningReason?}`,
  de `AdminListEntriesScreen`. Entra mesmo com a lista fechada — é justamente a inclusão tardia
  que motiva a tela existir. `issueWarning` é escolha do admin a cada inclusão: colocar o nome
  no prazo é responsabilidade do aluno, mas nem todo atraso é culpa dele. O aluno adicionado
  assim (`ListEntry.addedByAdmin`, que assume `false` quando o campo nem vem no JSON — backend
  antigo em cache ou resposta parcial não pode estourar o parsing da lista inteira) fica marcado
  na lista com um selo "Incluído pelo admin" — a
  lista e o relatório precisam deixar isso visível, com ou sem advertência junto. O seletor de
  aluno (`StudentPicker`) busca todos os alunos da rota de uma vez (não só a primeira página):
  a folha tem busca por nome, e buscar dentro de um pedaço só encontraria quem calhou de vir
  primeiro. A confirmação final (`confirmEnroll`) é uma tela separada de `EnrollSheet`, de
  propósito: a ação é irreversível pelo lado do aluno — a advertência entra no histórico dele, e
  tirar de lá exige o admin apagar à mão.

## Layout / seções

- Cartão por advertência: motivo, data da lista de origem, quando foi emitida e por quem.
  `listDate` vem nulo quando a lista de origem já foi apagada — o cartão omite essa linha nesse
  caso.
- Admin vê o nome do aluno e o botão de remover; o aluno vê só as próprias, sem ações.
- Vazio para o aluno: "Você não tem advertências".

## Estados

- `issueWarning: false` inclui na lista **sem** gerar advertência — a escolha é do admin.
- Motivo em branco cai no texto padrão ("Inscrição feita pelo administrador fora do horário").
- Aluno chamando `GET /api/warnings` recebe `403`.
- Falha no push não desfaz a inscrição nem a advertência (o registro é o que sobrevive).

## Regras aplicáveis

Backend: RN26. Relacionadas: RN18, RN24.
