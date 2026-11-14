#!/usr/bin/env bash
# Runs the client-analyze and client-test jobs of client-quality.yml locally,
# in the same order, stopping at the first failure.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== client-analyze"
tool/gen.sh
git diff --exit-code -- .
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
dart run tool/check_imports.dart
dart run tool/check_l10n.dart
dart run tool/license_audit.dart
dart run tool/gen_icons.dart --check
(cd packages/soundspan_api && dart analyze --fatal-infos)

echo "== client-test"
(cd packages/soundspan_api && dart test --coverage-path=coverage/lcov.info)
flutter test --coverage --exclude-tags golden,contract,engine
dart run tool/coverage_floor.dart
