#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
(
  cd packages/soundspan_api
  # Guarded until the swagger_parser configuration exists (#69 removes it).
  if [[ -f swagger_parser.yaml ]]; then
    dart run swagger_parser
  fi
  dart run build_runner build --delete-conflicting-outputs
)
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
