.PHONY: setup bootstrap gen l10n analyze test format clean all run-quiz-dev run-quiz-stg run-client-dev run-client-stg ci help

MAKE := make

# Run melos via `flutter pub run` to use Flutter's bundled Dart SDK.
# The standalone dart SDK in PATH can't resolve Flutter packages.
# --no-select skips the interactive package selection prompt.
MELOS := flutter pub run melos

# ============================================================================
# MonoApp - Developer Makefile
# ============================================================================

## Setup & Bootstrap --------------------------------------------------------

setup: ## First-time setup: bootstrap workspace dependencies
	@echo "=> Bootstrapping workspace..."
	flutter pub get
	@$(MAKE) gen
	@$(MAKE) l10n
	@echo "=> Done! Run 'make run-quiz-dev' to start the app."

bootstrap: ## Resolve all workspace dependencies
	flutter pub get

## Code Generation ----------------------------------------------------------

gen: ## Run build_runner in all packages (sequential, topological order via melos)
	$(MELOS) run gen --no-select

gen-clean: ## Clean build_runner cache and regenerate everything
	$(MELOS) run gen:clean --no-select
	@$(MAKE) gen

l10n: ## Generate localization files for all packages
	$(MELOS) run l10n --no-select

## Quality ------------------------------------------------------------------

analyze: ## Run dart analyze across the workspace
	dart analyze

test: ## Run tests in all packages
	$(MELOS) run test --no-select

format: ## Format all Dart files
	dart format .

format-check: ## Check formatting without modifying files
	dart format --set-exit-if-changed .

ci: analyze format-check test ## Run full CI pipeline (analyze + format check + test)

## Run Apps -----------------------------------------------------------------

run-quiz-dev: ## Run quiz_app with dev flavor (Android)
	@cd apps/quiz_app && flutter run --flavor dev --dart-define-from-file=env/dev.json

run-quiz-stg: ## Run quiz_app with stg flavor (Android)
	@cd apps/quiz_app && flutter run --flavor stg --dart-define-from-file=env/stg.json

run-quiz-prod: ## Run quiz_app with prod flavor (Android)
	@cd apps/quiz_app && flutter run --flavor prod --dart-define-from-file=env/prod.json

# iOS ainda não tem schemes por flavor (bundle id único com.quizmobile.app).
run-quiz-dev-ios: ## Run quiz_app dev on iOS (sem flavor scheme)
	@cd apps/quiz_app && flutter run --dart-define-from-file=env/dev.json

run-client-dev: ## Run client_example with dev flavor
	@cd apps/client_example && flutter run --dart-define-from-file=env/dev.json

run-client-stg: ## Run client_example with stg flavor
	@cd apps/client_example && flutter run --dart-define-from-file=env/stg.json

run-client-prod: ## Run client_example with prod flavor
	@cd apps/client_example && flutter run --dart-define-from-file=env/prod.json

## Build Apps ---------------------------------------------------------------

build-quiz-apk-dev: ## Build APK for quiz_app (dev)
	@cd apps/quiz_app && flutter build apk --flavor dev --dart-define-from-file=env/dev.json

build-quiz-apk-prod: ## Build APK for quiz_app (prod)
	@cd apps/quiz_app && flutter build apk --flavor prod --dart-define-from-file=env/prod.json

build-quiz-ios-dev: ## Build iOS for quiz_app (dev)
	@cd apps/quiz_app && flutter build ios --dart-define-from-file=env/dev.json --no-codesign

build-quiz-ios-prod: ## Build iOS for quiz_app (prod)
	@cd apps/quiz_app && flutter build ios --dart-define-from-file=env/prod.json --no-codesign

## Client App Generation ----------------------------------------------------

create-app: ## Create a new client app (usage: make create-app NAME=client_acme DISPLAY="Acme Corp" BUNDLE=com.acme.app)
	@if [ -z "$(NAME)" ] || [ -z "$(DISPLAY)" ] || [ -z "$(BUNDLE)" ]; then \
		echo "Usage: make create-app NAME=client_acme DISPLAY=\"Acme Corp\" BUNDLE=com.acme.app"; \
		exit 1; \
	fi
	./scripts/create_app.sh --name "$(NAME)" --display-name "$(DISPLAY)" --bundle-id "$(BUNDLE)"

## Cleanup ------------------------------------------------------------------

clean: ## Clean all packages (flutter clean + remove generated files)
	$(MELOS) run clean --no-select
	@echo "=> Cleaned."

clean-all: clean ## Deep clean: remove all generated code, caches, and pods
	@echo "=> Removing generated files..."
	@find . -name "*.g.dart" -delete 2>/dev/null || true
	@find . -name "*.freezed.dart" -delete 2>/dev/null || true
	@find . -name "*.gr.dart" -delete 2>/dev/null || true
	@find . -name "*.module.dart" -delete 2>/dev/null || true
	@find . -name "*.config.dart" -delete 2>/dev/null || true
	@find . -type d -name ".dart_tool" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "build" -exec rm -rf {} + 2>/dev/null || true
	@echo "=> Deep clean complete. Run 'make setup' to rebuild."

## Help ---------------------------------------------------------------------

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
