#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
#
# Smoke test of the web container image (doc 10, Web: Container).
#
# Usage: smoke.sh <image tarball>
#
# Loads the image saved by `docker save | gzip`, runs it read-only with a
# tmpfs on /tmp as UID 12345 in group 0, and checks redirects, the
# single-page fallback, the cache and security headers, the wasm content
# type, the content-hashed cache rule (through a derived image) and the
# health check. Exits non-zero with a message on the first failed check.
#
# Environment: SMOKE_PORT (default 8080) and SMOKE_HASHED_PORT (default
# 8081) are the host ports the two containers publish.

set -euo pipefail

tarball="${1:?usage: smoke.sh <image tarball>}"
port="${SMOKE_PORT:-8080}"
hashed_port="${SMOKE_HASHED_PORT:-8081}"
base="http://127.0.0.1:$port"
csp="default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; connect-src *; img-src * blob: data:; media-src *; style-src 'self' 'unsafe-inline'; worker-src 'self' blob:"
uid=12345
hashed_name=x.0123456789abcdef.js

work="$(mktemp -d)"
container=""
hashed_container=""
derived_image=""

cleanup() {
  local status=$?
  if [ "$status" -ne 0 ] && [ -n "$container" ]; then
    echo "--- container log ---" >&2
    docker logs "$container" >&2 || true
  fi
  if [ -n "$container" ]; then docker rm -f "$container" >/dev/null 2>&1 || true; fi
  if [ -n "$hashed_container" ]; then docker rm -f "$hashed_container" >/dev/null 2>&1 || true; fi
  if [ -n "$derived_image" ]; then docker rmi -f "$derived_image" >/dev/null 2>&1 || true; fi
  rm -rf "$work"
  exit "$status"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "ok: $*"
}

# fetch <name> <url> [curl args...]: writes <name>.headers, <name>.body
# and prints the status code.
fetch() {
  local name="$1" url="$2"
  shift 2
  curl -sS -o "$work/$name.body" -D "$work/$name.headers" -w '%{http_code}' "$@" "$url"
}

# header <name> <header>: the value of a response header, without CR.
header() {
  grep -i "^$2:" "$work/$1.headers" | head -n 1 | cut -d: -f2- | sed -e 's/^ *//' -e 's/\r$//'
}

expect_status() {
  [ "$2" = "$3" ] || fail "$1: status $2, expected $3"
}

expect_header() {
  local value
  value="$(header "$2" "$3")"
  [ "$value" = "$4" ] || fail "$1: $3 is '$value', expected '$4'"
}

expect_no_header() {
  if grep -qi "^$3:" "$work/$2.headers"; then
    fail "$1: unexpected $3 header"
  fi
}

# run_image <image> <host port>: starts the image the way an operator with
# a restricted runtime would, and prints the container id.
run_image() {
  docker run -d --read-only --tmpfs /tmp --user "$uid:0" -p "$2:8080" "$1"
}

wait_ready() {
  local url="$1"
  for _ in $(seq 1 60); do
    if curl -fsS -o /dev/null "$url/healthz" 2>/dev/null; then return 0; fi
    sleep 1
  done
  fail "$url/healthz did not answer within 60 s"
}

load_output="$(gunzip -c "$tarball" | docker load)"
echo "$load_output"
image="$(printf '%s\n' "$load_output" | sed -n 's/^Loaded image: //p' | head -n 1)"
[ -n "$image" ] || fail "docker load named no image"

container="$(run_image "$image" "$port")"
wait_ready "$base"
pass "/healthz answers"

status="$(fetch healthz "$base/healthz")"
expect_status "GET /healthz" "$status" 200
[ "$(cat "$work/healthz.body")" = ok ] || fail "GET /healthz: body is not 'ok'"
pass "GET /healthz is 200 ok"

status="$(fetch root "$base/")"
expect_status "GET /" "$status" 302
location="$(header root Location)"
[[ "$location" == */app/ ]] || fail "GET /: Location '$location' does not end with /app/"
pass "GET / redirects to /app/"

status="$(fetch app_no_slash "$base/app")"
expect_status "GET /app" "$status" 301
location="$(header app_no_slash Location)"
[[ "$location" == */app/ ]] || fail "GET /app: Location '$location' does not end with /app/"
pass "GET /app redirects to /app/"

status="$(fetch index "$base/app/")"
expect_status "GET /app/" "$status" 200
grep -qF '<base href="/app/">' "$work/index.body" || fail 'GET /app/: body has no <base href="/app/">'
expect_header "GET /app/" index Cache-Control "no-cache"
expect_header "GET /app/" index Content-Security-Policy "$csp"
expect_header "GET /app/" index X-Content-Type-Options "nosniff"
expect_header "GET /app/" index Referrer-Policy "no-referrer"
expect_no_header "GET /app/" index Cross-Origin-Opener-Policy
expect_no_header "GET /app/" index Cross-Origin-Embedder-Policy
pass "GET /app/ serves index.html with the cache and security headers"

for file in flutter_bootstrap.js main.dart.js; do
  status="$(fetch "$file" "$base/app/$file")"
  expect_status "GET /app/$file" "$status" 200
  expect_header "GET /app/$file" "$file" Cache-Control "no-cache"
  [ -n "$(header "$file" ETag)" ] || fail "GET /app/$file: no ETag"
  expect_header "GET /app/$file" "$file" Content-Security-Policy "$csp"
  pass "GET /app/$file is revalidated (no-cache, ETag)"
done

etag="$(header main.dart.js ETag)"
status="$(fetch revalidate "$base/app/main.dart.js" -H "If-None-Match: $etag")"
expect_status "GET /app/main.dart.js with If-None-Match" "$status" 304
pass "GET /app/main.dart.js with If-None-Match is 304"

status="$(fetch deep_link "$base/app/library/albums")"
expect_status "GET /app/library/albums" "$status" 200
cmp -s "$work/deep_link.body" "$work/index.body" || fail "GET /app/library/albums: body differs from index.html"
pass "GET /app/library/albums serves index.html"

# The CanvasKit wasm when the build has it, otherwise any wasm under
# canvaskit/ (the renderer files differ between SDK versions).
wasm="canvaskit/canvaskit.wasm"
if ! docker exec "$container" test -f "/usr/share/nginx/html/app/$wasm"; then
  wasm="$(docker exec "$container" find /usr/share/nginx/html/app/canvaskit -name '*.wasm' | head -n 1 | sed 's|^/usr/share/nginx/html/app/||')"
  [ -n "$wasm" ] || fail "the bundle has no wasm file under canvaskit/"
fi
status="$(fetch wasm "$base/app/$wasm")"
expect_status "GET /app/$wasm" "$status" 200
expect_header "GET /app/$wasm" wasm Content-Type "application/wasm"
pass "GET /app/$wasm is application/wasm"

for file in sqlite3.wasm drift_worker.js; do
  status="$(fetch "$file" "$base/app/$file")"
  expect_status "GET /app/$file" "$status" 200
  pass "GET /app/$file is 200"
done
expect_header "GET /app/sqlite3.wasm" sqlite3.wasm Content-Type "application/wasm"

# A content-hashed file name is cached for a year. Flutter's own output
# has none, so a derived image adds one.
mkdir -p "$work/derived"
echo 'console.log("hashed");' > "$work/derived/$hashed_name"
printf 'FROM %s\nCOPY %s /usr/share/nginx/html/app/%s\n' "$image" "$hashed_name" "$hashed_name" > "$work/derived/Dockerfile"
derived_image="soundspan-client-web-smoke-hashed:$$"
docker build -q -t "$derived_image" "$work/derived" >/dev/null
hashed_container="$(run_image "$derived_image" "$hashed_port")"
wait_ready "http://127.0.0.1:$hashed_port"
status="$(fetch hashed "http://127.0.0.1:$hashed_port/app/$hashed_name")"
expect_status "GET /app/$hashed_name" "$status" 200
cache_control="$(header hashed Cache-Control)"
[[ "$cache_control" == *immutable* ]] || fail "GET /app/$hashed_name: Cache-Control '$cache_control' is not immutable"
pass "GET /app/$hashed_name is immutable ($cache_control)"

running_uid="$(docker exec "$container" id -u)"
[ "$running_uid" = "$uid" ] || fail "the container runs as UID $running_uid, expected $uid"
running_gid="$(docker exec "$container" id -g)"
[ "$running_gid" = 0 ] || fail "the container runs in group $running_gid, expected 0"
pass "the container runs as UID $uid in group 0"

health=""
for _ in $(seq 1 60); do
  health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$container")"
  [ "$health" = healthy ] && break
  sleep 1
done
[ "$health" = healthy ] || fail "the container reports '$health', expected healthy"
running="$(docker inspect -f '{{.State.Running}}' "$container")"
[ "$running" = true ] || fail "the container is not running"
pass "docker inspect: running and healthy"

echo "smoke-web: every check passed"
