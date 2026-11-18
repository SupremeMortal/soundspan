#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
#
# Builds soundspan-<version>-linux-x64.flatpak, a single-file bundle, from the
# Linux release tarball (doc 10, Linux). Builds a copy of
# io.soundspan.app.yml whose soundspan source is the local tarball (path and
# computed SHA-256) and whose version is <version>; the committed manifest is
# never modified. The runtime and SDK come from the user's flathub remote.
#
# Usage: flatpak/build_flatpak.sh <bundle tarball> <version> <out dir>
#
# FLATPAK_STATE_DIR: flatpak-builder's state directory (downloads, git
# mirrors and the build cache of every module), default a temporary one; CI
# caches it so the mpv module is not rebuilt on every run.
set -euo pipefail

usage='usage: build_flatpak.sh <bundle tarball> <version> <out dir>'
tarball="${1:?$usage}"
version="${2:?$usage}"
out="${3:?$usage}"

[[ -f "$tarball" ]] || {
  echo "no such tarball: $tarball" >&2
  exit 2
}
tarball="$(cd "$(dirname "$tarball")" && pwd)/$(basename "$tarball")"

flatpak_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_id='io.soundspan.app'

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
state="${FLATPAK_STATE_DIR:-$work/state}"

# The copy keeps the packaging tree around it, so the manifest's relative
# file sources (../common.sh, ../icons, ...) resolve as they do for the
# committed one.
cp -a "$flatpak_dir/.." "$work/packaging"
manifest="$work/packaging/flatpak/$app_id.yml"

sum="$(sha256sum "$tarball" | cut -d' ' -f1)"
awk -v path="$tarball" -v sum="$sum" -v version="$version" '
  /^ *url: .*\/soundspan-[^\/]*-linux-x64-unsigned\.tar\.gz$/ {
    sub(/url: .*/, "path: " path); urls++; replaced = 1; print; next
  }
  replaced && /^ *sha256: / {
    sub(/sha256: .*/, "sha256: " sum); sums++; replaced = 0; print; next
  }
  /^ *SOUNDSPAN_VERSION: / {
    sub(/SOUNDSPAN_VERSION: .*/, "SOUNDSPAN_VERSION: " version); versions++
  }
  { print }
  END {
    if (urls != 1 || sums != 1 || versions != 1) {
      printf "manifest: expected one release tarball url, its sha256 and SOUNDSPAN_VERSION; found %d, %d, %d\n", urls, sums, versions > "/dev/stderr"
      exit 1
    }
  }
' "$flatpak_dir/$app_id.yml" > "$manifest"

mkdir -p "$out"
flatpak-builder --user --force-clean --disable-rofiles-fuse \
  --install-deps-from=flathub --state-dir="$state" --repo="$work/repo" \
  "$work/build" "$manifest"

bundle="$out/soundspan-$version-linux-x64.flatpak"
flatpak build-bundle --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo \
  "$work/repo" "$bundle" "$app_id"
echo "built $bundle"
