// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/sync/data/confirmed_track_preferences.dart';
import 'package:soundspan/core/sync/data/plays_repository.dart';
import 'package:soundspan/core/sync/data/preference_remote_source.dart';
import 'package:soundspan/core/sync/data/preference_repository.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/sync_providers.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/domain/library_repository.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/domain/track.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan/shared/providers/repositories.dart';

export 'package:soundspan/core/sync/data/preference_repository.dart'
    show preferenceOfSignal;

/// The local data the preference handlers update: the profile's cache and
/// its library repository, both opened on first use.
typedef PreferenceCacheAccess = ({
  Future<CacheStore> Function() store,
  Future<LibraryRepository> Function() library,
});

/// Delivers `preference` ops and applies the server's answer (doc 07,
/// Worker).
///
/// On success the answered state is written into every cached copy of the
/// track and into [ConfirmedTrackPreferences], and the `liked` list is
/// marked stale, so its next read refetches.
/// On a conflict the track's album is fetched again when the cache knows
/// it; any other drop needs nothing, since removing the op removes the
/// overlay.
final class TrackPreferenceHandler implements OutboxHandler<PreferenceOp> {
  /// Creates the handler over [_remote] and [_cache]; answers are also
  /// recorded in [confirmed] when given.
  const new(this._remote, this._cache, {this.confirmed});

  final PreferenceRemoteSource _remote;
  final PreferenceCacheAccess _cache;

  /// Where confirmed answers are recorded for the players.
  final ConfirmedTrackPreferences? confirmed;

  @override
  Future<Object?> send(PreferenceOp op) => _remote.setTrackPreference(
    PlaybackId(op.playbackId),
    preferenceOfSignal(op.signal),
    meta: TrackMeta.fromJson(op.metadata),
  );

  @override
  Future<void> onSuccess(PreferenceOp op, Object? response) async {
    final store = await _cache.store();
    if (response is Preference) {
      confirmed?.record(op.playbackId, response);
      await store.setTrackPreference(op.playbackId, response);
    }
    await store.markListStale('liked');
  }

  @override
  Future<void> onDropped(PreferenceOp op, OutboxDropReason reason) async {
    if (reason != OutboxDropReason.conflict) return;
    final store = await _cache.store();
    await store.markListStale('liked');
    final cached = await store.watchTrack(op.playbackId).first;
    final albumId = cached?.value.albumId;
    if (albumId == null) return;
    await (await _cache.library()).refreshAlbum(albumId);
  }
}

/// Delivers `albumPreference` ops and applies the server's answer: on
/// success the answered state is written into every cached copy of the
/// album; on a conflict the album is fetched again.
final class AlbumPreferenceHandler implements OutboxHandler<AlbumPreferenceOp> {
  /// Creates the handler over [_remote] and [_cache].
  const new(this._remote, this._cache);

  final PreferenceRemoteSource _remote;
  final PreferenceCacheAccess _cache;

  @override
  Future<Object?> send(AlbumPreferenceOp op) =>
      _remote.setAlbumPreference(op.albumId, preferenceOfSignal(op.signal));

  @override
  Future<void> onSuccess(AlbumPreferenceOp op, Object? response) async {
    if (response is! Preference) return;
    await (await _cache.store()).setAlbumPreference(op.albumId, response);
  }

  @override
  Future<void> onDropped(AlbumPreferenceOp op, OutboxDropReason reason) async {
    if (reason != OutboxDropReason.conflict) return;
    await (await _cache.library()).refreshAlbum(op.albumId);
  }
}

/// The handlers for `preference`, `albumPreference` and `play` over
/// [preferences], [plays] and the local data of [cache]; confirmed track
/// likes are recorded in [confirmed] when given.
List<OutboxHandlerEntry> syncOutboxHandlers(
  PreferenceRemoteSource preferences,
  PlaysRepository plays,
  PreferenceCacheAccess cache, {
  ConfirmedTrackPreferences? confirmed,
}) => [
  outboxHandlerEntry(
    PreferenceOp.type,
    TrackPreferenceHandler(preferences, cache, confirmed: confirmed),
  ),
  outboxHandlerEntry(
    AlbumPreferenceOp.type,
    AlbumPreferenceHandler(preferences, cache),
  ),
  outboxHandlerEntry(
    PlayOp.type,
    SendOnlyOutboxHandler<PlayOp>(
      (op) => plays.report(
        playbackId: PlaybackId(op.playbackId),
        meta: TrackMeta.fromJson(op.metadata),
        playedAt: op.playedAt,
        listenedMs: op.listenedMs,
      ),
    ),
  ),
];

/// The outbox handlers of `core/sync`'s repositories.
final Provider<List<OutboxHandlerEntry>> syncOutboxHandlersProvider =
    Provider<List<OutboxHandlerEntry>>(
      (ref) => syncOutboxHandlers(
        ref.watch(preferenceRemoteSourceProvider),
        ref.watch(playsRepositoryProvider),
        (
          store: () => ref.read(cacheStoreProvider.future),
          library: () => ref.read(libraryRepositoryProvider.future),
        ),
        confirmed: ref.watch(confirmedTrackPreferencesProvider),
      ),
      dependencies: [
        confirmedTrackPreferencesProvider,
        preferenceRemoteSourceProvider,
        playsRepositoryProvider,
        cacheStoreProvider,
        libraryRepositoryProvider,
      ],
    );
