#!/usr/bin/env bash
# Fails when the built Linux executable or any bundled shared library has a
# dependency the dynamic loader cannot resolve.
# Usage: tool/check_ldd.sh <bundle-dir>   (e.g. build/linux/x64/release/bundle)
set -euo pipefail

bundle="${1:?usage: check_ldd.sh <bundle-dir>}"
exe="$bundle/soundspan"
[[ -x "$exe" ]] || { echo "check_ldd: executable not found: $exe" >&2; exit 2; }

status=0
check() {
  local out
  out="$(LD_LIBRARY_PATH="$bundle/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ldd "$1" 2>&1)" || true
  if grep -q 'not found' <<< "$out"; then
    echo "check_ldd: unresolved dependency in $1:" >&2
    grep 'not found' <<< "$out" >&2
    status=1
  fi
}

check "$exe"
shopt -s nullglob
for lib in "$bundle"/lib/*.so*; do
  check "$lib"
done

if [[ $status -eq 0 ]]; then
  echo "check_ldd: every dependency of $exe and $bundle/lib/*.so resolves"
fi
exit $status
