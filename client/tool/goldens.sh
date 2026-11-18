#!/usr/bin/env bash
# Regenerates the golden images: flutter test --tags golden --update-goldens.
#
# Goldens are rendered on Linux with the Flutter version pinned in .fvmrc.
# On such a host the command runs directly; anywhere else it runs in a Linux
# container with that Flutter version, through Docker or Podman. Extra
# arguments are passed to `flutter test`, for example a test file.
#
# Usage, from client/: tool/goldens.sh [flutter test arguments...]
set -euo pipefail
cd "$(dirname "$0")/.."

pinned="$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc)"
if [[ -z "$pinned" ]]; then
  echo "goldens.sh: cannot read the Flutter version from .fvmrc" >&2
  exit 1
fi

local_version=""
if command -v flutter >/dev/null 2>&1; then
  local_version="$(flutter --version 2>/dev/null | sed -n 's/^Flutter \([^ ]*\).*/\1/p' | head -n 1)"
fi

if [[ "$(uname -s)" == "Linux" && "$local_version" == "$pinned" ]]; then
  exec flutter test --tags golden --update-goldens "$@"
fi

engine=""
for candidate in docker podman; do
  if command -v "$candidate" >/dev/null 2>&1; then
    engine="$candidate"
    break
  fi
done
if [[ -z "$engine" ]]; then
  echo "goldens.sh: goldens are rendered on Linux with Flutter $pinned." >&2
  echo "This host has Flutter '${local_version:-none}' on $(uname -s), and neither" >&2
  echo "Docker nor Podman is installed to run it in a container. Install one" >&2
  echo "of them, or commit the client-golden-rendered artifact of a failing" >&2
  echo "client-golden CI run instead." >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
image="ghcr.io/cirruslabs/flutter:${pinned}"
echo "goldens.sh: running in $image through $engine" >&2

# The Linux build packages of doc 01 are needed by the native-asset build
# hooks that `flutter test` runs. Files written in the container are handed
# back to the calling user.
"$engine" run --rm \
  -v "$repo_root:/work" \
  -w /work/client \
  -e HOST_UID="$(id -u)" \
  -e HOST_GID="$(id -g)" \
  "$image" \
  bash -c '
    set -euo pipefail
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends \
      clang cmake ninja-build pkg-config libgtk-3-dev libx11-dev \
      libxi-dev libmpv-dev libsecret-1-dev libjsoncpp-dev >/dev/null
    git config --global --add safe.directory "*"
    status=0
    flutter pub get && flutter test --tags golden --update-goldens "$@" || status=$?
    chown -R "$HOST_UID:$HOST_GID" /work/client
    exit "$status"
  ' goldens "$@"
