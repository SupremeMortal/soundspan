#!/usr/bin/env bash
# MPRIS check of the Linux desktop app (doc 10, Linux: Media controls; doc
# 11, Integration (desktop)). Runs
# integration_test/desktop/media_controls_smoke_test.dart, and while the test
# holds the media controls up, asserts from outside the app that the session
# bus owns org.mpris.MediaPlayer2.soundspan.instance<pid>; then lets the test
# finish and passes on its exit code.
#
# Needs a display and a D-Bus session bus (DBUS_SESSION_BUS_ADDRESS) shared
# with the app, for example under `dbus-run-session -- xvfb-run -a`, and
# dbus-send. Usage, from client/:
#   tool/ci/mpris_smoke_linux.sh
set -euo pipefail

prefix="org.mpris.MediaPlayer2.soundspan.instance"
hold="$(mktemp -u "${TMPDIR:-/tmp}/soundspan-mpris-hold.XXXXXX")"

flutter test integration_test/desktop/media_controls_smoke_test.dart -d linux \
  --dart-define=MEDIA_CONTROLS_HOLD_FILE="$hold" &
run=$!

bus_names() {
  dbus-send --session --print-reply --dest=org.freedesktop.DBus \
    /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2> /dev/null |
    sed -n 's/^ *string "\(.*\)"$/\1/p'
}

owner=""
# The first run builds the app, so allow 15 minutes.
for _ in $(seq 1 900); do
  if ! kill -0 "$run" 2> /dev/null; then
    break
  fi
  owner="$(bus_names | grep -F "$prefix" | head -n 1 || true)"
  if [[ -n "$owner" ]]; then
    break
  fi
  sleep 1
done

if [[ -n "$owner" ]]; then
  echo "The session bus owns $owner."
else
  echo "::error::the session bus never owned $prefix<pid>"
fi
touch "$hold"
status=0
wait "$run" || status=$?
rm -f "$hold"
if [[ -z "$owner" ]]; then
  exit 1
fi
exit "$status"
