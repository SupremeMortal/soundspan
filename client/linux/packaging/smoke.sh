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
# "Launches": started with `dbus-run-session -- xvfb-run -a`, the process is
# still running after 20 seconds and a log file exists in the app's log
# directory (<XDG_DATA_HOME>/<app>/logs/app.*.log); then it is stopped. A
# second launch with a soundspan:// link, which the first instance logs,
# guarantees a log entry when start-up wrote none.
set -euo pipefail

# A nested __inside call shares the parent's work directory.
work="${SMOKE_WORK:-$(mktemp -d)}"
export SMOKE_WORK="$work"
export XDG_DATA_HOME="$work/data" XDG_CACHE_HOME="$work/cache" XDG_CONFIG_HOME="$work/config"
mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"

pass() { echo "PASS: $*"; }

save_logs() {
  [[ -n "${log_out:-}" ]] || return 0
  mkdir -p "$log_out"
  cp "$work"/*.out "$log_out/" 2> /dev/null || true
  find "$XDG_DATA_HOME" -name 'app.*.log' -exec cp {} "$log_out/" \; 2> /dev/null || true
}

fail() {
  echo "FAIL: $*" >&2
  save_logs
  exit 1
}

find_logs() { find "$XDG_DATA_HOME" -path '*/logs/app.*.log' -type f 2> /dev/null; }

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
    echo "no app.*.log under $XDG_DATA_HOME" >&2
    find "$XDG_DATA_HOME" >&2 || true
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

self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
if [[ "${1:-}" == __inside ]]; then
  shift
  inside_session "$@"
  exit
fi

usage='usage: smoke.sh deb|appimage <dist dir> <version> [log out]'
kind="${1:?$usage}"
dist="${2:?$usage}"
version="${3:?$usage}"
log_out="${4:-}"
[[ -n "$log_out" ]] && log_out="$(mkdir -p "$log_out" && cd "$log_out" && pwd)"

case "$kind" in
  deb) smoke_deb ;;
  appimage) smoke_appimage ;;
  *) echo "$usage" >&2; exit 64 ;;
esac
echo "smoke-linux $kind: every check passed"
