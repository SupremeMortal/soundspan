// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:collection/collection.dart';
import 'package:soundspan/features/player/domain/lrc.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// The lyrics of a track (doc 09, Now Playing, Queue, Lyrics).
sealed class Lyrics {
  const new();

  /// Decodes lyrics written by [toJson].
  factory fromJson(Object? json) {
    final map = json! as Map<String, Object?>;
    return switch (map['kind']) {
      'synced' => SyncedLyrics([
        for (final line
            in (map['lines']! as List<Object?>).cast<Map<String, Object?>>())
          LyricLine(
            time: Duration(milliseconds: line['ms']! as int),
            text: line['text']! as String,
          ),
      ]),
      'plain' => PlainLyrics(map['text']! as String),
      'none' => const NoLyrics(),
      final kind => throw FormatException('Unknown lyrics kind $kind'),
    };
  }

  /// The cache form of these lyrics.
  Map<String, Object?> toJson();
}

/// Lyrics timed line by line.
final class SyncedLyrics extends Lyrics {
  /// The timed [lines], sorted by time and never empty.
  const new(this.lines);

  /// The timed lines, sorted by time.
  final List<LyricLine> lines;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'synced',
    'lines': [
      for (final line in lines)
        {'ms': line.time.inMilliseconds, 'text': line.text},
    ],
  };

  @override
  // Every field is final; `meta` is not imported so the domain stays pure.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is SyncedLyrics &&
      const ListEquality<LyricLine>().equals(other.lines, lines);

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => const ListEquality<LyricLine>().hash(lines);

  @override
  String toString() => 'SyncedLyrics(${lines.length} lines)';
}

/// Untimed lyrics.
final class PlainLyrics extends Lyrics {
  /// The lyrics [text], not blank.
  const new(this.text);

  /// The words.
  final String text;

  @override
  Map<String, Object?> toJson() => {'kind': 'plain', 'text': text};

  @override
  // Every field is final; `meta` is not imported so the domain stays pure.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => other is PlainLyrics && other.text == text;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => text.hashCode;

  @override
  String toString() => 'PlainLyrics(${text.length} chars)';
}

/// The server found no lyrics.
final class NoLyrics extends Lyrics {
  /// No lyrics.
  const new();

  @override
  Map<String, Object?> toJson() => {'kind': 'none'};

  @override
  // Every field is final; `meta` is not imported so the domain stays pure.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => other is NoLyrics;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes, see ==.
  int get hashCode => (NoLyrics).hashCode;

  @override
  String toString() => 'NoLyrics()';
}

/// The lyrics of tracks, cached (doc 05, Read Policy).
abstract interface class LyricsRepository {
  /// The lyrics of [track], stale-while-revalidate: lyrics are fresh for
  /// 30 days and [NoLyrics] for 24 hours. A track the server cannot look
  /// up (no library id and no playback id) has [NoLyrics] without a
  /// request.
  Stream<Cached<Lyrics>> lyrics(Track track);
}
