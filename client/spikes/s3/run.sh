#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
#
# Spike S3 driver: installs the harness APK on the running emulator, drives it
# with adb and prints one result line per question (S3-Q1, S3-Q2, S3-Q3) from
# the SPIKE_S3 logcat lines of the app. Exits non-zero only when it could not
# take a measurement at all.
#
# Usage: run.sh [apk]   (environment: S3_Q1_SECONDS, default 600; S3_API)
set -u

PKG=dev.soundspan.spike.spike_s3
APK=${1:-build/app/outputs/flutter-apk/app-debug.apk}
Q1_SECONDS=${S3_Q1_SECONDS:-600}
API=${S3_API:-$(adb shell getprop ro.build.version.sdk | tr -d '\r')}
SPIKE_LOG=spike-lines.txt
FULL_LOG=logcat-full.txt

say() { echo "[$(date -u +%H:%M:%S)] $*"; }
sh() { adb shell "$@" | tr -d '\r'; }

# Line count of the SPIKE_S3 capture; analyses read the lines after a mark.
mark() { wc -l < "$SPIKE_LOG" | tr -d ' '; }
since() { tail -n +"$(($1 + 1))" "$SPIKE_LOG"; }
field() { sed -n "s/.*[[:space:]]$1=\([^[:space:]]*\).*/\1/p"; }
app_pid() { sh pidof "$PKG"; }

# Tick lines after mark $1, optionally of pid $2: "pid wallMs playing playedMs".
ticks() {
  since "$1" | grep 'event=tick' | while read -r line; do
    p=$(echo "$line" | field pid)
    [ -n "${2:-}" ] && [ "$p" != "$2" ] && continue
    echo "$p $(echo "$line" | field wallMs) $(echo "$line" | field playing) $(echo "$line" | field playedMs)"
  done
}

# Largest (wall delta - played delta) between consecutive ticks of one pid.
max_stall() { awk 'NR>1 { s = ($2 - w) - ($4 - p); if (s > m) m = s } { w = $2; p = $4 } END { print m + 0 }'; }

is_foreground() { sh dumpsys activity services "$PKG" | grep -q 'isForeground=true'; }
not_foreground() { ! is_foreground; }
no_app() { [ -z "$(app_pid)" ]; }
some_app() { [ -n "$(app_pid)" ]; }

wait_for() { # seconds, then a command; polls once per second
  local n=$1; shift
  for _ in $(seq "$n"); do "$@" && return 0; sleep 1; done
  return 1
}

playing_now() { # mark, pid: the last tick of pid says playing=true
  ticks "$1" "$2" | tail -1 | grep -q ' true '
}

dispatch() { # play|pause, through the media session service then a key event
  local key=MEDIA_PLAY
  [ "$1" = pause ] && key=MEDIA_PAUSE
  sh cmd media_session dispatch "$1" >/dev/null 2>&1 || sh input keyevent "KEYCODE_$key"
}

wake() {
  sh input keyevent KEYCODE_WAKEUP
  sh wm dismiss-keyguard >/dev/null 2>&1 || true
}

# --- set-up ----------------------------------------------------------------
adb root >/dev/null 2>&1 && adb wait-for-device
adb logcat -c
adb logcat -G 16M >/dev/null 2>&1 || true
adb logcat -v threadtime > "$FULL_LOG" 2>&1 &
FULL_PID=$!
adb logcat -v tag 'SPIKE_S3:I' 'flutter:I' '*:S' 2>/dev/null | grep --line-buffered 'SPIKE_S3' > "$SPIKE_LOG" &
LINES_PID=$!
trap 'kill $FULL_PID $LINES_PID 2>/dev/null' EXIT

say "Installing $APK on API $API"
adb install -r -g "$APK" || { echo "S3: could not install the APK"; exit 2; }
sh pm grant "$PKG" android.permission.POST_NOTIFICATIONS >/dev/null 2>&1 || true
sh dumpsys deviceidle whitelist -"$PKG" >/dev/null 2>&1 || true
wake

m=$(mark)
sh am start -W -n "$PKG/.MainActivity" >/dev/null
engine_logged() { since "$1" | grep -q 'event=engine'; }
if ! wait_for 60 engine_logged "$m"; then
  echo "S3: the app never logged its engine start"; exit 2
fi
pid=$(app_pid)
say "App started, pid $pid"

# Start playback: media session dispatch, then a key event, then a tap.
started=""
for how in dispatch keyevent tap; do
  case $how in
    dispatch) sh cmd media_session dispatch play >/dev/null 2>&1 ;;
    keyevent) sh input keyevent KEYCODE_MEDIA_PLAY ;;
    tap) sh input tap 300 600 ;;
  esac
  if wait_for 10 playing_now "$m" "$pid"; then started=$how; break; fi
done
if [ -z "$started" ]; then echo "S3: playback never started"; exit 2; fi
say "Playback started by $started"
sleep 5

# --- Q1: screen off, unplugged, forced idle --------------------------------
say "Q1: screen off, battery unplugged, deep idle for ${Q1_SECONDS}s"
m=$(mark)
sh input keyevent KEYCODE_SLEEP
sh dumpsys battery unplug
sh dumpsys deviceidle force-idle
sh dumpsys deviceidle get deep | sed 's/^/  deep idle state: /'
sleep "$Q1_SECONDS"
sh dumpsys deviceidle get deep | sed 's/^/  deep idle state: /'
pid_after=$(app_pid)
fg=false; is_foreground && fg=true
ticks "$m" "$pid" > q1.ticks
first=$(head -1 q1.ticks); last=$(tail -1 q1.ticks)
wall=0; played=0
if [ -n "$first" ]; then
  wall=$(( $(echo "$last" | cut -d' ' -f2) - $(echo "$first" | cut -d' ' -f2) ))
  played=$(( $(echo "$last" | cut -d' ' -f4) - $(echo "$first" | cut -d' ' -f4) ))
fi
stall=$(max_stall < q1.ticks)
target=$(( Q1_SECONDS * 1000 ))
q1=no
if [ -n "$first" ] && [ "$pid_after" = "$pid" ] && [ "$fg" = true ] && [ "$stall" -le 2000 ] \
  && [ $(( played - target )) -le 5000 ] && [ $(( target - played )) -le 5000 ]; then q1=yes; fi
if [ ! -s q1.ticks ]; then q1=unanswerable; fi
Q1_LINE="S3-Q1 api=$API pidBefore=$pid pidAfter=$pid_after foregroundService=$fg ticks=$(wc -l < q1.ticks | tr -d ' ') wallMs=$wall advancedMs=$played expectedMs=$target maxStallMs=$stall answer=$q1"
echo "$Q1_LINE"
sh dumpsys deviceidle unforce >/dev/null
sh dumpsys battery reset >/dev/null
wake
sleep 3

# --- Q3: task swiped away while playing -------------------------------------
say "Q3: remove the task while playing"
pid=$(app_pid)
if ! playing_now "$(( $(mark) > 5 ? $(mark) - 5 : 0 ))" "$pid"; then dispatch play; sleep 3; fi
sh am start -W -n "$PKG/.MainActivity" >/dev/null
sleep 2
task_present() { sh dumpsys activity recents | grep -q "A=[0-9]*:$PKG"; }
task_id=$(sh am stack list 2>/dev/null | sed -n "s/.*taskId=\([0-9]*\): $PKG.*/\1/p" | head -1)
[ -z "$task_id" ] && task_id=$(sh dumpsys activity recents | sed -n "s/.*Task{[0-9a-f]* #\([0-9]*\) .*A=[0-9]*:$PKG.*/\1/p" | head -1)
say "  task id: ${task_id:-unknown}"
removed_by=""
if [ -n "$task_id" ]; then
  sh am stack remove "$task_id" >/dev/null 2>&1
  sleep 2
  task_present || removed_by="am stack remove"
fi
if [ -z "$removed_by" ]; then
  sh input keyevent KEYCODE_APP_SWITCH; sleep 2
  sh input swipe 540 1400 540 200 300; sleep 2
  task_present || removed_by="recents swipe"
fi
m=$(mark)
sleep 60
pid_after=$(app_pid)
ticks "$m" "$pid" > q3.ticks
played=0
if [ -s q3.ticks ]; then
  played=$(( $(tail -1 q3.ticks | cut -d' ' -f4) - $(head -1 q3.ticks | cut -d' ' -f4) ))
fi
q3=no
if [ -z "$removed_by" ]; then q3=unanswerable
elif [ "$pid_after" = "$pid" ] && [ "$played" -ge 55000 ]; then q3=yes; fi
Q3_LINE="S3-Q3 api=$API taskRemovedBy=${removed_by:-none} pidBefore=$pid pidAfter=${pid_after:-none} advancedMs=$played windowMs=60000 answer=$q3"
echo "$Q3_LINE"

# --- Q2: paused, killed, restarted by a media button (three times) ----------
say "Q2: pause, kill the process, press play"
passes=0; delivered=0; details=""
for attempt in 1 2 3; do
  pid=$(app_pid)
  if [ -z "$pid" ]; then
    wake; sh am start -W -n "$PKG/.MainActivity" >/dev/null
    wait_for 30 some_app; pid=$(app_pid)
    dispatch play; sleep 3
  fi
  dispatch pause
  m=$(mark)
  wait_for 10 not_foreground
  fg=false; is_foreground && fg=true
  sh kill -9 "$pid"
  wait_for 10 no_app
  self_restart=$(app_pid)
  m=$(mark)
  result=fail; via=none
  for how in dispatch keyevent; do
    if [ $how = dispatch ]; then sh cmd media_session dispatch play >/dev/null 2>&1
    else sh input keyevent KEYCODE_MEDIA_PLAY; fi
    ok=""
    for _ in $(seq 15); do
      sleep 1
      new_pid=$(since "$m" | grep 'event=engine' | head -1 | field pid)
      [ -z "$new_pid" ] && continue
      if since "$m" | grep "pid=$new_pid " | grep -q 'event=handler-play' \
        && [ "$(ticks "$m" "$new_pid" | awk '$3 == "true" { print $4 }' | sort -n | uniq | wc -l)" -ge 2 ]; then
        ok=1; break
      fi
    done
    if [ -n "$new_pid" ]; then delivered=$((delivered + 1)); via=$how; fi
    if [ -n "$ok" ]; then result=pass; break; fi
    [ -n "$new_pid" ] && break
  done
  entry=$(since "$m" | grep "pid=${new_pid:-x} " | grep 'event=tick' | field entry | grep -v pending | head -1)
  [ "$result" = pass ] && passes=$((passes + 1))
  details="$details run$attempt=$result(via=$via,oldPid=$pid,newPid=${new_pid:-none},entry=${entry:-none},foregroundAfterPause=$fg,selfRestart=${self_restart:-none})"
  say "  attempt $attempt: $result"
  sh input keyevent KEYCODE_MEDIA_PAUSE
  sleep 3
done
q2=no
[ "$passes" = 3 ] && q2=yes
[ "$delivered" = 0 ] && q2=unanswerable
Q2_LINE="S3-Q2 api=$API passes=$passes/3 delivered=$delivered/3$details answer=$q2"
echo "$Q2_LINE"

{
  echo "$Q1_LINE"
  echo "$Q2_LINE"
  echo "$Q3_LINE"
} > results.txt
say "Done"
