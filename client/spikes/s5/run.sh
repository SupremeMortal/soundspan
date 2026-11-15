#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
#
# Spike S5 driver, question 4: starts the slow server on this host (the
# emulator reaches it at 10.0.2.2:8765), installs the harness APK and, three
# times: clears the app, launches it (it enqueues task s5-q4), waits for 20 %
# progress, kills the process with kill -9, relaunches it (it calls
# FileDownloader().start() and resumeFromBackground()) and waits for the
# task to complete under its original id with the reference SHA-256. Prints
# one S5-Q4 result line. Exits non-zero only when it could not take a
# measurement at all.
#
# Usage: run.sh [apk]   (environment: S5_API)
set -u

PKG=dev.soundspan.spike.spike_s5
APK=${1:-build/app/outputs/flutter-apk/app-debug.apk}
API=${S5_API:-$(adb shell getprop ro.build.version.sdk | tr -d '\r')}
SPIKE_LOG=spike-lines.txt
FULL_LOG=logcat-full.txt

say() { echo "[$(date -u +%H:%M:%S)] $*"; }
sh() { adb shell "$@" | tr -d '\r'; }
mark() { wc -l < "$SPIKE_LOG" | tr -d ' '; }
since() { tail -n +"$(($1 + 1))" "$SPIKE_LOG"; }
field() { sed -n "s/.*[[:space:]]$1=\([^[:space:]]*\).*/\1/p"; }
app_pid() { sh pidof "$PKG"; }
no_app() { [ -z "$(app_pid)" ]; }

wait_for() { # seconds, then a command; polls once per second
  local n=$1; shift
  for _ in $(seq "$n"); do "$@" && return 0; sleep 1; done
  return 1
}

logged() { # mark, pattern
  since "$1" | grep -q -- "$2"
}

progress_at_least() { # mark, pid, minimum percent
  since "$1" | grep "pid=$2 " | grep 'event=progress taskId=s5-q4' | field progress \
    | awk -v min="$3" '$1 * 100 >= min { found = 1 } END { exit !found }'
}

# --- set-up ----------------------------------------------------------------
dart run tool/slow_server.dart 8765 > slow-server.log 2>&1 &
SERVER_PID=$!
adb root >/dev/null 2>&1 && adb wait-for-device
adb logcat -c
adb logcat -G 16M >/dev/null 2>&1 || true
adb logcat -v threadtime > "$FULL_LOG" 2>&1 &
FULL_PID=$!
adb logcat -v tag 'SPIKE_S5:I' '*:S' 2>/dev/null | grep --line-buffered 'SPIKE_S5' > "$SPIKE_LOG" &
LINES_PID=$!
trap 'kill $FULL_PID $LINES_PID $SERVER_PID 2>/dev/null' EXIT
wait_for 120 grep -q 'S5-SLOW-SERVER listening' slow-server.log \
  || { echo "S5: the slow server did not start"; cat slow-server.log; exit 2; }

say "Installing $APK on API $API"
adb install -r -g "$APK" || { echo "S5: could not install the APK"; exit 2; }

passes=0; measured=0; details=""
for attempt in 1 2 3; do
  sh am force-stop "$PKG"
  sh pm clear "$PKG" >/dev/null
  sh input keyevent KEYCODE_WAKEUP
  m=$(mark)
  sh am start -W -n "$PKG/.MainActivity" >/dev/null
  result=fail; old=""; new=""; reported=none; sha=none; ref=none; killedAt=none
  if wait_for 60 logged "$m" 'event=enqueued taskId=s5-q4 ok=true'; then
    old=$(since "$m" | grep 'event=enqueued' | head -1 | field pid)
    if wait_for 90 progress_at_least "$m" "$old" 20; then
      killedAt=$(since "$m" | grep "pid=$old " | grep 'event=progress' | tail -1 | field progress)
      sh kill -9 "$old"
      wait_for 15 no_app
      say "  attempt $attempt: killed pid $old at progress $killedAt"
      sleep 3
      m=$(mark)
      sh am start -W -n "$PKG/.MainActivity" >/dev/null
      if wait_for 30 logged "$m" 'event=started'; then
        measured=$((measured + 1))
        new=$(since "$m" | grep 'event=started' | head -1 | field pid)
        if wait_for 240 logged "$m" "pid=$new .*event=complete taskId=s5-q4"; then
          line=$(since "$m" | grep "pid=$new " | grep 'event=complete' | head -1)
          reported=$(echo "$line" | field taskId)
          sha=$(echo "$line" | field sha256)
          ref=$(echo "$line" | field referenceSha256)
          [ "$reported" = s5-q4 ] && [ "$sha" = "$ref" ] && result=pass
        else
          last=$(since "$m" | grep "pid=$new " | grep 'event=status' | tail -1 | field status)
          result="fail-lastStatus=${last:-none}"
        fi
      fi
    fi
  fi
  [ "$result" = pass ] && passes=$((passes + 1))
  details="$details run$attempt=$result(oldPid=${old:-none},newPid=${new:-none},killedAtProgress=$killedAt,taskId=$reported,sha256=$sha,referenceSha256=$ref)"
  say "  attempt $attempt: $result"
done

q4=no
[ "$passes" = 3 ] && q4=yes
[ "$measured" = 0 ] && q4=unanswerable
Q4_LINE="S5-Q4 api=$API passes=$passes/3 measured=$measured/3$details answer=$q4"
echo "$Q4_LINE"
echo "$Q4_LINE" > results.txt
say "Done"
