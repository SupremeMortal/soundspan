#!/usr/bin/env bash
# Runs the contract suite locally, as the client-contract job does: generates
# the fixture library, starts the contract server (compose.yaml) from this
# working tree's backend, seeds it, runs the contract tests, and always tears
# the server down with its volumes. Needs Docker with Compose, ffmpeg, jq,
# Node 24 and the Dart SDK of the pinned Flutter release.
#
#   run.sh [--capture]
#
# --capture also runs tool/capture_fixtures.dart after the contract tests,
# writing the decode smoke fixtures to ../packages/soundspan_api/test/fixtures/.
set -euo pipefail
cd "$(dirname "$0")"

capture=false
case "${1:-}" in
"") ;;
--capture) capture=true ;;
*)
    echo "Usage: run.sh [--capture]" >&2
    exit 64
    ;;
esac

compose=(docker compose -f compose.yaml)
trap '"${compose[@]}" down -v --remove-orphans' EXIT

fixtures/generate.sh
"${compose[@]}" up -d --build --wait
node seed.ts
dart pub get
dart test --tags contract
if [[ "$capture" == true ]]; then dart run tool/capture_fixtures.dart; fi
# Exit code 79 means no test matched: an empty selection is not a failure.
status=0
dart test --tags contract-destructive || status=$?
if [[ "$status" -ne 0 && "$status" -ne 79 ]]; then exit "$status"; fi
