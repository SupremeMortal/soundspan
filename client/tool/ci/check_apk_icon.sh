#!/usr/bin/env bash
# Fails unless the APK's launcher icon has an adaptive variant: an XML
# file under anydpi-v26, or under anydpi when minSdk is 26 or more and
# aapt2 drops the implied -v26 qualifier. Reads the compiled resource table
# with aapt2, because a release build shortens resource file paths inside
# the APK.
#
# Usage, from client/:
#   tool/ci/check_apk_icon.sh <apk>
#   tool/ci/check_apk_icon.sh --resources <file>
# The second form reads a saved `aapt2 dump resources` output instead of
# running aapt2 (test/tool/check_apk_icon_test.dart feeds it fixtures).
#
# Exit codes: 0 adaptive variant found, 1 not found, 2 usage or setup error.
set -euo pipefail

usage="usage: check_apk_icon.sh <apk> | --resources <file>"

# Prints the mipmap/ic_launcher entry of an `aapt2 dump resources` output
# read from stdin: its resource line and the configuration lines under it.
launcher_block() {
  awk '
    / resource 0x[0-9a-f]+ mipmap\/ic_launcher( |$)/ { inside = 1; print; next }
    / resource 0x/ { inside = 0 }
    inside { print }
  '
}

if [[ "${1:-}" == "--resources" ]]; then
  resources="${2:?$usage}"
  if [[ ! -f "$resources" ]]; then
    echo "check_apk_icon: no such resources file: $resources" >&2
    exit 2
  fi
  source_name="$resources"
  block="$(launcher_block < "$resources")"
else
  apk="${1:?$usage}"
  sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  aapt2=""
  if [[ -n "$sdk" && -d "$sdk/build-tools" ]]; then
    aapt2="$(find "$sdk/build-tools" -maxdepth 2 -name aapt2 -type f | sort -V | tail -n 1)"
  fi
  if [[ -z "$aapt2" ]]; then
    echo "check_apk_icon: no aapt2 under \$ANDROID_HOME/build-tools" >&2
    exit 2
  fi
  source_name="$apk"
  block="$("$aapt2" dump resources "$apk" | launcher_block)"
fi

if grep -Eq '\(anydpi(-v26)?\) \(file\) .* type=XML' <<< "$block"; then
  echo "check_apk_icon: mipmap/ic_launcher has an adaptive (anydpi) variant"
  exit 0
fi
echo "check_apk_icon: mipmap/ic_launcher has no adaptive (anydpi) variant in $source_name" >&2
printf '%s\n' "${block:-(no mipmap/ic_launcher resource)}" >&2
exit 1
