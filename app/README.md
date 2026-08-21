# Quiz App (Flutter workspace)

Flutter monorepo (Melos workspace) for the quiz app described in the [root README](../README.md).
It's a **single-app** workspace with **multi-flavor** (dev/stg/prod) support and shared
packages, following clean architecture.

The workspace was originally generated from the white-label
[`prodevcom/flutter-mono-repo`](https://github.com/prodevcom/flutter-mono-repo) boilerplate
(MIT). The multi-app/white-label machinery (`create_app.sh`, generating new client apps) is
kept for reference below since it still works, but this project only ships one app: `quiz_app`.

## Tech Stack

| Category | Tool | Version |
|---|---|---|
| Framework | Flutter | 3.38+ |
| Monorepo | Melos | 7+ |
| Routing | auto_route | 11 |
| DI | get_it + injectable | 8 / 2.5 |
| State | Bloc / Cubit | 9.1 |
| Serialization | Freezed + json_serializable | 3.0 / 6.9 |
| Network | Dio | 5.8 |
| i18n | intl + gen-l10n | 0.20 |

## Project Structure

```
app/
├── quiz_app/                    # The app - entry points, env config, all dev happens here
├── packages/
│   ├── core/                   # Foundation: networking, storage, env, base classes
│   ├── design_system/          # Tokens, theme, widgets, i18n
│   ├── shared/                 # Analytics, crash reporting, connectivity
│   ├── modules/                # Domain: business logic + data (NO UI)
│   │   ├── question_bank/      # Questions, progress, DB sync (Drift/SQLite)
│   │   ├── quiz/                # Quiz session, spaced repetition, streak/XP
│   │   ├── auth/
│   │   ├── home/
│   │   └── user_profile/
│   └── features/                # UI: routes, cubits, pages, widgets, i18n
│       ├── quiz_flow/           # Quiz session: question, options, feedback, summary
│       ├── stats_flow/          # Stats and mistake review
│       ├── home_flow/
│       ├── auth_flow/
│       ├── onboarding/
│       └── profile_flow/
├── scripts/
│   └── create_app.sh            # Leftover white-label tooling (unused by this product)
├── Makefile                     # Developer commands
└── melos.yaml                   # Melos workspace config
```

## Quick Start

### Prerequisites

- Flutter SDK 3.38+
- Dart SDK 3.10+
- Melos (`dart pub global activate melos`) — optional, `make` already wraps it

### First Run

```bash
make setup
```

This will install dependencies, run code generation, and generate localizations.

### Run the App

```bash
make run-quiz-dev    # dev flavor, fake/offline data - no API needed
make run-quiz-stg    # stg flavor
make run-quiz-prod   # prod flavor
```

### VS Code

Open the project in VS Code and use the pre-configured launch configurations in `.vscode/launch.json`. Press F5 and select the desired flavor.

## Common Commands

| Command | Description |
|---|---|
| `make setup` | First-time setup (install + bootstrap + gen + l10n) |
| `make gen` | Run build_runner in all packages (sequential) |
| `make gen-clean` | Clean caches and regenerate everything |
| `make l10n` | Generate localization files |
| `make analyze` | Run dart analyze |
| `make test` | Run all tests |
| `make ci` | Full CI pipeline (analyze + format check + test) |
| `make clean` | Flutter clean all packages |
| `make clean-all` | Deep clean (remove all generated code) |
| `make help` | Show all available commands |

## Creating a New Client App (unused white-label tooling)

Inherited from the boilerplate; not part of this product, but kept working in case the
white-label flow is ever needed again:

```bash
make create-app NAME=client_acme DISPLAY="Acme Corp" BUNDLE=com.acme.app
```

See [docs/05-creating-client-apps.md](docs/05-creating-client-apps.md) for details.

## Flavors

`quiz_app` supports three flavors configured via `--dart-define-from-file`:

| Flavor | Entry Point | Config | DI Environment |
|---|---|---|---|
| **dev** | `main_dev.dart` | `env/dev.json` | Fake data sources (no API) |
| **stg** | `main_stg.dart` | `env/stg.json` | Real data sources |
| **prod** | `main_prod.dart` | `env/prod.json` | Real data sources |

## Architecture

```
                  quiz_app
             /      |       \
      features/*  design_system  shared
         |    \       |           |
     modules/*  \   core        core
         |       |
       core    core
```

**Rules:**
- Modules never depend on features
- Features never depend on other features
- `quiz_app` composes features selectively

See [docs/02-architecture.md](docs/02-architecture.md) for the full architecture guide.

## Documentation

| Guide | Description |
|---|---|
| [01 - Getting Started](docs/01-getting-started.md) | Setup, prerequisites, first run |
| [02 - Architecture](docs/02-architecture.md) | Clean architecture, layers, dependency graph |
| [03 - Creating Modules](docs/03-creating-modules.md) | Step-by-step guide to create a new domain module |
| [04 - Creating Features](docs/04-creating-features.md) | Step-by-step guide to create a new feature |
| [05 - Creating Client Apps](docs/05-creating-client-apps.md) | White-label app generation |
| [06 - Dependency Injection](docs/06-dependency-injection.md) | DI setup, environments, micro-packages |
| [07 - Routing](docs/07-routing.md) | Auto route, AppRoutes, navigation patterns |
| [08 - Internationalization](docs/08-internationalization.md) | i18n with intl + ARB files |
| [09 - Theming](docs/09-theming.md) | Design system, client theme overrides |

## License

This project is licensed under the [MIT License](LICENSE). Base workspace architecture adapted
from [prodevcom/flutter-mono-repo](https://github.com/prodevcom/flutter-mono-repo) by Marcelo
Mussi (MIT).

See the [root README](../README.md) for the full picture of this project, including the
question-generation pipeline that feeds this app.
