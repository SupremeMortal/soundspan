#!/usr/bin/env bash
# Single-instance check of the Linux release build (doc 10, Linux: Single
# instance). Starts the app, starts it again with a soundspan:// link, and
# asserts that the second process exits 0 within 10 s, that one app process
# and one top-level window remain, and that the first instance logged the
# second launch.
#
# Needs a display (Xvfb with a window manager), a D-Bus session bus and
# xdotool. Usage, from client/:
#   tool/ci/single_instance_linux.sh [bundle-dir]
# (default build/linux/x64/release/bundle).
set -euo pipefail

bundle="${1:-build/linux/x64/release/bundle}"
exe="$(cd "$bundle" && pwd)/soundspan"
[[ -x "$exe" ]] || { echo "single_instance: executable not found: $exe" >&2; exit 2; }
link='soundspan://link?code=TEST22&server=https%3A%2F%2Fexample.invalid'

work="$(mktemp -d)"
export XDG_DATA_HOME="$work/data" XDG_CACHE_HOME="$work/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CACHE_HOME"

first_pid=""
cleanup() {
  [[ -n "$first_pid" ]] && kill "$first_pid" 2> /dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

fail() {
  echo "single_instance: $*" >&2
  echo "--- first instance output" >&2
  cat "$work/first.out" >&2 || true
  find "$XDG_DATA_HOME" -name 'app.*.log' -exec sh -c 'echo "--- $1"; cat "$1"' _ {} \; >&2 || true
  exit 1
}

windows() { xdotool search --onlyvisible --class 'soundspan' 2> /dev/null || true; }

"$exe" > "$work/first.out" 2>&1 &
first_pid=$!

for _ in $(seq 1 60); do
  [[ -n "$(windows)" ]] && break
  kill -0 "$first_pid" 2> /dev/null || fail "the first instance exited"
  sleep 1
done
[[ -n "$(windows)" ]] || fail "the first instance's window did not appear within 60 s"

set +e
timeout 10 "$exe" "$link" > "$work/second.out" 2>&1
second_status=$?
set -e
[[ $second_status -eq 0 ]] || fail "the second instance exited with $second_status (124 is the 10 s timeout)"

processes="$(pgrep -fc "^$exe" || true)"
[[ "$processes" == "1" ]] || fail "expected one app process, found $processes"
kill -0 "$first_pid" 2> /dev/null || fail "the first instance is gone"

window_count="$(windows | wc -l)"
[[ "$window_count" == "1" ]] || fail "expected one top-level window, found $window_count"

for _ in $(seq 1 10); do
  if grep -rqs 'Second instance launched' "$XDG_DATA_HOME" --include='app.*.log'; then
    echo "single_instance: second launch forwarded to the first instance"
    exit 0
  fi
  sleep 1
done
fail "the first instance's log has no second-launch entry"
