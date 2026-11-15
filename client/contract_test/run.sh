#!/usr/bin/env bash
# Runs the contract suite locally, as the client-contract job does: generates
# the fixture library, starts the contract server (compose.yaml) from this
# working tree's backend, seeds it, runs the contract tests, and always tears
# the server down with its volumes. Needs Docker with Compose, ffmpeg, jq,
# Node 24 and the Dart SDK of the pinned Flutter release.
set -euo pipefail
cd "$(dirname "$0")"

compose=(docker compose -f compose.yaml)
trap '"${compose[@]}" down -v --remove-orphans' EXIT

fixtures/generate.sh
"${compose[@]}" up -d --build --wait
node seed.ts
dart pub get
dart test --tags contract
# Exit code 79 means no test matched: an empty selection is not a failure.
status=0
dart test --tags contract-destructive || status=$?
if [[ "$status" -ne 0 && "$status" -ne 79 ]]; then exit "$status"; fi
