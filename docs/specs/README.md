# Especificações do projeto

Onde ficam as especificações e como elas se relacionam:

| Onde | O que é | Quando consultar |
|---|---|---|
| **`docs/specs/`** (aqui) | As três **specs originais** que definiram o produto: o quê e por quê | Entender a motivação e as decisões de partida |
| [`openspec/specs/`](../../openspec/specs/) | **Capacidades** atuais (requisitos e cenários testáveis), mantidas a cada mudança arquivada | Saber como o sistema **deve se comportar hoje** |
| [`openspec/changes/`](../../openspec/changes/) | Mudanças em andamento (proposta, design, specs delta e tasks) e o histórico em `archive/` | Acompanhar ou propor uma mudança |
| [`app/docs/`](../../app/docs/) | Guias de engenharia do app (arquitetura, DI, rotas, i18n, tema) e [`ux-refresh.md`](../../app/docs/ux-refresh.md) | Desenvolver no app |
| [`pipeline/README.md`](../../pipeline/README.md) | Como rodar o pipeline de questões | Gerar/atualizar o banco |

> Regra prática: **as specs deste diretório não são atualizadas a cada mudança**. Para novas
> funcionalidades, crie uma change no OpenSpec (`/opsx:propose`); ao arquivá-la, as capacidades
> em `openspec/specs/` passam a ser a fonte da verdade.

## As specs originais

| Spec | Escopo | Implementação |
|---|---|---|
| [01 — Conversor](01-conversor.md) | Pipeline que baixa perguntas de repositórios open source, gera questões de múltipla escolha via LLM e exporta um banco JSON versionado | [`pipeline/`](../../pipeline/) |
| [02 — App Flutter](02-app-flutter.md) | Fundação do app: boilerplate, Firebase, offline-first (Drift), deeplinks, i18n, CI | [`app/`](../../app/) (`core`, `shared`, `question_bank`, `quiz_app`) |
| [03 — Features do quiz](03-features-quiz.md) | Sessões de quiz, repetição espaçada, streak/XP e estatísticas | [`app/packages/modules/quiz`](../../app/packages/modules/quiz) e `features/{quiz_flow,home_flow,stats_flow}` |

## O que evoluiu desde as specs

**Spec 01**
- O escopo deixou de ser só mobile: qualquer área técnica pode virar roadmap adicionando uma
  fonte em `pipeline/sources.yaml` (veja o README da raiz).
- Questões geradas internamente (revisadas manualmente) complementam as fontes externas.

**Spec 02**
- Itens listados como v2 foram entregues: login social (Google) e por e-mail além do anônimo,
  e notificações push (FCM).
- Foi criado e depois **removido** o desbloqueio por biometria; a sessão agora é recuperada
  automaticamente após o primeiro login (change `ux-refresh-learning-path`).
- Novo ícone, splash e paleta pastel; build de produção assinado e ofuscado.

**Spec 03**
- A **pré-sessão** (slider de quantidade) foi substituída pela **trilha de lições** estilo
  Duolingo: lições fixas de 5 questões, e a próxima só libera com **>= 80% de acertos**; cada
  tópico é um roadmap independente.
- Nova **tela de resultado**, **efeitos sonoros** e card de explicação com dicas de que gira.
- O streak passou a contar **dias de calendário** (corrige horário de verão e relógio
  voltando); perder um dia zera, e a primeira sessão da volta inicia nova sequência em 1.
- Rotas `/quiz/{topic}`, `/question/{id}` e `/daily` continuam válidas.

Detalhes: [`openspec/changes/ux-refresh-learning-path`](../../openspec/changes/ux-refresh-learning-path/)
e [`app/docs/ux-refresh.md`](../../app/docs/ux-refresh.md).
