# docs/ — o que está onde

Documentação **de processo** do repositório. A documentação de produto vive junto de
cada aplicação:

| Onde | O quê |
|---|---|
| [`smartboarding-api/docs/spec.md`](../smartboarding-api/docs/spec.md) | Spec do backend: papéis, regras de negócio (RN1…RN26), entidades, contratos de API. |
| [`smartboarding_app/docs/spec.md`](../smartboarding_app/docs/spec.md) | Spec do app: arquitetura, estado, regras na ótica da interface. |
| [`smartboarding_app/docs/PAGES.md`](../smartboarding_app/docs/PAGES.md) | Índice de telas → uma spec por tela em `specs/<categoria>/`. |
| [`smartboarding_app/docs/design/`](../smartboarding_app/docs/design/) | Design system (tokens) e os prompts de layout usados pra gerar as telas. |

## O que tem aqui

| Pasta | O quê | Vale como |
|---|---|---|
| `superpowers/plans/` | Planos de implementação, um por frente de trabalho, com data no nome. | **Registro histórico.** Descrevem o que foi feito naquele momento — não são a fonte da verdade sobre o estado atual. Quando um plano e a spec discordam, **a spec vence**. |
| `superpowers/specs/` | Documentos de design que precederam os planos maiores. | Idem: histórico da decisão, não descrição do presente. |
| `work/` | Intake de demandas: o pedido cru antes de virar plano. | Histórico. |

## Por que os planos continuam aqui

Eles respondem "por que isso é assim", que o código não conta. Um plano de uma
abordagem que depois foi revertida é ruído — esse a gente apaga (foi o caso do
cadastro por convite, removido em setembro/2026). Um plano do que está em pé fica.

> Planos do app e do backend ficam **nesta pasta**, não dentro de cada projeto: eram
> duas pastas `superpowers/` e ninguém sabia em qual procurar.
