#!/usr/bin/env bash
# Smoke test of the macOS disk image (doc 11, client-build.yml: smoke-macos)
# on a clean macOS runner:
#   1. verifies and mounts the image, which holds soundspan.app and an
#      /Applications symlink;
#   2. copies the app out and checks its ad-hoc signature, hardened runtime
#      and both architectures;
#   3. checks the built Info.plist and the signed entitlements (the ad-hoc
#      ones, without keychain-access-groups) with
#      tool/check_platform_config.dart;
#   4. launches the executable, expects it alive after 20 s, expects a log
#      file in its container (when start-up wrote none, within 15 s of
#      opening soundspan://smoke-log, an unknown link the app ignores and
#      logs), opens soundspan://album/smoke, expects it alive 5 s later, and
#      quits it;
#   5. detaches the image.
# On failure it copies to the diagnostics directory the app logs, the last
# two minutes of the unified log for the process and for the services that
# can kill it before it writes anything (kernel, amfid, taskgated,
# syspolicyd), the crash reports of the app, and its signature and
# entitlements.
#
# Usage, from client/:
#   macos/packaging/smoke.sh <path to .dmg> [diagnostics dir]
# (default diagnostics dir: $RUNNER_TEMP/smoke-macos, else a temporary one).
set -euo pipefail

fail() { echo "smoke: $*" >&2; exit 1; }

dmg="${1:-}"
[[ -n "$dmg" ]] || { echo "usage: $0 <path to .dmg> [diagnostics dir]" >&2; exit 64; }
[[ -f "$dmg" ]] || fail "disk image not found: $dmg"
diagnostics="${2:-${RUNNER_TEMP:-$(mktemp -d)}/smoke-macos}"
mkdir -p "$diagnostics"

bundle_id='io.soundspan.app'
container="$HOME/Library/Containers/$bundle_id/Data/Library/Application Support"
work="$(mktemp -d)"
mount_point="$work/volume"
app_pid=""
mounted=false

cleanup() {
  local status=$?
  if [[ -n "$app_pid" ]] && kill -0 "$app_pid" 2> /dev/null; then
    kill "$app_pid" 2> /dev/null || true
  fi
  if [[ $status -ne 0 ]]; then
    echo "smoke: failed; diagnostics in $diagnostics" >&2
    if [[ -d "$container" ]]; then
      find "$container" -path '*/logs/*.log' -exec cp {} "$diagnostics/" \; || true
    fi
    log show --last 2m --predicate 'process == "soundspan"' \
      > "$diagnostics/unified-log.txt" 2>&1 || true
    log show --last 2m --info --debug --predicate \
      'process IN {"kernel", "amfid", "taskgated", "taskgated-helper", "syspolicyd"} OR sender IN {"AppleMobileFileIntegrity", "AppleSystemPolicy", "Sandbox"}' \
      > "$diagnostics/unified-log-system.txt" 2>&1 || true
    find "$HOME/Library/Logs/DiagnosticReports" /Library/Logs/DiagnosticReports \
      -maxdepth 1 \( -name 'soundspan*.ips' -o -name 'soundspan*.crash' \) \
      -exec cp {} "$diagnostics/" \; 2> /dev/null || true
    if [[ -d "$work/soundspan.app" ]]; then
      codesign -dvvv --entitlements - --xml "$work/soundspan.app" \
        > "$diagnostics/signature.txt" 2>&1 || true
    fi
  fi
  if $mounted; then hdiutil detach "$mount_point" -quiet || hdiutil detach "$mount_point" -force -quiet || true; fi
  rm -rf "$work"
  exit "$status"
}
trap cleanup EXIT

# 1. The image.
echo "smoke: verifying $dmg"
hdiutil verify "$dmg"
mkdir -p "$mount_point"
hdiutil attach "$dmg" -nobrowse -readonly -noautoopen -mountpoint "$mount_point" > /dev/null
mounted=true
[[ -d "$mount_point/soundspan.app" ]] || fail "the volume has no soundspan.app"
[[ -L "$mount_point/Applications" ]] || fail "the volume has no Applications symlink"
[[ "$(readlink "$mount_point/Applications")" == /Applications ]] ||
  fail "the Applications symlink does not point to /Applications"

# 2. The signature and architectures of a copy outside the image.
app="$work/soundspan.app"
ditto "$mount_point/soundspan.app" "$app"
exe="$app/Contents/MacOS/soundspan"
codesign --verify --deep --strict --verbose=2 "$app"
signature="$(codesign -dv "$app" 2>&1)"
echo "$signature"
grep -q '^Signature=adhoc$' <<< "$signature" || fail "the app is not ad-hoc signed"
grep -Eq '^CodeDirectory .*flags=.*runtime' <<< "$signature" ||
  fail "the app is not signed with the hardened runtime"
archs="$(lipo -archs "$exe")"
echo "smoke: architectures: $archs"
[[ " $archs " == *" arm64 "* && " $archs " == *" x86_64 "* ]] ||
  fail "the executable is not universal"

# 3. Info.plist and the entitlements the app is signed with.
plutil -convert xml1 -o "$work/Info.plist" "$app/Contents/Info.plist"
codesign -d --entitlements - --xml "$app" > "$work/signed.entitlements"
dart run tool/check_platform_config.dart \
  --macos-plist="$work/Info.plist" \
  --macos-entitlements="$work/signed.entitlements" \
  --macos-adhoc-entitlements="$work/signed.entitlements"

# 4. Launch, deep link, quit.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app" || true
"$exe" > "$diagnostics/stdout.txt" 2>&1 &
app_pid=$!
echo "smoke: launched pid $app_pid"
sleep 20
kill -0 "$app_pid" 2> /dev/null || fail "the app exited within 20 s"
find_logs() { find "$container" -path '*/logs/*.log' 2> /dev/null || true; }
logs="$(find_logs)"
if [[ -z "$logs" ]]; then
  # A release build logs nothing at start-up; the router logs the link with
  # an unknown host it ignores, which makes the first entry.
  open -a "$app" 'soundspan://smoke-log'
  for _ in $(seq 1 15); do
    logs="$(find_logs)"
    [[ -n "$logs" ]] && break
    sleep 1
  done
fi
[[ -n "$logs" ]] || fail "no log file under $container"
echo "smoke: log files: $logs"
open -a "$app" 'soundspan://album/smoke'
sleep 5
kill -0 "$app_pid" 2> /dev/null || fail "the app exited after soundspan://album/smoke"
kill -TERM "$app_pid"
for _ in $(seq 1 20); do
  kill -0 "$app_pid" 2> /dev/null || break
  sleep 0.5
done
if kill -0 "$app_pid" 2> /dev/null; then
  kill -KILL "$app_pid" 2> /dev/null || true
fi
app_pid=""

# 5. Detach.
hdiutil detach "$mount_point" -quiet
mounted=false
echo "smoke: ok"
