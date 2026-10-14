# Handoff — fluxo de entrada do aluno (14/09/2026)

Onde paramos, pra retomar sem reconstruir contexto.

## Estado do git

Branch `feature/codigo-de-rota-e-detalhes-ui`, **2 commits ainda nao enviados**:

- `a5be8ac` feat(app): admin gera codigo de rota e aluno entra por "Minhas rotas"
- `3c42433` feat(app): telas de entrada ganham autofill e navegacao pelo teclado

**Nao commitado** (correcao feita hoje, aguardando seu aval):

- `smartboarding-api/src/main/resources/db/seed/V2__seed_data.sql` — restaurado
  byte a byte pro conteudo original
- `smartboarding-api/src/main/resources/db/seed/README.md` — novo

Nada foi commitado nem enviado.

## O que a correcao de hoje resolve

Ao mover o seed pra `db/seed`, eu tinha **editado o cabecalho do arquivo**. O
Flyway guarda o checksum do conteudo, entao qualquer banco de desenvolvimento
que ja tivesse aplicado a V2 passou a recusar o boot:

```
Migration checksum mismatch for migration version 2
-> Applied to database : -1644803191
-> Resolved locally    : 1081743151
```

A mensagem daquele commit afirmava o contrario ("o arquivo e o mesmo, so mudou
de lugar, entao o checksum bate"). Era falso, e so apareceu ao subir o ambiente
de verdade — a suite de testes nao pega isso porque o Testcontainers sobe banco
limpo.

Correcao: o `.sql` voltou ao conteudo original (checksum bate de novo) e o aviso
foi pra um `README.md` ao lado, que o Flyway nao le. Verificado: a API sobe,
schema na versao 27.

## Fluxo verificado contra a API rodando

Todos os passos abaixo foram exercitados com `curl` na API local, nao so em teste:

| Passo | Resultado |
|---|---|
| Cadastro proprio (`POST /auth/signup`) | 201, sessao ja com `email` |
| Conta nasce sem rota (`GET /me/routes`) | `[]` |
| Solicitacao de dados pessoais (`POST /me/profile-requests`) | 201, fica PENDING |
| Admin aprova (`POST /profile-requests/{id}/approve`) | 200 |
| Admin gera codigo com validade (`POST /routes/{id}/invite-codes`) | 201, `expiresAt` respeitado |
| Aluno entra com o codigo (`POST /me/routes`) | 200, rota passa a aparecer |

Bordas, todas com mensagem em portugues:

| Caso | Resposta |
|---|---|
| Mesmo codigo de novo | 409 `ALREADY_MEMBER` |
| Codigo inexistente | 400 `INVALID_CODE` |
| Codigo vazio | 400 `VALIDATION_ERROR` |
| Codigo revogado | 400 `CODE_REVOKED` |
| Validade no passado | 400 `INVALID_EXPIRY` |
| Aluno tentando gerar codigo | 403 |
| Perfil sem instituicao | 400 `PROFILE_INCOMPLETE` |
| Codigo em minusculas | 200 (normaliza) |
| Codigo com espacos em volta | 200 (normaliza) |

As duas ultimas importam: o aluno cola o codigo do WhatsApp e funciona, como no
Classroom.

## O que falta

1. **Percorrer o fluxo na mao no emulador.** O APK esta instalado no Pixel 9
   (`com.smartboarding.smartboarding_app`), apontando pra `http://10.0.2.2:8080/api`.
   Falta a passada visual pelas telas.

2. **O trecho do Google.** O client ID mora em `smartboarding-api/.env`
   (`GOOGLE_CLIENT_ID`), que o `run-local.sh` exporta pro Spring — a API pega
   sozinha. O app precisa do mesmo valor via `--dart-define`:

   ```bash
   GID=$(grep -E "^GOOGLE_CLIENT_ID=" smartboarding-api/.env | cut -d= -f2-)
   flutter run \
     --dart-define=API_BASE_URL=http://10.0.2.2:8080/api \
     --dart-define=GOOGLE_WEB_CLIENT_ID="$GID"
   ```

   Sem o define o botao do Google nem renderiza.

   > Armadilha: `grep -r` neste ambiente **pula arquivos gitignored**, e o
   > `.env` e um deles. Buscar o client ID recursivamente devolve vazio mesmo
   > com o arquivo ali. Grepe o `.env` direto.

3. **Decidir sobre push/PR.** Os 2 commits e a correcao do seed continuam
   locais, esperando voce pedir.

## Ambiente (pode ter caido enquanto voce esteve fora)

```bash
cd smartboarding-api && docker compose up -d && ./run-local.sh
emulator -avd Pixel_9_37.0_35_plus
```
