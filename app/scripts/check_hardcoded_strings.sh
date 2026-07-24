#!/bin/bash
# Falha se encontrar strings de UI hardcoded (Text() e props de texto de
# widgets como title/label/hint/tooltip) fora dos arquivos gerados de l10n.
#
# Escopo: apenas texto de UI. Mensagens de domínio/exceção (message:,
# Failure) e dados de seed/fake não são cobertos — não são texto exibido
# diretamente sem passar por uma camada de apresentação localizável.
#
# apps/client_example é o demo do fluxo white-label do boilerplate,
# explicitamente fora de escopo (Spec 02) e não usado pelo quiz_app.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PATTERN='Text\(\s*['"'"'"][A-Za-zÀ-ÿ]|\b\w*(Label|Title|Hint|Tooltip):\s*['"'"'"][A-Za-zÀ-ÿ]'

MATCHES=$(grep -rnE "$PATTERN" apps packages --include="*.dart" \
  | grep -v -E '\.g\.dart:|\.freezed\.dart:|\.config\.dart:|\.gr\.dart:' \
  | grep -v -E '/l10n/generated/|/generated/|/test/' \
  | grep -v '^apps/client_example/' \
  || true)

if [ -n "$MATCHES" ]; then
  echo "Strings de UI hardcoded encontradas (mova para os arquivos .arb):"
  echo "$MATCHES"
  exit 1
fi

echo "Nenhuma string de UI hardcoded encontrada."
