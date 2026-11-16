// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/platform/stream_auth/stream_auth.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Why a queue item could not be turned into an [EngineSource].
sealed class SourceResolutionException implements Exception {
  const new();
}

/// The track has no `playbackId`, so the server cannot stream it.
final class NotPlayable extends SourceResolutionException {
  /// Creates the exception for the queue entry [queueItemId].
  const new(this.queueItemId);

  /// The queue entry that cannot be played.
  final String queueItemId;

  @override
  String toString() => 'NotPlayable($queueItemId)';
}

/// Returns a credential with at least [minRemaining] of lifetime left;
/// `SessionController.ensureFresh` in the app.
typedef EnsureFreshCredentials = Future<Credentials> Function({
  required Duration minRemaining,
});

/// The lifetime a stream source's credential must have left when the
/// source is built (doc 06, Credential freshness).
const streamCredentialMinRemaining = Duration(hours: 2);

/// Turns a [QueueItem] into the [EngineSource] an engine plays (doc 06,
/// Source Resolution).
///
/// Every track takes the same path: its `playbackId` is passed to
/// [StreamUrls.track] as an opaque value, never inspected.
class SourceResolver {
  /// Creates the resolver of one profile.
  new({
    required this._ensureFresh,
    required this._urls,
    required this._quality,
    required this._auth,
  });

  final EnsureFreshCredentials _ensureFresh;
  final StreamUrls _urls;
  final StreamQualityPolicy _quality;
  final StreamAuth _auth;

  /// The source of [item], starting at [startAt].
  ///
  /// Throws [NotPlayable] for a track without a `playbackId`, and what
  /// `ensureFresh` throws when no usable credential can be had.
  Future<EngineSource> resolve(
    QueueItem item, {
    Duration startAt = Duration.zero,
  }) => _resolveStream(item, startAt);

  /// The stream branch (doc 06, step 3). The downloaded-file and offline
  /// steps run before it.
  Future<EngineSource> _resolveStream(QueueItem item, Duration startAt) async {
    if (item case TrackQueueItem(:final track) when track.playbackId == null) {
      throw NotPlayable(item.queueItemId);
    }
    final credentials = await _ensureFresh(
      minRemaining: streamCredentialMinRemaining,
    );
    final quality = item is TrackQueueItem ? await _quality.current() : null;
    final (Uri url, int? durationSec) = switch (item) {
      TrackQueueItem(:final track) => (
        _urls.track(
          track.playbackId!.value,
          quality: quality,
          // ignore: avoid_redundant_argument_values, plays are reported by PlayReporter, never by the stream request (P7).
          reportPlay: false,
        ),
        track.meta.durationSec,
      ),
      EpisodeQueueItem(:final podcast, :final episode) => (
        _urls.episode(podcast.id, episode.id),
        episode.durationSec,
      ),
    };
    final authorized = _auth.apply(url, credentials);
    return EngineSource(
      queueItemId: item.queueItemId,
      uri: authorized.uri,
      headers: authorized.headers,
      knownDuration: durationSec != null && durationSec > 0
          ? Duration(seconds: durationSec)
          : null,
      startAt: startAt,
      streamQuality: quality,
    );
  }
}
