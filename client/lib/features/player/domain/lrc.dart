// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// LRC parsing for synced lyrics (doc 09, Now Playing, Queue, Lyrics).
library;

/// One timed line of synced lyrics.
final class LyricLine {
  /// The line [text], sung from [time].
  const new({required this.time, required this.text});

  /// When the line starts.
  final Duration time;

  /// The words; empty for an instrumental gap.
  final String text;

  @override
  // Every field is final; `meta` is not imported so the domain stays pure.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is LyricLine && other.time == time && other.text == text;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => Object.hash(time, text);

  @override
  String toString() => 'LyricLine($time, $text)';
}

/// A leading run of `[mm:ss]`, `[mm:ss.x]` … `[mm:ss.xxx]` stamps (`:` is
/// accepted as the fraction separator too).
final RegExp _stamps = RegExp(r'^(?:\[\d+:\d{2}(?:[.:]\d{1,3})?\])+');

final RegExp _stamp = RegExp(r'\[(\d+):(\d{2})(?:[.:](\d{1,3}))?\]');

/// The timed lines of the LRC text [source], sorted by time.
///
/// A line with several stamps gives one [LyricLine] per stamp; a stamp
/// with no text is kept as an instrumental gap. Lines without a valid
/// stamp, identifier tags (`[ar:…]`, `[offset:…]` and the like) included,
/// are dropped; `offset` is not applied. CRLF line ends and a leading BOM
/// are tolerated. It never throws.
List<LyricLine> parseLrc(String source) {
  final text = source.startsWith('﻿') ? source.substring(1) : source;
  final lines = <LyricLine>[];
  for (final raw in text.split('\n')) {
    final line = raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
    final stamps = _stamps.firstMatch(line);
    if (stamps == null) continue;
    final words = line.substring(stamps.end).trim();
    for (final stamp in _stamp.allMatches(stamps[0]!)) {
      final seconds = int.parse(stamp[2]!);
      if (seconds > 59) continue;
      final fraction = stamp[3];
      final millis = fraction == null
          ? 0
          : int.parse(fraction.padRight(3, '0'));
      lines.add(
        LyricLine(
          time: Duration(
            minutes: int.parse(stamp[1]!),
            seconds: seconds,
            milliseconds: millis,
          ),
          text: words,
        ),
      );
    }
  }
  // List.sort is not stable; the index keeps lines of one time in order.
  final indexed = lines.indexed.toList()
    ..sort((a, b) {
      final byTime = a.$2.time.compareTo(b.$2.time);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  return [for (final (_, line) in indexed) line];
}

/// The index of the last of [lines] (sorted by time) that starts at or
/// before [position]; null before the first line.
int? currentLineIndex(List<LyricLine> lines, Duration position) {
  var low = 0;
  var high = lines.length;
  // The first line that starts after position.
  while (low < high) {
    final mid = (low + high) >> 1;
    if (lines[mid].time <= position) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low == 0 ? null : low - 1;
}
