#!/usr/bin/env bash
# Fails unless the APK's launcher icon has an adaptive (anydpi-v26)
# variant. Reads the compiled resource table with aapt2, because a release
# build shortens resource file paths inside the APK.
#
# Usage, from client/:
#   tool/ci/check_apk_icon.sh <apk>
set -euo pipefail

apk="${1:?usage: check_apk_icon.sh <apk>}"
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
aapt2="$(find "$sdk/build-tools" -maxdepth 2 -name aapt2 -type f 2>/dev/null | sort -V | tail -n 1)"
if [[ -z "$aapt2" ]]; then
  echo "check_apk_icon: no aapt2 under \$ANDROID_HOME/build-tools" >&2
  exit 2
fi

block="$("$aapt2" dump resources "$apk" | awk '
  / resource 0x[0-9a-f]+ mipmap\/ic_launcher( |$)/ { inside = 1; print; next }
  / resource 0x/ { inside = 0 }
  inside { print }
')"
if grep -q '(anydpi-v26)' <<< "$block"; then
  echo "check_apk_icon: mipmap/ic_launcher has an anydpi-v26 variant"
  exit 0
fi
echo "check_apk_icon: mipmap/ic_launcher has no anydpi-v26 variant in $apk" >&2
printf '%s\n' "${block:-(no mipmap/ic_launcher resource)}" >&2
exit 1
