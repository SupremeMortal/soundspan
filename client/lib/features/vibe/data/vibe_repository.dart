// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/features/vibe/domain/vibe_repository.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/data/library/library_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// How long a [VibeRepository.similar] answer is reused.
const Duration similarTtl = Duration(minutes: 5);

/// [VibeRepository] over the generated `DiscoveryClient`. Similar tracks
/// are memoised per id for [similarTtl], so the Vibe screen and Start
/// radio share one request; failures are not memoised.
class ApiVibeRepository implements VibeRepository {
  /// A repository calling [_client], timed by [_clock].
  new(this._client, this._clock);

  final api.DiscoveryClient _client;
  final Clock _clock;
  final Map<(String, int), (DateTime, Future<List<Track>>)> _similar = {};

  @override
  Future<List<Track>> similar(String libraryId, {int limit = 50}) {
    final key = (libraryId, limit);
    final now = _clock.now();
    if (_similar[key] case (final at, final answer)
        when now.difference(at) < similarTtl) {
      return answer;
    }
    final answer = _fetchSimilar(libraryId, limit);
    _similar[key] = (now, answer);
    unawaited(
      answer.then<void>(
        (_) {},
        onError: (Object _) {
          if (identical(_similar[key]?.$2, answer)) _similar.remove(key);
        },
      ),
    );
    return answer;
  }

  Future<List<Track>> _fetchSimilar(String libraryId, int limit) async {
    try {
      final wire = await _client.getSimilarTracks(
        trackId: libraryId,
        limit: limit,
      );
      return [for (final track in wire.tracks) _fromSimilar(track)];
    } on api.NotFound {
      return const [];
    }
  }

  @override
  Future<List<Track>> search(String query, {int limit = 50}) async {
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength || trimmed.length > maxQueryLength) {
      return const [];
    }
    final wire = await _client.searchVibe(
      body: api.VibeSearchRequest(query: trimmed, limit: limit),
    );
    return [for (final track in wire.tracks) _fromSearch(track)];
  }
}

Track _fromSimilar(api.SimilarTrack wire) => trackFromParts(
  id: wire.id,
  playbackId: _playbackId(wire.playbackId),
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

Track _fromSearch(api.VibeSearchTrack wire) => trackFromParts(
  id: wire.id,
  playbackId: _playbackId(wire.playbackId),
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

/// An empty `playbackId` is a track the server cannot play.
String? _playbackId(String? value) =>
    value == null || value.isEmpty ? null : value;
