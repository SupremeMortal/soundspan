// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// A [LyricsRepository] answering from [byTitle] (keyed by track title),
/// [NoLyrics] for any other track. While [pending] is set a read never
/// emits; while [error] is set a read errors with it. Every track read is
/// recorded in [requested].
class FakeLyricsRepository implements LyricsRepository {
  /// The lyrics by track title.
  final Map<String, Lyrics> byTitle = {};

  /// Whether reads wait forever.
  bool pending = false;

  /// What reads fail with, if anything.
  Object? error;

  /// The tracks read, in order.
  final List<Track> requested = [];

  final List<StreamController<Cached<Lyrics>>> _open = [];

  @override
  Stream<Cached<Lyrics>> lyrics(Track track) {
    requested.add(track);
    if (pending) {
      final controller = StreamController<Cached<Lyrics>>();
      _open.add(controller);
      return controller.stream;
    }
    if (error case final error?) return Stream.error(error);
    return Stream.value(
      Cached(
        value: byTitle[track.meta.title] ?? const NoLyrics(),
        fetchedAt: DateTime.utc(2026),
      ),
    );
  }

  /// Closes the reads left waiting by [pending].
  Future<void> close() async {
    for (final controller in _open) {
      await controller.close();
    }
  }
}
