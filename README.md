# Quiz Technical App

App de estudo estilo Duolingo para entrevistas técnicas mobile (Android/iOS/Flutter/System
Design). O usuário responde questões de múltipla escolha organizadas por tópico, erra, lê a
explicação, e o app agenda a repetição espaçada da questão para reforçar o aprendizado — com
streak diário e XP para gamificar o hábito.

O projeto tem duas partes independentes:

| Parte | O que faz | Stack |
|---|---|---|
| [`pipeline/`](pipeline/) | Baixa perguntas de entrevista de repositórios open source, gera questões de múltipla escolha via LLM e exporta um banco JSON versionado | Python 3.11+ |
| [`app/`](app/) | App Flutter que consome esse banco e roda o quiz offline-first, com progresso, repetição espaçada e estatísticas | Flutter/Dart |

O `pipeline` roda de forma manual/periódica (não em runtime do app) para gerar novas versões
do banco de questões; o `app` importa esse banco na primeira execução e sincroniza atualizações
depois.

## Como funciona, de ponta a ponta

1. **`pipeline fetch`** baixa o markdown de repositórios de perguntas de entrevista (declarados
   em [`pipeline/sources.yaml`](pipeline/sources.yaml)), com cache por hash.
2. **`pipeline parse`** extrai pares pergunta/resposta do markdown.
3. **`pipeline generate`** usa um LLM (Anthropic) para transformar cada par em uma questão de
   múltipla escolha (5 alternativas + explicação), de forma idempotente.
4. **`pipeline validate`** valida o schema e remove duplicatas.
5. **`pipeline export`** gera `data/output/questions_v<N>.json` + `manifest.json` (com checksum
   SHA-256 e licenças das fontes).
6. O **app Flutter** importa esse banco embarcado no primeiro launch (SQLite via Drift) e, em
   execuções seguintes, verifica se há uma versão nova para sincronizar — validando o checksum
   antes de aplicar.
7. Ao responder uma questão, o app roda um agendador de repetição espaçada (SM-2 simplificado):
   erro → revisão em 1 dia; acertos consecutivos → intervalos crescentes (1d/3d/7d/21d). Isso
   alimenta o modo **Revisão** e o **streak diário**.

Detalhes de design de cada etapa estão em [`spec-01-conversor.md`](spec-01-conversor.md)
(pipeline), [`spec-02-app-flutter.md`](spec-02-app-flutter.md) (fundação do app) e
[`spec-03-features-quiz.md`](spec-03-features-quiz.md) (features do quiz).

---

## Rodando o pipeline (gerar/atualizar o banco de questões)

Você só precisa disso se for adicionar fontes novas ou regenerar questões. Para apenas rodar o
app, pule para a próxima seção — o banco já vem embarcado.

```bash
cd pipeline
python3 -m venv .venv
.venv/bin/pip install -e ".[dev]"
cp .env.example .env   # preencher ANTHROPIC_API_KEY
```

```bash
.venv/bin/python -m pipeline fetch          # baixa/atualiza fontes (cache por hash)
.venv/bin/python -m pipeline parse          # markdown -> pares Q/A
.venv/bin/python -m pipeline generate       # Q/A -> MCQ via LLM (idempotente)
.venv/bin/python -m pipeline validate       # valida schema e deduplica
.venv/bin/python -m pipeline export --bump  # gera data/output/questions_v<N>.json + manifest
.venv/bin/python -m pipeline run            # as 4 etapas acima em sequência
```

Antes de gerar de verdade, estime o custo (cada questão custa 1 chamada ao modelo):

```bash
.venv/bin/python -m pipeline generate --dry-run
.venv/bin/python -m pipeline generate --dry-run --limit 10
```

Testes (offline, HTTP e LLM mockados):

```bash
.venv/bin/python -m pytest
```

Mais detalhes (estrutura de dados, formato das fontes) em [`pipeline/README.md`](pipeline/README.md).

---

## Rodando o app Flutter

### Pré-requisitos

- Flutter SDK 3.38+ / Dart SDK 3.10+ (o repo fixa a versão via [`app/.fvmrc`](app/.fvmrc); se
  usar [FVM](https://fvm.app/), rode `fvm use` dentro de `app/`)
- Melos (`dart pub global activate melos`) — só necessário se não usar os comandos via
  `flutter pub run melos`, que o Makefile já resolve para você
- Um emulador/simulador Android ou iOS (ou dispositivo físico)

### Instalação (primeira vez)

```bash
cd app
make setup
```

Isso roda `flutter pub get`, gera código (Freezed, injectable, Drift, auto_route) e as
localizações (`intl`/ARB). Ao final, o app está pronto para rodar.

### Rodando o app

O app tem três flavors (dev/stg/prod), configurados via `--dart-define-from-file`. O flavor
**dev** roda sem backend — tudo é local (dados fake/offline), então é o ponto de partida:

```bash
make run-quiz-dev        # Android, flavor dev
make run-quiz-stg        # Android, flavor stg
make run-quiz-prod       # Android, flavor prod

make run-quiz-dev-ios    # iOS (ainda sem schemes por flavor)
```

Ou diretamente:

```bash
cd app/quiz_app
flutter run --flavor dev --dart-define-from-file=env/dev.json
```

### Build

```bash
make build-quiz-apk-dev    # APK dev
make build-quiz-apk-prod   # APK prod
make build-quiz-ios-dev    # iOS dev (--no-codesign)
make build-quiz-ios-prod   # iOS prod (--no-codesign)
```

### Qualidade e testes

```bash
make analyze   # dart analyze + checagem de strings hardcoded
make test      # testes de todos os packages
make ci        # analyze + format-check + test (o que roda no CI local)
```

Rode `make help` em `app/` para ver todos os comandos disponíveis (geração de código,
limpeza de caches, etc.).

---

## Estrutura do app

O app segue clean architecture em um monorepo Melos: `modules/*` concentra lógica de domínio
(sem UI), `features/*` concentra UI/navegação/estado (Cubit como ViewModel, estado imutável via
Freezed), e `quiz_app/` é a casca que compõe tudo.

```
app/
├── quiz_app/                    # entry point do app (main_dev/stg/prod.dart)
├── packages/
│   ├── core/                    # networking, storage, env, base classes
│   ├── design_system/           # tokens, tema, widgets, i18n
│   ├── shared/                  # analytics, crash reporting, connectivity
│   ├── modules/                 # domínio: lógica + dados, sem UI
│   │   ├── question_bank/       # questões, progresso, sync do banco (Drift/SQLite)
│   │   ├── quiz/                # sessão de quiz, repetição espaçada, streak/XP
│   │   ├── auth/
│   │   ├── home/
│   │   └── user_profile/
│   └── features/                # UI: rotas, cubits, páginas, i18n
│       ├── quiz_flow/           # sessão de quiz: pergunta, alternativas, feedback, resumo
│       ├── stats_flow/          # estatísticas e revisão de erros
│       ├── home_flow/
│       ├── auth_flow/
│       ├── onboarding/
│       └── profile_flow/
├── docs/                        # guias de arquitetura, DI, roteamento, i18n, etc.
└── Makefile                     # todos os comandos de desenvolvimento
```

Regras de dependência: `modules` nunca depende de `features`; `features` nunca depende de
outro `features`; `quiz_app` compõe as features. Guias completos em [`app/docs/`](app/docs/),
a começar por [`02-architecture.md`](app/docs/02-architecture.md).

## Modos de sessão

- **Por tópico**: N questões de um tópico, priorizando as ainda não vistas e as vencidas para
  revisão.
- **Revisão**: apenas questões com repetição vencida (`nextReviewAt <= now`), de qualquer
  tópico.
- **Desafio diário**: 10 questões fixas por dia (seed pela data), acessível via deeplink
  `/daily`.

Em qualquer modo, as alternativas de cada questão são embaralhadas a cada exibição — a ordem
não se repete entre sessões, então memorizar a posição da resposta certa não funciona.

## Licença

[MIT](app/LICENSE) para o código do app (baseado no boilerplate
[prodevcom/flutter-mono-repo](https://github.com/prodevcom/flutter-mono-repo)). As fontes de
perguntas usadas pelo pipeline têm suas próprias licenças, declaradas em
[`pipeline/sources.yaml`](pipeline/sources.yaml).
