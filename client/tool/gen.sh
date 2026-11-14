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
# Schema dumps and migration helpers per database (doc 05, Migrations).
dart run drift_dev schema dump lib/core/storage/app/app_database.dart drift_schemas/app/
dart run drift_dev schema steps drift_schemas/app/ lib/core/storage/app/app_database.steps.g.dart
mkdir -p test/core/storage/generated_migrations
dart run drift_dev schema generate drift_schemas/app/ test/core/storage/generated_migrations/app/
flutter gen-l10n
