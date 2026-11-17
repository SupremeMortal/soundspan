#!/usr/bin/env bash
# Checks the merged AndroidManifest.xml of a built APK against the doc 10
# manifest table: exports it with apkanalyzer (Android SDK command-line
# tools) and runs tool/check_platform_config.dart on it.
#
#   tool/ci/check_apk_manifest.sh <apk>
#
# Run from client/. The resource files are checked from the source tree.
set -euo pipefail

apk="${1:?usage: check_apk_manifest.sh <apk>}"
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
apkanalyzer=""
if [[ -n "$sdk" && -d "$sdk/cmdline-tools" ]]; then
  apkanalyzer="$(find "$sdk/cmdline-tools" -maxdepth 3 -name apkanalyzer -type f | sort -V | tail -n 1)"
fi
if [[ -z "$apkanalyzer" ]]; then
  apkanalyzer="$(command -v apkanalyzer || true)"
fi
if [[ -z "$apkanalyzer" ]]; then
  echo "check_apk_manifest: no apkanalyzer under \$ANDROID_HOME/cmdline-tools" >&2
  exit 2
fi

manifest="$(mktemp --suffix=.xml)"
trap 'rm -f "$manifest"' EXIT
"$apkanalyzer" manifest print "$apk" > "$manifest"
echo "check_apk_manifest: merged manifest of $apk"
dart run tool/check_platform_config.dart --android-manifest="$manifest"
