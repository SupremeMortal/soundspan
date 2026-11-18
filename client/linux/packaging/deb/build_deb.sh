#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
#
# Builds soundspan-<version>-linux-amd64.deb from a Flutter release bundle
# (doc 10, Linux). libmpv, GTK, libsecret and the EGL and GLES libraries the
# Flutter engine opens at run time come from the distribution:
#   Depends: libmpv2 | libmpv1, libgtk-3-0, libsecret-1-0, libegl1, libgles2
#
# Usage: deb/build_deb.sh <bundle dir> <version> <out dir>
set -euo pipefail

bundle="${1:?usage: build_deb.sh <bundle dir> <version> <out dir>}"
version="${2:?usage: build_deb.sh <bundle dir> <version> <out dir>}"
out="${3:?usage: build_deb.sh <bundle dir> <version> <out dir>}"

# shellcheck source-path=SCRIPTDIR source=../common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
check_bundle "$bundle"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
root="$work/root"

# The Flutter bundle keeps its layout: the executable finds lib/ and data/
# next to itself.
install -d "$root/usr/lib/soundspan" "$root/usr/bin"
cp -a "$bundle/." "$root/usr/lib/soundspan/"
ln -s ../lib/soundspan/soundspan "$root/usr/bin/soundspan"

install_desktop_metadata "$root/usr" "$version"
install -Dm644 "$packaging_dir/../../LICENSE" "$root/usr/share/doc/soundspan/copyright"

installed_size="$(du -sk --exclude=DEBIAN "$root" | cut -f1)"
install -d "$root/DEBIAN"
cat > "$root/DEBIAN/control" <<CONTROL
Package: soundspan
Version: $version
Architecture: amd64
Maintainer: soundspan project <https://github.com/soundspan/soundspan>
Installed-Size: $installed_size
Depends: libmpv2 | libmpv1, libgtk-3-0, libsecret-1-0, libegl1, libgles2
Section: sound
Priority: optional
Homepage: https://github.com/soundspan/soundspan
Description: Music, podcasts and audiobooks from your soundspan server
 soundspan is the client for a self-hosted soundspan server. It plays your
 music library, podcasts and audiobooks, keeps downloads for offline
 listening and shows synced lyrics.
CONTROL

# Directories 755, files 644, executables (and the bundle's shared
# libraries) 755, whatever the umask of the build.
find "$root" -type d -exec chmod 755 {} +
find "$root" -type f -exec chmod go-w,a+r {} +

mkdir -p "$out"
deb="$out/soundspan-$version-linux-amd64.deb"
dpkg-deb --build --root-owner-group "$root" "$deb"
echo "built $deb"
