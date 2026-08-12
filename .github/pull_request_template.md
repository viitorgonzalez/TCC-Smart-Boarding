## Descrição

<!-- O que muda e POR QUÊ. Contexto suficiente pra quem não acompanhou o trabalho. -->

## Tipo de mudança

- [ ] `feat` — funcionalidade nova
- [ ] `fix` — correção de bug
- [ ] `refactor` — mudança interna sem alterar comportamento
- [ ] `perf` — performance
- [ ] `docs` — documentação
- [ ] `chore` / `build` / `ci` — manutenção
- [ ] **Breaking change** (descreva a migração abaixo)

## Onde mexe

- [ ] `smartboarding-api/` (Spring Boot)
- [ ] `smartboarding_app/` (Flutter)

<!-- Mudança de contrato (DTO/endpoint/enum) quase sempre marca OS DOIS.
     API alterada sem o app correspondente deixa o app quebrado em runtime. -->

## Mudanças

<!-- Bullets do que foi tocado, do mais relevante pro menos. Não é lista de arquivos. -->

-

## Como testar

<!-- Passos determinísticos. API: `docker compose up -d` + `./run-local.sh`.
     App: `flutter run --dart-define=API_BASE_URL=http://<ip-da-lan>:8080`. -->

1.

## Evidências

<!-- Screenshot/GIF pra mudança de tela; saída de teste ou log pra backend. Remova se não se aplica. -->

## Checklist

- [ ] `./mvnw test` verde (se mexeu na API)
- [ ] `flutter analyze` e `flutter test` verdes (se mexeu no app)
- [ ] Testes cobrindo a mudança (ou justificativa de por que não)
- [ ] Sem segredo commitado — nada de `.env`, credencial do Firebase ou senha
- [ ] Migration nova em vez de editar `V*.sql` já aplicada
- [ ] Spec (`smartboarding_app/docs/spec.md`) atualizada quando a regra de negócio mudou
- [ ] Base do PR é `main`

## Issues relacionadas

<!-- Closes #42 -->
