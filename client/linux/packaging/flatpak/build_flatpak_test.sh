#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
#
# Self-test of build_flatpak.sh's manifest rewriting, with stub
# flatpak-builder and flatpak commands on PATH (doc 11, client-build.yml:
# package-flatpak). Checks that the manifest it builds names the local
# tarball by path with its SHA-256 and the given version, that its file
# sources resolve, that the bundle lands under the expected name, and that
# the committed manifest is untouched. Exits 1 on the first failure.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
committed="$here/io.soundspan.app.yml"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}
pass() { echo "PASS: $*"; }

# Stubs: flatpak-builder keeps a copy of the manifest it was given and
# checks its relative file sources from the manifest's own directory;
# flatpak build-bundle writes the bundle file.
mkdir -p "$work/bin" "$work/seen"
cat > "$work/bin/flatpak-builder" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
manifest="${*: -1}"
printf '%s\n' "$@" > "$STUB_SEEN/builder-args"
cp "$manifest" "$STUB_SEEN/manifest.yml"
cd "$(dirname "$manifest")"
missing=0
while read -r rel; do
  [[ -e "$rel" ]] || { echo "unresolved file source: $rel" >&2; missing=1; }
done < <(awk '$1 == "path:" && $2 ~ /^\.\.\// { print $2 }' "$manifest")
exit "$missing"
STUB
cat > "$work/bin/flatpak" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == build-bundle ]] || { echo "unexpected: flatpak $*" >&2; exit 1; }
printf '%s\n' "$@" > "$STUB_SEEN/bundle-args"
args=("$@")
echo bundle > "${args[-2]}"
STUB
chmod +x "$work/bin/flatpak-builder" "$work/bin/flatpak"
export PATH="$work/bin:$PATH" STUB_SEEN="$work/seen"

tarball="$work/in/soundspan-9.8.7-linux-x64-unsigned.tar.gz"
mkdir -p "$work/in/bundle"
echo app > "$work/in/bundle/soundspan"
tar -czf "$tarball" -C "$work/in" bundle
sum="$(sha256sum "$tarball" | cut -d' ' -f1)"
before="$(sha256sum "$committed")"

bash "$here/build_flatpak.sh" "$tarball" 9.8.7 "$work/out" > "$work/build.log" 2>&1 \
  || { cat "$work/build.log" >&2; fail "build_flatpak.sh exited non-zero"; }
pass "build_flatpak.sh runs with the stub tools"

built="$work/seen/manifest.yml"
grep -qxF "        path: $tarball" "$built" || fail "the built manifest does not name the local tarball by path"
grep -qxF "        sha256: $sum" "$built" || fail "the built manifest does not carry the tarball's SHA-256"
pass "the soundspan source is the local tarball with its SHA-256"

if grep -q 'linux-x64-unsigned\.tar\.gz$' <(grep 'url:' "$built"); then
  fail "the built manifest still downloads the release tarball"
fi
pass "the release tarball url is gone"

grep -qxF '        SOUNDSPAN_VERSION: 9.8.7' "$built" || fail "the built manifest does not carry version 9.8.7"
pass "the version is 9.8.7"

[[ "$(grep -c 'sha256: 0\{64\}' "$built" || true)" == 0 ]] || fail "a placeholder SHA-256 is left"
diff <(grep -v -e 'path: /' -e 'sha256: ' -e 'SOUNDSPAN_VERSION: ' "$built") \
  <(grep -v -e 'url: .*linux-x64-unsigned' -e 'sha256: ' -e 'SOUNDSPAN_VERSION: ' "$committed") \
  > /dev/null || fail "the built manifest differs from the committed one beyond the tarball and version"
pass "everything else matches the committed manifest"

grep -qx -- '--force-clean' "$work/seen/builder-args" || fail "flatpak-builder runs without --force-clean"
grep -q -- '^--repo=' "$work/seen/builder-args" || fail "flatpak-builder runs without --repo"
pass "flatpak-builder gets --force-clean and --repo"

[[ -s "$work/out/soundspan-9.8.7-linux-x64.flatpak" ]] || fail "no soundspan-9.8.7-linux-x64.flatpak in the out dir"
grep -qx 'io.soundspan.app' "$work/seen/bundle-args" || fail "build-bundle does not name io.soundspan.app"
pass "flatpak build-bundle writes soundspan-9.8.7-linux-x64.flatpak"

[[ "$(sha256sum "$committed")" == "$before" ]] || fail "the committed manifest changed"
pass "the committed manifest is untouched"

if bash "$here/build_flatpak.sh" "$work/missing.tar.gz" 9.8.7 "$work/out2" > /dev/null 2>&1; then
  fail "a missing tarball does not fail"
fi
pass "a missing tarball fails"

echo "build_flatpak_test: every check passed"
