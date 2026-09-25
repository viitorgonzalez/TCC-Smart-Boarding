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

> **⚠️ Decisão aberta.** Você citou "endereço, número, etc". O `address` hoje é
> um campo de texto livre — não há `número` separado. Quebrar em
> logradouro/número/bairro é mudança de schema e de tela. A tabela acima assume
> **manter texto livre e só exigir que esteja preenchido**. Se você quiser o
> endereço estruturado, isso vira uma migration e um formulário novo — me diga
> antes da Task 1.

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
- **Tempo estimado até a parada principal** (detalhe abaixo)

Atualiza por **polling enquanto a tela está aberta** — a cada 20s. Sem
WebSocket: o trajeto dura minutos, o dado muda a cada parada, e manter conexão
viva custa bateria pra ganhar segundos de latência que ninguém percebe.

> **⚠️ Decisão aberta:** "parada principal" precisa de definição. Assumo **a
> última parada do trajeto** (o destino). Se for a instituição do aluno — que
> pode ser uma parada intermediária — o cálculo muda e cada aluno vê um tempo
> diferente. Me diga qual.

---

## 6. Tempo estimado e tempo médio

### A descoberta

O OSRM já devolve `duration` (segundos) e `distance` (metros) **na mesma
resposta** que o app usa pra desenhar o trajeto. O `RoadRouteService` lê só a
geometria e joga o resto fora.

Ou seja: **não precisa de serviço novo, nem de chave de API, nem de custo.**
Precisa ler dois campos que já chegam.

### As duas medidas

**Tempo estimado (ao vivo, na tela de acompanhamento).**
Trecho da parada atual até a última, pelo OSRM, mais **1 min por parada
restante** — o tempo de embarque que você pediu.

```
estimado = duração_osrm(parada_atual → última) + (paradas_restantes × 1 min)
```

**Tempo médio da viagem (na lista).**
Trajeto inteiro, primeira à última parada, mais 1 min por parada. É um número
estável da rota — não muda por dia — então é **calculado no backend e guardado
na rota**, recalculado quando as paradas mudam. Calcular no app faria cada
aparelho bater no OSRM pra chegar ao mesmo número.

> **Por que no backend:** o OSRM público tem limite de uso. Uma chamada por
> mudança de parada é sustentável; uma por aluno que abre a lista, não.

---

## O que **não** está aqui

**A borda verde-limão.** Você pediu pra anotar. Verifiquei antes de escrever
esta spec: ela **não existe no app**. Aparece só no build de **debug** — é
ferramenta do Flutter. No build de release a borda é `#F4F6F4`, o fundo do app,
até o último pixel. Confirmei também que ela não aparece na tela inicial do
Android nem em outro app, e que a cor (`#A9D32A`) não existe na nossa paleta
nem no tema Android do projeto. Nenhum aluno vai ver aquilo.

**Troca do OSRM público por serviço com contrato** — infraestrutura de deploy,
não de funcionalidade.

**Endereço estruturado** (logradouro/número/bairro) — depende da sua resposta
na seção 1.

---

## Ordem de execução

As frentes 1–3 são independentes e pequenas. As 4–6 formam um bloco: o tempo
estimado depende da distância real, que depende do caminho por ruas.

```
1. Perfil obrigatório      (backend + app)     independente
2. Cabeçalho do aluno      (app)               independente
3. Ordem dos cards         (app)               independente
4. Parada grudada na via   (app)               base pro bloco
6a. Tempo médio da rota    (backend)           usa (4)
5. Trajeto ao vivo         (backend + app)     usa (4)
6b. Tempo estimado         (app)               usa (5)
```
