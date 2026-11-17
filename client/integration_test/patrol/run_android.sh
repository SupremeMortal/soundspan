#!/usr/bin/env bash
# Runs the Patrol suite on the booted emulator emulator-5554 against the
# contract server on the runner's port 3030 (doc 11, Integration (mobile));
# the patrol-android job of .github/workflows/client-device-tests.yml runs it
# inside the emulator action, from client/:
#
#   integration_test/patrol/run_android.sh <log directory>
#
# E2E_USERNAME and E2E_PASSWORD name the seeded user. adb logcat is written
# to the log directory throughout, and a screenshot on failure.
set -euo pipefail
log_dir="$1"
mkdir -p "$log_dir"

adb logcat -c || true
adb logcat > "$log_dir/logcat.txt" 2>&1 &
logcat=$!
trap 'kill "$logcat" 2> /dev/null || true' EXIT

status=0
patrol test \
    --target integration_test/patrol/playback_background_test.dart \
    --device emulator-5554 \
    --dart-define=E2E_SERVER=http://10.0.2.2:3030 \
    --dart-define=E2E_USERNAME="$E2E_USERNAME" \
    --dart-define=E2E_PASSWORD="$E2E_PASSWORD" ||
    status=$?
if [[ "$status" -ne 0 ]]; then
    adb exec-out screencap -p > "$log_dir/screenshot.png" || true
fi
exit "$status"
