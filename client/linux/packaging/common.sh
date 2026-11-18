#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
#
# Shared installation steps of the Linux packages (doc 10, Linux): the
# desktop file, the hicolor icons and the AppStream metainfo, each under the
# application id io.soundspan.app. Sourced by deb/build_deb.sh and
# appimage/build_appimage.sh.

packaging_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_id='io.soundspan.app'

# install_desktop_metadata <prefix> <version>
# Installs into <prefix> (for example <root>/usr):
#   share/applications/io.soundspan.app.desktop
#   share/icons/hicolor/<size>/apps/io.soundspan.app.{png,svg}
#   share/metainfo/io.soundspan.app.metainfo.xml, its release set to <version>
install_desktop_metadata() {
  local prefix="$1" version="$2"
  local date="${RELEASE_DATE:-$(date -u +%F)}"

  install -Dm644 "$packaging_dir/$app_id.desktop" \
    "$prefix/share/applications/$app_id.desktop"

  local icon rel
  while IFS= read -r -d '' icon; do
    rel="${icon#"$packaging_dir/icons/"}"
    install -Dm644 "$icon" "$prefix/share/icons/$rel"
  done < <(find "$packaging_dir/icons/hicolor" -type f -print0)

  install -d "$prefix/share/metainfo"
  sed -e "s/@VERSION@/$version/" -e "s/@DATE@/$date/" \
    "$packaging_dir/$app_id.metainfo.xml" \
    > "$prefix/share/metainfo/$app_id.metainfo.xml"
  chmod 644 "$prefix/share/metainfo/$app_id.metainfo.xml"
}

# check_bundle <bundle dir>: the Flutter bundle has its executable.
check_bundle() {
  [[ -x "$1/soundspan" && -d "$1/lib" && -d "$1/data" ]] || {
    echo "not a Flutter bundle (soundspan, lib/, data/): $1" >&2
    exit 2
  }
}
