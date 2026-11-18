// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/features/player/domain/lrc.dart';
import 'package:soundspan/features/player/domain/lyrics.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// How long found lyrics are fresh (doc 05, TTL table).
const Duration lyricsTtl = Duration(days: 30);

/// How long [NoLyrics] is fresh, so lyrics added on the server appear the
/// next day.
const Duration noLyricsTtl = Duration(hours: 24);

/// The blob that holds the lyrics of [track]: `lyrics:<tracks.key>`.
String lyricsKey(Track track) => 'lyrics:${CacheStore.trackKey(track)}';

/// [LyricsRepository] over the cache and the generated `PlaybackClient`
/// (doc 03, `GET /lyrics/:trackId`).
///
/// The path value is the track's library id when it has one, else its
/// playback id passed through unchanged; the metadata parameters always
/// come from `TrackMeta`. The client never inspects the id to choose.
class CachedLyricsRepository implements LyricsRepository {
  /// A repository reading [_client] into [_store] through [_swr]; [_clock]
  /// dates the [NoLyrics] of a track that cannot be looked up.
  new(this._client, this._store, this._swr, this._clock);

  final api.PlaybackClient _client;
  final CacheStore _store;
  final Swr _swr;
  final Clock _clock;

  @override
  Stream<Cached<Lyrics>> lyrics(Track track) {
    final trackId = track.libraryTrackId ?? track.playbackId?.value;
    if (trackId == null) {
      return Stream.value(
        Cached(value: const NoLyrics(), fetchedAt: _clock.now()),
      );
    }
    final key = lyricsKey(track);
    return _swr.watch(
      key: key,
      ttl: lyricsTtl,
      ttlOf: (lyrics) => lyrics is NoLyrics ? noLyricsTtl : lyricsTtl,
      cache: () => _store.watchBlob(key, Lyrics.fromJson),
      fetch: () async {
        await _store.putBlob(key, (await _fetch(trackId, track.meta)).toJson());
      },
    );
  }

  Future<Lyrics> _fetch(String trackId, TrackMeta meta) async {
    try {
      return lyricsOf(
        await _client.getLyrics(
          trackId: trackId,
          artist: meta.artist,
          title: meta.title,
          album: meta.album,
          duration: meta.durationSec,
        ),
      );
    } on api.NotFound {
      return const NoLyrics();
    }
  }
}

/// The domain lyrics of the server's [answer]: synced when it says so and
/// its LRC has timed lines, else plain when its plain text is not blank,
/// else [NoLyrics].
Lyrics lyricsOf(api.Lyrics answer) {
  if (answer.synced) {
    final lines = parseLrc(answer.syncedLyrics ?? '');
    if (lines.isNotEmpty) return SyncedLyrics(lines);
  }
  final plain = answer.plainLyrics;
  if (plain != null && plain.trim().isNotEmpty) return PlainLyrics(plain);
  return const NoLyrics();
}
