#!/usr/bin/env bash
# Writes the contract suite's fixture music library under
# client/contract_test/.fixtures/music: one tagged FLAC sine tone per track of
# fixtures/library.json, at the frequency and length listed there, each with
# the same embedded 600x600 PNG front cover so albums have cover art. Also
# writes the fixture podcast under client/contract_test/.fixtures/podcast:
# fixtures/podcast/feed.xml and one MP3 sine tone per episode it lists, served
# by the podcast-feed service of compose.yaml. The output depends only on
# library.json, feed.xml and the ffmpeg build, so every run writes the same
# files. Needs ffmpeg and jq.
set -euo pipefail
cd "$(dirname "$0")/.."

library=fixtures/library.json
out=.fixtures/music

command -v ffmpeg >/dev/null || { echo "generate.sh: ffmpeg is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "generate.sh: jq is required" >&2; exit 1; }

rm -rf "$out"
mkdir -p "$out"

cover="$out/.cover.png"
ffmpeg -nostdin -hide_banner -loglevel error -y \
  -f lavfi -i "color=c=0x3366aa:s=600x600" -frames:v 1 \
  -c:v png -fflags +bitexact -flags +bitexact "$cover"

# One tab-separated line per track; lyrics are base64 so newlines survive.
jq -r '
  .artists[] as $artist
  | $artist.albums[] as $album
  | ($album.tracks | map(.disc) | max) as $discs
  | $album.tracks[]
  | [
      $artist.name, $album.title, ($album.year | tostring),
      (.disc | tostring), ($discs | tostring),
      (.track | tostring),
      ([$album.tracks[] as $t | select($t.disc == .disc)] | length | tostring),
      .title, (.frequencyHz | tostring), (.seconds | tostring),
      ((.lyrics // "") | @base64)
    ]
  | @tsv
' "$library" |
  while IFS=$'\t' read -r artist album year disc discs track tracks title freq seconds lyrics64; do
    dir="$out/$artist/$album"
    mkdir -p "$dir"
    file="$dir/$(printf '%d-%02d %s.flac' "$disc" "$track" "$title")"
    lyrics_args=()
    if [[ -n "$lyrics64" ]]; then
      lyrics_args=(-metadata "LYRICS=$(printf '%s' "$lyrics64" | base64 -d)")
    fi
    ffmpeg -nostdin -hide_banner -loglevel error -y \
      -f lavfi -i "sine=frequency=$freq:duration=$seconds:sample_rate=44100" \
      -i "$cover" -map 0:a -map 1:v -c:v copy -disposition:v attached_pic \
      -metadata:s:v "comment=Cover (front)" \
      -ac 1 -c:a flac -fflags +bitexact -flags:a +bitexact \
      -metadata "title=$title" \
      -metadata "artist=$artist" \
      -metadata "album_artist=$artist" \
      -metadata "album=$album" \
      -metadata "date=$year" \
      -metadata "track=$track/$tracks" \
      -metadata "disc=$disc/$discs" \
      "${lyrics_args[@]}" \
      "$file"
  done

rm "$cover"

count="$(find "$out" -name '*.flac' | wc -l)"
expected="$(jq '[.artists[].albums[].tracks[]] | length' "$library")"
if [[ "$count" -ne "$expected" ]]; then
  echo "generate.sh: wrote $count files, library.json lists $expected" >&2
  exit 1
fi
echo "generate.sh: wrote $count tracks to $out"

podcast=.fixtures/podcast
rm -rf "$podcast"
mkdir -p "$podcast"
cp fixtures/podcast/feed.xml "$podcast/feed.xml"
# The episode files feed.xml names, with the lengths of its itunes:duration.
for episode in "1 6 330" "2 8 550"; do
  read -r number seconds freq <<<"$episode"
  ffmpeg -nostdin -hide_banner -loglevel error -y \
    -f lavfi -i "sine=frequency=$freq:duration=$seconds:sample_rate=44100" \
    -ac 1 -c:a libmp3lame -b:a 64k -fflags +bitexact -flags:a +bitexact \
    "$podcast/episode-$number.mp3"
done
echo "generate.sh: wrote the fixture podcast to $podcast"
