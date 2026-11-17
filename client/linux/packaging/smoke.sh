#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
#
# Install-and-launch smoke test of a Linux package in a clean container
# (doc 11, client-build.yml: smoke-linux). One sub-check per line; the first
# failure exits 1 with a message and copies the app log to <log out>.
#
#   smoke.sh deb <dist dir> <version> [log out]
#     Run as root in a bare ubuntu container with xvfb, dbus and
#     desktop-file-utils added: apt installs the .deb with its dependencies;
#     dpkg reports it installed; the desktop file validates; ldd resolves
#     every dependency of /usr/lib/soundspan/soundspan; the app launches;
#     apt-get remove leaves nothing under /usr/lib/soundspan.
#
#   smoke.sh appimage <dist dir> <version> [log out]
#     Run in a bare ubuntu container with only libgtk-3-0, xvfb, dbus and
#     the host's EGL and GLES libraries (libegl1, libgles2) added (no mpv,
#     no ffmpeg): --appimage-extract works; ldd resolves every
#     dependency of the executable and of the bundled libmpv; libmpv and its
#     codec libraries resolve inside the AppDir, and the system has no
#     libmpv; the app launches with --appimage-extract-and-run.
#
#   smoke.sh flatpak <dist dir> <version> [log out]
#     Run as a user with flatpak, xvfb and dbus and the flathub remote added
#     for that user: flatpak install --user takes the bundle and its runtime;
#     flatpak info reports <version>; the sandbox permissions are exactly
#     doc 10's finish-args; inside the sandbox ldd resolves every dependency
#     of /app/lib/soundspan/soundspan and of /app/lib/libmpv.so.*, which the
#     library cache maps libmpv to; the app launches with flatpak run, writing
#     its log under ~/.var/app/io.soundspan.app; flatpak uninstall --user
#     removes it.
#
# "Launches": started with `dbus-run-session -- xvfb-run -a`, the process is
# still running after 20 seconds and a log file exists in the app's log
# directory (<XDG_DATA_HOME>/<app>/logs/app.*.log; for the Flatpak, the
# sandbox's own data directory); then it is stopped. A
# second launch with a soundspan:// link, which the first instance logs,
# guarantees a log entry when start-up wrote none.
set -euo pipefail

# A nested __inside call shares the parent's work directory.
work="${SMOKE_WORK:-$(mktemp -d)}"
export SMOKE_WORK="$work"
export XDG_DATA_HOME="$work/data" XDG_CACHE_HOME="$work/cache" XDG_CONFIG_HOME="$work/config"
mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
# Where the app writes its data; a sandboxed app has its own.
export LOG_ROOT="${LOG_ROOT:-$XDG_DATA_HOME}"

pass() { echo "PASS: $*"; }

save_logs() {
  [[ -n "${log_out:-}" ]] || return 0
  mkdir -p "$log_out"
  cp "$work"/*.out "$log_out/" 2> /dev/null || true
  find "$LOG_ROOT" -name 'app.*.log' -exec cp {} "$log_out/" \; 2> /dev/null || true
}

fail() {
  echo "FAIL: $*" >&2
  save_logs
  exit 1
}

find_logs() { find "$LOG_ROOT" -path '*/logs/app.*.log' -type f 2> /dev/null; }

# no_unresolved <file> [LD_LIBRARY_PATH]: ldd reports no "not found".
no_unresolved() {
  local out
  [[ -e "$1" ]] || fail "missing: $1"
  out="$(LD_LIBRARY_PATH="${2:-}" ldd "$1" 2>&1)" || fail "ldd failed on $1: $out"
  if grep -q 'not found' <<< "$out"; then
    grep 'not found' <<< "$out" >&2
    fail "ldd: unresolved dependency of $1"
  fi
  pass "ldd resolves every dependency of $1"
}

# The launch sequence, run inside the D-Bus session and the X display that
# launch() sets up. Exits 0 when the app ran for 20 s and wrote a log file.
inside_session() {
  local pid
  setsid "$@" > "$work/app.out" 2>&1 &
  pid=$!
  sleep 20
  if ! kill -0 "$pid" 2> /dev/null; then
    echo "the app exited within 20 s" >&2
    return 1
  fi
  echo "the app is running after 20 s"
  if [[ -z "$(find_logs)" ]]; then
    timeout 10 "$@" 'soundspan://album/smoke' > "$work/second.out" 2>&1 || true
    for _ in $(seq 1 15); do
      [[ -n "$(find_logs)" ]] && break
      sleep 1
    done
  fi
  local logs
  logs="$(find_logs)"
  kill -TERM -- "-$pid" 2> /dev/null || kill -TERM "$pid" 2> /dev/null || true
  for _ in $(seq 1 10); do
    kill -0 "$pid" 2> /dev/null || break
    sleep 1
  done
  kill -KILL -- "-$pid" 2> /dev/null || true
  if [[ -z "$logs" ]]; then
    echo "no app.*.log under $LOG_ROOT" >&2
    find "$LOG_ROOT" >&2 || true
    return 1
  fi
  echo "the app wrote $logs"
}

# launch <description> <command...>
launch() {
  local what="$1"
  shift
  dbus-run-session -- xvfb-run -a "$self" __inside "$@" \
    || fail "$what does not launch (see the app output in the logs)"
  pass "$what launches: running after 20 s with a log file"
}

smoke_deb() {
  local debs=("$dist"/soundspan-"$version"-linux-amd64.deb)
  [[ -f "${debs[0]}" ]] || fail "no soundspan-$version-linux-amd64.deb in $dist"
  local deb
  deb="$(cd "$(dirname "${debs[0]}")" && pwd)/$(basename "${debs[0]}")"

  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y "$deb" || fail "apt-get install of $deb failed"
  pass "apt-get install pulled the dependencies of $(basename "$deb")"

  [[ "$(dpkg-query -W -f '${Status}' soundspan 2> /dev/null)" == 'install ok installed' ]] \
    || fail "dpkg -s soundspan does not report it installed"
  dpkg -s soundspan > /dev/null
  pass "dpkg -s soundspan: installed"

  desktop-file-validate /usr/share/applications/io.soundspan.app.desktop \
    || fail "desktop-file-validate rejects the desktop file"
  pass "desktop-file-validate accepts io.soundspan.app.desktop"

  no_unresolved /usr/lib/soundspan/soundspan

  [[ -x "$(command -v soundspan)" ]] || fail "soundspan is not on PATH"
  launch "the installed .deb" soundspan

  apt-get remove -y soundspan || fail "apt-get remove soundspan failed"
  if [[ -e /usr/lib/soundspan ]] && [[ -n "$(find /usr/lib/soundspan -mindepth 1 -print -quit)" ]]; then
    find /usr/lib/soundspan >&2
    fail "apt-get remove left files under /usr/lib/soundspan"
  fi
  pass "apt-get remove leaves no files under /usr/lib/soundspan"
}

smoke_appimage() {
  local image="$dist/soundspan-$version-linux-x64.AppImage"
  [[ -f "$image" ]] || fail "no soundspan-$version-linux-x64.AppImage in $dist"
  image="$(cd "$dist" && pwd)/$(basename "$image")"
  chmod +x "$image"

  if [[ -n "$(ldconfig -p | grep -E 'libmpv\.so|libavcodec\.so' || true)" ]]; then
    fail "this container has a system libmpv or ffmpeg; the AppImage check needs one without"
  fi
  pass "the container has no system libmpv or ffmpeg"

  (cd "$work" && "$image" --appimage-extract > /dev/null) || fail "--appimage-extract failed"
  local appdir="$work/squashfs-root"
  [[ -x "$appdir/AppRun" && -x "$appdir/usr/bin/soundspan" ]] \
    || fail "the extracted AppDir has no AppRun or usr/bin/soundspan"
  pass "--appimage-extract unpacks AppRun and usr/bin/soundspan"

  no_unresolved "$appdir/usr/bin/soundspan"

  local libmpv
  libmpv="$(find "$appdir/usr/lib" -maxdepth 1 -name 'libmpv.so.*' | head -n 1)"
  [[ -n "$libmpv" ]] || fail "no libmpv.so.* in the AppDir's usr/lib"
  no_unresolved "$libmpv"

  local codec
  codec="$(ldd "$libmpv" | awk '$1 ~ /^libavcodec\.so/ { print $3 }')"
  [[ "$codec" == "$appdir"/* ]] || fail "libmpv's libavcodec resolves to '$codec', not inside the AppDir"
  pass "libmpv ($(basename "$libmpv")) and its libavcodec resolve inside the AppDir"

  launch "the AppImage" "$image" --appimage-extract-and-run
}

# The sandbox permissions doc 10 lists, one "<section> <key> <value>" line
# each, as flatpak info --show-permissions reports them: flatpak records
# --socket=fallback-x11 as both x11 and fallback-x11.
expected_flatpak_permissions() {
  cat << 'PERMISSIONS'
Context devices dri
Context shared network
Context sockets fallback-x11
Context sockets pulseaudio
Context sockets wayland
Context sockets x11
Session Bus Policy org.freedesktop.secrets talk
Session Bus Policy org.kde.StatusNotifierWatcher talk
Session Bus Policy org.mpris.MediaPlayer2.soundspan.* own
PERMISSIONS
}

# Turns flatpak info --show-permissions output into the lines above.
normalize_flatpak_permissions() {
  awk '
    /^\[.*\]$/ { section = substr($0, 2, length($0) - 2); next }
    index($0, "=") {
      key = substr($0, 1, index($0, "=") - 1)
      value = substr($0, index($0, "=") + 1)
      n = split(value, values, ";")
      for (i = 1; i <= n; i++) if (values[i] != "") print section " " key " " values[i]
    }
  ' | LC_ALL=C sort
}

smoke_flatpak() {
  local bundle="$dist/soundspan-$version-linux-x64.flatpak"
  local app='io.soundspan.app'
  [[ -f "$bundle" ]] || fail "no soundspan-$version-linux-x64.flatpak in $dist"

  flatpak install --user -y --noninteractive "$bundle" \
    || fail "flatpak install --user of $(basename "$bundle") failed"
  pass "flatpak install --user installed $(basename "$bundle") and its runtime"

  local installed
  installed="$(flatpak info "$app" | awk '$1 == "Version:" { print $2 }')"
  [[ "$installed" == "$version" ]] || fail "flatpak info reports version '$installed', not $version"
  pass "flatpak info $app reports version $version"

  local diff_out
  if ! diff_out="$(diff <(expected_flatpak_permissions | LC_ALL=C sort) \
    <(flatpak info --show-permissions "$app" | normalize_flatpak_permissions))"; then
    echo "$diff_out" >&2
    fail "the sandbox permissions differ from doc 10's finish-args (< expected, > actual)"
  fi
  pass "the sandbox permissions are exactly doc 10's finish-args"

  local sandbox_check
  # shellcheck disable=SC2016 # expanded inside the sandbox
  sandbox_check='
    set -e
    libmpv="$(find /app/lib -maxdepth 1 -name "libmpv.so.*" | sort | head -n 1)"
    [ -n "$libmpv" ] || { echo "no /app/lib/libmpv.so.*"; exit 1; }
    for f in /app/lib/soundspan/soundspan "$libmpv"; do
      out="$(ldd "$f")"
      if echo "$out" | grep "not found"; then echo "unresolved dependency of $f"; exit 1; fi
      echo "ldd resolves every dependency of $f"
    done
    soname="$(basename "$libmpv" | cut -d. -f1-3)"
    target="$(ldconfig -p | awk -v n="$soname" "\$1 == n { print \$NF; exit }")"
    case "$target" in
      /app/*) echo "$soname resolves to $target" ;;
      *) echo "$soname resolves to \"$target\", not under /app"; exit 1 ;;
    esac'
  flatpak run --command=sh "$app" -c "$sandbox_check" > "$work/sandbox.out" 2>&1 \
    || { cat "$work/sandbox.out" >&2; fail "the libraries inside the sandbox do not resolve"; }
  sed 's/^/  /' "$work/sandbox.out"
  pass "inside the sandbox the app and libmpv resolve, libmpv under /app"

  LOG_ROOT="$HOME/.var/app/$app"
  rm -rf "$LOG_ROOT"
  launch "the Flatpak" flatpak run "$app"

  flatpak uninstall --user -y --noninteractive "$app" || fail "flatpak uninstall --user $app failed"
  if flatpak info "$app" > /dev/null 2>&1; then
    fail "flatpak info still finds $app after uninstall"
  fi
  pass "flatpak uninstall --user removes $app"
}

self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
if [[ "${1:-}" == __inside ]]; then
  shift
  inside_session "$@"
  exit
fi

usage='usage: smoke.sh deb|appimage|flatpak <dist dir> <version> [log out]'
kind="${1:?$usage}"
dist="${2:?$usage}"
version="${3:?$usage}"
log_out="${4:-}"
[[ -n "$log_out" ]] && log_out="$(mkdir -p "$log_out" && cd "$log_out" && pwd)"

case "$kind" in
  deb) smoke_deb ;;
  appimage) smoke_appimage ;;
  flatpak) smoke_flatpak ;;
  *) echo "$usage" >&2; exit 64 ;;
esac
echo "smoke-linux $kind: every check passed"
