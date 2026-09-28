# Trajeto ao vivo e perfil obrigatório — Design

**Data:** 25/09/2026
**Branch:** `feature/trajeto-ao-vivo-e-perfil-obrigatorio`

Seis frentes pedidas de uma vez. Duas mudaram de forma depois de olhar o código:
o caminho por ruas **já existe** e o tempo estimado **já vem na resposta que o app
recebe** — só não é lido. Isso está detalhado em cada seção.

---

## 1. Perfil completo como pré-requisito da lista

### O problema

Hoje o perfil incompleto só barra a **entrada na rota** (`PROFILE_INCOMPLETE`, e
só checa se há instituição declarada). Entrar na **lista do dia** não checa nada.

Um aluno pode estar na rota com endereço vazio e telefone em branco. No dia da
viagem o motorista tem um nome na lista e nenhuma forma de saber onde a pessoa
embarca nem como falar com ela.

### A regra

Entrar na lista do dia exige **perfil completo**:

| Campo | Por que é obrigatório |
|---|---|
| `fullName` | Identifica na chamada |
| `phone` | Único contato direto no dia da viagem |
| `address` | Onde a pessoa embarca — sem isso o motorista não sabe onde parar |
| instituição (≥1) | Decide em que contagem a pessoa entra |

`birthDate` e `course` ficam **opcionais**: descrevem a pessoa, não a operação
do transporte.

### Endereço estruturado, preenchido por CEP

**Decidido:** o endereço passa a ser estruturado e o CEP preenche o resto.

`users.address` (texto livre) dá lugar a:

| Coluna | Origem |
|---|---|
| `zip_code` | digitado |
| `street` | do CEP |
| `neighborhood` | do CEP |
| `city` | do CEP |
| `state` | do CEP |
| `street_number` | digitado |
| `complement` | digitado, opcional |

O aluno digita **CEP e número**. O resto chega preenchido.

**Serviço:** ViaCEP (`https://viacep.com.br/ws/{cep}/json/`) — gratuito, sem
chave, o padrão de fato no Brasil. Mesma postura do OSRM: sem SLA, então
**falha não trava o formulário** — os campos ficam editáveis à mão e o aluno
termina o cadastro do mesmo jeito. Um CEP fora do ar não pode impedir alguém de
pegar o ônibus.

**Obrigatórios:** `zip_code`, `street`, `neighborhood`, `street_number`.
`complement` é opcional — nem todo endereço tem.

**Migração do dado existente:** `address` é texto livre e não dá pra quebrar
com segurança. A coluna antiga é **mantida** como `address_legacy` e os campos
novos nascem nulos; quem já tinha endereço preenche de novo na primeira vez
que abrir o perfil. Tentar adivinhar rua e número de texto livre produziria
endereço errado com cara de certo — e endereço errado é o motorista parando no
lugar errado.

### O beco sem saída que isso cria

Hoje **o aluno não edita o próprio perfil**: ele envia uma solicitação e o admin
aprova (`ProfileUpdateRequest`). Junte com a regra nova e o resultado é:

> "Complete seu perfil pra entrar na lista" → o aluno preenche → **fica esperando
> o admin aprovar** → perde a viagem de amanhã.

Um bloqueio que a própria pessoa não consegue destravar não é uma regra, é uma
parede.

**Correção:** separar campo de **identidade** de campo de **operação**.

| Campo | Salva | Por quê |
|---|---|---|
| `fullName` | aprovação | Identifica na chamada — trocar é virar outra pessoa |
| instituição | aprovação | Decide em que contagem ele entra |
| `phone` | **direto** | É o contato dele; errado só prejudica ele mesmo |
| endereço | **direto** | É onde ele embarca; errado só prejudica ele mesmo |
| `course` | **direto** | Descritivo, não decide nada |

O motivo original da aprovação está preservado: o que decide **em qual
transporte a pessoa entra** continua passando pelo admin. O que só descreve
como alcançá-la, não.

### Onde a regra mora

No backend, em `AddEntryUseCase` — a mesma porta por onde o aluno entra na
lista. Só no app seria decorativa: quem chamasse a API direto passaria.

Erro novo: `PROFILE_INCOMPLETE_FOR_LIST`, devolvendo **quais campos faltam**,
não só que falta algo — a mensagem genérica obriga o aluno a adivinhar.

```json
{ "code": "PROFILE_INCOMPLETE_FOR_LIST",
  "error": "Complete seu perfil para entrar na lista.",
  "missing": ["phone", "address"] }
```

### Na tela

O card do aluno mostra o aviso **antes** de ele tentar entrar, não depois de
tomar erro: se o perfil está incompleto, o botão "Entrar na lista" dá lugar a
um bloco com o que falta e um atalho pro perfil. Descobrir o bloqueio só ao
tocar no botão é fazer a pessoa esbarrar numa parede que dava pra sinalizar.

O admin **não** é afetado: ele não entra em lista.

---

## 2. Cabeçalho do aluno

Dois problemas, um deles de dado:

**Nome completo.** "Vítor Silva Pastor Gonzalez" ocupa duas linhas e empurra as
ações. Passa a mostrar **só o primeiro nome** — é como a pessoa se chama, e o
cabeçalho é uma saudação, não um documento.

**Os três botões.** Hoje são três quadrados verdes preenchidos, lado a lado,
com o mesmo peso visual: `+` (entrar com código), perfil e sair. Três blocos
sólidos competindo entre si num cabeçalho escuro.

Vira: **um** botão de ação (entrar com código) e as outras duas em um menu de
excesso (⋮). Sair e abrir perfil são ações ocasionais — não precisam de alvo
permanente. O avatar continua abrindo o perfil, como no painel do admin.

---

## 3. Ordem dos cards do admin

Ordem atual (criada por acaso, conforme as telas nasceram):

```
Rotas e Listas    | Enviar Aviso
Avisos enviados   | Advertências
Relatórios        | Usuários
Códigos de acesso | Instituições
```

Ordem proposta — frequência de uso decrescente, com Relatórios à esquerda e
Advertências ao lado, como você pediu:

```
Rotas e Listas    | Enviar Aviso        ← todo dia
Relatórios        | Advertências        ← acompanhamento
Usuários          | Avisos enviados     ← eventual
Códigos de acesso | Instituições        ← por semestre
```

A leitura fica em faixas de propósito: operação do dia, acompanhamento,
gestão de gente, configuração.

---

## 4. Trajeto correto dentro da cidade

### O que já existe

`RoadRouteService` já busca o caminho **por ruas** no OSRM e desenha a
polilinha real — não é linha reta. Isso está em produção no app desde o mapa da
rota.

### O que realmente limita

Três coisas, em ordem de impacto:

**(a) A parada fica onde o dedo tocou.** Ao criar uma parada tocando o mapa, o
ponto guardado pode cair no meio de um quarteirão ou no lado errado da via. O
OSRM "gruda" o ponto na rua mais próxima pra calcular, mas o **pino** continua
no lugar errado — o desenho e a realidade divergem, e o aluno vê uma parada que
não é onde o ônibus encosta.

Correção: ao soltar o pino, **gruda na via mais próxima** (`/nearest` do OSRM) e
guarda a coordenada corrigida. Não muda nada pro admin — ele toca no mapa igual,
e o pino se ajusta sozinho.

**(b) A ordem das paradas é a ordem de cadastro.** Se o admin cadastrar fora de
ordem, o trajeto zigue-zagueia. Não vou resolver isso automaticamente: reordenar
sozinho tiraria do admin o controle de uma decisão que é dele (pode haver motivo
pra uma ordem que parece ruim no mapa). Em vez disso, a tela **avisa** quando o
caminho se cruza, e ele decide.

**(c) OSRM público não tem SLA.** É o servidor de demonstração do projeto, com
limite de uso. Funciona pro TCC; não serve pra produção com turma real.
Já está registrado como aviso no próprio serviço. **Não entra neste plano** —
é decisão de infraestrutura pra quando houver deploy.

---

## 5. Conduzir trajeto, refeito

### O que já existe

O backend **já tem** o ciclo completo: `POST /api/trip/{listId}/start`,
`POST /api/trip/{listId}/checkpoint/{stopId}`, `POST /api/trip/{listId}/finish`,
e `GET /api/trip/{listId}` devolvendo o estado. Entidades `TripLeg` e
`TripCheckpoint` guardam ida/volta e cada parada alcançada.

O que falta é o **lado do aluno** e a simplificação da tela do admin.

### Tela do admin durante o trajeto

Só o necessário para quem está dirigindo:

- Próxima parada, grande, legível de relance
- Um botão único: **"Cheguei nesta parada"**
- Quantas faltam
- Encerrar trajeto

Sai da tela: mapa de edição, lista de inscritos, qualquer coisa que não seja a
decisão do momento. Quem conduz não navega o app — toca uma vez por parada.

### Aviso ao aluno: dentro do app, sem incomodar

Nada de push. O aluno vê o andamento **quando abre a rota**, como você pediu.

Rota em andamento ganha, na tela da lista, um botão **"Acompanhar trajeto"**.

### Tela de acompanhamento

Reaproveita o mapa que já existe, com:

- As paradas como **checklist**: alcançadas marcadas, a atual destacada
- A polilinha real do trajeto (já temos)
- **Tempo estimado até a instituição do aluno** (detalhe em §6)

Atualiza por **polling enquanto a tela está aberta** — a cada 20s. Sem
WebSocket: o trajeto dura minutos, o dado muda a cada parada, e manter conexão
viva custa bateria pra ganhar segundos de latência que ninguém percebe.

**Decidido:** o tempo é **até a instituição do aluno**. Cada aluno vê o seu
próprio tempo — quem desce na terceira parada não quer saber quando o ônibus
chega na sétima.

> **⚠️ Isso tem uma dependência que não estava à vista.** Ver §7.

---

## 6. Tempo estimado e tempo médio

### A descoberta

O OSRM já devolve `duration` (segundos) e `distance` (metros) **na mesma
resposta** que o app usa pra desenhar o trajeto. O `RoadRouteService` lê só a
geometria e joga o resto fora.

Ou seja: **não precisa de serviço novo, nem de chave de API, nem de custo.**
Precisa ler dois campos que já chegam.

### As duas medidas

Ambas terminam **na instituição do aluno**, não na última parada — é a decisão
da §5, e ela vale para as duas medidas. Mostrar a média do trajeto inteiro pra
quem desce na terceira de sete paradas seria um número que não é sobre a viagem
dele.

**Tempo estimado (ao vivo, na tela de acompanhamento).**
Trecho da parada atual até a parada da instituição dele, pelo OSRM, mais
**1 min por parada no meio** — o tempo de embarque que você pediu.

```
estimado = duração_osrm(parada_atual → parada_da_instituição)
         + (paradas_no_meio × 1 min)
```

Dois alunos no mesmo ônibus veem números diferentes. Por isso o rótulo
**nomeia o destino** ("até a UNIFOR"): sem o nome, quem vê o número do colega
conclui que o app está errado.

Ônibus que já passou da instituição do aluno não mostra tempo negativo — mostra
que o trecho dele acabou.

**Tempo médio da viagem (na lista).**
Do início até **cada parada principal**, mais 1 min por parada até ali. São
números estáveis da rota — não mudam por dia — então são **calculados no
backend e guardados em `stops.avg_minutes_from_start`**, recalculados quando as
paradas mudam. A lista mostra o da instituição do aluno. Calcular no app faria
cada aparelho bater no OSRM pra chegar ao mesmo número.

> **Por que no backend:** o OSRM público tem limite de uso. Uma chamada por
> mudança de parada é sustentável; uma por aluno que abre a lista, não.

---

## 7. A dependência escondida: qual parada é a instituição do aluno

"Tempo até a **sua** instituição" só funciona se o sistema souber **qual parada
é a instituição de cada aluno**. Hoje ele não sabe direito.

### O que existe

`stops.is_main_point` já existe (RN23): marca "rodoviária + instituições da
rota", e só ponto principal aceita checkpoint. Mas o vínculo foi feito por
**comparação de nome**, numa migration:

```sql
UPDATE stops s SET is_main_point = TRUE
  FROM institutions i
 WHERE i.route_id = s.route_id
   AND s.name LIKE i.name || '%';
```

### Só que isso já está quebrado hoje

Procurando o que escreve `is_main_point`, achei que **nada escreve**:

- `CreateStopRequest` não tem o campo
- `StopUseCaseImpl.add()` nunca o define — fica no default `false`
- `StopUseCaseImpl.update()` não o toca
- `grep -rn "setMainPoint" src/main/java` → **nenhum resultado**

O campo é populado **só pela migration V20**, uma vez, no dado que já existia.

E `TripUseCaseImpl.checkpoint` recusa parada que não seja ponto principal:

```java
if (!stop.isMainPoint()) {
    throw new BadRequestException("STOP_NOT_MAIN_POINT", ...);
}
```

Juntando: **qualquer rota criada depois da V20 não tem nenhum ponto principal.**
O admin consegue iniciar o trajeto e não consegue marcar parada nenhuma — toda
tentativa devolve `STOP_NOT_MAIN_POINT`. O "conduzir trajeto" só funciona no
dado de seed, e por acidente.

O banco local confirma até no seed:

```
 UNIFOR-MG — Formiga       | t
 Campus Unifor             | f   ← é a mesma instituição, e ficou de fora
 IFMG — Campus Formiga     | t
```

"Campus Unifor" não casou com o `LIKE` porque a instituição se chama
"UNIFOR-MG — Formiga". A fragilidade não é hipotética: ela já produziu dado
errado no único dado que existe.

Isso reposiciona esta seção: não é refinamento de modelagem, é **pré-requisito**
do bloco inteiro do trajeto (§5 e §6). Sem ela, a tela nova do admin teria um
botão que só dá erro.

Renomear a parada para "Portão 2 da UNIFOR" também quebraria o vínculo em
silêncio — mas esse é o problema menor dos dois.

`institutions` tem `latitude`/`longitude` próprias, então dava pra rotear
direto pro ponto da instituição. Mas o ônibus para **na parada**, não no portão,
e o "1 min por parada" precisa contar quantas paradas faltam até lá. Coordenada
solta não responde isso.

### A correção

`stops.institution_id` (nullable, FK). Explícito, em vez de adivinhado por
nome:

- A parada que serve uma instituição aponta pra ela
- `is_main_point` passa a ser **derivado**: é ponto principal quem tem
  `institution_id` ou é a rodoviária
- A migration popula pelo mesmo `LIKE` de antes — uma vez, como dado, não como
  regra viva
- Na tela de paradas, o admin escolhe a instituição ao criar a parada
  (opcional: parada comum não tem)

Com isso, "tempo até a sua instituição" vira uma consulta direta: a parada cuja
`institution_id` é a instituição declarada do aluno.

> **⚠️ Caso sem resposta óbvia:** aluno com **duas** instituições declaradas na
> mesma rota. Assumo a **primeira declarada** — que já é a "principal" hoje
> (decide em que contagem ele entra, ver `my_institutions_card.dart`). Mantém
> uma regra só no app inteiro.

> **⚠️ Aluno cuja instituição não tem parada:** mostra o tempo até a **última**
> parada, com o rótulo dizendo qual é. Omitir seria pior — ele fica sem
> nenhuma noção de quando chega.

### Consequência no tempo médio (§6)

Se o tempo ao vivo é até a instituição do aluno, o **tempo médio** na lista
também precisa ser. Mostrar a média do trajeto inteiro pra quem desce na
terceira de sete paradas seria um número que não é sobre a viagem dele.

O tempo médio passa a ser guardado **por parada principal** — quanto leva do
início até cada uma — e a lista mostra o da instituição do aluno.

---

## 8. Carteirinha de estudante virtual

Feature nova, pedida junto do CEP.

### O que mostra

| Bloco | Conteúdo |
|---|---|
| Identidade | Nome completo, instituição, curso |
| Endereço | **Rua, bairro e número** — só isso |
| Validade | Ver abaixo |

O endereço limitado a rua/bairro/número é o que você pediu. Faz sentido: CEP e
cidade/estado não identificam ninguém numa conferência presencial, e CEP é dado
que não precisa circular numa tela que se mostra pra outra pessoa.

### Validade

`users.expiry_date` já existe — **mas não serve aqui**. Ela alimenta
`isAccountNonExpired()` do Spring Security: preencher com a validade da
carteirinha faria o aluno **perder o login** no dia em que a carteirinha
vencesse. São coisas diferentes com o mesmo nome.

A carteirinha vale enquanto o aluno estiver **ativo e vinculado a uma rota** —
que é exatamente o que ela atesta. Sem campo novo.

### O que ela **não** é

Não é documento oficial nem prova de matrícula. O app não valida vínculo com a
instituição — ele sabe o que o aluno declarou. A tela precisa deixar isso
explícito, senão vira documento com aparência de oficial que ninguém auditou.

> **⚠️ Decisões abertas:**
> - **Foto?** Não há campo de foto em `users`. Adicionar significa upload,
>   armazenamento e moderação — é uma frente inteira. Assumo **sem foto**, com
>   as iniciais como avatar (o padrão já usado no app).
> - **QR code de conferência?** Só faz sentido se alguém for escanear. Se a
>   conferência é visual, é enfeite. Assumo **sem QR**.

## O que **não** está aqui

**A borda verde-limão.** Você pediu pra anotar. Verifiquei antes de escrever
esta spec: ela **não existe no app**. Aparece só no build de **debug** — é
ferramenta do Flutter. No build de release a borda é `#F4F6F4`, o fundo do app,
até o último pixel. Confirmei também que ela não aparece na tela inicial do
Android nem em outro app, e que a cor (`#A9D32A`) não existe na nossa paleta
nem no tema Android do projeto. Nenhum aluno vai ver aquilo.

**Troca do OSRM público por serviço com contrato** — infraestrutura de deploy,
não de funcionalidade.

**Foto e QR na carteirinha** — ver decisões abertas na §8.

**Reordenar paradas automaticamente** — §4b: é decisão do admin, o app só avisa
quando o caminho se cruza.

---

## Ordem de execução

As frentes 1–3 são independentes e pequenas. As 4–6 formam um bloco: o tempo
estimado depende da distância real, que depende do caminho por ruas.

```
1. Endereço por CEP        (backend + app)     base — a carteirinha usa
2. Perfil obrigatório      (backend + app)     usa (1)
3. Cabeçalho do aluno      (app)               independente
4. Ordem dos cards         (app)               independente
8. Carteirinha             (app)               usa (1)
5. Parada grudada na via   (app)               base pro bloco do trajeto
7. Parada ↔ instituição    (backend)           base pro bloco do trajeto
6a. Tempo médio por parada (backend)           usa (5) e (7)
5b. Trajeto ao vivo        (backend + app)     usa (7)
6b. Tempo estimado         (app)               usa (5b)
```

O endereço por CEP subiu pra primeiro: a carteirinha mostra rua/bairro/número,
e esses campos não existem até ele ser feito.
