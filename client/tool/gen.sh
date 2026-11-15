#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
(
  cd packages/soundspan_api
  # The generator reads a copy with nullable allOf references rewritten
  # (tool/normalize_spec.dart); the committed spec stays as emitted.
  normalized="$(mktemp -d)/soundspan-client.json"
  dart run tool/normalize_spec.dart openapi/soundspan-client.json "$normalized"
  dart run swagger_parser --schema_path "$normalized"
  # Anonymous operations and operation ids, read from the same spec.
  dart run tool/gen_anonymous_operations.dart
  dart format lib/src/generated/anonymous_operations.g.dart
  dart run build_runner build --delete-conflicting-outputs
)
dart run build_runner build --delete-conflicting-outputs
# Schema dumps and migration helpers per database (doc 05, Migrations).
dart run drift_dev schema dump lib/core/storage/app/app_database.dart drift_schemas/app/
dart run drift_dev schema steps drift_schemas/app/ lib/core/storage/app/app_database.steps.g.dart
mkdir -p test/core/storage/generated_migrations
dart run drift_dev schema generate drift_schemas/app/ test/core/storage/generated_migrations/app/
dart run drift_dev schema dump lib/core/storage/state/state_database.dart drift_schemas/state/
dart run drift_dev schema steps drift_schemas/state/ lib/core/storage/state/state_database.steps.g.dart
dart run drift_dev schema generate drift_schemas/state/ test/core/storage/generated_migrations/state/
# cache.db is recreated, not migrated: only the dump, no migration helpers.
dart run drift_dev schema dump lib/core/storage/cache/cache_database.dart drift_schemas/cache/
# The en_XA pseudo-locale ARB is generated from the English template.
dart run tool/gen_pseudo_locale.dart
flutter gen-l10n
