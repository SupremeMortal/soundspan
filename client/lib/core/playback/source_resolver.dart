// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_store.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/stream_quality_policy.dart';
import 'package:soundspan/platform/clock/system_clock.dart';
import 'package:soundspan/platform/media_files/media_files.dart';
import 'package:soundspan/platform/stream_auth/stream_auth.dart';
import 'package:soundspan/shared/clock.dart';
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

/// The item has no downloaded file and the server cannot be reached
/// (offline mode, no network, or the server does not answer), so it cannot
/// be played now (doc 06, Source Resolution, step 2).
final class NotAvailableOffline extends SourceResolutionException {
  /// Creates the exception for the queue entry [queueItemId].
  const new(this.queueItemId);

  /// The queue entry that cannot be played offline.
  final String queueItemId;

  @override
  String toString() => 'NotAvailableOffline($queueItemId)';
}

/// The downloaded file a source plays: the item's key and the quality it
/// was downloaded at.
final class LocalDownload {
  /// Creates the description of item [key]'s file.
  const new({required this.key, this.quality});

  /// The download item the file belongs to.
  final DownloadItemKey key;

  /// The stored quality (`original`, `high`, `medium`, `low`), or null
  /// when the server default was downloaded.
  final String? quality;
}

/// What [SourceResolver.resolveSource] built: the engine's source and,
/// when it plays a downloaded file, which one.
final class ResolvedSource {
  /// Creates the result for [source], local when [download] is set.
  const new(this.source, {this.download});

  /// What the engine plays.
  final EngineSource source;

  /// The downloaded file [source] plays; null for a stream.
  final LocalDownload? download;

  /// Whether [source] plays a downloaded file.
  bool get isLocalFile => download != null;
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
/// A downloaded file is played whenever one exists; without one, an item
/// cannot be played while the server is out of reach; otherwise it is
/// streamed. The choice is by file presence only.
///
/// Every track takes the same path: its `playbackId` is passed to
/// [StreamUrls.track] and to its download key as an opaque value, never
/// inspected.
class SourceResolver {
  /// Creates the resolver of one profile.
  ///
  /// Without a download store (web, or a platform that cannot download)
  /// the downloaded-file step is skipped. Without a reachability controller
  /// the server counts as reachable. The requeue callback runs after a
  /// download whose file is gone was queued again, to start its transfer.
  new({
    required this._ensureFresh,
    required this._urls,
    required this._quality,
    required this._auth,
    this._downloads,
    this._files,
    this._reachability,
    this._clock = const SystemClock(),
    this._onRequeued,
  });

  final EnsureFreshCredentials _ensureFresh;
  final StreamUrls _urls;
  final StreamQualityPolicy _quality;
  final StreamAuth _auth;
  final DownloadStore? _downloads;
  final MediaFiles? _files;
  final ReachabilityController? _reachability;
  final Clock _clock;
  final void Function()? _onRequeued;

  /// The source of [item], starting at [startAt]; see [resolveSource].
  Future<EngineSource> resolve(
    QueueItem item, {
    Duration startAt = Duration.zero,
  }) async => (await resolveSource(item, startAt: startAt)).source;

  /// The source of [item], starting at [startAt], and whether it plays a
  /// downloaded file (doc 06, Source Resolution).
  ///
  /// 1. A `completed` download whose file exists is played from the file,
  ///    with no headers and no network call. A `completed` row whose file
  ///    is gone is queued again ([markMissing]) and resolution goes on.
  /// 2. While the server is out of reach, throws [NotAvailableOffline].
  /// 3. Otherwise the item is streamed.
  ///
  /// Throws [NotPlayable] for a track without a `playbackId`, and what
  /// `ensureFresh` throws when no usable credential can be had.
  Future<ResolvedSource> resolveSource(
    QueueItem item, {
    Duration startAt = Duration.zero,
  }) async {
    final local = await _resolveFile(item, startAt);
    if (local != null) return local;
    final reachability = _reachability;
    if (reachability != null && !reachability.isOnline) {
      throw NotAvailableOffline(item.queueItemId);
    }
    return ResolvedSource(await _resolveStream(item, startAt));
  }

  /// Records that the downloaded file [download] started playing now, for
  /// the eviction order of the storage limit (doc 07).
  Future<void> markPlayed(LocalDownload download) async {
    await _downloads?.touchLastPlayed(download.key, _clock.now());
  }

  /// Records that [download]'s file is gone or cannot be played: the item
  /// is queued to be downloaded again (doc 07, `completed → missing`).
  Future<void> markMissing(LocalDownload download) => _requeue(download.key);

  /// The downloaded-file branch (doc 06, step 1); null when there is no
  /// playable file.
  Future<ResolvedSource?> _resolveFile(QueueItem item, Duration startAt) async {
    final downloads = _downloads;
    final files = _files;
    if (downloads == null || files == null) return null;
    final key = _keyOf(item);
    if (key == null) return null;
    final path = await downloads.completedFile(key);
    if (path == null) return null;
    if (await files.length(path) == null) {
      await _requeue(key);
      return null;
    }
    final row = await downloads.item(key);
    return ResolvedSource(
      EngineSource(
        queueItemId: item.queueItemId,
        uri: Uri.file(path),
        knownDuration: _knownDuration(item),
        startAt: startAt,
      ),
      download: LocalDownload(key: key, quality: row?.quality),
    );
  }

  Future<void> _requeue(DownloadItemKey key) async {
    final downloads = _downloads;
    if (downloads == null) return;
    await downloads.markFileMissing(key, _clock.now());
    _onRequeued?.call();
  }

  static DownloadItemKey? _keyOf(QueueItem item) => switch (item) {
    TrackQueueItem(:final track) => switch (track.playbackId) {
      final id? => TrackItemKey(id.value),
      null => null,
    },
    EpisodeQueueItem(:final podcast, :final episode) => EpisodeItemKey(
      podcastId: podcast.id,
      episodeId: episode.id,
    ),
  };

  static Duration? _knownDuration(QueueItem item) {
    final seconds = switch (item) {
      TrackQueueItem(:final track) => track.meta.durationSec,
      EpisodeQueueItem(:final episode) => episode.durationSec,
    };
    return seconds != null && seconds > 0 ? Duration(seconds: seconds) : null;
  }

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
    final url = switch (item) {
      TrackQueueItem(:final track) => _urls.track(
        track.playbackId!.value,
        quality: quality,
        // ignore: avoid_redundant_argument_values, plays are reported by PlayReporter, never by the stream request (P7).
        reportPlay: false,
      ),
      EpisodeQueueItem(:final podcast, :final episode) => _urls.episode(
        podcast.id,
        episode.id,
      ),
    };
    final authorized = _auth.apply(url, credentials);
    return EngineSource(
      queueItemId: item.queueItemId,
      uri: authorized.uri,
      headers: authorized.headers,
      knownDuration: _knownDuration(item),
      startAt: startAt,
      streamQuality: quality,
    );
  }
}
