# Acompanhar trajeto

**Rota:** empurrada do card da lista (`student_follow_trip`) · **Papel:** `STUDENT`

## Quando aparece

O botão só existe com o trajeto **em andamento** (`tripInProgress` no `GET /api/lists/today`).
Oferecer sempre levaria a uma tela que só diz "não começou"; esconder sempre esconderia a
feature.

Só dentro do app, como pedido: **nada de push**. Quem quer saber abre a tela; quem não quer não
é interrompido.

## O que mostra

| Bloco | Origem |
|---|---|
| "Você desce em" + nome da parada | `myStop.stopName` |
| "Cerca de X min até \<parada\>" | `myStop.etaMinutes` |
| Paradas como checklist | `stops[]`, com `reachedAt` |

A parada do aluno fica **destacada** na lista — sem marcação ele a procura a cada atualização.

## O tempo é dele

Dois alunos da mesma lista veem números diferentes: quem desce na terceira de sete paradas não
quer saber quando o ônibus chega na sétima. Por isso o destino vem **nomeado** — sem ele, quem
compara com o colega conclui que o app está errado.

O número sai da **diferença** entre os `avg_minutes_from_start` já calculados (RN31): a parada
dele menos a última alcançada. **Nunca** de uma chamada ao OSRM por consulta — com polling de
20s isso seria 3 requisições por minuto por aluno, num serviço com limite de uso, pra chegar no
mesmo número.

## Quando o tempo não aparece

Nulo é "não sei", e a tela **omite**. Um zero o aluno leria como "o ônibus já chegou".

| Situação | Por quê |
|---|---|
| Sem `avg_minutes_from_start` | O OSRM não respondeu quando as paradas mudaram |
| Perna de volta | Ele embarca na instituição; "quanto falta até ela" não quer dizer nada |
| Ônibus já passou | Mostra "o ônibus já passou por X" |
| A conta daria negativo | O admin pulou um checkpoint — "-7 min" é pior que nada |

## Fallback

Instituição sem parada declarada na rota → mostra a **última** parada com aviso explícito. Um
tempo até um lugar que não é o dele, sem aviso, é pior que tempo nenhum.

## Atualização

Polling de **20s**, cancelado no `dispose`. O trajeto dura minutos e o dado muda a cada parada;
mais rápido gastaria bateria de quem está no ônibus pra ganhar segundos que ninguém percebe.
Timer vivo depois de sair é vazamento — e gasta bateria justamente quando ela importa.

Falha de polling **não** apaga o que já está na tela: trocar dado bom por mensagem de erro é
pior que ficar um ciclo desatualizado.

## Escopo

`GET /api/trip/{listId}` aceita qualquer autenticado, mas o controller confere o vínculo: aluno
de outra rota toma **403**. Conduzir o trajeto continua exclusivo do `ADMIN` (RN23).
