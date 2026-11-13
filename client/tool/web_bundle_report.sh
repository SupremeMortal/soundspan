#!/usr/bin/env bash
# Prints a Markdown report of the web build's gzip-compressed size and its
# five largest files. No threshold is enforced.
# Usage: tool/web_bundle_report.sh <build-dir>   (e.g. build/web)
set -euo pipefail

dir="${1:?usage: web_bundle_report.sh <build-dir>}"
[[ -d "$dir" ]] || { echo "web_bundle_report: not a directory: $dir" >&2; exit 2; }

total=0
rows="$(
  find "$dir" -type f -print0 | while IFS= read -r -d '' f; do
    printf '%s\t%s\t%s\n' "$(gzip -9 -c "$f" | wc -c)" "$(wc -c < "$f")" "${f#"$dir"/}"
  done | sort -nr
)"
while IFS=$'\t' read -r gz _ _; do
  total=$((total + gz))
done <<< "$rows"

echo "### Web bundle size"
echo
echo "Total, gzip-compressed: **$((total / 1024)) KiB** ($total bytes)"
echo
echo "| File | Raw (bytes) | Gzip (bytes) |"
echo "|---|---:|---:|"
head -n 5 <<< "$rows" | while IFS=$'\t' read -r gz raw name; do
  echo "| \`$name\` | $raw | $gz |"
done
