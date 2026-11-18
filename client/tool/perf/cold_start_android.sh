#!/usr/bin/env bash
# Android cold start on a running emulator or device (doc 11, CI Workflows:
# perf-android). Installs the release APK, then five times stops the app
# and launches it with `am start -W`, saving each output, and finally checks
# the median TotalTime against tool/perf/budgets.json with
# tool/perf/cold_start.dart. Run from client/.
#
# Usage: tool/perf/cold_start_android.sh [apk] [output-dir]
#   apk         default build/app/outputs/flutter-apk/app-release.apk
#   output-dir  default build/perf/cold_start
set -euo pipefail

apk="${1:-build/app/outputs/flutter-apk/app-release.apk}"
out="${2:-build/perf/cold_start}"
package=io.soundspan.app
activity="$package/.MainActivity"
runs=5

[[ -f "$apk" ]] || { echo "cold_start_android: no APK at $apk" >&2; exit 2; }
mkdir -p "$out"

adb wait-for-device
adb install -r "$apk"

files=()
for run in $(seq 1 "$runs"); do
  adb shell am force-stop "$package"
  # Let the process exit and the system settle before the next launch.
  sleep 3
  file="$out/run-$run.txt"
  adb shell am start -W -n "$activity" | tee "$file"
  files+=("$file")
done
adb shell am force-stop "$package"

dart run tool/perf/cold_start.dart "${files[@]}"
