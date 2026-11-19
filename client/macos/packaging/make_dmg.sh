#!/usr/bin/env bash
# Packs the macOS release build into the unsigned disk image (doc 10,
# macOS: Distribution):
#   1. checks that the app is universal (x86_64 and arm64);
#   2. re-signs it ad hoc, inside out, with the hardened runtime: nested
#      dylibs and frameworks, then nested helper bundles and the app with
#      the ad-hoc entitlements;
#   3. creates a compressed, read-only image (UDZO) of a folder holding the
#      app and an /Applications symlink, with hdiutil.
#
# The ad-hoc entitlements are macos/Runner/AdHoc.entitlements, unless an
# entitlements file is passed as the fourth argument: Release.entitlements
# without keychain-access-groups, a restricted entitlement that needs a
# provisioning profile. macOS kills (SIGKILL) an ad-hoc signed app that
# carries it as soon as it starts.
#
# Usage:
#   macos/packaging/make_dmg.sh <path to soundspan.app> <version> <output dir> [entitlements]
# Writes <output dir>/soundspan-<version>-macos-universal-unsigned.dmg.
set -euo pipefail

fail() { echo "make_dmg: $*" >&2; exit 1; }

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "usage: $0 <path to soundspan.app> <version> <output dir> [entitlements]" >&2
  exit 64
fi
app="${1%/}"
version="$2"
out_dir="$3"
[[ -d "$app/Contents/MacOS" ]] || fail "not an app bundle: $app"
[[ -n "$version" ]] || fail "empty version"
exe="$app/Contents/MacOS/$(plutil -extract CFBundleExecutable raw -o - "$app/Contents/Info.plist")"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# 1. Universal.
archs="$(lipo -archs "$exe")"
echo "make_dmg: architectures: $archs"
[[ " $archs " == *" arm64 "* && " $archs " == *" x86_64 "* ]] ||
  fail "the executable is not universal: $archs"

# 2. Ad-hoc signature, inside out.
entitlements="${4:-$(cd "$(dirname "$0")/../Runner" && pwd)/AdHoc.entitlements}"
[[ -f "$entitlements" ]] || fail "entitlements not found: $entitlements"

sign() { codesign --force --options runtime --timestamp=none --sign - "$@"; }

# Deepest paths first, so every container is signed after its contents.
by_depth() { awk -F/ '{ print NF "\t" $0 }' | sort -rn | cut -f2-; }

while IFS= read -r code; do
  [[ -n "$code" ]] && sign "$code"
done < <(find "$app/Contents" \( -name '*.dylib' -o -name '*.framework' \) | by_depth)
while IFS= read -r helper; do
  [[ -n "$helper" ]] && sign --entitlements "$entitlements" "$helper"
done < <(find "$app/Contents" -mindepth 1 \( -name '*.app' -o -name '*.xpc' -o -name '*.appex' \) | by_depth)
sign --entitlements "$entitlements" "$app"
codesign --verify --deep --strict "$app"

# 3. The image.
staging="$work/staging"
mkdir -p "$staging" "$out_dir"
ditto "$app" "$staging/soundspan.app"
ln -s /Applications "$staging/Applications"
dmg="$out_dir/soundspan-$version-macos-universal-unsigned.dmg"
rm -f "$dmg"
hdiutil create -volname soundspan -srcfolder "$staging" -fs HFS+ -format UDZO -ov "$dmg"
echo "make_dmg: wrote $dmg"
