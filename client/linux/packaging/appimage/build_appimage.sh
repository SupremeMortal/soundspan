#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
#
# Builds soundspan-<version>-linux-x64.AppImage from a Flutter release bundle
# (doc 10, Linux). libmpv and its non-base dependencies are copied into the
# AppDir by linuxdeploy; GTK is bundled by linuxdeploy-plugin-gtk. Both tools
# are pinned and checksum-verified.
#
# The AppImage runtime is pinned too.
#
# Needs: curl, file, dpkg-dev, pkg-config, the GTK 3 development files and
# the libmpv the bundle was built against (the build-linux container has
# them). Runs linuxdeploy with APPIMAGE_EXTRACT_AND_RUN, so FUSE is not
# needed.
#
# Usage: appimage/build_appimage.sh <bundle dir> <version> <out dir>
# TOOLS_DIR (optional) keeps the downloaded tools between runs.
set -euo pipefail

bundle="${1:?usage: build_appimage.sh <bundle dir> <version> <out dir>}"
version="${2:?usage: build_appimage.sh <bundle dir> <version> <out dir>}"
out="${3:?usage: build_appimage.sh <bundle dir> <version> <out dir>}"

linuxdeploy_url='https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20251107-1/linuxdeploy-x86_64.AppImage'
linuxdeploy_sha256='c20cd71e3a4e3b80c3483cef793cda3f4e990aca14014d23c544ca3ce1270b4d'
gtk_plugin_url='https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/3b67a1d1c1b0c8268f57f2bce40fe2d33d409cea/linuxdeploy-plugin-gtk.sh'
gtk_plugin_sha256='b0f4cbc684a0103a9651f0955b635eaea0096b3a66c0f5a2c2aa337960375171'
# appimagetool would otherwise download the moving "continuous" runtime.
runtime_url='https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64'
runtime_sha256='2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d'

# shellcheck source-path=SCRIPTDIR source=../common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"
check_bundle "$bundle"
bundle="$(cd "$bundle" && pwd)"
mkdir -p "$out"
out="$(cd "$out" && pwd)"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
tools="${TOOLS_DIR:-$work/tools}"
mkdir -p "$tools"

# fetch <url> <sha256> <file>: downloads unless a verified copy is there.
fetch() {
  local url="$1" sum="$2" file="$3"
  if ! echo "$sum  $file" | sha256sum --check --status 2> /dev/null; then
    curl -fsSL --retry 3 -o "$file" "$url"
    echo "$sum  $file" | sha256sum --check --strict || {
      echo "checksum mismatch: $url" >&2
      exit 1
    }
  fi
  chmod +x "$file"
}
fetch "$linuxdeploy_url" "$linuxdeploy_sha256" "$tools/linuxdeploy-x86_64.AppImage"
fetch "$gtk_plugin_url" "$gtk_plugin_sha256" "$tools/linuxdeploy-plugin-gtk.sh"
fetch "$runtime_url" "$runtime_sha256" "$tools/runtime-x86_64"

# The libmpv media_kit opens by name (libmpv.so.2, else libmpv.so.1).
libmpv=''
for name in libmpv.so.2 libmpv.so.1; do
  libmpv="$(ldconfig -p | awk -v n="$name" '$1 == n && /x86-64/ { print $NF; exit }')"
  [[ -n "$libmpv" ]] && break
done
[[ -n "$libmpv" ]] || { echo "no libmpv.so.2 or libmpv.so.1 on this system" >&2; exit 1; }
libmpv_name="$(basename "$libmpv")"
echo "bundling $libmpv ($libmpv_name)"

# Dependencies of libmpv that linuxdeploy's excludelist leaves to the host,
# but that a system without audio or GL packages lacks (the smoke-linux
# container has none of them): they are deployed explicitly.
extra_libs=()
for name in libasound.so.2 libEGL.so.1 libgbm.so.1 libjack.so.0 libusb-1.0.so.0; do
  path="$(ldd "$libmpv" | awk -v n="$name" '$1 == n { print $3; exit }')"
  [[ -n "$path" && -e "$path" ]] && extra_libs+=(--library "$path")
done

# The Flutter bundle keeps its layout under usr/bin (the executable finds
# lib/libapp.so and data/ next to itself); linuxdeploy adds the shared
# libraries under usr/lib.
appdir="$work/AppDir"
install -d "$appdir/usr/bin"
cp -a "$bundle/." "$appdir/usr/bin/"
install_desktop_metadata "$appdir/usr" "$version"

# media_kit loads libmpv with dlopen, so it is not a dependency linuxdeploy
# sees: it is deployed with --library and AppRun points media_kit at it.
cat > "$work/AppRun" <<APPRUN
#!/bin/sh
here="\$(dirname "\$(readlink -f "\$0")")"
export APPDIR="\${APPDIR:-\$here}"
export LIBMPV_LIBRARY_PATH="\$here/usr/lib/$libmpv_name"
exec "\$here/usr/bin/soundspan" "\$@"
APPRUN
chmod +x "$work/AppRun"

cd "$work"
export PATH="$tools:$PATH" LINUXDEPLOY="$tools/linuxdeploy-x86_64.AppImage"
export APPIMAGE_EXTRACT_AND_RUN=1 NO_STRIP=1 DEPLOY_GTK_VERSION=3
export LDAI_RUNTIME_FILE="$tools/runtime-x86_64"
export LDAI_OUTPUT="soundspan-$version-linux-x64.AppImage"
"$tools/linuxdeploy-x86_64.AppImage" \
  --appdir "$appdir" \
  --executable "$appdir/usr/bin/soundspan" \
  --deploy-deps-only "$appdir/usr/bin/lib" \
  --library "$libmpv" \
  "${extra_libs[@]}" \
  --desktop-file "$appdir/usr/share/applications/$app_id.desktop" \
  --icon-file "$packaging_dir/icons/hicolor/256x256/apps/$app_id.png" \
  --custom-apprun "$work/AppRun" \
  --plugin gtk \
  --output appimage

[[ -s "$work/$LDAI_OUTPUT" ]] || { echo "linuxdeploy wrote no $LDAI_OUTPUT" >&2; ls -l "$work" >&2; exit 1; }
mv "$work/$LDAI_OUTPUT" "$out/"
echo "built $out/$LDAI_OUTPUT"
