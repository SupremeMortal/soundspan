// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/core/playback/stream_quality_info.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

/// Describes what the server streams for a track
/// (`GET /playback/stream-info/:playbackId`). `ApiException` propagates.
///
/// Answers are kept in memory per `(playbackId, quality)` for the life of
/// the repository, which is the profile scope; failures are not kept.
final class PlaybackInfoRepository {
  /// Creates a repository over the generated playback client.
  new(this._client);

  final api.PlaybackClient _client;
  final _cache = <(PlaybackId, String?), StreamQualityInfo>{};

  /// The stream of [id] at [quality]; null [quality] is the server default.
  Future<StreamQualityInfo> streamInfo(PlaybackId id, {String? quality}) async {
    final key = (id, quality);
    final cached = _cache[key];
    if (cached != null) return cached;
    final info = streamQualityInfoFromWire(
      await _client.getStreamInfo(
        playbackId: id.value,
        quality: quality == null ? null : api.PlaybackQuality.fromJson(quality),
      ),
    );
    return _cache[key] = info;
  }
}

/// Maps the wire stream description to [StreamQualityInfo].
StreamQualityInfo streamQualityInfoFromWire(api.StreamInfo info) =>
    StreamQualityInfo(
      quality: info.quality.toJson(),
      contentType: info.contentType,
      codec: info.codec,
      bitrate: info.bitrate,
      sampleRate: info.sampleRate,
      bitDepth: info.bitDepth,
      durationMs: info.durationMs,
      contentLength: info.contentLength,
    );
