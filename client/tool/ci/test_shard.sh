#!/usr/bin/env bash
# Prints the test files of one shard of the client's unit and widget tests,
# one per line. Files are split whole, so each shard compiles only its own
# files: taken largest first, each goes to the shard with the fewest bytes
# so far. The split depends only on the files, so it is the same on every run.
#
# Usage, from client/:
#   tool/ci/test_shard.sh <shard-count> <shard-index>
set -euo pipefail

count="${1:?usage: test_shard.sh <shard-count> <shard-index>}"
index="${2:?usage: test_shard.sh <shard-count> <shard-index>}"
if ! [[ "$count" =~ ^[1-9][0-9]*$ && "$index" =~ ^[0-9]+$ ]] || ((index >= count)); then
  echo "test_shard: need 0 <= index < count, got index $index of $count" >&2
  exit 2
fi

find test -name '*_test.dart' -type f -printf '%s %p\n' |
  LC_ALL=C sort -k1,1nr -k2,2 |
  awk -v count="$count" -v index_="$index" '
    {
      best = 0
      for (i = 1; i < count; i++) if (load[i] < load[best]) best = i
      load[best] += $1
      if (best == index_) print $2
    }
  '
