#!/usr/bin/env bash
# Checks the merged AndroidManifest.xml of a built APK against the doc 10
# manifest table: exports it with apkanalyzer (Android SDK command-line
# tools), writes the resource names back over the compiled resource ids
# (read with aapt2), and runs tool/check_platform_config.dart on it.
#
#   tool/ci/check_apk_manifest.sh <apk>
#
# Run from client/. The resource files are checked from the source tree.
set -euo pipefail

apk="${1:?usage: check_apk_manifest.sh <apk>}"
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
apkanalyzer=""
aapt2=""
if [[ -n "$sdk" && -d "$sdk/cmdline-tools" ]]; then
  apkanalyzer="$(find "$sdk/cmdline-tools" -maxdepth 3 -name apkanalyzer -type f | sort -V | tail -n 1)"
fi
if [[ -n "$sdk" && -d "$sdk/build-tools" ]]; then
  aapt2="$(find "$sdk/build-tools" -maxdepth 2 -name aapt2 -type f | sort -V | tail -n 1)"
fi
if [[ -z "$apkanalyzer" || -z "$aapt2" ]]; then
  echo "check_apk_manifest: no apkanalyzer under \$ANDROID_HOME/cmdline-tools or aapt2 under \$ANDROID_HOME/build-tools" >&2
  exit 2
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
"$apkanalyzer" manifest print "$apk" > "$work/compiled.xml"
# "resource 0x7f140000 xml/backup_rules" -> s|"@[^"]*0x7f140000"|"@xml/backup_rules"|I
"$aapt2" dump resources "$apk" \
  | sed -nE 's#^ *resource (0x[0-9a-fA-F]{8}) ([A-Za-z_]+/[A-Za-z0-9_.]+).*#s|"@[^"]*\1"|"@\2"|I#p' \
  > "$work/names.sed"
sed -f "$work/names.sed" "$work/compiled.xml" > "$work/AndroidManifest.xml"
echo "check_apk_manifest: merged manifest of $apk"
if ! dart run tool/check_platform_config.dart --android-manifest="$work/AndroidManifest.xml"; then
  echo "check_apk_manifest: the <application>, <activity>, <service> and <receiver> lines checked:" >&2
  grep -nE '<(application|activity|service|receiver)|launchMode|foregroundServiceType|networkSecurityConfig|dataExtractionRules|fullBackupContent' \
    "$work/AndroidManifest.xml" >&2 || true
  exit 1
fi
