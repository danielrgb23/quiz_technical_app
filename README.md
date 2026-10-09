# Quiz Technical App

> Plataforma de estudo para entrevistas técnicas, do jeito que você aprende idiomas: trilhas
> (roadmaps) de lições curtas, streak diário e repetição espaçada — tudo funcionando offline.
> O conteúdo inicial é de **desenvolvimento mobile** (Android, iOS, Flutter, System Design), e a
> estrutura foi feita para crescer para **qualquer área técnica**.

## A ideia

Entrevistas técnicas cobram um volume enorme de conceitos, e o material para estudar costuma
estar espalhado em listas gigantes de perguntas em repositórios do GitHub, sem ordem, sem
feedback e sem nenhum jeito de saber o que você já domina. Ler a lista inteira uma vez não
fixa nada — o que fixa é **praticar, errar, ler a explicação e rever na hora certa**.

O **Quiz Technical App** transforma essas listas em um app de estudo, e **cada tópico vira um
roadmap**. Hoje o banco cobre mobile (ciclo de vida, concorrência, gerenciamento de estado,
arquitetura, performance, system design…), mas nada no app é específico de mobile: novas áreas
— backend, dados, DevOps, front-end, segurança, cloud, algoritmos, o que for — entram apenas
adicionando fontes e perguntas ao banco (veja
[Adicionando novas áreas e roadmaps](#adicionando-novas-áreas-e-roadmaps)).

- **Pratique em vez de só ler**: perguntas de múltipla escolha com 5 alternativas embaralhadas
  a cada exibição e uma explicação de cada resposta (toque no card para virá-lo).
- **Roadmaps de aprendizado**: cada tópico é uma trilha de lições de 5 questões, no estilo
  Duolingo. A próxima lição só libera com **pelo menos 80% de acertos**, e você pode ter
  várias trilhas em andamento ao mesmo tempo, cada uma com o seu progresso.
- **Repetição espaçada**: errou? A questão volta na revisão em 1 dia; acertou várias vezes
  seguidas? Os intervalos crescem (1d/3d/7d/21d). Você gasta tempo no que ainda não sabe.
- **Hábito**: streak diário, XP, níveis e desafio diário (10 questões por dia) para manter a
  constância — que é o que realmente prepara para entrevistas.
- **Offline-first**: o banco de questões vem embarcado no app; dá para estudar no metrô, sem
  internet.

**Para quem é**: quem está se preparando para vagas técnicas e quer um jeito estruturado e leve
de revisar conceitos e acompanhar o próprio progresso por tópico — hoje com foco em quem busca
vagas de mobile. O objetivo do projeto é **reduzir o atrito de estudar**: você abre o app, faz
uma lição de poucos minutos e sabe exatamente o que revisar a seguir.

## Baixe e teste o app (Android)

> Versão **1.0.0** (build de produção, assinada e ofuscada) — Android 7.0+ (API 24).

| | |
|---|---|
| **Download** | [⬇️ Baixar o APK (última versão em *Releases*)](https://github.com/danielrgb23/quiz_technical_app/releases/latest) |
| **SHA-256 do APK 1.0.0** | `11f73eea26a4df8faf365d5500490894337d6e5410d268de21d2c685d159415d` |
| **Pacote** | `com.quizmobile.app` |

**Como instalar**

1. Baixe o `app-prod-release.apk` pelo link acima direto no celular.
2. Abra o arquivo; se o Android pedir, permita **"Instalar apps desconhecidos"** para o
   navegador/gerenciador de arquivos usado.
3. Abra o **Quiz Mobile**, toque em **Continuar como convidado** (ou entre com e-mail/Google) e
   escolha um tópico para iniciar a primeira lição.

Confira a integridade do arquivo baixado: `shasum -a 256 app-prod-release.apk` deve bater com o
hash da tabela acima.

### 🎬 Vídeo de demonstração

<!-- Substitua o link abaixo pelo vídeo (YouTube/Drive/Loom) ou use um GIF em docs/media/. -->
**[▶️ Assista ao vídeo de demonstração](#)** — _link em breve_.

<!-- Exemplo de GIF: ![Demo do app](docs/media/demo.gif) -->

> **Mantenedor — publicar uma versão:** gere o APK (`cd app && make build-quiz-apk-prod`; saída
> em `app/quiz_app/build/app/outputs/flutter-apk/app-prod-release.apk`) e publique com
> `gh release create v1.0.0 app/quiz_app/build/app/outputs/flutter-apk/app-prod-release.apk
> --title "Quiz Mobile 1.0.0"`. Atualize o SHA-256 acima a cada versão. A assinatura usa o
> keystore fora do repositório referenciado em `app/quiz_app/android/key.properties`
> (gitignored) — veja [Build de produção](#build-de-produção-apk-assinado).

## O projeto tem duas partes independentes

| Parte | O que faz | Stack |
|---|---|---|
| [`pipeline/`](pipeline/) | Baixa perguntas de entrevista de repositórios open source, gera questões de múltipla escolha via LLM e exporta um banco JSON versionado | Python 3.11+ |
| [`app/`](app/) | App Flutter que consome esse banco e roda o quiz offline-first, com trilhas, progresso, repetição espaçada e estatísticas | Flutter/Dart |

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
[`spec-03-features-quiz.md`](spec-03-features-quiz.md) (features do quiz). As mudanças mais
recentes (trilha, resultado, sons, paleta pastel) estão em
[`app/docs/ux-refresh.md`](app/docs/ux-refresh.md) e em
[`openspec/changes/`](openspec/changes/).

## De onde vêm as questões (coleta de dados de repositórios)

O conteúdo do app **não é copiado de uma única fonte nem digitado à mão**: ele é gerado por um
pipeline reprodutível a partir de repositórios públicos de perguntas de entrevista (hoje, de mobile).

**O que é coletado.** Apenas o **markdown público** (`README.md`) de repositórios listados
explicitamente em [`pipeline/sources.yaml`](pipeline/sources.yaml) — nada de issues, pull
requests, contribuidores, dados de usuários ou qualquer conteúdo fora desses arquivos. Cada
fonte declara o repositório, os arquivos, o tópico padrão e, obrigatoriamente, a **licença**.

| Fonte | Tópico | Licença | Questões no banco atual |
|---|---|---|---|
| [MindorksOpenSource/android-interview-questions](https://github.com/MindorksOpenSource/android-interview-questions) | Android | Apache-2.0 | 107 |
| [thecodexhub/flutter-interview-questions](https://github.com/thecodexhub/flutter-interview-questions) | Flutter | MIT | 88 |
| [onthecodepath/iOS-Interview-Questions](https://github.com/onthecodepath/iOS-Interview-Questions) | iOS | MIT | 41 |
| [weeeBox/mobile-system-design](https://github.com/weeeBox/mobile-system-design) | System Design | MIT | 1 |
| Geradas internamente com revisão manual (cobrir Dart, Kotlin, performance etc.) | vários | — | 30 |

O banco embarcado atual (versão 3) tem **267 questões** em 14 tópicos (Android, Flutter, iOS,
Dart, performance, storage, concorrência, arquitetura, system design, Kotlin, state management,
Swift, networking e testes).

**Como é processado.**

1. **Download com cache por hash** (`fetch`): cada arquivo é guardado com seu SHA-256; se o
   conteúdo não mudou, nada é refeito e nenhuma chamada extra é feita.
2. **Extração heurística** (`parse`): títulos/listas viram pares pergunta/resposta. Cada fonte
   tem um mínimo esperado de pares (`min_expected_pairs`); se uma mudança de estrutura no repo
   derrubar a extração, o resultado anterior é **preservado** em vez de ser sobrescrito.
3. **Transformação por LLM** (`generate`): cada par vira uma questão de múltipla escolha com 5
   alternativas plausíveis e uma explicação. Nas fontes que só têm a pergunta (sem resposta), o
   LLM escreve a resposta e a questão recebe a marca `generated_answer: true` (137 das 267
   questões atuais) para ficar rastreável.
4. **Validação e deduplicação** (`validate`): schema estrito, descarte de falhas e de perguntas
   repetidas — tudo que é rejeitado vai para `data/review/` com o motivo, para revisão humana.
5. **Exportação versionada** (`export`): `questions_v<N>.json` + `manifest.json` com versão,
   contagem, **fontes e licenças** (atribuição) e checksum SHA-256 que o app confere antes de
   aplicar qualquer atualização.

**Cuidados.** A geração é manual e deliberada (não roda em CI, para controlar custo e conteúdo),
os ids são determinísticos (reexecutar não duplica) e há uma estimativa de custo antes de gerar
(`generate --dry-run`). Como parte do texto é produzida por LLM, **pode haver imprecisões**: por
isso o app tem o botão **Reportar questão**, que registra o id em uma coleção protegida do
Firestore para revisão. Se você é autor de um dos repositórios e quer ajustar ou remover o uso do
seu conteúdo, abra uma issue.

## Adicionando novas áreas e roadmaps

O app não tem nenhum tópico fixo no código: a lista de roadmaps da Home vem dos `topic`
presentes no banco de questões, e cada tópico ganha automaticamente a sua trilha, o seu
progresso e a sua entrada na revisão e nas estatísticas. Para abrir uma nova área:

1. **Adicione uma fonte** em [`pipeline/sources.yaml`](pipeline/sources.yaml) (`repo`, `files`,
   `topic_default`, `license` e o `parser`), ou escreva as questões diretamente no formato do
   banco (`question`, 5 `options`, `correctIndex`, `explanation`, `topic`, `level`).
2. **Gere e exporte** com o pipeline (`pipeline run` e depois `pipeline export --bump`), que
   valida, deduplica e cria a nova versão do banco com o checksum.
3. **Publique a versão**: embarque o JSON em `app/quiz_app/assets/question_bank/` (ou publique
   no Firestore, que o app sincroniza validando o checksum). Os novos tópicos aparecem como
   novos roadmaps, sem mudar código.
4. *(Opcional)* Dê um ícone ao tópico no mapa de ícones da Home
   ([`home_page.dart`](app/packages/features/home_flow/lib/src/presentation/pages/home_page.dart));
   sem isso, o app usa um ícone padrão.

## Dados do usuário e privacidade

O app foi pensado para coletar o mínimo necessário:

- **Conta**: Firebase Authentication — convidado (anônimo), e-mail/senha ou Google. A sessão é
  mantida no aparelho (refresh token do Firebase) e não há mais login por biometria.
- **Progresso**: o progresso por questão, XP e streak ficam **no aparelho** (SQLite/
  armazenamento local) e, para quem tem conta, são sincronizados no Firestore em
  `users/{uid}/progress`, com regras que só permitem ler/gravar o **próprio** documento. O
  progresso de convidado é mesclado à conta ao fazer login.
- **Telemetria**: eventos de uso anônimos (início/fim de sessão, questão respondida com tópico,
  nível e acerto/erro, streak) via Firebase Analytics e relatórios de falhas via Crashlytics,
  apenas nos builds de homologação/produção — o flavor `dev` nunca fala com o Firebase.
- **Notificações**: o token FCM é guardado em `users/{uid}/fcm_tokens` para o envio de notificações push.
- **Segurança**: tokens e cache de usuário em armazenamento seguro (Keychain/Keystore), App Check
  habilitado e build de produção ofuscado. O banco de questões é público (somente leitura).
- O app não exibe anúncios e não vende dados.

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
make build-quiz-apk-prod   # APK prod de release (assinado + ofuscado)
make build-quiz-ios-dev    # iOS dev (--no-codesign)
make build-quiz-ios-prod   # iOS prod (--no-codesign)
```

### Build de produção (APK assinado)

```bash
cd app
make build-quiz-apk-prod
# saída: app/quiz_app/build/app/outputs/flutter-apk/app-prod-release.apk
```

Equivale a `flutter build apk --release --flavor prod -t lib/main_prod.dart
--dart-define-from-file=env/prod.json --obfuscate --split-debug-info=build/symbols`. Guarde a
pasta `build/symbols` de cada release para desofuscar stack traces do Crashlytics.

A assinatura usa o keystore apontado por `app/quiz_app/android/key.properties`
(**gitignored**, com `storeFile`, `storePassword`, `keyAlias` e `keyPassword`; o `.jks` fica fora
do repositório). Sem esse arquivo, o build de release cai na chave de debug — serve para testar,
mas **não** para publicar. O build de produção exige também o `google-services.json` e o
`firebase_options.dart` do projeto Firebase (ambos gitignored). Para iOS é necessário assinar
pelo Xcode (`make build-quiz-ios-prod` gera sem assinatura).

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

- **Trilha por tópico**: cada tópico é um roadmap de lições de 5 questões (blocos fixos);
  a próxima lição só libera com >= 80% de acertos e dá para refazer qualquer lição.
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
