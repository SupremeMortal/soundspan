// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/features/explore/domain/radio_repository.dart';
import 'package:soundspan/features/explore/domain/radio_station.dart';
import 'package:soundspan/shared/data/cache_store.dart';
import 'package:soundspan/shared/data/library/library_mappers.dart';
import 'package:soundspan/shared/data/swr.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// The blob of the library's radio genres.
const radioGenresKey = 'radio:genres';

/// The blob of the library's radio decades.
const radioDecadesKey = 'radio:decades';

/// How long the genre and decade lists are fresh.
const Duration radioListTtl = Duration(minutes: 10);

/// [RadioRepository] over the cache and the generated `DiscoveryClient`.
/// The genre and decade lists are one blob each; stations are not cached.
class CachedRadioRepository implements RadioRepository {
  /// A repository reading [_client] into [_store] through [_swr].
  new(this._client, this._store, this._swr);

  final api.DiscoveryClient _client;
  final CacheStore _store;
  final Swr _swr;

  @override
  Stream<Cached<List<RadioGenre>>> genres() => _swr.watch(
    key: radioGenresKey,
    ttl: radioListTtl,
    cache: () => _store.watchBlob(radioGenresKey, (json) {
      return [
        for (final item in json! as List<Object?>)
          RadioGenre.fromJson(item! as Map<String, Object?>),
      ];
    }),
    fetch: _fetchGenres,
  );

  @override
  Future<void> refreshGenres() => _swr.refresh(radioGenresKey, _fetchGenres);

  @override
  Stream<Cached<List<RadioDecade>>> decades() => _swr.watch(
    key: radioDecadesKey,
    ttl: radioListTtl,
    cache: () => _store.watchBlob(radioDecadesKey, (json) {
      return [
        for (final item in json! as List<Object?>)
          RadioDecade.fromJson(item! as Map<String, Object?>),
      ];
    }),
    fetch: _fetchDecades,
  );

  @override
  Future<void> refreshDecades() => _swr.refresh(radioDecadesKey, _fetchDecades);

  @override
  Future<List<Track>> station(RadioStation station, {int limit = 50}) async {
    final (type, value) = switch (station) {
      GenreStation(:final name) => (api.RadioTypeValue.genre, name),
      DecadeStation(:final decade) => (api.RadioTypeValue.decade, '$decade'),
    };
    final wire = await _client.getRadio(
      type: api.RadioTypeKnown(type),
      value: value,
      limit: limit,
    );
    return [for (final track in wire.tracks) trackFromRadio(track)];
  }

  Future<void> _fetchGenres() async {
    final wire = await _client.listRadioGenres();
    await _store.putBlob(radioGenresKey, [
      for (final genre in wire.genres)
        RadioGenre(name: genre.genre, trackCount: genre.count),
    ]);
  }

  Future<void> _fetchDecades() async {
    final wire = await _client.listRadioDecades();
    await _store.putBlob(radioDecadesKey, [
      for (final decade in wire.decades)
        RadioDecade(decade: decade.decade, trackCount: decade.count),
    ]);
  }
}

/// A track of a radio station. An empty `playbackId` is a track the
/// server cannot play.
Track trackFromRadio(api.RadioTrack wire) => trackFromParts(
  id: wire.id,
  playbackId: wire.playbackId.isEmpty ? null : wire.playbackId,
  title: wire.title,
  artistName: wire.artist?.name ?? wire.album?.artist?.name,
  albumTitle: wire.album?.title,
  durationSec: wire.duration,
  artworkRef: wire.album?.coverArt ?? wire.album?.coverUrl,
  isrc: wire.isrc,
  albumId: wire.albumId ?? wire.album?.id,
  artistId: wire.artist?.id,
  loudnessLufs: wire.loudnessLufs,
  truePeakDb: wire.truePeakDb,
  albumLoudnessLufs: wire.album?.albumLoudnessLufs,
  albumTruePeakDb: wire.album?.albumTruePeakDb,
  discNumber: wire.discNo,
  trackNumber: wire.trackNo,
);
