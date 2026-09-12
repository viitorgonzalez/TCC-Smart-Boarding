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
- Origem: `POST /api/lists/{id}/entries/admin {userId, tripType?, issueWarning, warningReason?}`.

## Layout / seções

- Cartão por advertência: motivo, data da lista de origem, quando foi emitida e por quem.
- Admin vê o nome do aluno e o botão de remover; o aluno vê só as próprias, sem ações.
- Vazio para o aluno: "Você não tem advertências".

## Estados

- `issueWarning: false` inclui na lista **sem** gerar advertência — a escolha é do admin.
- Motivo em branco cai no texto padrão ("Inscrição feita pelo administrador fora do horário").
- Aluno chamando `GET /api/warnings` recebe `403`.
- Falha no push não desfaz a inscrição nem a advertência (o registro é o que sobrevive).

## Regras aplicáveis

Backend: RN26. Relacionadas: RN18, RN24.
